

import 'package:canimage/Hive_Database/post_recca_seePlan_db.dart';
import 'package:canimage/Repository/post_recca_post_plan_repository.dart';
import 'package:canimage/Repository/remarks_repository.dart';
import 'package:canimage/Repository/village_artwork_repository.dart';
import 'package:canimage/utils/base.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Hive_Database/remarks_db.dart';
import '../Hive_Database/execution_seeplan_db.dart';
import '../Hive_Database/rework_db.dart';
import '../Hive_Database/village_artwork_db.dart';
import '../Repository/execution_plan_repository.dart';
import '../Repository/rework_post_plan_repository.dart';
import '../utils/DeviceIdManager.dart';
import '../utils/error_log.dart';
import '../utils/print_crash_manager.dart';
import '../utils/server_failover_interceptor.dart';
import '../utils/shared_preference.dart';

// ==================== PROVIDERS ====================
final isRefreshingProvider = StateProvider<bool>((ref) => false);

final plansProvider = FutureProvider<List<PlanItem>>((ref) async {
  final plans = await ExecutionHiveRepository().loadPlans();
  if (plans.isEmpty) {
    final fetchedPlans = await fetchPlansFromApi();
    await ExecutionHiveRepository().savePlans(fetchedPlans);
    return fetchedPlans;
  }
  return plans;
});

final reloadPlansProvider = FutureProvider.family<void, bool>((ref, forceReload) async {
  try {
    ref.read(isRefreshingProvider.notifier).state = true;

    // Fetch first; only touch local Hive data once we know the fetch succeeded,
    // so a failed/offline reload doesn't wipe out previously downloaded plans.
    final plans = await fetchPlansFromApi();

    await VillageArtworkHiveRepository().clearAllVillageArtworks();
    await ExecutionHiveRepository().clearAndSavePlansWithBalanceFilter(plans);

    if (plans.isNotEmpty) {
      final villageAndPlanCodes = plans.map((plan) => {'artworkId': plan.artworkId}).toList();
      await fetchAndStoreVillageDetails(villageAndPlanCodes);
    }

    ref.invalidate(plansProvider);
  } catch (e) {
    await _logError('Error during reloadPlansProvider', e);
    rethrow;
  } finally {
    ref.read(isRefreshingProvider.notifier).state = false;
  }
});

final plansSUProvider = FutureProvider<List<SUPlanModel>>((ref) async {
  final plans = await PostReccaPlanHiveRepository().loadSUPlans();
  if (plans.isEmpty) {
    final fetchedPlans = await fetchSUPlansFromApi();
    await PostReccaPlanHiveRepository().saveSUPlans(fetchedPlans);
    return fetchedPlans;
  }
  return plans;
});

final reloadSUPlansProvider = FutureProvider.family<void, bool>((ref, forceReload) async {
  try {
    ref.read(isRefreshingProvider.notifier).state = true;
    final plans = await fetchSUPlansFromApi();

    if (plans.isNotEmpty) {
      final remarksCodes = plans.map((plan) => {'ProjectId': plan.projectId}).toList();
      await fetchRemarksDetails(remarksCodes);
    }

    await PostReccaPlanHiveRepository().clearAndSaveSUPlans(plans);
    ref.invalidate(plansSUProvider);
  } catch (e) {
    await _logError('Error during reloadSUPlansProvider', e);
    rethrow;
  } finally {
    ref.read(isRefreshingProvider.notifier).state = false;
  }
});

final reworkPlansProvider = FutureProvider<List<ReworkModel>>((ref) async {
  final plans = await ReworkPlanRepository().loadReworkPlans();
  if (plans.isEmpty) {
    final fetchedPlans = await fetchReworkPlansFromApi();
    await ReworkPlanRepository().saveReworkPlans(fetchedPlans);
    return fetchedPlans;
  }
  return plans;
});

final reloadReworkPlansProvider = FutureProvider.family<void, bool>((ref, forceReload) async {
  try {
    ref.read(isRefreshingProvider.notifier).state = true;
    final plans = await fetchReworkPlansFromApi();

    if (plans.isNotEmpty) {
      final remarksCodes = plans.map((plan) => {'ProjectId': plan.projectId}).toList();
      await fetchRemarksDetails(remarksCodes);
    }

    await ReworkPlanRepository().clearAndSaveReworkPlans(plans);
    ref.invalidate(reworkPlansProvider);
  } catch (e) {
    await _logError('Error during reloadReworkPlansProvider', e);
    rethrow;
  } finally {
    ref.read(isRefreshingProvider.notifier).state = false;
  }
});

