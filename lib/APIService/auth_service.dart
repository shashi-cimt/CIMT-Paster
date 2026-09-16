import 'dart:convert';
import 'dart:io';
import 'package:canimage/Model/execution_dashboard_summary_details_model.dart';
import 'package:canimage/Model/login_model.dart';
import 'package:canimage/utils/base.dart';
import 'package:canimage/utils/sync_crash_manager.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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
import '../utils/server_failover_interceptor.dart';
import '../utils/shared_preference.dart';
import '../utils/token_manager.dart';

class Auth {
  static final Dio _dio = Dio();
  static Dio get dio => _dio;

  static void initialize() {
    debugPrint("******** Auth.initialize() ********");

    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 20);
    _dio.options.sendTimeout = const Duration(seconds: 15);

    _dio.interceptors.clear();

    _dio.interceptors.add(AuthInterceptor());
    _dio.interceptors.add(ServerFailoverInterceptor(_dio));

    debugPrint("Interceptor Count: ${_dio.interceptors.length}");
    _dio.interceptors.add(
      LogInterceptor(
        responseBody: true,
        request: true,
        requestBody: true,
        logPrint: print,
        error: true,
        requestHeader: true,
        responseHeader: true,
      ),
    );
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

      debugPrint(deviceId);

      await _logRequest('REGISTRATION', {
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'uid': uid,
        'role': role,
        'image': userImage?.path ?? 'No Image',
      });

      final formData = FormData.fromMap({
        'FirstName': firstName,
        'LastName': lastName,
        'PhoneNumber': phoneNumber,
        'Password': password,
        'UId': uid,
        'RoleFlag': role,
        'UserImagePath': null,
        if (userImage != null)
          'UserImage': await MultipartFile.fromFile(
            userImage.path,
            filename: userImage.path.split('/').last,
          ),
      });

      debugPrint("========== FORM DATA ==========");
      for (final field in formData.fields) {
        debugPrint("${field.key}: ${field.value}");
      }

      for (final file in formData.files) {
        debugPrint("${file.key}: ${file.value.filename}");
      }
      debugPrint("===============================");

