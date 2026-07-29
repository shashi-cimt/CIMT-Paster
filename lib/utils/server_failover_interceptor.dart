import 'package:dio/dio.dart';

import 'base.dart';
import 'server_manager.dart';

/// Transparently retries a request against the next candidate server when
/// the current one is unreachable (timeout / connection error) — the caller
/// never sees the failure unless every candidate is exhausted.
///
/// Deliberately does NOT fail over on a genuine HTTP error response
/// (4xx/5xx): that means the server IS reachable and answered, so switching
/// domains wouldn't help and could mask a real application error.
///
/// Attach one instance per Dio client, passing that same client in (it uses
/// `dio.fetch` to replay the request against the new domain).
class ServerFailoverInterceptor extends Interceptor {
  final Dio dio;

  ServerFailoverInterceptor(this.dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {

    print("===== ServerFailoverInterceptor =====");
    print("Status: ${err.response?.statusCode}");
    print("Type: ${err.type}");
    print("URL: ${err.requestOptions.path}");

    final shouldFailover =
        _isConnectivityError(err) || _isGatewayError(err);

    if (!shouldFailover) {
      return handler.next(err);
    }

    final originalPath = err.requestOptions.path;

    // Derive which domain THIS request actually went out on directly from
    // its own path, rather than trusting the shared, mutable APIURLs.URL /
    // APIURLs.baseURL — a concurrent request's failover could have already
    // advanced those between this request being sent and it erroring out,
    // which would silently corrupt the substring split below.
    String? firstMatch(List<String> candidates) {
      for (final url in candidates) {
        if (originalPath.startsWith(url)) return url;
      }
      return null;
    }

    final matchedSeePlanUrl = firstMatch(APIURLs.seePlanUrls);
    final matchedBaseUrl = firstMatch(APIURLs.baseUrls);

    final isSeePlan = matchedSeePlanUrl != null;
    final isBase = matchedBaseUrl != null;

    if (!isSeePlan && !isBase) {
      // Doesn't match either known URL family — nothing safe to fail over to.
      return handler.next(err);
    }

    String currentBase = (isSeePlan ? matchedSeePlanUrl : matchedBaseUrl)!;
    final suffix = originalPath.substring(currentBase.length);
    DioException lastError = err;

    while (true) {
      final switched = isSeePlan
          ? ServerManager.failoverSeePlanUrl(currentBase)
          : ServerManager.failoverBaseUrl(currentBase);

      if (!switched) {
        // No more candidates left; surface the original failure.
        return handler.next(lastError);
      }

      currentBase = isSeePlan ? APIURLs.URL : APIURLs.baseURL;
      final retryOptions = err.requestOptions.copyWith(path: '$currentBase$suffix');

      print(' [ServerFailover] ${suffix.split('?').first} unreachable, retrying via $currentBase');

      try {
        final response = await dio.fetch(retryOptions);
        return handler.resolve(response);
      } on DioException catch (retryError) {
        final shouldRetry =
            _isConnectivityError(retryError) || _isGatewayError(retryError);

        if (!shouldRetry) {
          return handler.next(retryError);
        }

        lastError = retryError;
        // Try the next server
      }
    }
  }

  bool _isConnectivityError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      default:
        return false;
    }
  }

  bool _isGatewayError(DioException e) {
    if (e.type != DioExceptionType.badResponse) {
      return false;
    }

    final statusCode = e.response?.statusCode;
    if (statusCode == null) return false;

    // Any 5xx means the origin/upstream is the problem, not our request —
    // safe to try a backup domain. This deliberately covers more than just
    // 502/503/504: domains fronted by Cloudflare (cimtone.cimtapps.com is)
    // surface origin-connectivity failures as 521-527 ("Web server is
    // down", "Origin unreachable", "A timeout occurred", etc.), which were
    // previously falling through as non-retryable application errors.
    return statusCode >= 500 && statusCode < 600;
  }
}
