// import 'dart:convert';
// import 'dart:io';
// import 'package:canimage/Model/execution_dashboard_summary_details_model.dart';
// import 'package:canimage/Model/login_model.dart';
// import 'package:canimage/utils/base.dart';
// import 'package:canimage/utils/sync_crash_manager.dart';
// import 'package:dio/dio.dart';
// import 'package:intl/intl.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../Hive_Database/post_recca_image_upload_db.dart';
// import '../Hive_Database/execution_image_upload_db.dart';
// import '../Model/execution_dashboard_summary_model.dart';
// import '../Model/project_model.dart';
// import '../Model/recca_remarks_model.dart';
// import '../Model/registration_model.dart';
// import '../Model/see_plan_model.dart';
// import '../Repository/execution_image_upload_repository.dart';
// import '../Repository/post_recca_image_upload_repository.dart';
// import '../utils/crash_manager.dart';
// import '../utils/error_log.dart';
// import '../utils/print_crash_manager.dart';
// import '../utils/shared_preference.dart';
// import '../utils/token_manager.dart';
//
// class Auth {
//   static final Dio _dio = Dio(); // Create a Dio instance
//   static Dio get dio => _dio;
//
//   static void initialize() async {
//     _dio.interceptors.add(AuthInterceptor()); // Add this line
//     _dio.interceptors.add(LogInterceptor(
//       responseBody: true,
//       request: true,
//       requestBody: true,
//       logPrint: print,
//       error: true,
//       requestHeader: true,
//       responseHeader: true,
//     ));
//   }
//
//   // API method to authenticate Registration
//   Future<RegistrationAuthModel?> registration(String firstName, String lastName, String phoneNumber, String password, String uid, String role, {File? userImage}) async {
//     try {
//       await CrashReportManager.storeLogMessage(
//           "REGISTRATION API REQUEST\n"
//               "URL: ${APIURLs.registerURL}\n"
//               "FirstName: $firstName\n"
//               "LastName: $lastName\n"
//               "PhoneNumber: $phoneNumber\n"
//               "UID: $uid\n"
//               "Role: $role\n"
//               "Image: ${userImage?.path ?? "No Image"}"
//       );
//
//       FormData formData = FormData.fromMap({
//         "FirstName": firstName,
//         "LastName": lastName,
//         "PhoneNumber": phoneNumber,
//         "Password": password,
//         "UId": uid,
//         "RoleFlag": role,
//         // ImagePath send as null (or empty string depending on backend)
//         "UserImagePath": null,
//         if (userImage != null)
//           "UserImage": await MultipartFile.fromFile(
//             userImage.path,
//             filename: userImage.path.split('/').last,
//           ),
//       });
//       // var query = {
//       //   "firstName": firstName,
//       //   "lastName": lastName,
//       //   "phoneNumber": phoneNumber,
//       //   "password": password,
//       //   "uId": uid,
//       //   "roleFlag": role
//       // };
//       Response response = await dio.post(
//         "${APIURLs.baseURL}${APIURLs.registerURL}",
//         data: formData,
//         options: Options(
//           headers: {
//             // Dio will set proper boundary, you can even skip this header
//             'Content-Type': 'multipart/form-data',
//             'accept': '*/*',
//           },
//         ),
//       );
//       await CrashReportManager.storeLogMessage(
//           "REGISTRATION API RESPONSE\n"
//               "StatusCode: ${response.statusCode}\n"
//               "Response: ${response.data}"
//       );
//
//       if (response.data != null) {
//         Map<String, dynamic> resultData = response.data;
//         RegistrationAuthModel result = RegistrationAuthModel.fromJson(resultData);
//         if (result.isSuccess == true) {
//           await CrashReportManager.storeLogMessage(
//               "REGISTRATION SUCCESS\n"
//                   "Message: ${result.message}"
//           );
//         }
//         return result;
//       } else {
//         await ErrorReportManager.storeErrorReport(
//           error: 'No response from server during registration',
//           level: ErrorLevel.warning,
//           additionalInfo: {'phoneNumber': phoneNumber},
//         );
//         return RegistrationAuthModel(
//           isSuccess: false,
//           message: "No response from server",
//         );
//       }
//     } on DioException catch (dioError) {
//       await CrashReportManager.storeLogMessage(
//           "REGISTRATION DIO ERROR\n"
//               "Type: ${dioError.type}\n"
//               "StatusCode: ${dioError.response?.statusCode}\n"
//               "Response: ${dioError.response?.data}"
//       );
//       if (dioError.response?.data != null) {
//         try {
//           Map<String, dynamic> errorData = dioError.response!.data;
//           RegistrationAuthModel result = RegistrationAuthModel.fromJson(errorData);
//           await ErrorReportManager.storeErrorReport(
//             error: 'Registration failed: ${result.message}',
//             level: ErrorLevel.error,
//             stackTrace: StackTrace.current.toString(),
//             additionalInfo: {
//               'phoneNumber': phoneNumber,
//               'statusCode': dioError.response?.statusCode ?? 0,
//             },
//           );
//           return result;
//         } catch (parseError) {
//           print("Failed to parse error response: $parseError");
//         }
//       }
//
//       String errorMessage;
//       switch (dioError.type) {
//         case DioExceptionType.connectionTimeout:
//         case DioExceptionType.sendTimeout:
//         case DioExceptionType.receiveTimeout:
//           errorMessage = "Connection timeout. Please try again.";
//           break;
//         case DioExceptionType.badResponse:
//           errorMessage = "Phone Number or Password is Incorrect";
//           break;
//         case DioExceptionType.cancel:
//           errorMessage = "Request cancelled";
//           break;
//         case DioExceptionType.connectionError:
//           errorMessage = "Network error occurred. Please check your internet connection.";
//           break;
//         default:
//           errorMessage = "Phone Number or Password is Incorrect";
//       }
//
//       await ErrorReportManager.storeErrorReport(
//         error: 'Registration DioException: $errorMessage',
//         level: ErrorLevel.error,
//         stackTrace: StackTrace.current.toString(),
//         additionalInfo: {
//           'phoneNumber': phoneNumber,
//           'errorType': dioError.type.toString(),
//         },
//       );
//
//       return RegistrationAuthModel(
//         isSuccess: false,
//         message: errorMessage,
//       );
//     } catch (e) {
//       await CrashReportManager.storeLogMessage(
//           "REGISTRATION UNKNOWN ERROR\n"
//               "Error: $e"
//       );
//       await ErrorReportManager.storeErrorReport(
//         error: 'Registration unexpected error: $e',
//         level: ErrorLevel.critical,
//         stackTrace: StackTrace.current.toString(),
//         additionalInfo: {'phoneNumber': phoneNumber},
//       );
//       return RegistrationAuthModel(
//         isSuccess: false,
//         message: "An unexpected error occurred. Please try again.",
//       );
//     }
//   }
//
//   //LoginAuth
//   // Future<LoginAuthModel?> login(String phoneNumber, String password, String userID, String UID) async {
//   //   try {
//   //     var query = {
//   //       "loginId": phoneNumber,
//   //       "password": password,
//   //       //"uId": "9698520501771303"
//   //       "uId": UID
//   //     };
//   //
//   //     Response response = await dio.post(
//   //       "${APIURLs.baseURL}${APIURLs.loginURL}",
//   //       data: query,
//   //       options: Options(
//   //         headers: {'Content-Type': 'application/json'},
//   //       ),
//   //     );
//   //
//   //     if (response.data != null) {
//   //       Map<String, dynamic> resultData = response.data;
//   //       LoginAuthModel result = LoginAuthModel.fromJson(resultData);
//   //       await PrintCrashReportManager.storeCrashReport(
//   //         error: "Login Data: ${response.data}",
//   //         stackTrace: StackTrace.current.toString(),
//   //         additionalInfo: {
//   //           'phase': 'Login Data',
//   //           'timestamp': DateTime.now().toIso8601String(),
//   //         },
//   //       );
//   //       return result;
//   //     } else {
//   //       await ErrorReportManager.storeErrorReport(
//   //         error: 'No response from server during login',
//   //         level: ErrorLevel.warning,
//   //         additionalInfo: {'phoneNumber': phoneNumber},
//   //       );
//   //       return LoginAuthModel(
//   //         isSuccess: false,
//   //         message: "No response from server",
//   //       );
//   //     }
//   //   } on DioException catch (dioError) {
//   //     if (dioError.response?.data != null) {
//   //       try {
//   //         Map<String, dynamic> errorData = dioError.response!.data;
//   //         LoginAuthModel result = LoginAuthModel.fromJson(errorData);
//   //
//   //         await ErrorReportManager.storeErrorReport(
//   //           error: 'Login failed: ${result.message}',
//   //           level: ErrorLevel.error,
//   //           stackTrace: StackTrace.current.toString(),
//   //           additionalInfo: {
//   //             'phoneNumber': phoneNumber,
//   //             'statusCode': dioError.response?.statusCode ?? 0,
//   //           },
//   //         );
//   //         return result;
//   //       } catch (parseError) {
//   //         print("Failed to parse error response: $parseError");
//   //       }
//   //     }
//   //
//   //     String errorMessage;
//   //     switch (dioError.type) {
//   //       case DioExceptionType.connectionTimeout:
//   //       case DioExceptionType.sendTimeout:
//   //       case DioExceptionType.receiveTimeout:
//   //         errorMessage = "Connection timeout. Please try again.";
//   //         break;
//   //       case DioExceptionType.badResponse:
//   //         errorMessage = "Phone Number or Password is Incorrect";
//   //         break;
//   //       case DioExceptionType.cancel:
//   //         errorMessage = "Request cancelled";
//   //         break;
//   //       case DioExceptionType.connectionError:
//   //         errorMessage = "Network error occurred. Please check your internet connection.";
//   //         break;
//   //       default:
//   //         errorMessage = "Phone Number or Password is Incorrect";
//   //     }
//   //
//   //     await ErrorReportManager.storeErrorReport(
//   //       error: 'Login DioException: $errorMessage',
//   //       level: ErrorLevel.error,
//   //       stackTrace: StackTrace.current.toString(),
//   //       additionalInfo: {
//   //         'phoneNumber': phoneNumber,
//   //         'errorType': dioError.type.toString(),
//   //       },
//   //     );
//   //
//   //     return LoginAuthModel(
//   //       isSuccess: false,
//   //       message: errorMessage,
//   //     );
//   //   } catch (e) {
//   //
//   //     await ErrorReportManager.storeErrorReport(
//   //       error: 'Login unexpected error: $e',
//   //       level: ErrorLevel.critical,
//   //       stackTrace: StackTrace.current.toString(),
//   //       additionalInfo: {'phoneNumber': phoneNumber},
//   //     );
//   //     return LoginAuthModel(
//   //       isSuccess: false,
//   //       message: "An unexpected error occurred. Please try again.",
//   //     );
//   //   }
//   // }
//
//
//   //Remarks API
//   Future<LoginAuthModel?> login(
//       String phoneNumber,
//       String password,
//       String userID,
//       String UID,
//       ) async {try {var query = {"loginId": phoneNumber, "password": password, "uId": UID};await CrashReportManager.storeLogMessage(" USER API REQUEST\n""URL : ${APIURLs.loginURL}\n""BODY : $query");Response response = await dio.post("${APIURLs.baseURL}${APIURLs.loginURL}", data: query, options: Options(headers: {'Content-Type': 'application/json'}),);await CrashReportManager.storeLogMessage("LOGIN API RESPONSE\n""StatusCode: ${response.statusCode}\n""Response: ${response.data}");if (response.data != null) {final result = LoginAuthModel.fromJson(response.data);
//
//         /// ✅ SAVE USER DATA (IMPORTANT)
//         if (result.isSuccess == true && result.data != null) {
//           final prefs = await SharedPreferences.getInstance();
//
//           await prefs.setString("userId", result.data!.userId ?? "");
//           await prefs.setString("uId", result.data!.uId ?? "");
//           await prefs.setString("roleFlag", result.data!.roleFlag ?? "");
//           await prefs.setString("roleName", (result.data!.roleName ?? "").trim());
//           await prefs.setString("fname", (result.data!.fname ?? "").trim());
//           await prefs.setString("token", result.data!.accessToken ?? "");
//
//           await CrashReportManager.storeLogMessage(
//               "LOGIN SUCCESS\n"
//                   "userId: ${result.data!.userId}\n"
//                   "role: ${result.data!.roleName}\n"
//                   "name: ${result.data!.fname}"
//           );
//
//           /// Debug log
//           await CrashReportManager.storeLogMessage(
//               "LOGIN SUCCESS DATA SAVED\n"
//                   "userId: ${result.data!.userId}\n"
//                   "role: ${result.data!.roleName}\n"
//                   "name: ${result.data!.fname}"
//           );
//         }
//
//         return result;
//       }
//
//       ///  No response
//       await ErrorReportManager.storeErrorReport(
//         error: 'No response from server during login',
//         level: ErrorLevel.warning,
//         additionalInfo: {'phoneNumber': phoneNumber},
//       );
//
//       return LoginAuthModel(
//         isSuccess: false,
//         message: "No response from server",
//       );
//     }
//
//     ///  DIO ERROR
//     on DioException catch (dioError) {
//       ///  PRINT DIO ERROR
//       await CrashReportManager.storeLogMessage(
//           "LOGIN DIO ERROR\n"
//               "Type: ${dioError.type}\n"
//               "StatusCode: ${dioError.response?.statusCode}\n"
//               "Response: ${dioError.response?.data}"
//       );
//       String errorMessage = "Something went wrong";
//
//       if (dioError.response?.data != null) {
//         try {
//           final errorData = dioError.response!.data;
//           final result = LoginAuthModel.fromJson(errorData);
//
//           errorMessage = result.message ?? errorMessage;
//
//           await ErrorReportManager.storeErrorReport(
//             error: 'Login failed: $errorMessage',
//             level: ErrorLevel.error,
//             stackTrace: StackTrace.current.toString(),
//             additionalInfo: {
//               'phoneNumber': phoneNumber,
//               'statusCode': dioError.response?.statusCode ?? 0,
//             },
//           );
//
//           return result;
//         } catch (_) {}
//       }
//
//       switch (dioError.type) {
//         case DioExceptionType.connectionTimeout:
//         case DioExceptionType.sendTimeout:
//         case DioExceptionType.receiveTimeout:
//           errorMessage = "Connection timeout. Please try again.";
//           break;
//
//         case DioExceptionType.badResponse:
//           errorMessage = "Phone Number or Password is Incorrect";
//           break;
//
//         case DioExceptionType.connectionError:
//           errorMessage = "No internet connection";
//           break;
//
//         case DioExceptionType.cancel:
//           errorMessage = "Request cancelled";
//           break;
//
//         default:
//           errorMessage = "Login failed. Try again.";
//       }
//
//       await ErrorReportManager.storeErrorReport(
//         error: 'Login DioException: $errorMessage',
//         level: ErrorLevel.error,
//         stackTrace: StackTrace.current.toString(),
//         additionalInfo: {
//           'phoneNumber': phoneNumber,
//           'errorType': dioError.type.toString(),
//         },
//       );
//
//       return LoginAuthModel(
//         isSuccess: false,
//         message: errorMessage,
//       );
//     }
//
//     ///  UNKNOWN ERROR
//     catch (e) {
//
//       await CrashReportManager.storeLogMessage(
//           "LOGIN UNKNOWN ERROR\n"
//               "Error: $e"
//       );
//
//       await ErrorReportManager.storeErrorReport(
//         error: 'Login unexpected error: $e',
//         level: ErrorLevel.critical,
//         stackTrace: StackTrace.current.toString(),
//         additionalInfo: {'phoneNumber': phoneNumber},
//       );
//
//       return LoginAuthModel(
//         isSuccess: false,
//         message: "Unexpected error. Please try again.",
//       );
//     }
//   }
//
//   Future<ReccaRemarksModel> fetchReccaRemarksModel(String projectID) async {
//     String getToken = await getAuthToken();
//     try {
//       Response response = await dio.get(
//         "${APIURLs.baseURL}${APIURLs.reccaRemarks}?ProjectId=${projectID}",
//         options: Options(
//           headers: {
//             'Content-Type': 'application/json',
//             'Authorization': getToken,
//           },
//         ),
//       );
//       // The API response is likely a single JSON object with a 'data' key
//       return ReccaRemarksModel.fromJson(response.data);
//     } catch (e) {
//       await CrashReportManager.storeCrashReport(
//         error: "ReccaRemarks error: $e",
//         stackTrace: StackTrace.current.toString(),
//       );
//       await ErrorReportManager.storeErrorReport(
//         error: 'Failed to fetch ReccaRemarks for ProjectId: $projectID',
//         level: ErrorLevel.error,
//         stackTrace: StackTrace.current.toString(),
//         additionalInfo: {'projectID': projectID},
//       );
//       // Return an empty model on failure
//       return ReccaRemarksModel(data: []);
//     }
//   }
//
//   //Project Get API
//   Future<ProjectModel> fetchProjectModel() async {
//     String getToken = await getAuthToken();
//     try {
//       Response response = await dio.get(
//         "${APIURLs.baseURL}${APIURLs.projects}",
//         options: Options(
//           headers: {
//             'Content-Type': 'application/json',
//             'Authorization': getToken,
//           },
//         ),
//       );
//       // The API response is likely a single JSON object with a 'data' key
//       return ProjectModel.fromJson(response.data);
//     } catch (e) {
//       await ErrorReportManager.storeErrorReport(
//         error: 'Failed to fetch ProjectModel: $e',
//         level: ErrorLevel.error,
//         stackTrace: StackTrace.current.toString(),
//       );
//       // Return an empty model on failure
//       return ProjectModel(data: []);
//     }
//   }
//
//   //See Plan API
//   Future<SeePlanModel> fetchSeePlanModel() async {
//     String getToken = await getAuthToken();
//     try {
//       Response response = await dio.get(
//         "${APIURLs.baseURL}${APIURLs.seePlanURL}?PlanCode=0&VillageCode=0",
//         options: Options(
//           headers: {
//             'Content-Type': 'application/json',
//             'Authorization': getToken,
//           },
//         ),
//       );
//       // The API response is likely a single JSON object with a 'data' key
//       return SeePlanModel.fromJson(response.data);
//     } catch (e) {
//       await ErrorReportManager.storeErrorReport(
//         error: 'Failed to fetch SeePlanModel: $e',
//         level: ErrorLevel.error,
//         stackTrace: StackTrace.current.toString(),
//       );
//       // Return an empty model on failure
//       return SeePlanModel(data: []);
//     }
//   }
//
//   // ExcutionSummaryDashboard API
//   Future<ExecutionDashboardSummaryModel?> fetchExecutionDashboardSummary(String StartDate, String EndDate, String ProjectID) async {
//     String getToken = await getAuthToken();
//
//     try {
//       Response response = await dio.get(
//         "${APIURLs.baseURL}${APIURLs.executionDashoardSummary}?ProjectId=${ProjectID}&StartDate=${StartDate}&EndDate=${EndDate}",
//         options: Options(
//           headers: {
//             'Content-Type': 'application/json',
//             'Authorization': getToken,
//           },
//         ),
//       );
//
//       if (response.statusCode == 200) {
//         // Validate response structure
//         if (response.data != null && response.data is Map<String, dynamic>) {
//           Map<String, dynamic> resultData = response.data;
//
//           // Check if the response has the expected structure
//           if (resultData.containsKey('isSuccess') && resultData.containsKey('data')) {
//             try {
//               var dashboardModel = ExecutionDashboardSummaryModel.fromJson(resultData);
//               return dashboardModel;
//             } catch (parseError) {
//               await ErrorReportManager.storeErrorReport(
//                 error: 'Error parsing ExecutionDashboardSummary: $parseError',
//                 level: ErrorLevel.error,
//                 stackTrace: StackTrace.current.toString(),
//                 additionalInfo: {
//                   'ProjectID': ProjectID,
//                   'StartDate': StartDate,
//                   'EndDate': EndDate,
//                 },
//               );
//               return null;
//             }
//           } else {
//             await ErrorReportManager.storeErrorReport(
//               error: 'ExecutionDashboardSummary response missing expected keys',
//               level: ErrorLevel.warning,
//               additionalInfo: {'ProjectID': ProjectID},
//             );
//             return null;
//           }
//         } else {
//           await ErrorReportManager.storeErrorReport(
//             error: 'ExecutionDashboardSummary response data is null or not a Map',
//             level: ErrorLevel.warning,
//             additionalInfo: {'ProjectID': ProjectID},
//           );
//           return null;
//         }
//       } else {
//         await ErrorReportManager.storeErrorReport(
//           error: 'ExecutionDashboardSummary API error - Status Code: ${response.statusCode}',
//           level: ErrorLevel.error,
//           additionalInfo: {'ProjectID': ProjectID},
//         );
//         return null;
//       }
//     } on DioError catch (dioError) {
//       await ErrorReportManager.storeErrorReport(
//         error: 'ExecutionDashboardSummary DioError: ${dioError.message}',
//         level: ErrorLevel.error,
//         stackTrace: StackTrace.current.toString(),
//         additionalInfo: {
//           'ProjectID': ProjectID,
//           'statusCode': dioError.response?.statusCode ?? 0,
//         },
//       );
//       return null;
//     } catch (e) {
//       await ErrorReportManager.storeErrorReport(
//         error: 'ExecutionDashboardSummary unexpected error: $e',
//         level: ErrorLevel.critical,
//         stackTrace: StackTrace.current.toString(),
//         additionalInfo: {'ProjectID': ProjectID},
//       );
//       return null;
//     }
//   }
//
//   //Execution Summary Details Dashboard API
//   Future<ExecutionDashboardSummaryDetailsModel?> fetchExecutionDashboardSummaryDetails(
//       String plan, String StartDate, String EndDate, String ProjectID) async {
//     String getToken = await getAuthToken();
//
//     try {
//       Response response = await dio.get(
//         "${APIURLs.baseURL}${APIURLs.executionDashoardSummaryDetails}?ProjectId=${ProjectID}&StartDate=${StartDate}&EndDate=${EndDate}&Flag=${plan}",
//         options: Options(
//           headers: {
//             'Content-Type': 'application/json',
//             'Authorization': getToken,
//           },
//         ),
//       );
//
//       if (response.statusCode == 200) {
//         if (response.data != null && response.data is Map<String, dynamic>) {
//           Map<String, dynamic> resultData = response.data;
//
//           if (resultData.containsKey('isSuccess') && resultData.containsKey('data')) {
//             try {
//               var dashboardModel = ExecutionDashboardSummaryDetailsModel.fromJson(resultData);
//
//               return dashboardModel;
//             } catch (parseError) {
//               await ErrorReportManager.storeErrorReport(
//                 error: 'Error parsing ExecutionDashboardSummaryDetails: $parseError',
//                 level: ErrorLevel.error,
//                 stackTrace: StackTrace.current.toString(),
//                 additionalInfo: {
//                   'ProjectID': ProjectID,
//                   'plan': plan,
//                 },
//               );
//               return null;
//             }
//           } else {
//             await ErrorReportManager.storeErrorReport(
//               error: 'ExecutionDashboardSummaryDetails response missing expected keys',
//               level: ErrorLevel.warning,
//               additionalInfo: {'ProjectID': ProjectID, 'plan': plan},
//             );
//             return null;
//           }
//         } else {
//           return null;
//         }
//       } else {
//         await ErrorReportManager.storeErrorReport(
//           error: 'ExecutionDashboardSummaryDetails API error - Status Code: ${response.statusCode}',
//           level: ErrorLevel.error,
//           additionalInfo: {'ProjectID': ProjectID, 'plan': plan},
//         );
//         return null;
//       }
//     } catch (e) {
//       await ErrorReportManager.storeErrorReport(
//         error: 'ExecutionDashboardSummaryDetails error: $e',
//         level: ErrorLevel.critical,
//         stackTrace: StackTrace.current.toString(),
//         additionalInfo: {'ProjectID': ProjectID, 'plan': plan},
//       );
//       return null;
//     }
//   }
//
//
//   Future<bool> uploadMetadata(SUImageUploaddata metadata) async {
//     try {
//       Dio dio = Dio();
//       String currentDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
//       String getToken = await getAuthToken();
//
//       // Create form data
//       FormData formData = FormData.fromMap({
//         'PrintId': metadata.printId,
//         'PrintNo': metadata.printNo,
//         'PlanCode': metadata.planCode,
//         'Near_Latitude': metadata.nearLatitude,
//         'Near_Longitude': metadata.nearLongitude,
//         'Far_Latitude': metadata.farLatitude,
//         'Far_Longitude': metadata.farLongitude,
//         'VillageCode': metadata.villageCode,
//         'Remark': metadata.remark,
//         'ExecutionDate': metadata.executionDate,
//         'UploadDate': currentDate,
//         // Add the image files as multipart files if they exist
//         if (metadata.nearImagePath != null)
//           'NearImage': await MultipartFile.fromFile(metadata.nearImagePath!),
//         if (metadata.farImagePath != null)
//           'FarImage': await MultipartFile.fromFile(metadata.farImagePath!),
//       });
//
//       // Send the request to the API
//       var response = await dio.post(
//           '${APIURLs.baseURL}${APIURLs.reccaPost}',
//           options: Options(
//             headers: {
//               'Content-Type': 'multipart/form-data',
//               'Authorization': getToken,
//             },
//           ),
//           data: formData
//       );
//
//       if (response.statusCode == 200) {
//         // After successfully uploading, delete the metadata from Hive
//         await PostReccaImageUploadHiveRepository().deleteMetadataFromHive(metadata.printId);
//
//         String metadataJson = jsonEncode(metadata);
//         await SyncCrashReportManager.storeCrashReport(
//           error: "Post Recca Sync Data: ${metadataJson}",
//           stackTrace: StackTrace.current.toString(),
//           additionalInfo: {
//             'phase': 'Post Recca Sync Data',
//             'timestamp': DateTime.now().toIso8601String(),
//           },
//         );
//
//         return true;
//       }
//       return false;
//     } on DioError catch (e) {
//
//       if (e.response != null) {
//         // Extract actual error message from server response
//         String serverMessage = '';
//         if (e.response?.data is Map && e.response?.data['message'] != null) {
//           serverMessage = e.response!.data['message'].toString();
//         }
//
//         switch (e.response!.statusCode) {
//           case 400:
//           // CRITICAL: Handle duplicate images error
//             if (serverMessage.toLowerCase().contains('duplicate')) {
//               // Delete from Hive since it already exists on server
//               await PostReccaImageUploadHiveRepository().deleteMetadataFromHive(metadata.printId);
//               await ErrorReportManager.storeErrorReport(
//                 error: 'Duplicate image detected for PrintId: ${metadata.printId}',
//                 level: ErrorLevel.warning,
//                 additionalInfo: {'printId': metadata.printId},
//               );
//               // Throw specific duplicate error
//               throw 'DUPLICATE_IMAGE_ERROR: This print has already been uploaded to the server.';
//             }
//             throw 'Bad Request: ${serverMessage.isNotEmpty ? serverMessage : "No data found. Please try again later."}';
//           case 401:
//             throw 'Unauthorized: Authentication failed. Please login again.';
//           case 403:
//             throw 'Forbidden: Access denied. Please contact admin.';
//           case 404:
//             throw 'Not Found: No data found. Please try again later.';
//           case 500:
//             throw 'Internal Server Error: Please contact admin for assistance.';
//           case 502:
//             throw 'Bad Gateway: Server temporarily unavailable. Please try again later.';
//           case 503:
//             throw 'Service Unavailable: Please try again later.';
//           default:
//             throw 'Server Error (${e.response!.statusCode}): ${serverMessage.isNotEmpty ? serverMessage : "No data found. Please try again later."}';
//         }
//
//       } else {
//         await ErrorReportManager.storeErrorReport(
//           error: 'Post Recca network error for PrintId: ${metadata.printId}',
//           level: ErrorLevel.critical,
//           stackTrace: StackTrace.current.toString(),
//           additionalInfo: {'printId': metadata.printId},
//         );
//         throw 'Network error: Please check your internet connection and try again.';
//       }
//     } catch (e) {
//       await ErrorReportManager.storeErrorReport(
//         error: 'Post Recca unexpected error: $e',
//         level: ErrorLevel.critical,
//         stackTrace: StackTrace.current.toString(),
//         additionalInfo: {'printId': metadata.printId},
//       );
//       if (e is String) {
//         throw e; // Re-throw our custom error messages
//       }
//       throw 'An unexpected error occurred. Please try again later.';
//     }
//   }
//   //Post Recca Image Upload SYNCALL API
//   Future<bool> syncAllMetadata(List<SUImageUploaddata> metadataList) async {
//     bool anySuccess = false;
//     List<String> errors = [];
//     String? criticalError; // To track network/critical errors
//
//     for (var metadata in metadataList) {
//       try {
//         bool result = await uploadMetadata(metadata);
//         if (result) {
//           anySuccess = true;
//         } else {
//           errors.add('Failed to upload PrintId: ${metadata.printId}');
//         }
//       } on DioError catch (e) {
//         String errorMessage;
//         if (e.response != null) {
//           switch (e.response!.statusCode) {
//             case 400:
//               errorMessage = 'Bad Request: No data found. Please try again later.';
//               break;
//             case 401:
//               errorMessage = 'Unauthorized: Authentication failed. Please login again.';
//               break;
//             case 403:
//               errorMessage = 'Forbidden: Access denied. Please contact admin.';
//               break;
//             case 404:
//               errorMessage = 'Not Found: No data found. Please try again later.';
//               break;
//             case 500:
//               errorMessage = 'Internal Server Error: Please contact admin for assistance.';
//               break;
//             case 502:
//               errorMessage = 'Bad Gateway: Server temporarily unavailable. Please try again later.';
//               break;
//             case 503:
//               errorMessage = 'Service Unavailable: Please try again later.';
//               break;
//             default:
//               errorMessage = 'Server Error (${e.response!.statusCode}): No data found. Please try again later.';
//           }
//         } else {
//           // This is a network error - should be shown to user immediately
//           errorMessage = 'Network error: Please check your internet connection and try again.';
//           criticalError = errorMessage; // Mark as critical error
//         }
//
//         errors.add('PrintId ${metadata.printId}: $errorMessage');
//
//         // If it's a network error, throw immediately instead of continuing
//         if (criticalError != null) {
//           throw criticalError;
//         }
//
//       } catch (e) {
//         String errorMessage = e is String ? e : 'An unexpected error occurred. Please try again later.';
//         errors.add('PrintId ${metadata.printId}: $errorMessage');
//
//         // For network-related errors, throw immediately
//         if (errorMessage.contains('Network') || errorMessage.contains('internet connection')) {
//           throw errorMessage;
//         }
//       }
//     }
//
//     // If we had errors but some succeeded, you might want to show a partial success message
//     if (errors.isNotEmpty && anySuccess) {
//       for (String error in errors) {
//       }
//     }
//
//     return anySuccess;
//   }
//
//  //  Future<Map<String, dynamic>> uploadPlanMetadata(ImageUploaddata metadata) async {
//  //    try {
//  //      Dio dio = Dio();
//  //      String currentDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
//  //      String getToken = await getAuthToken();
//  //
//  //      // Validate required fields
//  //      if (metadata.ServerPlanId == null || metadata.PlanCode == null || metadata.PrintNo == null) {
//  //        throw 'Missing required metadata fields';
//  //      }
//  //
//  //      // Fixed Address validation
//  //      String addressValue = "No Data";
//  //      if (metadata.Address != null &&
//  //          metadata.Address!.trim().isNotEmpty &&
//  //          metadata.Address != "null") {
//  //        addressValue = metadata.Address!;
//  //      }
//  //
//  //      // Create form data
//  //      FormData formData = FormData.fromMap({
//  //        'ServerPlanId': metadata.ServerPlanId.toString(),
//  //        'PlanCode': metadata.PlanCode.toString(),
//  //        'PrintNo': metadata.PrintNo.toString(),
//  //        'VillageCode': metadata.VillageCode?.toString() ?? '',
//  //        'Address': addressValue,
//  //        'ExecutionDate': metadata.ExecutionDate ?? currentDate,
//  //        'UploadDate': currentDate,
//  //        'Clean_Latitude': metadata.CleanLatitude?.toString() ?? '0.0',
//  //        'Clean_Longitude': metadata.CleanLongitude?.toString() ?? '0.0',
//  //        'WB_Latitude': metadata.WBLatitude?.toString() ?? '0.0',
//  //        'WB_Longitude': metadata.WBLongitude?.toString() ?? '0.0',
//  //        'Spray_Latitude': metadata.SprayLatitude?.toString() ?? '0.0',
//  //        'Spray_Longitude': metadata.SprayLongitude?.toString() ?? '0.0',
//  //        'Near_Latitude': metadata.NearLatitude?.toString() ?? '0.0',
//  //        'Near_Longitude': metadata.NearLongitude?.toString() ?? '0.0',
//  //        'Far_Latitude': metadata.FarLatitude?.toString() ?? '0.0',
//  //        'Far_Longitude': metadata.FarLongitude?.toString() ?? '0.0',
//  //        'New6_Latitude': metadata.New6Latitude?.toString() ?? '0.0',
//  //        'New6_Longitude': metadata.New6Longitude?.toString() ?? '0.0',
//  //        'New7_Latitude': metadata.New7Latitude?.toString() ?? '0.0',
//  //        'New7_Longitude': metadata.New7Longitude?.toString() ?? '0.0',
//  //        'NetworkStatus': metadata.networkFlagString.toString() ?? '',
//  //      });
//  //
//  //      // Add images with existence validation
//  //      if (metadata.CleanImage != null) {
//  //        File cleanFile = File(metadata.CleanImage!);
//  //        if (await cleanFile.exists()) {
//  //          formData.files.add(MapEntry('CleanImage', await MultipartFile.fromFile(metadata.CleanImage!)));
//  //        }
//  //      }
//  //      if (metadata.WBImage != null) {
//  //        File wbFile = File(metadata.WBImage!);
//  //        if (await wbFile.exists()) {
//  //          formData.files.add(MapEntry('WBImage', await MultipartFile.fromFile(metadata.WBImage!)));
//  //        }
//  //      }
//  //      if (metadata.SprayImage != null) {
//  //        File sprayFile = File(metadata.SprayImage!);
//  //        if (await sprayFile.exists()) {
//  //          formData.files.add(MapEntry('SprayImage', await MultipartFile.fromFile(metadata.SprayImage!)));
//  //        }
//  //      }
//  //      if (metadata.NearImage != null) {
//  //        File nearFile = File(metadata.NearImage!);
//  //        if (await nearFile.exists()) {
//  //          formData.files.add(MapEntry('NearImage', await MultipartFile.fromFile(metadata.NearImage!)));
//  //        }
//  //      }
//  //      if (metadata.FarImage != null) {
//  //        File farFile = File(metadata.FarImage!);
//  //        if (await farFile.exists()) {
//  //          formData.files.add(MapEntry('FarImage', await MultipartFile.fromFile(metadata.FarImage!)));
//  //        }
//  //      }
//  //      if (metadata.NewImage6 != null) {
//  //        File new6File = File(metadata.NewImage6!);
//  //        if (await new6File.exists()) {
//  //          formData.files.add(MapEntry('NewImage6', await MultipartFile.fromFile(metadata.NewImage6!)));
//  //        }
//  //      }
//  //      if (metadata.NewImage7 != null) {
//  //        File new7File = File(metadata.NewImage7!);
//  //        if (await new7File.exists()) {
//  //          formData.files.add(MapEntry('NewImage7', await MultipartFile.fromFile(metadata.NewImage7!)));
//  //        }
//  //      }
//  //
//  //      // Send the request
//  //      var response = await dio.post(
//  //          '${APIURLs.baseURL}${APIURLs.executionPost}',
//  //          options: Options(
//  //            headers: {
//  //              'Content-Type': 'multipart/form-data',
//  //              'Authorization': getToken,
//  //            },
//  //          ),
//  //          data: formData
//  //      );
//  //
//  //      if (response.statusCode == 200) {
//  //        // Extract printId from the response structure you provided
//  //        String? printIdFromResponse;
//  //        if (response.data is Map<String, dynamic>) {
//  //          // Based on your JSON: response.data['data']['printId']
//  //          if (response.data['data'] != null && response.data['data'] is Map<String, dynamic>) {
//  //            printIdFromResponse = response.data['data']['printId']?.toString();
//  //          }
//  //        }
//  //
//  //        // IMPORTANT: Save printId to metadata BEFORE deleting from Hive
//  //        if (printIdFromResponse != null) {
//  //          metadata.printId = printIdFromResponse;
//  //        }
//  //
//  //        // Delete from pending sync after successful upload
//  //        await ExecutionImageUploadHiveRepository().deleteMetadata(
//  //            metadata.ServerPlanId.toString(),
//  //            metadata.PrintNo.toString()
//  //        );
//  //
//  //        String metadataJson = jsonEncode(metadata.toJson());
//  //        await SyncCrashReportManager.storeCrashReport(
//  //          error: "Execution Sync Data: ${metadataJson}",
//  //          stackTrace: StackTrace.current.toString(),
//  //          additionalInfo: {
//  //            'phase': 'Execution Sync Data',
//  //            'timestamp': DateTime.now().toIso8601String(),
//  //            'printId': printIdFromResponse ?? 'null',
//  //          },
//  //        );
//  //
//  //        // Return structured response
//  //        return {
//  //          'success': true,
//  //          'message': response.data['message'] ?? 'Successfully synced',
//  //          'data': {
//  //            'printId': printIdFromResponse,
//  //            'serverPlanId': response.data['data']?['serverPlanId']?.toString(),
//  //            'planCode': response.data['data']?['planCode']?.toString(),
//  //            'printNo': response.data['data']?['printNo']?.toString(),
//  //          }
//  //        };
//  //      }
//  //
//  //      return {
//  //        'success': false,
//  //        'message': 'Upload failed',
//  //      };
//  //    } on DioError catch (e) {
//  //
//  //      if (e.response != null) {
//  //        String serverMessage = '';
//  //        if (e.response?.data is Map && e.response?.data['message'] != null) {
//  //          serverMessage = e.response!.data['message'].toString();
//  //        }
//  //
//  //        switch (e.response!.statusCode) {
//  //          case 400:
//  //            if (serverMessage.toLowerCase().contains('duplicate')) {
//  //              await ExecutionImageUploadHiveRepository().deleteMetadata(
//  //                  metadata.ServerPlanId.toString(),
//  //                  metadata.PrintNo.toString()
//  //              );
//  //              throw 'DUPLICATE_IMAGE_ERROR: This print has already been uploaded to the server.';
//  //            }
//  //            throw 'Bad Request: ${serverMessage.isNotEmpty ? serverMessage : "Invalid data provided."}';
//  //          case 401:
//  //            throw 'Unauthorized: Authentication failed. Please login again.';
//  //          case 403:
//  //            throw 'Forbidden: Access denied. Please contact admin.';
//  //          case 404:
//  //            throw 'Not Found: No data found. Please try again later.';
//  //          case 500:
//  //            throw 'Internal Server Error: Please contact admin for assistance.';
//  //          case 502:
//  //            throw 'Bad Gateway: Server temporarily unavailable. Please try again later.';
//  //          case 503:
//  //            throw 'Service Unavailable: Please try again later.';
//  //          default:
//  //            throw 'Server Error (${e.response!.statusCode}): ${serverMessage.isNotEmpty ? serverMessage : "Please try again later."}';
//  //        }
//  //      } else {
//  //        throw 'Network error: Please check your internet connection and try again.';
//  //      }
//  //    } catch (e) {
//  //      if (e is String) {
//  //        throw e;
//  //      }
//  //      throw 'An unexpected error occurred. Please try again later.';
//  //    }
//  //  }
//   /// Execution post Reword post
//   // Future<Map<String, dynamic>> uploadPlanMetadata(ImageUploaddata metadata) async {
//   //   try {
//   //     Dio dio = Auth.dio;
//   //
//   //     final uploadType = (metadata.uploadType ?? "execution").toLowerCase();
//   //     String currentDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
//   //     String getToken = await getAuthToken();
//   //
//   //     // ================= VALIDATION =================
//   //     if (metadata.ServerPlanId == null ||
//   //         metadata.PlanCode == null ||
//   //         metadata.PrintNo == null) {
//   //       throw 'Missing required metadata fields';
//   //     }
//   //
//   //     // ✅ Validate rework requires printId
//   //     if (uploadType == "rework" && metadata.printId == null) {
//   //       throw Exception('Rework upload requires printId');
//   //     }
//   //
//   //     // ================= ADDRESS FIX =================
//   //     String addressValue = "No Data";
//   //     if (metadata.Address != null &&
//   //         metadata.Address!.trim().isNotEmpty &&
//   //         metadata.Address != "null") {
//   //       addressValue = metadata.Address!;
//   //     }
//   //
//   //     // ================= FORM DATA =================
//   //     FormData formData = FormData.fromMap({
//   //       'ServerPlanId': metadata.ServerPlanId.toString(),
//   //       'PlanCode': metadata.PlanCode.toString(),
//   //       'PrintNo': metadata.PrintNo.toString(),
//   //       'VillageCode': metadata.VillageCode?.toString() ?? '',
//   //       'Address': addressValue,
//   //       'ExecutionDate': metadata.ExecutionDate ?? currentDate,
//   //       'UploadDate': currentDate,
//   //
//   //       'Clean_Latitude': metadata.CleanLatitude?.toString() ?? '0.0',
//   //       'Clean_Longitude': metadata.CleanLongitude?.toString() ?? '0.0',
//   //       'WB_Latitude': metadata.WBLatitude?.toString() ?? '0.0',
//   //       'WB_Longitude': metadata.WBLongitude?.toString() ?? '0.0',
//   //       'Spray_Latitude': metadata.SprayLatitude?.toString() ?? '0.0',
//   //       'Spray_Longitude': metadata.SprayLongitude?.toString() ?? '0.0',
//   //       'Near_Latitude': metadata.NearLatitude?.toString() ?? '0.0',
//   //       'Near_Longitude': metadata.NearLongitude?.toString() ?? '0.0',
//   //       'Far_Latitude': metadata.FarLatitude?.toString() ?? '0.0',
//   //       'Far_Longitude': metadata.FarLongitude?.toString() ?? '0.0',
//   //       'New6_Latitude': metadata.New6Latitude?.toString() ?? '0.0',
//   //       'New6_Longitude': metadata.New6Longitude?.toString() ?? '0.0',
//   //       'New7_Latitude': metadata.New7Latitude?.toString() ?? '0.0',
//   //       'New7_Longitude': metadata.New7Longitude?.toString() ?? '0.0',
//   //
//   //       'NetworkStatus': metadata.networkFlagString ?? 'UNKNOWN',
//   //     });
//   //
//   //     // ✅ ADD printId ONLY FOR REWORK
//   //     if (metadata.uploadType == "rework") {
//   //       formData.fields.add(MapEntry('PrintId', metadata.printId!));
//   //     }
//   //
//   //     // ================= ADD IMAGES =================
//   //     Future<void> addImage(String key, String? path) async {
//   //       if (path != null) {
//   //         File file = File(path);
//   //         if (await file.exists()) {
//   //           formData.files.add(MapEntry(key, await MultipartFile.fromFile(path)));
//   //         }
//   //       }
//   //     }
//   //
//   //     await addImage('CleanImage', metadata.CleanImage);
//   //     await addImage('WBImage', metadata.WBImage);
//   //     await addImage('SprayImage', metadata.SprayImage);
//   //     await addImage('NearImage', metadata.NearImage);
//   //     await addImage('FarImage', metadata.FarImage);
//   //     await addImage('NewImage6', metadata.NewImage6);
//   //     await addImage('NewImage7', metadata.NewImage7);
//   //
//   //     // ================= API SWITCH =================
//   //     String apiUrl = uploadType == "rework"
//   //         ? APIURLs.ReworkUpload
//   //         : APIURLs.executionPost;
//   //
//   //     final url = "${APIURLs.baseURL}${apiUrl.startsWith('/') ? '' : '/'}$apiUrl";
//   //
//   //     // ================= API CALL =================
//   //     var response = await dio.post(
//   //       '${APIURLs.baseURL}$apiUrl',
//   //       options: Options(
//   //         headers: {
//   //           'Content-Type': 'multipart/form-data',
//   //           'Authorization': getToken,
//   //         },
//   //       ),
//   //       data: formData,
//   //     );
//   //
//   //     // ================= SUCCESS =================
//   //     if (response.statusCode == 200) {
//   //
//   //       String? printIdFromResponse;
//   //
//   //       if (response.data is Map<String, dynamic>) {
//   //         final data = response.data['data'];
//   //         if (data is Map<String, dynamic>) {
//   //           printIdFromResponse = data['printId']?.toString();
//   //         }
//   //       }
//   //
//   //       // ✅ ONLY UPDATE printId FOR EXECUTION
//   //       if (uploadType == "execution" && printIdFromResponse != null) {
//   //         metadata.printId = printIdFromResponse;
//   //       }
//   //
//   //       // ✅ DELETE FROM HIVE AFTER SUCCESS
//   //       if (uploadType == "execution") {
//   //         await ExecutionImageUploadHiveRepository().deleteMetadata(
//   //           metadata.ServerPlanId.toString(),
//   //           metadata.PrintNo.toString(),
//   //         );
//   //       }
//   //
//   //       // ================= LOG =================
//   //       String metadataJson = jsonEncode(metadata.toJson());
//   //
//   //       await SyncCrashReportManager.storeCrashReport(
//   //         error: "Execution/Rework Sync Data: $metadataJson",
//   //         stackTrace: StackTrace.current.toString(),
//   //         additionalInfo: {
//   //           'phase': metadata.uploadType,
//   //           'timestamp': DateTime.now().toIso8601String(),
//   //           'printId': printIdFromResponse ?? metadata.printId ?? 'null',
//   //         },
//   //       );
//   //
//   //       return {
//   //         'success': true,
//   //         'message': response.data['message'] ?? 'Successfully synced',
//   //         'data': {
//   //           'printId': printIdFromResponse ?? metadata.printId,
//   //           'serverPlanId': response.data['data']?['serverPlanId']?.toString(),
//   //           'planCode': response.data['data']?['planCode']?.toString(),
//   //           'printNo': response.data['data']?['printNo']?.toString(),
//   //         }
//   //       };
//   //     }
//   //
//   //     return {
//   //       'success': false,
//   //       'message': 'Upload failed',
//   //     };
//   //
//   //   } on DioError catch (e) {
//   //
//   //     if (e.response != null) {
//   //       String serverMessage = '';
//   //
//   //       if (e.response?.data is Map &&
//   //           e.response?.data['message'] != null) {
//   //         serverMessage = e.response!.data['message'].toString();
//   //       }
//   //
//   //       switch (e.response!.statusCode) {
//   //
//   //         case 400:
//   //           if (serverMessage.toLowerCase().contains('duplicate')) {
//   //             throw Exception('Already uploaded (duplicate)');
//   //           }
//   //           throw 'Bad Request: ${serverMessage.isNotEmpty ? serverMessage : "Invalid data"}';
//   //
//   //         case 401:
//   //           throw 'Unauthorized: Please login again';
//   //
//   //         case 403:
//   //           throw 'Forbidden: Access denied';
//   //
//   //         case 404:
//   //           throw 'Not Found';
//   //
//   //         case 500:
//   //           throw 'Server Error';
//   //
//   //         default:
//   //           throw 'Server Error (${e.response!.statusCode})';
//   //       }
//   //
//   //     } else {
//   //       throw 'Network error: Check internet connection';
//   //     }
//   //
//   //   } catch (e) {
//   //     if (e is String) throw e;
//   //     throw 'Unexpected error occurred';
//   //   }
//   // }
//   ///
//   // Future<Map<String, dynamic>> uploadPlanMetadata(ImageUploaddata metadata) async {
//   //   try {
//   //     Dio dio = Auth.dio;
//   //
//   //     // ================= FIX KEY MISMATCH =================
//   //     metadata.PrintNo = metadata.PrintNo?.trim().toUpperCase();
//   //     metadata.ServerPlanId = metadata.ServerPlanId?.trim();
//   //
//   //     final uploadType = (metadata.uploadType ?? "execution").toLowerCase();
//   //
//   //     String currentDate =
//   //     DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
//   //     String getToken = await getAuthToken();
//   //
//   //     // ================= VALIDATION =================
//   //     if (metadata.ServerPlanId == null ||
//   //         metadata.PlanCode == null ||
//   //         metadata.PrintNo == null) {
//   //       throw 'Missing required metadata fields';
//   //     }
//   //
//   //     // Rework must have printId
//   //     if (uploadType == "rework" && metadata.printId == null) {
//   //       throw Exception('Rework upload requires printId');
//   //     }
//   //
//   //     // ================= ADDRESS FIX =================
//   //     String addressValue = "No Data";
//   //     if (metadata.Address != null &&
//   //         metadata.Address!.trim().isNotEmpty &&
//   //         metadata.Address != "null") {
//   //       addressValue = metadata.Address!;
//   //     }
//   //
//   //     // ================= FORM DATA =================
//   //     FormData formData = FormData.fromMap({
//   //       'ServerPlanId': metadata.ServerPlanId,
//   //       'PlanCode': metadata.PlanCode,
//   //       'PrintNo': metadata.PrintNo,
//   //       'VillageCode': metadata.VillageCode ?? '',
//   //       'Address': addressValue,
//   //       'ExecutionDate': metadata.ExecutionDate ?? currentDate,
//   //       'UploadDate': currentDate,
//   //
//   //       'Clean_Latitude': metadata.CleanLatitude ?? '0.0',
//   //       'Clean_Longitude': metadata.CleanLongitude ?? '0.0',
//   //       'WB_Latitude': metadata.WBLatitude ?? '0.0',
//   //       'WB_Longitude': metadata.WBLongitude ?? '0.0',
//   //       'Spray_Latitude': metadata.SprayLatitude ?? '0.0',
//   //       'Spray_Longitude': metadata.SprayLongitude ?? '0.0',
//   //       'Near_Latitude': metadata.NearLatitude ?? '0.0',
//   //       'Near_Longitude': metadata.NearLongitude ?? '0.0',
//   //       'Far_Latitude': metadata.FarLatitude ?? '0.0',
//   //       'Far_Longitude': metadata.FarLongitude ?? '0.0',
//   //       'New6_Latitude': metadata.New6Latitude ?? '0.0',
//   //       'New6_Longitude': metadata.New6Longitude ?? '0.0',
//   //       'New7_Latitude': metadata.New7Latitude ?? '0.0',
//   //       'New7_Longitude': metadata.New7Longitude ?? '0.0',
//   //
//   //       'NetworkStatus': metadata.networkFlagString ?? 'UNKNOWN',
//   //     });
//   //
//   //     // ✅ ADD printId ONLY FOR REWORK
//   //     if (uploadType == "rework") {
//   //       formData.fields.add(MapEntry('PrintId', metadata.printId!));
//   //     }
//   //
//   //     // ================= ADD IMAGES =================
//   //     Future<void> addImage(String key, String? path) async {
//   //       if (path != null) {
//   //         File file = File(path);
//   //         if (await file.exists()) {
//   //           formData.files.add(
//   //             MapEntry(key, await MultipartFile.fromFile(path)),
//   //           );
//   //         }
//   //       }
//   //     }
//   //
//   //     await addImage('CleanImage', metadata.CleanImage);
//   //     await addImage('WBImage', metadata.WBImage);
//   //     await addImage('SprayImage', metadata.SprayImage);
//   //     await addImage('NearImage', metadata.NearImage);
//   //     await addImage('FarImage', metadata.FarImage);
//   //     await addImage('NewImage6', metadata.NewImage6);
//   //     await addImage('NewImage7', metadata.NewImage7);
//   //
//   //     // ================= API SWITCH =================
//   //     String apiUrl = uploadType == "rework"
//   //         ? APIURLs.ReworkUpload
//   //         : APIURLs.executionPost;
//   //
//   //     // ================= API CALL =================
//   //     var response = await dio.post(
//   //       '${APIURLs.baseURL}$apiUrl',
//   //       options: Options(
//   //         headers: {
//   //           'Content-Type': 'multipart/form-data',
//   //           'Authorization': getToken,
//   //         },
//   //       ),
//   //       data: formData,
//   //     );
//   //
//   //     // ================= HANDLE RESPONSE =================
//   //     final responseData = response.data;
//   //
//   //     bool isSuccess = false;
//   //     String message = '';
//   //     Map<String, dynamic>? dataMap;
//   //
//   //     if (responseData is Map<String, dynamic>) {
//   //       isSuccess = responseData['isSuccess'] == true;
//   //
//   //       message = responseData['message']?.toString() ?? '';
//   //
//   //       //  SPECIAL CASE: "Already Executed" should be treated as SUCCESS
//   //       if (!isSuccess &&
//   //           message.toLowerCase().contains("already executed")) {
//   //         isSuccess = true;
//   //         message = "Already Executed (Synced successfully)";
//   //       }
//   //
//   //       if (responseData['data'] is Map<String, dynamic>) {
//   //         dataMap = responseData['data'];
//   //       }
//   //     }
//   //
//   //     // ================= SUCCESS FLOW (including "Already Executed") =================
//   //     if (isSuccess || response.statusCode == 200) {
//   //       String? printIdFromResponse;
//   //
//   //       if (dataMap != null) {
//   //         printIdFromResponse = dataMap['printId']?.toString();
//   //       }
//   //
//   //       //  Save printId only for execution
//   //       if (uploadType == "execution" && printIdFromResponse != null) {
//   //         metadata.printId = printIdFromResponse;
//   //       }
//   //
//   //       // DELETE FROM HIVE (FOR BOTH execution + rework)
//   //       await ExecutionImageUploadHiveRepository().deleteMetadata(
//   //         metadata.ServerPlanId!,
//   //         metadata.PrintNo!,
//   //       );
//   //
//   //       // ================= LOG =================
//   //       String metadataJson = jsonEncode(metadata.toJson());
//   //
//   //       await SyncCrashReportManager.storeCrashReport(
//   //         error: "Sync Data: $metadataJson",
//   //         stackTrace: StackTrace.current.toString(),
//   //         additionalInfo: {
//   //           'type': uploadType,
//   //           'timestamp': DateTime.now().toIso8601String(),
//   //           'printId': printIdFromResponse ?? metadata.printId ?? 'null',
//   //           'serverMessage': message,
//   //         },
//   //       );
//   //
//   //       return {
//   //         'success': true,
//   //         'message': message,
//   //         'data': {
//   //           'printId': printIdFromResponse ?? metadata.printId,
//   //           'serverPlanId': dataMap?['serverPlanId']?.toString(),
//   //           'planCode': dataMap?['planCode']?.toString(),
//   //           'printNo': dataMap?['printNo']?.toString(),
//   //         }
//   //       };
//   //     }
//   //
//   //     // ================= FAILURE =================
//   //     return {
//   //       'success': false,
//   //       'message': message.isNotEmpty ? message : 'Upload failed',
//   //     };
//   //   } on DioError catch (e) {
//   //     if (e.response != null) {
//   //       String serverMessage = '';
//   //
//   //       if (e.response?.data is Map &&
//   //           e.response?.data['message'] != null) {
//   //         serverMessage = e.response!.data['message'].toString();
//   //       }
//   //
//   //       // Also handle "Already Executed" in DioError (in case status code is not 200)
//   //       if (serverMessage.toLowerCase().contains("already executed")) {
//   //         // Treat as success even in error block
//   //         await ExecutionImageUploadHiveRepository().deleteMetadata(
//   //           metadata.ServerPlanId!,
//   //           metadata.PrintNo!,
//   //         );
//   //
//   //         return {
//   //           'success': true,
//   //           'message': 'Already Executed (Synced successfully)',
//   //         };
//   //       }
//   //
//   //       switch (e.response!.statusCode) {
//   //         case 400:
//   //           if (serverMessage.toLowerCase().contains('duplicate')) {
//   //             throw Exception('Already uploaded (duplicate)');
//   //           }
//   //           throw 'Bad Request: $serverMessage';
//   //
//   //         case 401:
//   //           throw 'Unauthorized';
//   //
//   //         case 403:
//   //           throw 'Forbidden';
//   //
//   //         case 404:
//   //           throw 'Not Found';
//   //
//   //         case 500:
//   //           throw 'Server Error';
//   //
//   //         default:
//   //           throw 'Server Error (${e.response!.statusCode})';
//   //       }
//   //     } else {
//   //       if (e.type == DioExceptionType.connectionError ||
//   //           e.type == DioExceptionType.connectionTimeout ||
//   //           e.type == DioExceptionType.receiveTimeout ||
//   //           e.type == DioExceptionType.sendTimeout) {
//   //         throw 'No internet connection';
//   //       }
//   //
//   //       throw 'Network error';
//   //     }
//   //   } catch (e) {
//   //     if (e is String) throw e;
//   //     throw 'Unexpected error: ${e.toString()}';
//   //   }
//   // }
// /// failed
//   Future<Map<String, dynamic>> uploadPlanMetadata(ImageUploaddata metadata) async {
//     try {
//       Dio dio = Auth.dio;
//
//       // ================= FIX KEY MISMATCH =================
//       metadata.PrintNo = metadata.PrintNo?.trim().toUpperCase();
//       metadata.ServerPlanId = metadata.ServerPlanId?.trim();
//
//       final uploadType = (metadata.uploadType ?? "execution").toLowerCase();
//
//       String currentDate =
//       DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
//       String getToken = await getAuthToken();
//
//       // ================= VALIDATION =================
//       if (metadata.ServerPlanId == null ||
//           metadata.PlanCode == null ||
//           metadata.PrintNo == null) {
//         return {
//           'success': false,
//           'message': 'Missing required metadata fields',
//         };
//       }
//
//       // ✅ Rework must have printId
//       if (uploadType == "rework" && metadata.printId == null) {
//         return {
//           'success': false,
//           'message': 'Rework upload requires printId',
//         };
//       }
//
//       // ================= ADDRESS FIX =================
//       String addressValue = "No Data";
//       if (metadata.Address != null &&
//           metadata.Address!.trim().isNotEmpty &&
//           metadata.Address != "null") {
//         addressValue = metadata.Address!;
//       }
//
//       // ================= FORM DATA =================
//       FormData formData = FormData.fromMap({
//         'ServerPlanId': metadata.ServerPlanId,
//         'PlanCode': metadata.PlanCode,
//         'PrintNo': metadata.PrintNo,
//         'VillageCode': metadata.VillageCode ?? '',
//         'Address': addressValue,
//         'ExecutionDate': metadata.ExecutionDate ?? currentDate,
//         'UploadDate': currentDate,
//         'Clean_Latitude': metadata.CleanLatitude ?? '0.0',
//         'Clean_Longitude': metadata.CleanLongitude ?? '0.0',
//         'WB_Latitude': metadata.WBLatitude ?? '0.0',
//         'WB_Longitude': metadata.WBLongitude ?? '0.0',
//         'Spray_Latitude': metadata.SprayLatitude ?? '0.0',
//         'Spray_Longitude': metadata.SprayLongitude ?? '0.0',
//         'Near_Latitude': metadata.NearLatitude ?? '0.0',
//         'Near_Longitude': metadata.NearLongitude ?? '0.0',
//         'Far_Latitude': metadata.FarLatitude ?? '0.0',
//         'Far_Longitude': metadata.FarLongitude ?? '0.0',
//         'New6_Latitude': metadata.New6Latitude ?? '0.0',
//         'New6_Longitude': metadata.New6Longitude ?? '0.0',
//         'New7_Latitude': metadata.New7Latitude ?? '0.0',
//         'New7_Longitude': metadata.New7Longitude ?? '0.0',
//         'NetworkStatus': metadata.networkFlagString ?? 'UNKNOWN',
//       });
//
//       // ✅ ADD printId ONLY FOR REWORK
//       if (uploadType == "rework") {
//         formData.fields.add(MapEntry('PrintId', metadata.printId!));
//       }
//
//       // ================= ADD IMAGES =================
//       Future<void> addImage(String key, String? path) async {
//         if (path != null) {
//           File file = File(path);
//           if (await file.exists()) {
//             formData.files.add(
//               MapEntry(key, await MultipartFile.fromFile(path)),
//             );
//           }
//         }
//       }
//
//       await addImage('CleanImage', metadata.CleanImage);
//       await addImage('WBImage', metadata.WBImage);
//       await addImage('SprayImage', metadata.SprayImage);
//       await addImage('NearImage', metadata.NearImage);
//       await addImage('FarImage', metadata.FarImage);
//       await addImage('NewImage6', metadata.NewImage6);
//       await addImage('NewImage7', metadata.NewImage7);
//
//       // ================= API SWITCH =================
//       String apiUrl = uploadType == "rework"
//           ? APIURLs.ReworkUpload
//           : APIURLs.executionPost;
//
//       // ================= API CALL =================
//       var response = await dio.post(
//         '${APIURLs.baseURL}$apiUrl',
//         options: Options(
//           headers: {
//             'Content-Type': 'multipart/form-data',
//             'Authorization': getToken,
//           },
//         ),
//         data: formData,
//       );
//
//       // ================= HANDLE RESPONSE =================
//       final responseData = response.data;
//
//       bool isSuccess = false;
//       String message = '';
//       Map<String, dynamic>? dataMap;
//
//       if (responseData is Map<String, dynamic>) {
//         isSuccess = responseData['isSuccess'] == true;
//         message = responseData['message']?.toString() ?? '';
//
//         // ✅ SPECIAL CASE: "Already Executed" should be treated as SUCCESS
//         if (!isSuccess && message.toLowerCase().contains("already executed")) {
//           isSuccess = true;
//           message = "Already Executed (Synced successfully)";
//         }
//
//         if (responseData['data'] is Map<String, dynamic>) {
//           dataMap = responseData['data'];
//         }
//       }
//
//       // ================= SUCCESS FLOW (including "Already Executed") =================
//       if (isSuccess || response.statusCode == 200) {
//         String? printIdFromResponse;
//
//         if (dataMap != null) {
//           printIdFromResponse = dataMap['printId']?.toString();
//         }
//
//         // ✅ Save printId only for execution
//         if (uploadType == "execution" && printIdFromResponse != null) {
//           metadata.printId = printIdFromResponse;
//         }
//
//         // ✅ DELETE FROM HIVE (FOR BOTH execution + rework)
//         await ExecutionImageUploadHiveRepository().deleteMetadata(
//           metadata.ServerPlanId!,
//           metadata.PrintNo!,
//         );
//
//         // ================= LOG =================
//         String metadataJson = jsonEncode(metadata.toJson());
//
//         await SyncCrashReportManager.storeCrashReport(
//           error: "Sync Data: $metadataJson",
//           stackTrace: StackTrace.current.toString(),
//           additionalInfo: {
//             'type': uploadType,
//             'timestamp': DateTime.now().toIso8601String(),
//             'printId': printIdFromResponse ?? metadata.printId ?? 'null',
//             'serverMessage': message,
//           },
//         );
//
//         return {
//           'success': true,
//           'message': message,
//           'data': {
//             'printId': printIdFromResponse ?? metadata.printId,
//             'serverPlanId': dataMap?['serverPlanId']?.toString(),
//             'planCode': dataMap?['planCode']?.toString(),
//             'printNo': dataMap?['printNo']?.toString(),
//           }
//         };
//       }
//
//       // ================= FAILURE =================
//       return {
//         'success': false,
//         'message': message.isNotEmpty ? message : 'Upload failed',
//       };
//
//     } on DioError catch (e) {
//       if (e.response != null) {
//         String serverMessage = '';
//
//         if (e.response?.data is Map && e.response?.data['message'] != null) {
//           serverMessage = e.response!.data['message'].toString();
//         }
//
//         // ✅ SPECIAL CASE: "Already Executed" should be treated as SUCCESS
//         if (serverMessage.toLowerCase().contains("already executed")) {
//           await ExecutionImageUploadHiveRepository().deleteMetadata(
//             metadata.ServerPlanId!,
//             metadata.PrintNo!,
//           );
//
//           return {
//             'success': true,
//             'message': 'Already Executed (Synced successfully)',
//           };
//         }
//
//         switch (e.response!.statusCode) {
//           case 400:
//           // ✅ DUPLICATE: Treat as success and delete from Hive
//             if (serverMessage.toLowerCase().contains('duplicate')) {
//               await ExecutionImageUploadHiveRepository().deleteMetadata(
//                 metadata.ServerPlanId!,
//                 metadata.PrintNo!,
//               );
//
//               return {
//                 'success': true,
//                 'message': 'Already uploaded on server',
//               };
//             }
//
//             return {
//               'success': false,
//               'message': serverMessage.isNotEmpty
//                   ? serverMessage
//                   : 'Invalid data provided.',
//             };
//
//           case 401:
//             return {
//               'success': false,
//               'message': 'Unauthorized: Authentication failed. Please login again.',
//             };
//
//           case 403:
//             return {
//               'success': false,
//               'message': 'Forbidden: Access denied. Please contact admin.',
//             };
//
//           case 404:
//             return {
//               'success': false,
//               'message': 'Not Found: No data found. Please try again later.',
//             };
//
//           case 500:
//             return {
//               'success': false,
//               'message': 'Internal Server Error: Please contact admin.',
//             };
//
//           case 502:
//             return {
//               'success': false,
//               'message': 'Bad Gateway: Server temporarily unavailable. Please try again later.',
//             };
//
//           case 503:
//             return {
//               'success': false,
//               'message': 'Service Unavailable: Please try again later.',
//             };
//
//           default:
//             return {
//               'success': false,
//               'message': 'Server Error (${e.response!.statusCode}): ${serverMessage.isNotEmpty ? serverMessage : "Please try again later."}',
//             };
//         }
//       } else {
//         return {
//           'success': false,
//           'message': 'Network error: Please check your internet connection and try again.',
//         };
//       }
//     } catch (e) {
//       return {
//         'success': false,
//         'message': 'An unexpected error occurred: ${e.toString()}',
//       };
//     }
//   }
//
//   Future<Map<String, dynamic>> syncAllPlanMetadata(List<ImageUploaddata> metadataList) async {
//     List<Map<String, dynamic>> results = [];
//     int successCount = 0;
//     int failureCount = 0;
//     List<String> errors = [];
//     String? criticalError;
//
//     for (var metadata in metadataList) {
//       try {
//         Map<String, dynamic> result = await uploadPlanMetadata(metadata);
//
//         bool isSuccess = result['success'] ?? false;
//
//         if (isSuccess) {
//           successCount++;
//           results.add({
//             'planId': metadata.ServerPlanId.toString(),
//             'success': true,
//             'message': result['message'] ?? 'Successfully uploaded',
//             'statusCode': 200,
//             'data': result['data'], // Contains printId
//           });
//         } else {
//           failureCount++;
//           results.add({
//             'planId': metadata.ServerPlanId.toString(),
//             'success': false,
//             'message': result['message'] ?? 'Upload failed',
//             'statusCode': 400,
//           });
//           errors.add('Failed to upload PrintId: ${metadata.ServerPlanId}');
//         }
//       } on DioError catch (e) {
//         String errorMessage;
//         if (e.response != null) {
//           switch (e.response!.statusCode) {
//             case 400:
//               errorMessage = 'Bad Request: No data found. Please try again later.';
//               break;
//             case 401:
//               errorMessage = 'Unauthorized: Authentication failed. Please login again.';
//               break;
//             case 403:
//               errorMessage = 'Forbidden: Access denied. Please contact admin.';
//               break;
//             case 404:
//               errorMessage = 'Not Found: No data found. Please try again later.';
//               break;
//             case 500:
//               errorMessage = 'Internal Server Error: Please contact admin for assistance.';
//               break;
//             case 502:
//               errorMessage = 'Bad Gateway: Server temporarily unavailable. Please try again later.';
//               break;
//             case 503:
//               errorMessage = 'Service Unavailable: Please try again later.';
//               break;
//             default:
//               errorMessage = 'Server Error (${e.response!.statusCode}): No data found. Please try again later.';
//           }
//         } else {
//           errorMessage = 'Network error: Please check your internet connection and try again.';
//           criticalError = errorMessage;
//         }
//
//         failureCount++;
//         results.add({
//           'planId': metadata.ServerPlanId.toString(),
//           'success': false,
//           'message': errorMessage,
//           'statusCode': e.response?.statusCode ?? 0,
//         });
//
//         errors.add('PrintId ${metadata.ServerPlanId}: $errorMessage');
//
//         if (criticalError != null) {
//           throw criticalError;
//         }
//       } catch (e) {
//         String errorMessage = e is String ? e : 'An unexpected error occurred. Please try again later.';
//
//         failureCount++;
//         results.add({
//           'planId': metadata.ServerPlanId.toString(),
//           'success': false,
//           'message': errorMessage,
//           'statusCode': 0,
//         });
//
//         errors.add('PrintId ${metadata.ServerPlanId}: $errorMessage');
//
//         if (errorMessage.contains('Network') || errorMessage.contains('internet connection')) {
//           throw errorMessage;
//         }
//       }
//     }
//
//     if (errors.isNotEmpty && successCount > 0) {
//       for (String error in errors) {
//       }
//     }
//
//     return {
//       'success': successCount > 0,
//       'message': successCount > 0
//           ? 'Synced $successCount out of ${metadataList.length} items'
//           : 'All syncs failed',
//       'results': results,
//       'successCount': successCount,
//       'failureCount': failureCount,
//     };
//   }
//
//   Future<bool> uploadPlanMetadataWithoutDelete(ImageUploaddata metadata) async {
//     try {
//       Dio dio = Auth.dio;
//       String currentDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
//       String getToken = await getAuthToken();
//
//       // Create form data
//       FormData formData = FormData.fromMap({
//         'ServerPlanId': metadata.ServerPlanId,
//         'PlanCode': metadata.PlanCode,
//         'PrintNo': metadata.PrintNo,
//         'VillageCode': metadata.VillageCode,
//         'Address': metadata.Address,
//         'ExecutionDate': metadata.ExecutionDate,
//         'UploadDate': currentDate,
//         'Clean_Latitude': metadata.CleanLatitude,
//         'Clean_Longitude': metadata.CleanLongitude,
//         'WB_Latitude': metadata.WBLatitude,
//         'WB_Longitude': metadata.WBLongitude,
//         'Spray_Latitude': metadata.SprayLatitude,
//         'Spray_Longitude': metadata.SprayLongitude,
//         'Near_Latitude': metadata.NearLatitude,
//         'Near_Longitude': metadata.NearLongitude,
//         'Far_Latitude': metadata.FarLatitude,
//         'Far_Longitude': metadata.FarLongitude,
//         'New6_Latitude': metadata.New6Latitude,
//         'New6_Longitude': metadata.New6Longitude,
//         'New7_Latitude': metadata.New7Latitude,
//         'New7_Longitude': metadata.New7Longitude,
//         'NetworkStatus': metadata.networkFlagString,
//
//         // Add the image files as multipart files if they exist
//         if (metadata.CleanImage != null)
//           'CleanImage': await MultipartFile.fromFile(metadata.CleanImage!),
//         if (metadata.WBImage != null)
//           'WBImage': await MultipartFile.fromFile(metadata.WBImage!),
//         if (metadata.SprayImage != null)
//           'SprayImage': await MultipartFile.fromFile(metadata.SprayImage!),
//         if (metadata.NearImage != null)
//           'NearImage': await MultipartFile.fromFile(metadata.NearImage!),
//         if (metadata.FarImage != null)
//           'FarImage': await MultipartFile.fromFile(metadata.FarImage!),
//         if (metadata.NewImage6 != null)
//           'NewImage6': await MultipartFile.fromFile(metadata.NewImage6!),
//         if (metadata.NewImage7 != null)
//           'NewImage7': await MultipartFile.fromFile(metadata.NewImage7!),
//       });
//
//       String resendUrl = '${APIURLs.baseURL}api/Execution/plans/resend-upload-prints';
//
//
//       // Send the request to the API
//       var response = await dio.post(
//           resendUrl,
//           options: Options(
//             headers: {
//               'Content-Type': 'multipart/form-data', // Changed from application/json
//               'Authorization': getToken,
//             },
//           ),
//           data: formData
//       );
//
//       if (response.statusCode == 200) {
//
//         return true;
//       }
//       return false;
//     } on DioError catch (e) {
//
//       if (e.response != null) {
//         switch (e.response!.statusCode) {
//           case 400:
//             throw 'Bad Request: Invalid data provided. Please check the details.';
//           case 401:
//             throw 'Unauthorized: Please login again.';
//           case 403:
//             throw 'Forbidden: Access denied.';
//           case 404:
//             throw 'Not Found: Resend endpoint not available. Please check API configuration.';
//           case 500:
//             throw 'Server Error: Please try again later.';
//           case 502:
//             throw 'Bad Gateway: Server temporarily unavailable.';
//           case 503:
//             throw 'Service Unavailable: Please try again later.';
//           default:
//             throw 'Server Error (${e.response!.statusCode}): Please try again later.';
//         }
//       } else {
//         throw 'Network error: Please check your internet connection.';
//       }
//     } catch (e) {
//       if (e is String) {
//         throw e;
//       }
//       throw 'An unexpected error occurred during resend.';
//     }
//   }
// }
//
//
// class AuthInterceptor extends Interceptor {
//   @override
//   void onError(DioException err, ErrorInterceptorHandler handler) async {
//     // Handle 401 Unauthorized - Token expired
//     if (err.response?.statusCode == 401) {
//       await TokenManager().logout('Your session has expired. Please login again.');
//     }
//     super.onError(err, handler);
//   }
//
//   @override
//   void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
//     // Skip token validation for authentication endpoints
//
//     final isAuthEndpoint = options.path.contains('api/Auth/sign-in') ||
//         options.path.contains('api/User/register-user') ||
//         options.path.contains('Auth/sign-in') ||
//         options.path.contains('User/register-user');
//
//     if (isAuthEndpoint) {
//       super.onRequest(options, handler);
//       return;
//     }
//
//     // For all other endpoints, check token validity
//     final isValid = await TokenManager().isTokenValid();
//
//     if (!isValid) {
//       await TokenManager().logout();
//       handler.reject(
//         DioException(
//           requestOptions: options,
//           error: 'Token expired',
//           type: DioExceptionType.cancel,
//         ),
//       );
//       return;
//     }
//
//     super.onRequest(options, handler);
//   }
// }