      final response = await dio.post(
        '${APIURLs.baseURL}${APIURLs.registerURL}',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data', 'accept': '*/*'},
        ),
      );
      debugPrint("========== REGISTRATION PAYLOAD ==========");
      debugPrint("FirstName : $firstName");
      debugPrint("LastName  : $lastName");
      debugPrint("Phone     : $phoneNumber");
      debugPrint("Password  : $password");
      debugPrint("UID        : $uid");
      debugPrint("Role       : $role");
      debugPrint("Image      : ${userImage?.path}");
      debugPrint("=========================================");

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

  RegistrationAuthModel _handleRegistrationError(
    DioException e,
    String phoneNumber,
  ) {
    final errorMessage = _getErrorMessage(e, 'Registration');

    if (e.response?.data != null) {
      try {
        final result = RegistrationAuthModel.fromJson(e.response!.data);
        return result;
      } catch (_) {}
    }

    return RegistrationAuthModel(isSuccess: false, message: errorMessage);
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

      debugPrint(deviceId);

      final query = {
        'loginId': phoneNumber,
        'password': password,
        // 'uId': DeviceIdManager.deviceId,
        'uId': UID,

        /// Paster login
        //'uId': '1204884291782376',
        /// Can image User  login
        /// 'uId': '3842013021782376',
      };

      await _logRequest('LOGIN', query);

      final response = await dio.post(
        '${APIURLs.baseURL}${APIURLs.loginURL}',
        data: query,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      await _logResponse('LOGIN', response);

      if (response.data != null) {
        final result = LoginAuthModel.fromJson(response.data);

        if (result.isSuccess == true && result.data != null) {
          // Note: Session data is saved in login_screen.dart only after
          // role verification succeeds, preventing premature or mismatched sessions.
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
        dynamic data = e.response!.data;
        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (_) {}
        }
        if (data is Map<String, dynamic>) {
          final result = LoginAuthModel.fromJson(data);
          return result;
        }
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
      //  final String userId = '20481';
      //  final String uId = 'TP1A.220624.014|20481';

      final url = "${APIURLs.URL}${APIURLs.seePlanURL}";

      final body = {
        "planCode": "0",
        "villageCode": "0",
        "userId": userId,
        // "uId": uId,
        // Static uId for testing/data fetch (dynamic fallback: uId)
        "uId": "5785297331775198",
      };

      debugPrint("========== FETCH SEE PLAN ==========");
      debugPrint("URL : $url");
      debugPrint("BODY : $body");

      final response = await dio.post(
        url,
        data: body,
        options: _getOptions(token),
      );

      debugPrint("========== RESPONSE ==========");
      debugPrint(response.data);

      final model = SeePlanModel.fromJson(response.data);

      debugPrint("Status : ${model.status}");
      debugPrint("Message : ${model.message}");
      debugPrint("Total Plans : ${model.data?.length}");

      return model;
    } on DioException catch (e) {
      debugPrint(e.response?.data);
      return SeePlanModel(data: []);
    } catch (e) {
      debugPrint(e.toString());
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

  Future<ExecutionDashboardSummaryDetailsModel?>
  fetchExecutionDashboardSummaryDetails(
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
      headers: {'Content-Type': 'application/json', 'Authorization': token},
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
        await PostReccaImageUploadHiveRepository().deleteMetadataFromHive(
          metadata.printId,
        );
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
    final currentDate = DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(DateTime.now());

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
        PostReccaImageUploadHiveRepository().deleteMetadataFromHive(
          metadata.printId,
        );
        throw Exception(
          'DUPLICATE_IMAGE_ERROR: This print has already been uploaded.',
        );
      }
    }

    throw Exception(errorMessage);
  }

  // ==================== EXECUTION UPLOAD ====================
  Future<Map<String, dynamic>> uploadPlanMetadata(
    ImageUploaddata metadata,
  ) async {
    try {
      // ========== DEBUG: PRINT PAYLOAD ==========
      debugPrint("==============================================");
      debugPrint(" EXECUTION UPLOAD PAYLOAD");
      debugPrint("==============================================");
      debugPrint("ServerPlanId: ${metadata.ServerPlanId}");
      debugPrint("locateId: ${metadata.locateId}");
      debugPrint("PlanCode: ${metadata.PlanCode}");
      debugPrint("debugPrintNo: ${metadata.PrintNo}");
      debugPrint("VillageCode: ${metadata.VillageCode}");
      debugPrint("Address: ${metadata.Address}");
      debugPrint("ExecutionDate: ${metadata.ExecutionDate}");
      debugPrint("UploadDate: ${metadata.UploadDate}");
      debugPrint("NetworkStatus: ${metadata.networkFlagString}");
      debugPrint("UploadType: ${metadata.uploadType ?? 'execution'}");
      debugPrint("----------------------------------------------");
      debugPrint(" GPS Coordinates:");
      debugPrint(
        "  Clean: (${metadata.CleanLatitude}, ${metadata.CleanLongitude})",
      );
      debugPrint("  WB: (${metadata.WBLatitude}, ${metadata.WBLongitude})");
      debugPrint(
        "  Spray: (${metadata.SprayLatitude}, ${metadata.SprayLongitude})",
      );
      debugPrint(
        "  Near: (${metadata.NearLatitude}, ${metadata.NearLongitude})",
      );
      debugPrint("  Far: (${metadata.FarLatitude}, ${metadata.FarLongitude})");
      debugPrint(
        "  New6: (${metadata.New6Latitude}, ${metadata.New6Longitude})",
      );
      debugPrint(
        "  New7: (${metadata.New7Latitude}, ${metadata.New7Longitude})",
      );
      debugPrint("----------------------------------------------");
      debugPrint(" Images:");
      debugPrint("  CleanImage: ${metadata.CleanImage?.split('/').last}");
      debugPrint("  WBImage: ${metadata.WBImage?.split('/').last}");
      debugPrint("  SprayImage: ${metadata.SprayImage?.split('/').last}");
      debugPrint("  NearImage: ${metadata.NearImage?.split('/').last}");
      debugPrint("  FarImage: ${metadata.FarImage?.split('/').last}");
      debugPrint("  NewImage6: ${metadata.NewImage6?.split('/').last}");
      debugPrint("  NewImage7: ${metadata.NewImage7?.split('/').last}");
      debugPrint("==============================================");
      // ========== END DEBUG ==========

      // ========== CHECK FOR ALREADY SYNCED ==========
      final existingResponses = await ApiResponseRepository()
          .loadAllResponses();

      for (var response in existingResponses) {
        String existingPrintNo = '';
        if (response.originalData is ImageUploaddata) {
          existingPrintNo =
              (response.originalData as ImageUploaddata).PrintNo?.toString() ??
              '';
        }

        if (response.planId == metadata.ServerPlanId &&
            existingPrintNo == metadata.PrintNo &&
            response.isSuccess == true) {
          debugPrint(
            " ALREADY SYNCED: ${metadata.ServerPlanId}_${metadata.PrintNo}",
          );

          await ExecutionImageUploadHiveRepository().deleteMetadata(
            metadata.ServerPlanId!,
            metadata.PrintNo!,
          );

          return {
            'success': true,
            'message': 'Already synced',
            'data': {'printId': response.originalData.printId ?? 'N/A'},
          };
        }
      }

      final uploadType = (metadata.uploadType ?? 'execution').toLowerCase();
      final token = await getAuthToken();

      if (metadata.ServerPlanId == null ||
          metadata.PlanCode == null ||
          metadata.PrintNo == null) {
        return {
          'success': false,
          'message': 'Missing required metadata fields',
        };
      }

      if (uploadType == 'rework' && metadata.printId == null) {
        return {'success': false, 'message': 'Rework upload requires printId'};
      }

      final apiUrl = uploadType == 'rework'
          ? APIURLs.ReworkUpload
          : APIURLs.executionPost;

      Response response;

      const int maxRetry = 3;
      int attempt = 0;

      while (true) {
        attempt++;

        try {
          debugPrint("Upload Attempt: $attempt / $maxRetry");

          // Rebuild FormData every attempt: MultipartFile file streams are
          // consumed once they're sent, so retrying with the same instance
          // would upload empty files on attempts 2-4.
          final formData = await _buildExecutionFormData(metadata, uploadType);

          response = await dio.post(
            '${APIURLs.baseURL}$apiUrl',
            options: Options(
              headers: {
                'Content-Type': 'multipart/form-data',
                'Authorization': token,
              },
            ),
            data: formData,
          );

          // Success -> stop retrying
          break;
        } on DioException catch (e) {
          debugPrint("Attempt $attempt failed: ${e.message}");

          if (attempt >= maxRetry) {
            return await _handleExecutionError(e, metadata, attempt);
          }

          // Persist the retry count: the item stays in the pending Print
          // Sync list, but its attempt count is durable even if the app is
          // closed mid-sync, and is visible in the UI.
          if (metadata.ServerPlanId != null && metadata.PrintNo != null) {
            await ExecutionImageUploadHiveRepository().incrementRetryCount(
              metadata.ServerPlanId!,
              metadata.PrintNo!,
            );
          }
          metadata.retryCount = attempt;

          // Wait before retry
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      debugPrint("==============================================");
      debugPrint(" EXECUTION UPLOAD RESPONSE");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response: ${response.data}");
      debugPrint("==============================================");
      // ========== END DEBUG ==========

      return await _handleExecutionResponse(response, metadata, uploadType);
    } on DioException catch (e) {
      // ========== DEBUG: PRINT ERROR ==========
      debugPrint("==============================================");
      debugPrint(" EXECUTION UPLOAD ERROR");
      debugPrint("Status Code: ${e.response?.statusCode}");
      debugPrint("Error: ${e.message}");
      debugPrint("Response: ${e.response?.data}");
      debugPrint("==============================================");
      // ========== END DEBUG ==========
      return await _handleExecutionError(e, metadata);
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: ${e.toString()}'};
    }
  }

  Future<FormData> _buildExecutionFormData(
    ImageUploaddata metadata,
    String uploadType,
  ) async {
    final currentDate = DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(DateTime.now());
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

  Future<void> _addImageToFormData(
    FormData formData,
    String key,
    String? path,
  ) async {
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        formData.files.add(MapEntry(key, await MultipartFile.fromFile(path)));
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
    debugPrint("==============================================");
    debugPrint(" debugPrint ID FROM RESPONSE");
    debugPrint("debugPrintId: $printIdFromResponse");
    debugPrint("isSuccess: $isSuccess");
    debugPrint("message: $message");
    debugPrint("==============================================");
    // ========== END DEBUG ==========

    if (isSuccess || response.statusCode == 200) {
      if (uploadType == 'execution' && printIdFromResponse != null) {
        metadata.printId = printIdFromResponse;
      }

      await ExecutionImageUploadHiveRepository().deleteMetadata(
        metadata.ServerPlanId!,
        metadata.PrintNo!,
      );

      await _logSync(
        'Sync Data (${uploadType.toUpperCase()})',
        printIdFromResponse ?? metadata.printId ?? 'null',
      );

      return {
        'success': true,
        'message': message,
        'data': {
          'printId': printIdFromResponse ?? metadata.printId,
          'serverPlanId': dataMap?['serverPlanId']?.toString(),
          'planCode': dataMap?['planCode']?.toString(),
          'printNo': dataMap?['printNo']?.toString(),
        },
      };
    }

    return {
      'success': false,
      'message': message.isNotEmpty ? message : 'Upload failed',
    };
  }

  Future<Map<String, dynamic>> _handleExecutionError(
    DioException e,
    ImageUploaddata metadata, [
    int attemptCount = 1,
  ]) async {
    String serverMessage = _getServerMessage(e);
    String errorMessage = serverMessage.isNotEmpty
        ? serverMessage
        : _getErrorMessage(e, 'Execution Upload');

    bool isAlreadyOnServer =
        serverMessage.toLowerCase().contains('already executed') ||
        serverMessage.toLowerCase().contains('duplicate');

    bool isSuccess = isAlreadyOnServer;

    // ========== DEBUG: PRINT ERROR ==========
    debugPrint("==============================================");
    debugPrint(" HANDLE EXECUTION ERROR");
    debugPrint("serverMessage: $serverMessage");
    debugPrint("isAlreadyOnServer: $isAlreadyOnServer");
    debugPrint("errorMessage: $errorMessage");
    debugPrint("==============================================");
    // ========== END DEBUG ==========

    final apiResponseRepo = ApiResponseRepository();
    await apiResponseRepo.saveApiResponse(
      ApiResponseData(
        planId: metadata.ServerPlanId!,
        originalData: metadata,
        isSuccess: isSuccess,
        responseMessage: errorMessage,
        responseTime: DateTime.now(),
        statusCode: e.response?.statusCode ?? 0,
        retryCount: attemptCount,
      ),
    );

    await ExecutionImageUploadHiveRepository().deleteMetadata(
      metadata.ServerPlanId!,
      metadata.PrintNo!,
    );

    if (isSuccess) {
      return {
        'success': true,
        'message': 'Already on server',
        'data': {'printId': metadata.printId ?? 'N/A'},
      };
    }

    return {'success': false, 'message': errorMessage};
  }

  String _getServerMessage(DioException e) {
    if (e.response?.data is Map && e.response?.data['message'] != null) {
      return e.response!.data['message'].toString();
    }
    return '';
  }

  // ==================== RESEND METHOD (NEW) ====================

  Future<Map<String, dynamic>> resendPlanMetadata(
    ImageUploaddata metadata,
  ) async {
    try {
      // Normalize data
      metadata.PrintNo = metadata.PrintNo?.trim().toUpperCase();

      final token = await getAuthToken();
      final currentDate = DateFormat(
        'yyyy-MM-dd HH:mm:ss',
      ).format(DateTime.now());

      final formData = await _buildResendFormData(metadata, currentDate);

      // ================= DEBUG =================
      debugPrint("==================================================");
      debugPrint(" RESEND REQUEST START");
      debugPrint("==================================================");
      debugPrint("API : ${APIURLs.baseURL}${APIURLs.executionPost}");
      debugPrint("TOKEN : $token");
      debugPrint("");

      debugPrint("--------------- PAYLOAD ----------------");

      for (final field in formData.fields) {
        debugPrint("${field.key} : ${field.value}");
      }

      debugPrint("");

      debugPrint("--------------- FILES ----------------");

      for (final file in formData.files) {
        debugPrint("${file.key} : ${file.value.filename}");
      }

      debugPrint("==================================================");

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

      debugPrint("==================================================");
      debugPrint(" RESEND RESPONSE");
      debugPrint("Status Code : ${response.statusCode}");
      debugPrint("Data : ${response.data}");
      debugPrint("==================================================");

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final Map<String, dynamic> responseData = response.data;

        bool success = responseData["isSuccess"] == true;

        String message = responseData["message"]?.toString() ?? "";

        if (!success && message.toLowerCase().contains("already executed")) {
          success = true;
          message = "Already Executed (Synced Successfully)";
        }

        return {
          "success": success,
          "message": message,
          "data": responseData["data"],
        };
      }

      return {"success": false, "message": "Unexpected server response."};
    } on DioException catch (e) {
      debugPrint("==================================================");
      debugPrint(" DIO ERROR");
      debugPrint("Type : ${e.type}");
      debugPrint("Message : ${e.message}");
      debugPrint("Status Code : ${e.response?.statusCode}");
      debugPrint("Response : ${e.response?.data}");
      debugPrint("==================================================");

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
          errorMessage = "No Internet Connection.";
          break;

        case DioExceptionType.badResponse:
          errorMessage = "Server Error (${e.response?.statusCode})";
          break;

        default:
          errorMessage = e.message ?? "Unknown Network Error";
      }

      if (e.response?.data is Map<String, dynamic>) {
        final serverMessage = e.response!.data["message"]?.toString();

        if (serverMessage != null && serverMessage.isNotEmpty) {
          errorMessage = serverMessage;
        }
      }

      return {"success": false, "message": errorMessage};
    } catch (e, s) {
      debugPrint("==================================================");
      debugPrint(" UNEXPECTED ERROR");
      debugPrint(e.toString());
      debugPrint(s.toString());
      debugPrint("==================================================");

      return {"success": false, "message": e.toString()};
    }
  }

  // ==================== BATCH SYNC ====================
  Future<Map<String, dynamic>> syncAllPlanMetadata(
    List<ImageUploaddata> metadataList,
  ) async {
    List<Map<String, dynamic>> results = [];
    int successCount = 0;
    int failureCount = 0;
    List<String> errors = [];

    Set<String> processedKeys = {};

    for (var metadata in metadataList) {
      String key = "${metadata.ServerPlanId}_${metadata.PrintNo}";

      if (processedKeys.contains(key)) {
        debugPrint(" SKIPPING DUPLICATE: $key");
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
        String errorMessage =
            'Network error: Please check your internet connection.';

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

  Future<FormData> _buildResendFormData(
    ImageUploaddata metadata,
    String currentDate,
  ) async {
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

  Future<void> _logError(
    String message, [
    String? identifier,
    dynamic error,
  ]) async {
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
      additionalInfo: {'timestamp': DateTime.now().toIso8601String()},
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
      await TokenManager().logout(
        'Your session has expired. Please login again.',
      );
    }
    super.onError(err, handler);
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final isAuthEndpoint =
        options.path.contains('api/Auth/sign-in') ||
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
