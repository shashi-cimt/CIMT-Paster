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
    if (!_isConnectivityError(err)) {
      return handler.next(err);
    }

    final originalPath = err.requestOptions.path;

    final isSeePlan = originalPath.startsWith(APIURLs.URL);
    final isBase = !isSeePlan && originalPath.startsWith(APIURLs.baseURL);

    if (!isSeePlan && !isBase) {
      // Doesn't match either known URL family — nothing safe to fail over to.
      return handler.next(err);
    }

    String currentBase = isSeePlan ? APIURLs.URL : APIURLs.baseURL;
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
        if (!_isConnectivityError(retryError)) {
          // Got a real server response this time (e.g. a 4xx/5xx) — stop
          // failing over and let normal error handling take it from here.
          return handler.next(retryError);
        }
        lastError = retryError;
        // loop again — try the next candidate, if any
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
}