import 'dart:convert';
import 'dart:io';
import 'package:canimage/Model/execution_dashboard_summary_details_model.dart';
import 'package:canimage/Model/login_model.dart';
import 'package:canimage/utils/base.dart';
import 'package:canimage/utils/sync_crash_manager.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Hive_Database/post_recca_image_upload_db.dart';
import '../Hive_Database/execution_image_upload_db.dart';
import '../Hive_Database/resend_db.dart';
import '../Model/execution_dashboard_summary_model.dart';
import '../Model/project_model.dart';
import '../Model/recca_remarks_model.dart' hide Data;
import '../Model/registration_model.dart' hide Data;
import '../Model/see_plan_model.dart' hide Data;
import '../Repository/execution_image_upload_repository.dart';
import '../Repository/execution_resend_repository.dart';
import '../Repository/post_recca_image_upload_repository.dart';
import '../utils/DeviceIdManager.dart';
import '../utils/crash_manager.dart';
import '../utils/error_log.dart';
import '../utils/print_crash_manager.dart';
import '../utils/shared_preference.dart';
import '../utils/token_manager.dart';
import '../Model/login_model.dart' hide Data;

class Auth {
  static final Dio _dio = Dio();
  static Dio get dio => _dio;

  static void initialize() {
    _dio.interceptors.add(AuthInterceptor());
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

  // ==================== REGISTRATION ====================
  Future<RegistrationAuthModel?> registration(
      String firstName,
      String lastName,
      String phoneNumber,
      String password,
      String uid,
      String role, {
        File? userImage,
      }) async {
    try {
      String deviceId = await DeviceIdManager.getDeviceId();

      print(deviceId);

      await _logRequest('REGISTRATION', {
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'uid': DeviceIdManager.deviceId,
        'role': role,
        'image': userImage?.path ?? 'No Image',
      });

      final formData = FormData.fromMap({
        'FirstName': firstName,
        'LastName': lastName,
        'PhoneNumber': phoneNumber,
        'Password': password,
        'UId': DeviceIdManager.deviceId,
        'RoleFlag': role,
        'UserImagePath': null,
        if (userImage != null)
          'UserImage': await MultipartFile.fromFile(
            userImage.path,
            filename: userImage.path.split('/').last,
          ),
      });

      final response = await dio.post(
        '${APIURLs.baseURL}${APIURLs.registerURL}',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
            'accept': '*/*',
          },
        ),
      );

      await _logResponse('REGISTRATION', response);

      if (response.data != null) {
        final result = RegistrationAuthModel.fromJson(response.data);
        if (result.isSuccess == true) {
          await CrashReportManager.storeLogMessage(
            'REGISTRATION SUCCESS: ${result.message}',
          );
        }
        return result;
      }

      await _logError('Registration: No response from server', phoneNumber);
      return RegistrationAuthModel(
        isSuccess: false,
        message: 'No response from server',
      );
    } on DioException catch (e) {
      return _handleRegistrationError(e, phoneNumber);
    } catch (e) {
      await _logError('Registration unexpected error: $e', phoneNumber);
      return RegistrationAuthModel(
        isSuccess: false,
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  RegistrationAuthModel _handleRegistrationError(DioException e, String phoneNumber) {
    final errorMessage = _getErrorMessage(e, 'Registration');

    if (e.response?.data != null) {
      try {
        final result = RegistrationAuthModel.fromJson(e.response!.data);
        return result;
      } catch (_) {}
    }

    return RegistrationAuthModel(
      isSuccess: false,
      message: errorMessage,
    );
  }

  // ==================== LOGIN ====================
  Future<LoginAuthModel?> login(
      String phoneNumber,
      String password,
      String userID,
      String UID,
      ) async {
    try {
      String deviceId = await DeviceIdManager.getDeviceId();

      print(deviceId);

      final query = {
        'loginId': phoneNumber,
        'password': password,
        'uId': DeviceIdManager.deviceId,
        /// Paster login
        //'uId': '1204884291782376',
        /// Can image User  login
       /// 'uId': '3842013021782376',
      };

      await _logRequest('LOGIN', query);

      final response = await dio.post(
        '${APIURLs.baseURL}${APIURLs.loginURL}',
        data: query,
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      await _logResponse('LOGIN', response);

      if (response.data != null) {
        final result = LoginAuthModel.fromJson(response.data);

        if (result.isSuccess == true && result.data != null) {
          await _saveUserData(result.data!);
          await CrashReportManager.storeLogMessage(
            'LOGIN SUCCESS: userId=${result.data!.userId}, role=${result.data!.roleName}',
          );
        }

        return result;
      }

      await _logError('Login: No response from server', phoneNumber);
      return LoginAuthModel(
        isSuccess: false,
        message: 'No response from server',
      );
    } on DioException catch (e) {
      return _handleLoginError(e, phoneNumber);
    } catch (e) {
      await _logError('Login unexpected error: $e', phoneNumber);
      return LoginAuthModel(
        isSuccess: false,
        message: 'Unexpected error. Please try again.',
      );
    }
  }

  LoginAuthModel _handleLoginError(DioException e, String phoneNumber) {
    // Log error but don't await here - this is a synchronous method
    ErrorReportManager.storeErrorReport(
      error: 'Login DioError: ${e.type}',
      level: ErrorLevel.error,
      stackTrace: StackTrace.current.toString(),
      additionalInfo: {'phoneNumber': phoneNumber},
    );

    if (e.response?.data != null) {
      try {
        final result = LoginAuthModel.fromJson(e.response!.data);
        return result;
      } catch (_) {}
    }

    return LoginAuthModel(
      isSuccess: false,
      message: _getErrorMessage(e, 'Login'),
    );
  }

  Future<void> _saveUserData(Data data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', data.userId ?? '');
    await prefs.setString('uId', data.uId ?? '');
    await prefs.setString('roleFlag', data.roleFlag ?? '');
    await prefs.setString('roleName', (data.roleName ?? '').trim());
    await prefs.setString('fname', (data.fname ?? '').trim());
    await prefs.setString('token', data.accessToken ?? '');
  }

  // ==================== FETCH METHODS ====================
  Future<ReccaRemarksModel> fetchReccaRemarksModel(String projectID) async {
    try {
      final token = await getAuthToken();
      final response = await dio.get(
        '${APIURLs.baseURL}${APIURLs.reccaRemarks}?ProjectId=$projectID',
        options: _getOptions(token),
      );
      return ReccaRemarksModel.fromJson(response.data);
    } catch (e) {
      await _logError('fetchReccaRemarks for ProjectId: $projectID', null, e);
      return ReccaRemarksModel(data: []);
    }
  }

  Future<ProjectModel> fetchProjectModel() async {
    try {
      final token = await getAuthToken();
      final response = await dio.get(
        '${APIURLs.baseURL}${APIURLs.projects}',
        options: _getOptions(token),
      );
      return ProjectModel.fromJson(response.data);
    } catch (e) {
      await _logError('fetchProjectModel', null, e);
      return ProjectModel(data: []);
    }
  }

  Future<SeePlanModel> fetchSeePlanModel() async {
    try {
      final token = await getAuthToken();
     final String userId = (await getUserID()).toString();
      final String uId = (await getFirstUID()).toString();
      // final String userId = '20119';
      // final String uId = '1204884291782376';

      final url = "${APIURLs.URL}${APIURLs.seePlanURL}";

      final body = {
        "planCode": "0",
        "villageCode": "0",
        "userId": userId,
        "uId": DeviceIdManager.deviceId,
      };

      print("========== FETCH SEE PLAN ==========");
      print("URL : $url");
      print("BODY : $body");

      final response = await dio.post(
        url,
        data: body,
        options: _getOptions(token),
      );

      print("========== RESPONSE ==========");
      print(response.data);

      final model = SeePlanModel.fromJson(response.data);

      print("Status : ${model.status}");
      print("Message : ${model.message}");
      print("Total Plans : ${model.data?.length}");

      return model;
    } on DioException catch (e) {
      print(e.response?.data);
      return SeePlanModel(data: []);
    } catch (e) {
      print(e);
      return SeePlanModel(data: []);
    }
  }

  Future<ExecutionDashboardSummaryModel?> fetchExecutionDashboardSummary(
      String startDate,
      String endDate,
      String projectID,
      ) async {
    try {
      final token = await getAuthToken();
      final response = await dio.get(
        '${APIURLs.baseURL}${APIURLs.executionDashoardSummary}'
            '?ProjectId=$projectID&StartDate=$startDate&EndDate=$endDate',
        options: _getOptions(token),
      );

      if (response.statusCode == 200 &&
          response.data is Map<String, dynamic> &&
          _hasValidResponse(response.data)) {
        return ExecutionDashboardSummaryModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      await _logError('fetchExecutionDashboardSummary', null, e);
      return null;
    }
  }

  Future<ExecutionDashboardSummaryDetailsModel?> fetchExecutionDashboardSummaryDetails(
      String plan,
      String startDate,
      String endDate,
      String projectID,
      ) async {
    try {
      final token = await getAuthToken();
      final response = await dio.get(
        '${APIURLs.baseURL}${APIURLs.executionDashoardSummaryDetails}'
            '?ProjectId=$projectID&StartDate=$startDate&EndDate=$endDate&Flag=$plan',
        options: _getOptions(token),
      );

      if (response.statusCode == 200 &&
          response.data is Map<String, dynamic> &&
          _hasValidResponse(response.data)) {
        return ExecutionDashboardSummaryDetailsModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      await _logError('fetchExecutionDashboardSummaryDetails', null, e);
      return null;
    }
  }

  bool _hasValidResponse(Map<String, dynamic> data) {
    return data.containsKey('isSuccess') && data.containsKey('data');
  }

  Options _getOptions(String token) {
    return Options(
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
    );
  }

  // ==================== POST RECCA UPLOAD ====================
  Future<bool> uploadMetadata(SUImageUploaddata metadata) async {
    try {
      final token = await getAuthToken();
      final formData = await _buildReccaFormData(metadata);

      final response = await dio.post(
        '${APIURLs.baseURL}${APIURLs.reccaPost}',
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
            'Authorization': token,
          },
        ),
        data: formData,
      );

      if (response.statusCode == 200) {
        await PostReccaImageUploadHiveRepository()
            .deleteMetadataFromHive(metadata.printId);
        await _logSync('Post Recca Sync Data', metadata.printId);
        return true;
      }
      return false;
    } on DioException catch (e) {
      return _handleReccaUploadError(e, metadata);
    } catch (e) {
      await _logError('Post Recca unexpected error', null, e);
      rethrow;
    }
  }

  Future<FormData> _buildReccaFormData(SUImageUploaddata metadata) async {
    final currentDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    return FormData.fromMap({
      'PrintId': metadata.printId,
      'PrintNo': metadata.printNo,
      'PlanCode': metadata.planCode,
      'Near_Latitude': metadata.nearLatitude,
      'Near_Longitude': metadata.nearLongitude,
      'Far_Latitude': metadata.farLatitude,
      'Far_Longitude': metadata.farLongitude,
      'VillageCode': metadata.villageCode,
      'Remark': metadata.remark,
      'ExecutionDate': metadata.executionDate,
      'UploadDate': currentDate,
      if (metadata.nearImagePath != null)
        'NearImage': await MultipartFile.fromFile(metadata.nearImagePath!),
      if (metadata.farImagePath != null)
        'FarImage': await MultipartFile.fromFile(metadata.farImagePath!),
    });
  }

  bool _handleReccaUploadError(DioException e, SUImageUploaddata metadata) {
    final errorMessage = _getErrorMessage(e, 'Recca Upload');

    if (e.response?.data is Map) {
      final serverMessage = e.response!.data['message']?.toString() ?? '';

      // Handle duplicate error
      if (serverMessage.toLowerCase().contains('duplicate')) {
        PostReccaImageUploadHiveRepository()
            .deleteMetadataFromHive(metadata.printId);
        throw Exception('DUPLICATE_IMAGE_ERROR: This print has already been uploaded.');
      }
    }

    throw Exception(errorMessage);
  }

  // ==================== EXECUTION UPLOAD ====================
  Future<Map<String, dynamic>> uploadPlanMetadata(ImageUploaddata metadata) async {
    try {
      // ========== DEBUG: PRINT PAYLOAD ==========
      print("==============================================");
      print("📤 EXECUTION UPLOAD PAYLOAD");
      print("==============================================");
      print("ServerPlanId: ${metadata.ServerPlanId}");
      print("locateId: ${metadata.locateId}");
      print("PlanCode: ${metadata.PlanCode}");
      print("PrintNo: ${metadata.PrintNo}");
      print("VillageCode: ${metadata.VillageCode}");
      print("Address: ${metadata.Address}");
      print("ExecutionDate: ${metadata.ExecutionDate}");
      print("UploadDate: ${metadata.UploadDate}");
      print("NetworkStatus: ${metadata.networkFlagString}");
      print("UploadType: ${metadata.uploadType ?? 'execution'}");
      print("----------------------------------------------");
      print("📍 GPS Coordinates:");
      print("  Clean: (${metadata.CleanLatitude}, ${metadata.CleanLongitude})");
      print("  WB: (${metadata.WBLatitude}, ${metadata.WBLongitude})");
      print("  Spray: (${metadata.SprayLatitude}, ${metadata.SprayLongitude})");
      print("  Near: (${metadata.NearLatitude}, ${metadata.NearLongitude})");
      print("  Far: (${metadata.FarLatitude}, ${metadata.FarLongitude})");
      print("  New6: (${metadata.New6Latitude}, ${metadata.New6Longitude})");
      print("  New7: (${metadata.New7Latitude}, ${metadata.New7Longitude})");
      print("----------------------------------------------");
      print("📷 Images:");
      print("  CleanImage: ${metadata.CleanImage?.split('/').last}");
      print("  WBImage: ${metadata.WBImage?.split('/').last}");
      print("  SprayImage: ${metadata.SprayImage?.split('/').last}");
      print("  NearImage: ${metadata.NearImage?.split('/').last}");
      print("  FarImage: ${metadata.FarImage?.split('/').last}");
      print("  NewImage6: ${metadata.NewImage6?.split('/').last}");
      print("  NewImage7: ${metadata.NewImage7?.split('/').last}");
      print("==============================================");
      // ========== END DEBUG ==========

      // ========== CHECK FOR ALREADY SYNCED ==========
      final existingResponses = await ApiResponseRepository().loadAllResponses();

      for (var response in existingResponses) {
        String existingPrintNo = '';
        if (response.originalData is ImageUploaddata) {
          existingPrintNo = (response.originalData as ImageUploaddata).PrintNo?.toString() ?? '';
        }

        if (response.planId == metadata.ServerPlanId &&
            existingPrintNo == metadata.PrintNo &&
            response.isSuccess == true) {
          print("✅ ALREADY SYNCED: ${metadata.ServerPlanId}_${metadata.PrintNo}");

          await ExecutionImageUploadHiveRepository().deleteMetadata(
            metadata.ServerPlanId!,
            metadata.PrintNo!,
          );

          return {
            'success': true,
            'message': 'Already synced',
            'data': {
              'printId': response.originalData.printId ?? 'N/A',
            }
          };
        }
      }

      final uploadType = (metadata.uploadType ?? 'execution').toLowerCase();
      final token = await getAuthToken();

      if (metadata.ServerPlanId == null || metadata.PlanCode == null || metadata.PrintNo == null) {
        return {'success': false, 'message': 'Missing required metadata fields'};
      }

      if (uploadType == 'rework' && metadata.printId == null) {
        return {'success': false, 'message': 'Rework upload requires printId'};
      }

      final formData = await _buildExecutionFormData(metadata, uploadType);
      final apiUrl = uploadType == 'rework' ? APIURLs.ReworkUpload : APIURLs.executionPost;

      final response = await dio.post(
        '${APIURLs.baseURL}$apiUrl',
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
            'Authorization': token,
          },
        ),
        data: formData,
      );

      // ========== DEBUG: PRINT RESPONSE ==========
      print("==============================================");
      print("📥 EXECUTION UPLOAD RESPONSE");
      print("Status Code: ${response.statusCode}");
      print("Response: ${response.data}");
      print("==============================================");
      // ========== END DEBUG ==========

      return await _handleExecutionResponse(response, metadata, uploadType);

    } on DioException catch (e) {
      // ========== DEBUG: PRINT ERROR ==========
      print("==============================================");
      print("❌ EXECUTION UPLOAD ERROR");
      print("Status Code: ${e.response?.statusCode}");
      print("Error: ${e.message}");
      print("Response: ${e.response?.data}");
      print("==============================================");
      // ========== END DEBUG ==========
      return await _handleExecutionError(e, metadata);
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: ${e.toString()}',
      };
    }
  }