// ==================== DIO INSTANCE ====================
final Dio _dio = Dio();
Dio get dio => _dio;

void initialize() {

  _dio.interceptors.add(ServerFailoverInterceptor(_dio));
  _dio.interceptors.add(LogInterceptor(
    responseBody: true,
    request: true,
    requestBody: true,
    logPrint: print,
    error: true,
    requestHeader: true,
    responseHeader: true,
  ));
}

// ==================== API METHODS ====================
Future<List<PlanItem>> fetchPlansFromApi() async {
  try {
    final token = await getAuthToken();
    final String userId = (await getUserID()).toString();
    final String uId = (await getFirstUID()).toString();
    // final String userId = '20427';
    // final String uId = 'RP1A.200720.011|20427';

    final url = "${APIURLs.URL}${APIURLs.seePlanURL}";
    print("===== BEFORE REQUEST =====");
    print("Dio HashCode: ${identityHashCode(dio)}");
    print("Interceptor Count: ${dio.interceptors.length}");
    print(dio.interceptors);

    final body = {
      "planCode": "0",
      "villageCode": "0",
      "userId": userId,
     // "uId": DeviceIdManager.deviceId,
      "uId": uId,
    };

    print("========== FETCH PLANS ==========");
    print("URL: $url");
    print("BODY: $body");

    final response = await dio.post(
      url,
      data: body,
      options: _getOptions(token),
    );

    print("========== RESPONSE ==========");
    print("Status Code : ${response.statusCode}");
    print("Response : ${response.data}");

    if (response.statusCode == 200 &&
        response.data is Map<String, dynamic>) {
      final Map<String, dynamic> json = response.data;

      print("Keys : ${json.keys}");

      if (json.containsKey("Data")) {
        final List resultData = json["Data"];

        print("Total Plans : ${resultData.length}");

        return resultData
            .map((e) => PlanItem.fromJson(e))
            .toList();
      }
    }

    print("No Data Found");
    return [];
  } on DioException catch (e) {
    print("========== DIO ERROR ==========");
    print(e.response?.data);
    print(e.response?.statusCode);
    return _handleDioError<List<PlanItem>>(e, 'fetchPlansFromApi', []);
  } catch (e, s) {
    print(e);
    print(s);
    await _logError('fetchPlansFromApi unexpected error', e);
    rethrow;
  }
}


Future<List<SUPlanModel>> fetchSUPlansFromApi() async {
  try {
    final token = await getAuthToken();
    final response = await dio.get(
      '${APIURLs.baseURL}${APIURLs.seeSUPlanURL}?PlanCode=0&VillageCode=0',
      options: _getOptions(token),
    );

    if (response.statusCode == 200 && response.data is Map && response.data.containsKey('data')) {
      final resultData = response.data['data'] as List;
      return resultData.map((data) => SUPlanModel.fromJson(data)).toList();
    }
    return [];
  } on DioException catch (e) {
    return _handleDioError<List<SUPlanModel>>(e, 'fetchSUPlansFromApi', []);
  } catch (e) {
    await _logError('fetchSUPlansFromApi unexpected error', e);
    rethrow;
  }
}

Future<List<ReworkModel>> fetchReworkPlansFromApi() async {
  try {
    final token = await getAuthToken();
    final response = await dio.get(
      '${APIURLs.baseURL}${APIURLs.ReworkUrl}?PlanCode=0&VillageCode=0',
      options: _getOptions(token),
    );

    if (response.statusCode == 200 && response.data is Map && response.data.containsKey('data')) {
      final resultData = response.data['data'] as List;
      return resultData.map((data) => ReworkModel.fromJson(data)).toList();
    }
    return [];
  } on DioException catch (e) {
    return _handleDioError<List<ReworkModel>>(e, 'fetchReworkPlansFromApi', []);
  } catch (e) {
    await _logError('fetchReworkPlansFromApi unexpected error', e);
    rethrow;
  }
}

