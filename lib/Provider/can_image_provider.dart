// import 'package:canimage/Hive_Database/post_recca_seePlan_db.dart';
// import 'package:canimage/Repository/post_recca_post_plan_repository.dart';
// import 'package:canimage/Repository/remarks_repository.dart';
// import 'package:canimage/Repository/village_artwork_repository.dart';
// import 'package:canimage/utils/base.dart';
// import 'package:dio/dio.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../Hive_Database/remarks_db.dart';
// import '../Hive_Database/execution_seeplan_db.dart';
// import '../Hive_Database/rework_db.dart';
// import '../Hive_Database/village_artwork_db.dart';
// import '../Repository/execution_plan_repository.dart';
// import '../Repository/rework_post_plan_repository.dart';
// import '../utils/error_log.dart';
// import '../utils/print_crash_manager.dart';
// import '../utils/shared_preference.dart';
//
//
//
// // Add a state provider to track refresh state
// final isRefreshingProvider = StateProvider<bool>((ref) => false);
//
// final plansProvider = FutureProvider<List<PlanItem>>((ref) async {
//
//   List<PlanItem> plans = await ExecutionHiveRepository().loadPlans();
//   // If no plans are found in Hive, fetch from API
//   if (plans.isEmpty) {
//     plans = await fetchPlansFromApi();
//     await ExecutionHiveRepository().savePlans(plans);
//   }
//
//   return plans;
// });
//
//
//
// // Modified reload provider that properly refreshes the data
// final reloadPlansProvider = FutureProvider.family<void, bool>((ref, forceReload) async {
//
//   try {
//     ref.read(isRefreshingProvider.notifier).state = true;
//
//     await VillageArtworkHiveRepository().clearAllVillageArtworks();
//
//     // Always fetch fresh data from API when reloading
//     final plans = await fetchPlansFromApi();
//
//     // Clear Hive regardless of whether we got data or not
//     await ExecutionHiveRepository().clearAndSavePlansWithBalanceFilter(plans);
//
//     // Handle the case where we get empty data (no pending plans)
//     if (plans.isEmpty) {
//       // Don't fetch village details if no plans
//     } else {
//       // Only fetch village details if we have plans
//       List<Map<String, dynamic>> villageAndPlanCodes = plans
//           .map((plan) => {
//         'artworkId': plan.artworkId
//       })
//           .toList();
//
//       // Fetch and store the village details for each plan
//       await fetchAndStoreVillageDetails(villageAndPlanCodes);
//     }
//
//     // Invalidate the plans provider to force a complete refresh
//     ref.invalidate(plansProvider);
//   } catch (e) {
//     await ErrorReportManager.storeErrorReport(
//       error: 'Error during reload: $e',
//       level: ErrorLevel.critical,
//       stackTrace: StackTrace.current.toString(),
//     );
//     throw e;
//   } finally {
//     ref.read(isRefreshingProvider.notifier).state = false;
//   }
// });
//
// final Dio _dio = Dio();
// Dio get dio => _dio;
//
// void initialize() async {
//   _dio.interceptors.add(LogInterceptor(
//     responseBody: true,
//     request: true,
//     requestBody: true,
//     logPrint: print,
//     error: true,
//     requestHeader: true,
//     responseHeader: true,
//   ));
// }
//
// Future<List<PlanItem>> fetchPlansFromApi() async {
//   String getUIDNumber = await getLoginUID();
//   String getUserID = await getUserIDLogin();
//   String getToken = await getAuthToken();
//   try {
//     Response response = await dio.get(
//       "${APIURLs.baseURL}${APIURLs.seePlanURL}?PlanCode=0&VillageCode=0",
//       options: Options(
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': getToken,
//         },
//       ),
//     );
//
//     if (response.statusCode == 200) {
//       if (response.data is Map && response.data.containsKey('data')) {
//         List<dynamic> resultData = response.data['data'];
//         List<PlanItem> customerList = resultData
//             .map((customerData) => PlanItem.fromJson(customerData))
//             .toList();
//
//         return customerList;
//       }
//     }
//     return [];
//
//   } on DioError catch (e) {
//     if (e.response != null) {
//       // Check if it's a 400 with "No pending plans found" message
//       if (e.response!.statusCode == 400) {
//         final responseData = e.response!.data;
//         if (responseData is Map &&
//             responseData['message']?.toString().contains('No pending plans found') == true) {
//           await ErrorReportManager.storeErrorMessage(
//             'No pending plans found - returning empty list',
//             level: ErrorLevel.info,
//           );
//           // This is a legitimate "no data" response, not an error
//           return []; // Return empty list instead of throwing error
//         }
//         await ErrorReportManager.storeErrorReport(
//           error: 'Bad Request: No data found',
//           level: ErrorLevel.warning,
//           stackTrace: StackTrace.current.toString(),
//           additionalInfo: {'statusCode': 400},
//         );
//         // Other 400 errors are genuine errors
//         throw 'Bad Request: No data found. Please try again later.';
//       }
//
//       switch (e.response!.statusCode) {
//         case 401:
//           throw 'Unauthorized: Authentication failed. Please login again.';
//         case 403:
//           throw 'Forbidden: Access denied. Please contact admin.';
//         case 404:
//           throw 'Not Found: No data found. Please try again later.';
//         case 500:
//           throw 'Internal Server Error: Please contact admin for assistance.';
//         case 502:
//           throw 'Bad Gateway: Server temporarily unavailable. Please try again later.';
//         case 503:
//           throw 'Service Unavailable: Please try again later.';
//         default:
//           throw 'Server Error (${e.response!.statusCode}): No data found. Please try again later.';
//       }
//     } else {
//       await ErrorReportManager.storeErrorReport(
//         error: 'FetchPlansFromApi network error',
//         level: ErrorLevel.critical,
//         stackTrace: StackTrace.current.toString(),
//       );
//       throw 'Network error: Please check your internet connection and try again.';
//     }
//   } catch (e) {
//     await ErrorReportManager.storeErrorReport(
//       error: 'FetchPlansFromApi unexpected error: $e',
//       level: ErrorLevel.critical,
//       stackTrace: StackTrace.current.toString(),
//     );
//     if (e is String) {
//       throw e; // Re-throw our custom error messages
//     }
//     throw 'An unexpected error occurred. Please try again later.';
//   }
// }
//
//
//
// Future<void> fetchAndStoreVillageDetails(List<Map<String, dynamic>> villageAndPlanCodes) async {
//   String getUIDNumber = await getLoginUID();
//   String getToken = await getAuthToken();
//
//   // Get unique artwork IDs to avoid duplicate API calls
//   Set<String> uniqueArtworkIds = villageAndPlanCodes
//       .map((codePair) => codePair['artworkId']!.toString())
//       .toSet();
//
//   try {
//     for (String artworkId in uniqueArtworkIds) {
//       String url =
//           "${APIURLs.baseURL}${APIURLs.artworkURL}?ArtworkId=$artworkId";
//      // String url = "http://103.224.6.71:5006/api/Master/artworks?ArtworkId=$artworkId";
//
//       try {
//         Response response = await dio.get(
//           url,
//           options: Options(
//             headers: {
//               'Content-Type': 'application/json',
//               'Authorization': getToken,
//             },
//           ),
//         );
//
//         if (response.statusCode == 200) {
//           if (response.data is Map && response.data.containsKey('data')) {
//             List<dynamic> resultData = response.data['data'];
//
//             List<VillageArtwork> artworks = resultData
//                 .map((artworkData) => VillageArtwork.fromJson(artworkData))
//                 .toList();
//
//             // This will now accumulate artworks instead of clearing each time
//             await VillageArtworkHiveRepository().saveVillageArtwork(artworks);
//
//           }
//         }
//       } on DioError catch (e) {
//         // Continue with next artwork instead of failing completely
//         continue;
//       }
//     }
//
//     // Debug: Print final artwork count
//     final finalArtworks = await VillageArtworkHiveRepository().loadVillageArtwork();
//
//   } catch (e) {
//     throw 'Error during fetching artwork details: Please try again later.';
//   }
// }
//
// Future<void> fetchRemarksDetails(List<Map<String, dynamic>> remarksCodes) async {
//   String getToken = await getAuthToken();
//   // print("Fetching remarks details...");
//
//   try {
//     for (var codePair in remarksCodes) {
//       String projectId = codePair['ProjectId']!.toString();
//       //String url = "http://103.224.6.71:5006/api/Master/post-recca-remarks?ProjectId=$projectId";
//       String url = "${APIURLs.baseURL}${APIURLs.postRecceRemarksURL}?ProjectId=$projectId";
//        print("Fetching remarks for projectId: $projectId, URL: $url");
//
//       try {
//         Response response = await dio.get(
//           url,
//           options: Options(
//             headers: {
//               'Content-Type': 'application/json',
//               'Authorization': getToken,
//             },
//           ),
//         );
//
//         if (response.statusCode == 200) {
//           if (response.data is Map && response.data.containsKey('data')) {
//             List<dynamic> resultData = response.data['data'];
//
//             List<Remarks> remarks = resultData
//                 .map((remarkData) => Remarks.fromJson(remarkData))
//                 .toList();
//
//             await RemarksHiveRepository().saveRemakrs(remarks);
//             // print('Saved remarks data: $projectId');
//           }
//         } else {
//           // print('Failed to fetch remarks for projectId: $projectId, Status code: ${response.statusCode}');
//         }
//       } on DioError catch (e) {
//         // print('Error fetching remarks for $projectId: ${_getErrorMessage(e)}');
//         // Continue with next artwork instead of failing completely
//         continue;
//       }
//     }
//
//   } catch (e) {
//     await ErrorReportManager.storeErrorReport(
//       error: 'Error during fetching remarks details: $e',
//       level: ErrorLevel.critical,
//       stackTrace: StackTrace.current.toString(),
//     );
//     throw 'Error during fetching remarks details: Please try again later.';
//   }
// }
//
//
// String _getErrorMessage(DioError e) {
//   if (e.response != null) {
//     switch (e.response!.statusCode) {
//       case 400:
//         return 'Bad Request: No data found. Please try again later.';
//       case 401:
//         return 'Unauthorized: Authentication failed. Please login again.';
//       case 403:
//         return 'Forbidden: Access denied. Please contact admin.';
//       case 404:
//         return 'Not Found: No data found. Please try again later.';
//       case 500:
//         return 'Internal Server Error: Please contact admin for assistance.';
//       case 502:
//         return 'Bad Gateway: Server temporarily unavailable. Please try again later.';
//       case 503:
//         return 'Service Unavailable: Please try again later.';
//       default:
//         return 'Server Error (${e.response!.statusCode}): No data found. Please try again later.';
//     }
//   } else {
//     return 'Network error: Please check your internet connection and try again.';
//   }
// }
//
// final plansSUProvider = FutureProvider<List<SUPlanModel>>((ref) async {
//
//   List<SUPlanModel> plans = await PostReccaPlanHiveRepository().loadSUPlans();
//   // print('Plans from Hive: ${plans.length}');
//
//   // If no plans are found in Hive, fetch from API
//   if (plans.isEmpty) {
//     plans = await fetchSUPlansFromApi();
//     await PostReccaPlanHiveRepository().saveSUPlans(plans);
//   }
//
//   return plans;
// });
//
// final reworkPlansProvider = FutureProvider<List<ReworkModel>>((ref) async {
//
//   List<ReworkModel> plans = await ReworkPlanRepository().loadReworkPlans();
//
//   // If Hive empty → fetch from API
//   if (plans.isEmpty) {
//     plans = await fetchReworkPlansFromApi(); // 🔥 YOU CREATE THIS
//     await ReworkPlanRepository().saveReworkPlans(plans);
//   }
//
//   return plans;
// });
//
//
// // Modified reload provider that properly refreshes the data
// final reloadSUPlansProvider = FutureProvider.family<void, bool>((ref, forceReload) async {
//
//
//   try {
//     ref.read(isRefreshingProvider.notifier).state = true;
//
//     // Always fetch fresh data from API when reloading
//     final plans = await fetchSUPlansFromApi();
//
//     // print("plan.projectId::::111");
//     List<Map<String, dynamic>> remarksCodes = plans
//         .map((plan) => {
//       'ProjectId': plan.projectId
//     })
//         .toList();
//     // print("plan.projectId");
//     // print(remarksCodes);
//     // print('Fetched remarksCodes for ${remarksCodes.length} plans');
//     // Fetch and store the village details for each plan
//     await fetchRemarksDetails(remarksCodes);
//
//     // Clear the Hive box and save new plans
//     await PostReccaPlanHiveRepository().clearAndSaveSUPlans(plans);
//
//     // Invalidate the plans provider to force a complete refresh
//     ref.invalidate(plansSUProvider);
//
//     // print('Reload completed successfully with ${plans.length} plans');
//
//   } catch (e) {
//     await ErrorReportManager.storeErrorReport(
//       error: 'Error during SU plans reload: $e',
//       level: ErrorLevel.critical,
//       stackTrace: StackTrace.current.toString(),
//     );
//     throw e;
//   } finally {
//     ref.read(isRefreshingProvider.notifier).state = false;
//   }
// });
//
// // Modified reload provider that properly refreshes the data
// final reloadReworkPlansProvider = FutureProvider.family<void, bool>((ref, forceReload) async {
//
//
//   try {
//     ref.read(isRefreshingProvider.notifier).state = true;
//
//     // Always fetch fresh data from API when reloading
//     final plans = await fetchReworkPlansFromApi();
//
//     // print("plan.projectId::::111");
//     List<Map<String, dynamic>> remarksCodes = plans
//         .map((plan) => {
//       'ProjectId': plan.projectId
//     })
//         .toList();
//     // print("plan.projectId");
//     // print(remarksCodes);
//     // print('Fetched remarksCodes for ${remarksCodes.length} plans');
//     // Fetch and store the village details for each plan
//     await fetchRemarksDetails(remarksCodes);
//
//     // Clear the Hive box and save new plans
//     await ReworkPlanRepository().clearAndSaveReworkPlans(plans);
//
//     // Invalidate the plans provider to force a complete refresh
//     ref.invalidate(reworkPlansProvider);
//
//     // print('Reload completed successfully with ${plans.length} plans');
//
//   } catch (e) {
//     await ErrorReportManager.storeErrorReport(
//       error: 'Error during Rework plans reload: $e',
//       level: ErrorLevel.critical,
//       stackTrace: StackTrace.current.toString(),
//     );
//     throw e;
//   } finally {
//     ref.read(isRefreshingProvider.notifier).state = false;
//   }
// });
//
//
// Future<List<SUPlanModel>> fetchSUPlansFromApi() async {
//   String getToken = await getAuthToken();
//   // print(getToken);
//   // print("getToken");
//
//   try {
//     // print("${APIURLs.baseURL}${APIURLs.seeSUPlanURL}?PlanCode=0&VillageCode=0");
//     Response response = await dio.get(
//       "${APIURLs.baseURL}${APIURLs.seeSUPlanURL}?PlanCode=0&VillageCode=0",
//       options: Options(
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': getToken,
//         },
//       ),
//     );
//
//     // print(response.data);
//     // print(getToken);
//     // print("response.data");
//
//     if (response.statusCode == 200) {
//       if (response.data is Map && response.data.containsKey('data')) {
//         List<dynamic> resultData = response.data['data'];
//         // print(resultData.length);
//         // print("resultData.length");
//
//         List<SUPlanModel> customerList = resultData
//             .map((customerData) => SUPlanModel.fromJson(customerData))
//             .toList();
//         return customerList;
//       }
//     }
//     return [];
//
//   } on DioError catch (e) {
//     if (e.response != null) {
//       switch (e.response!.statusCode) {
//         case 400:
//           throw 'Bad Request: No data found. Please try again later.';
//         case 401:
//           throw 'Unauthorized: Authentication failed. Please login again.';
//         case 403:
//           throw 'Forbidden: Access denied. Please contact admin.';
//         case 404:
//           throw 'Not Found: No data found. Please try again later.';
//         case 500:
//           throw 'Internal Server Error: Please contact admin for assistance.';
//         case 502:
//           throw 'Bad Gateway: Server temporarily unavailable. Please try again later.';
//         case 503:
//           throw 'Service Unavailable: Please try again later.';
//         default:
//           throw 'Server Error (${e.response!.statusCode}): No data found. Please try again later.';
//       }
//     } else {
//       await ErrorReportManager.storeErrorReport(
//         error: 'FetchSUPlansFromApi network error',
//         level: ErrorLevel.critical,
//         stackTrace: StackTrace.current.toString(),
//       );
//       throw 'Network error: Please check your internet connection and try again.';
//     }
//   } catch (e) {
//     await ErrorReportManager.storeErrorReport(
//       error: 'FetchSUPlansFromApi unexpected error: $e',
//       level: ErrorLevel.critical,
//       stackTrace: StackTrace.current.toString(),
//     );
//     if (e is String) {
//       throw e; // Re-throw our custom error messages
//     }
//     throw 'An unexpected error occurred. Please try again later.';
//   }
// }
//
// Future<List<ReworkModel>> fetchReworkPlansFromApi() async {
//   String getUIDNumber = await getLoginUID();
//   String getUserID = await getUserIDLogin();
//   String getToken = await getAuthToken();
//   // print(getToken);
//   // print("getToken");
//
//   try {
//     Response response = await dio.get(
//       "${APIURLs.baseURL}${APIURLs.ReworkUrl}?PlanCode=0&VillageCode=0",
//       options: Options(
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': getToken,
//         },
//       ),
//     );
//
//     // print(response.data);
//     // print(getToken);
//     // print("response.data");
//
//     if (response.statusCode == 200) {
//       if (response.data is Map && response.data.containsKey('data')) {
//         List<dynamic> resultData = response.data['data'];
//         // print(resultData.length);
//         // print("resultData.length");
//
//         List<ReworkModel> customerList = resultData
//             .map((customerData) => ReworkModel.fromJson(customerData))
//             .toList();
//         return customerList;
//       }
//     }
//     return [];
//
//   } on DioError catch (e) {
//     if (e.response != null) {
//       // Check if it's a 400 with "No pending plans found" message
//       if (e.response!.statusCode == 400) {
//         final responseData = e.response!.data;
//         if (responseData is Map &&
//             responseData['message']?.toString().contains('No Rework plans found') == true) {
//           await ErrorReportManager.storeErrorMessage(
//             'No Rework plans found - returning empty list',
//             level: ErrorLevel.info,
//           );
//           // This is a legitimate "no data" response, not an error
//           return []; // Return empty list instead of throwing error
//         }
//         await ErrorReportManager.storeErrorReport(
//           error: 'Bad Request: No data found',
//           level: ErrorLevel.warning,
//           stackTrace: StackTrace.current.toString(),
//           additionalInfo: {'statusCode': 400},
//         );
//         // Other 400 errors are genuine errors
//         throw 'Bad Request: No data found. Please try again later.';
//       }
//
//       switch (e.response!.statusCode) {
//         case 401:
//           throw 'Unauthorized: Authentication failed. Please login again.';
//         case 403:
//           throw 'Forbidden: Access denied. Please contact admin.';
//         case 404:
//           throw 'Not Found: No data found. Please try again later.';
//         case 500:
//           throw 'Internal Server Error: Please contact admin for assistance.';
//         case 502:
//           throw 'Bad Gateway: Server temporarily unavailable. Please try again later.';
//         case 503:
//           throw 'Service Unavailable: Please try again later.';
//         default:
//           throw 'Server Error (${e.response!.statusCode}): No data found. Please try again later.';
//       }
//     } else {
//       await ErrorReportManager.storeErrorReport(
//         error: 'FetchPlansFromApi network error',
//         level: ErrorLevel.critical,
//         stackTrace: StackTrace.current.toString(),
//       );
//       throw 'Network error: Please check your internet connection and try again.';
//     }
//   } catch (e) {
//     await ErrorReportManager.storeErrorReport(
//       error: 'FetchPlansFromApi unexpected error: $e',
//       level: ErrorLevel.critical,
//       stackTrace: StackTrace.current.toString(),
//     );
//     if (e is String) {
//       throw e; // Re-throw our custom error messages
//     }
//     throw 'An unexpected error occurred. Please try again later.';
//   }
// }

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
    await VillageArtworkHiveRepository().clearAllVillageArtworks();

    final plans = await fetchPlansFromApi();
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
    // final String userId = '20251';
    // final String uId = '1204884291782376';

    final url = "${APIURLs.URL}${APIURLs.seePlanURL}";

    final body = {
      "planCode": "0",
      "villageCode": "0",
      "userId": userId,
      "uId": DeviceIdManager.deviceId,
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
    return [];
  } catch (e, s) {
    print(e);
    print(s);
    return [];
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