  Future<FormData> _buildExecutionFormData(ImageUploaddata metadata, String uploadType) async {
    final currentDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final addressValue = _getValidAddress(metadata.Address);

    metadata.PrintNo = metadata.PrintNo?.trim().toUpperCase();
    metadata.ServerPlanId = metadata.ServerPlanId?.trim();

    final formData = FormData.fromMap({
      'ServerPlanId': metadata.ServerPlanId,
      'PlanCode': metadata.PlanCode,
      'PrintNo': metadata.PrintNo,
      'VillageCode': metadata.VillageCode ?? '',
      'Address': addressValue,
      'ExecutionDate': metadata.ExecutionDate ?? currentDate,
      'UploadDate': currentDate,
      'Clean_Latitude': metadata.CleanLatitude ?? '0.0',
      'Clean_Longitude': metadata.CleanLongitude ?? '0.0',
      'WB_Latitude': metadata.WBLatitude ?? '0.0',
      'WB_Longitude': metadata.WBLongitude ?? '0.0',
      'Spray_Latitude': metadata.SprayLatitude ?? '0.0',
      'Spray_Longitude': metadata.SprayLongitude ?? '0.0',
      'Near_Latitude': metadata.NearLatitude ?? '0.0',
      'Near_Longitude': metadata.NearLongitude ?? '0.0',
      'Far_Latitude': metadata.FarLatitude ?? '0.0',
      'Far_Longitude': metadata.FarLongitude ?? '0.0',
      'New6_Latitude': metadata.New6Latitude ?? '0.0',
      'New6_Longitude': metadata.New6Longitude ?? '0.0',
      'New7_Latitude': metadata.New7Latitude ?? '0.0',
      'New7_Longitude': metadata.New7Longitude ?? '0.0',
      'NetworkStatus': metadata.networkFlagString ?? 'UNKNOWN',
      'LocateId': metadata.locateId ?? '',
    });

    if (uploadType == 'rework') {
      formData.fields.add(MapEntry('PrintId', metadata.printId!));
    }

    await _addImageToFormData(formData, 'CleanImage', metadata.CleanImage);
    await _addImageToFormData(formData, 'WBImage', metadata.WBImage);
    await _addImageToFormData(formData, 'SprayImage', metadata.SprayImage);
    await _addImageToFormData(formData, 'NearImage', metadata.NearImage);
    await _addImageToFormData(formData, 'FarImage', metadata.FarImage);
    await _addImageToFormData(formData, 'NewImage6', metadata.NewImage6);
    await _addImageToFormData(formData, 'NewImage7', metadata.NewImage7);

    return formData;
  }