// ==================== VILLAGE DETAILS ====================
Future<void> fetchAndStoreVillageDetails(List<Map<String, dynamic>> villageAndPlanCodes) async {
  try {
    final token = await getAuthToken();
    final uniqueArtworkIds = villageAndPlanCodes
        .map((codePair) => codePair['artworkId']!.toString())
        .toSet();

    for (final artworkId in uniqueArtworkIds) {
      try {
        final response = await dio.get(
          '${APIURLs.baseURL}${APIURLs.artworkURL}?ArtworkId=$artworkId',
          options: _getOptions(token),
        );

        if (response.statusCode == 200 && response.data is Map && response.data.containsKey('data')) {
          final resultData = response.data['data'] as List;
          final artworks = resultData.map((data) => VillageArtwork.fromJson(data)).toList();
          await VillageArtworkHiveRepository().saveVillageArtwork(artworks);
        }
      } on DioException catch (e) {
        // Log but continue with next artwork
        await _logError('Failed to fetch artwork for ID: $artworkId', e);
        continue;
      }
    }
  } catch (e) {
    await _logError('fetchAndStoreVillageDetails error', e);
    rethrow;
  }
}

// ==================== REMARKS DETAILS ====================
Future<void> fetchRemarksDetails(List<Map<String, dynamic>> remarksCodes) async {
  try {
    final token = await getAuthToken();

    for (final codePair in remarksCodes) {
      final projectId = codePair['ProjectId']!.toString();

      try {
        final response = await dio.get(
          '${APIURLs.baseURL}${APIURLs.postRecceRemarksURL}?ProjectId=$projectId',
          options: _getOptions(token),
        );

        if (response.statusCode == 200 && response.data is Map && response.data.containsKey('data')) {
          final resultData = response.data['data'] as List;
          final remarks = resultData.map((data) => Remarks.fromJson(data)).toList();
          await RemarksHiveRepository().saveRemakrs(remarks);
        }
      } on DioException catch (e) {
        // Log but continue with next remarks
        await _logError('Failed to fetch remarks for projectId: $projectId', e);
        continue;
      }
    }
  } catch (e) {
    await _logError('fetchRemarksDetails error', e);
    rethrow;
  }
}

// ==================== HELPER METHODS ====================
Options _getOptions(String token) {
  return Options(
    headers: {
      'Content-Type': 'application/json',
      'Authorization': token,
    },
  );
}

T _handleDioError<T>(DioException e, String context, T fallback) {
  // Check for "No data found" or "No pending plans" as successful empty responses
  if (e.response?.statusCode == 400) {
    final responseData = e.response?.data;
    if (responseData is Map) {
      final message = responseData['message']?.toString() ?? '';
      if (message.contains('No pending plans found') ||
          message.contains('No Rework plans found') ||
          message.contains('No data found')) {
        return fallback;
      }
    }
  }

  // Log the error
  _logError('$context DioError', e);

  // Throw user-friendly error message
  throw _getUserFriendlyErrorMessage(e);
}

String _getUserFriendlyErrorMessage(DioException e) {
  if (e.response != null) {
    final statusCode = e.response!.statusCode;
    final serverMessage = _getServerMessage(e);

    switch (statusCode) {
      case 400:
        return serverMessage.isNotEmpty ? serverMessage : 'Bad Request. Please try again.';
      case 401:
        return 'Unauthorized: Please login again.';
      case 403:
        return 'Forbidden: Access denied. Please contact admin.';
      case 404:
        return 'Not Found: No data found.';
      case 500:
        return 'Internal Server Error. Please contact admin.';
      case 502:
        return 'Bad Gateway: Server temporarily unavailable.';
      case 503:
        return 'Service Unavailable. Please try again later.';
      default:
        return 'Server Error ($statusCode). Please try again later.';
    }
  } else {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please try again.';
      case DioExceptionType.connectionError:
        return 'Network error. Please check your internet connection.';
      case DioExceptionType.cancel:
        return 'Request cancelled.';
      default:
        return 'Network error. Please try again.';
    }
  }
}

String _getServerMessage(DioException e) {
  if (e.response?.data is Map) {
    final data = e.response!.data as Map;
    return data['message']?.toString() ?? '';
  }
  return '';
}

Future<void> _logError(String message, dynamic error) async {
  await ErrorReportManager.storeErrorReport(
    error: '$message: $error',
    level: ErrorLevel.error,
    stackTrace: StackTrace.current.toString(),
  );
}

// Keep the legacy method for backward compatibility if needed
String _getErrorMessage(DioException e) {
  return _getUserFriendlyErrorMessage(e);
}