  String _getValidAddress(String? address) {
    if (address != null && address.trim().isNotEmpty && address != 'null') {
      return address;
    }
    return 'No Data';
  }

  Future<void> _addImageToFormData(FormData formData, String key, String? path) async {
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        formData.files.add(
          MapEntry(key, await MultipartFile.fromFile(path)),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _handleExecutionResponse(
      Response response,
      ImageUploaddata metadata,
      String uploadType,
      ) async {
    final responseData = response.data as Map<String, dynamic>?;

    if (responseData == null) {
      return {'success': false, 'message': 'Empty response from server'};
    }

    bool isSuccess = responseData['isSuccess'] == true;
    String message = responseData['message']?.toString() ?? '';

    if (!isSuccess && message.toLowerCase().contains('already executed')) {
      isSuccess = true;
      message = 'Already Executed (Synced successfully)';
    }

    final dataMap = responseData['data'] as Map<String, dynamic>?;
    String? printIdFromResponse = dataMap?['printId']?.toString();

    // ========== DEBUG: PRINT PRINT ID ==========
    print("==============================================");
    print("✅ PRINT ID FROM RESPONSE");
    print("printId: $printIdFromResponse");
    print("isSuccess: $isSuccess");
    print("message: $message");
    print("==============================================");
    // ========== END DEBUG ==========

    if (isSuccess || response.statusCode == 200) {
      if (uploadType == 'execution' && printIdFromResponse != null) {
        metadata.printId = printIdFromResponse;
      }

      await ExecutionImageUploadHiveRepository().deleteMetadata(
        metadata.ServerPlanId!,
        metadata.PrintNo!,
      );

      await _logSync('Sync Data (${uploadType.toUpperCase()})',
          printIdFromResponse ?? metadata.printId ?? 'null');

      return {
        'success': true,
        'message': message,
        'data': {
          'printId': printIdFromResponse ?? metadata.printId,
          'serverPlanId': dataMap?['serverPlanId']?.toString(),
          'planCode': dataMap?['planCode']?.toString(),
          'printNo': dataMap?['printNo']?.toString(),
        }
      };
    }

    return {'success': false, 'message': message.isNotEmpty ? message : 'Upload failed'};
  }

  Future<Map<String, dynamic>> _handleExecutionError(DioException e, ImageUploaddata metadata) async {
    String serverMessage = _getServerMessage(e);
    String errorMessage = serverMessage.isNotEmpty ? serverMessage : _getErrorMessage(e, 'Execution Upload');

    bool isAlreadyOnServer = serverMessage.toLowerCase().contains('already executed') ||
        serverMessage.toLowerCase().contains('duplicate');

    bool isSuccess = isAlreadyOnServer;

    // ========== DEBUG: PRINT ERROR ==========
    print("==============================================");
    print(" HANDLE EXECUTION ERROR");
    print("serverMessage: $serverMessage");
    print("isAlreadyOnServer: $isAlreadyOnServer");
    print("errorMessage: $errorMessage");
    print("==============================================");
    // ========== END DEBUG ==========

    final apiResponseRepo = ApiResponseRepository();
    await apiResponseRepo.saveApiResponse(ApiResponseData(
      planId: metadata.ServerPlanId!,
      originalData: metadata,
      isSuccess: isSuccess,
      responseMessage: errorMessage,
      responseTime: DateTime.now(),
      statusCode: e.response?.statusCode ?? 0,
      retryCount: 0,
    ));

    await ExecutionImageUploadHiveRepository().deleteMetadata(
      metadata.ServerPlanId!,
      metadata.PrintNo!,
    );

    if (isSuccess) {
      return {
        'success': true,
        'message': 'Already on server',
        'data': {
          'printId': metadata.printId ?? 'N/A',
        }
      };
    }

    return {
      'success': false,
      'message': errorMessage,
    };
  }

  String _getServerMessage(DioException e) {
    if (e.response?.data is Map && e.response?.data['message'] != null) {
      return e.response!.data['message'].toString();
    }
    return '';
  }

  // ==================== RESEND METHOD (NEW) ====================

  Future<Map<String, dynamic>> resendPlanMetadata(
      ImageUploaddata metadata) async {
    try {
      // Normalize data
      metadata.PrintNo = metadata.PrintNo?.trim().toUpperCase();

      final token = await getAuthToken();
      final currentDate =
      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      final formData =
      await _buildResendFormData(metadata, currentDate);

      // ================= DEBUG =================
      print("==================================================");
      print(" RESEND REQUEST START");
      print("==================================================");
      print("API : ${APIURLs.baseURL}${APIURLs.executionPost}");
      print("TOKEN : $token");
      print("");

      print("--------------- PAYLOAD ----------------");

      for (final field in formData.fields) {
        print("${field.key} : ${field.value}");
      }

      print("");

      print("--------------- FILES ----------------");

      for (final file in formData.files) {
        print("${file.key} : ${file.value.filename}");
      }

      print("==================================================");

      dio.options.connectTimeout = const Duration(seconds: 60);
      dio.options.receiveTimeout = const Duration(seconds: 60);
      dio.options.sendTimeout = const Duration(seconds: 60);

      final response = await dio.post(
        "${APIURLs.baseURL}${APIURLs.executionPost}",
        data: formData,
        options: Options(
          headers: {
            "Authorization": token,
            "Content-Type": "multipart/form-data",
          },
        ),
      );

      print("==================================================");
      print(" RESEND RESPONSE");
      print("Status Code : ${response.statusCode}");
      print("Data : ${response.data}");
      print("==================================================");

      if (response.statusCode == 200 &&
          response.data is Map<String, dynamic>) {
        final Map<String, dynamic> responseData = response.data;

        bool success = responseData["isSuccess"] == true;

        String message =
            responseData["message"]?.toString() ?? "";

        if (!success &&
            message.toLowerCase().contains("already executed")) {
          success = true;
          message = "Already Executed (Synced Successfully)";
        }

        return {
          "success": success,
          "message": message,
          "data": responseData["data"],
        };
      }

      return {
        "success": false,
        "message": "Unexpected server response.",
      };
    } on DioException catch (e) {
      print("==================================================");
      print(" DIO ERROR");
      print("Type : ${e.type}");
      print("Message : ${e.message}");
      print("Status Code : ${e.response?.statusCode}");
      print("Response : ${e.response?.data}");
      print("==================================================");

      String errorMessage;

      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          errorMessage = "Connection timeout.";
          break;

        case DioExceptionType.sendTimeout:
          errorMessage = "Request timeout.";
          break;

        case DioExceptionType.receiveTimeout:
          errorMessage = "Server timeout.";
          break;

        case DioExceptionType.connectionError:
          errorMessage =
          "No Internet Connection.";
          break;

        case DioExceptionType.badResponse:
          errorMessage =
          "Server Error (${e.response?.statusCode})";
          break;

        default:
          errorMessage =
              e.message ?? "Unknown Network Error";
      }

      if (e.response?.data is Map<String, dynamic>) {
        final serverMessage =
        e.response!.data["message"]?.toString();

        if (serverMessage != null &&
            serverMessage.isNotEmpty) {
          errorMessage = serverMessage;
        }
      }

      return {
        "success": false,
        "message": errorMessage,
      };
    } catch (e, s) {
      print("==================================================");
      print("❌ UNEXPECTED ERROR");
      print(e);
      print(s);
      print("==================================================");

      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }

  // ==================== BATCH SYNC ====================
  Future<Map<String, dynamic>> syncAllPlanMetadata(List<ImageUploaddata> metadataList) async {
    List<Map<String, dynamic>> results = [];
    int successCount = 0;
    int failureCount = 0;
    List<String> errors = [];

    Set<String> processedKeys = {};

    for (var metadata in metadataList) {
      String key = "${metadata.ServerPlanId}_${metadata.PrintNo}";

      if (processedKeys.contains(key)) {
        print("⏭️ SKIPPING DUPLICATE: $key");
        continue;
      }
      processedKeys.add(key);

      try {
        Map<String, dynamic> result = await uploadPlanMetadata(metadata);
        bool isSuccess = result['success'] ?? false;

        if (isSuccess) {
          successCount++;
          results.add({
            'planId': metadata.ServerPlanId.toString(),
            'success': true,
            'message': result['message'] ?? 'Successfully uploaded',
            'statusCode': 200,
            'data': result['data'],
          });
        } else {
          failureCount++;
          results.add({
            'planId': metadata.ServerPlanId.toString(),
            'success': false,
            'message': result['message'] ?? 'Upload failed',
            'statusCode': 400,
          });
          errors.add('Failed to upload PrintId: ${metadata.ServerPlanId}');
        }
      } on DioError catch (e) {
        failureCount++;
        String errorMessage = 'Network error: Please check your internet connection.';

        results.add({
          'planId': metadata.ServerPlanId.toString(),
          'success': false,
          'message': errorMessage,
          'statusCode': e.response?.statusCode ?? 0,
        });

        errors.add('PrintId ${metadata.ServerPlanId}: $errorMessage');
      } catch (e) {
        failureCount++;
        results.add({
          'planId': metadata.ServerPlanId.toString(),
          'success': false,
          'message': e.toString(),
          'statusCode': 0,
        });
        errors.add('PrintId ${metadata.ServerPlanId}: $e');
      }
    }

    return {
      'success': successCount > 0,
      'message': successCount > 0
          ? 'Synced $successCount out of ${metadataList.length} items'
          : 'All syncs failed',
      'results': results,
      'successCount': successCount,
      'failureCount': failureCount,
    };
  }

  Future<bool> syncAllMetadata(List<SUImageUploaddata> metadataList) async {
    bool anySuccess = false;
    for (var metadata in metadataList) {
      try {
        if (await uploadMetadata(metadata)) {
          anySuccess = true;
        }
      } catch (e) {
        await _logError('Sync failed for ${metadata.printId}', null, e);
      }
    }
    return anySuccess;
  }

  Future<FormData> _buildResendFormData(ImageUploaddata metadata, String currentDate) async {
    final formData = FormData.fromMap({
      'ServerPlanId': metadata.ServerPlanId,
      'PlanCode': metadata.PlanCode,
      'PrintNo': metadata.PrintNo,
      'VillageCode': metadata.VillageCode,
      'Address': metadata.Address ?? 'No Data',
      'ExecutionDate': metadata.ExecutionDate,
      'UploadDate': currentDate,
      'Clean_Latitude': metadata.CleanLatitude ?? '0.0',
      'Clean_Longitude': metadata.CleanLongitude ?? '0.0',
      'WB_Latitude': metadata.WBLatitude ?? '0.0',
      'WB_Longitude': metadata.WBLongitude ?? '0.0',
      'Spray_Latitude': metadata.SprayLatitude ?? '0.0',
      'Spray_Longitude': metadata.SprayLongitude ?? '0.0',
      'Near_Latitude': metadata.NearLatitude ?? '0.0',
      'Near_Longitude': metadata.NearLongitude ?? '0.0',
      'Far_Latitude': metadata.FarLatitude ?? '0.0',
      'Far_Longitude': metadata.FarLongitude ?? '0.0',
      'New6_Latitude': metadata.New6Latitude ?? '0.0',
      'New6_Longitude': metadata.New6Longitude ?? '0.0',
      'New7_Latitude': metadata.New7Latitude ?? '0.0',
      'New7_Longitude': metadata.New7Longitude ?? '0.0',
      'NetworkStatus': metadata.networkFlagString ?? 'UNKNOWN',
      'LocateId': metadata.locateId ?? '',
    });

    await _addImageToFormData(formData, 'CleanImage', metadata.CleanImage);
    await _addImageToFormData(formData, 'WBImage', metadata.WBImage);
    await _addImageToFormData(formData, 'SprayImage', metadata.SprayImage);
    await _addImageToFormData(formData, 'NearImage', metadata.NearImage);
    await _addImageToFormData(formData, 'FarImage', metadata.FarImage);
    await _addImageToFormData(formData, 'NewImage6', metadata.NewImage6);
    await _addImageToFormData(formData, 'NewImage7', metadata.NewImage7);

    return formData;
  }

  // ==================== HELPER METHODS ====================
  String _getErrorMessage(DioException e, String context) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please try again.';
      case DioExceptionType.badResponse:
        return 'Server error. Please try again.';
      case DioExceptionType.cancel:
        return 'Request cancelled.';
      case DioExceptionType.connectionError:
        return 'Network error. Please check your internet connection.';
      default:
        return '$context failed. Please try again.';
    }
  }

  Future<void> _logRequest(String endpoint, dynamic data) async {
    await CrashReportManager.storeLogMessage(
      '$endpoint REQUEST\nURL: ${APIURLs.baseURL}${_getEndpointPath(endpoint)}\nBODY: ${jsonEncode(data)}',
    );
  }

  Future<void> _logResponse(String endpoint, Response response) async {
    await CrashReportManager.storeLogMessage(
      '$endpoint RESPONSE\nStatusCode: ${response.statusCode}\nResponse: ${response.data}',
    );
  }

  Future<void> _logError(String message, [String? identifier, dynamic error]) async {
    await ErrorReportManager.storeErrorReport(
      error: '$message${error != null ? ': $error' : ''}',
      level: ErrorLevel.error,
      stackTrace: StackTrace.current.toString(),
      additionalInfo: identifier != null ? {'identifier': identifier} : null,
    );
  }

  Future<void> _logSync(String label, String id) async {
    await SyncCrashReportManager.storeCrashReport(
      error: '$label: $id',
      stackTrace: StackTrace.current.toString(),
      additionalInfo: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  String _getEndpointPath(String endpoint) {
    switch (endpoint) {
      case 'LOGIN':
        return APIURLs.loginURL;
      case 'REGISTRATION':
        return APIURLs.registerURL;
      default:
        return endpoint;
    }
  }
}

// ==================== AUTH INTERCEPTOR ====================
class AuthInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await TokenManager().logout('Your session has expired. Please login again.');
    }
    super.onError(err, handler);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final isAuthEndpoint = options.path.contains('api/Auth/sign-in') ||
        options.path.contains('api/User/register-user') ||
        options.path.contains('Auth/sign-in') ||
        options.path.contains('User/register-user');

    if (!isAuthEndpoint) {
      if (!await TokenManager().isTokenValid()) {
        await TokenManager().logout();
        handler.reject(
          DioException(
            requestOptions: options,
            error: 'Token expired',
            type: DioExceptionType.cancel,
          ),
        );
        return;
      }
    }

    super.onRequest(options, handler);
  }
}