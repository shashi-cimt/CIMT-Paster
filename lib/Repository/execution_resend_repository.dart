import 'dart:math';

import 'package:hive/hive.dart';
import '../Hive_Database/execution_image_upload_db.dart';
import '../Hive_Database/resend_db.dart';

class ApiResponseRepository {
  Box<ApiResponseData>? _responseBox;

  Future<void> _openBox() async {
    if (_responseBox == null || !_responseBox!.isOpen) {
      _responseBox = await Hive.openBox<ApiResponseData>('ApiResponseData');
    }
  }
  static int _counter = 0; // Add a counter
  // Generate unique key for each API response
  String _generateUniqueKey(String planId) {
    _counter++;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999); // Extra uniqueness
    return "${planId}_${timestamp}_${_counter}_${random}";
  }




  Future<void> saveApiResponse(ApiResponseData responseData) async {
    await _openBox();

    String printNo = "";

    if (responseData.originalData is ImageUploaddata) {
      printNo =
          (responseData.originalData as ImageUploaddata).PrintNo?.trim() ?? "";
    }

    final uniqueUploadKey = "${responseData.planId}_$printNo";

    // Find only the latest response for THIS upload
    String? existingHiveKey;

    for (final entry in _responseBox!.toMap().entries) {
      final value = entry.value;

      String existingPrint = "";

      if (value.originalData is ImageUploaddata) {
        existingPrint =
            (value.originalData as ImageUploaddata).PrintNo?.trim() ?? "";
      }

      if ("${value.planId}_$existingPrint" == uniqueUploadKey) {
        existingHiveKey = entry.key.toString();
        break;
      }
    }

    // If latest is SUCCESS don't overwrite with "Already Executed"
    if (existingHiveKey != null) {
      final existing = _responseBox!.get(existingHiveKey);

      if (existing != null &&
          existing.isSuccess &&
          !responseData.isSuccess) {
        return;
      }
    }

    // Always save every SUCCESS
    final hiveKey = _generateUniqueKey(responseData.planId);

    await _responseBox!.put(hiveKey, responseData);
  }

  Future<List<ApiResponseData>> loadAllResponses() async {
    await _openBox();
    return _responseBox!.values.toList();
  }

  // NEW METHOD: Get unique responses (one per plan ID, showing the latest)
  // Future<List<ApiResponseData>> loadUniqueResponses() async {
  //
  //   await _openBox();
  //   final allResponses = _responseBox!.values.toList();
  //
  //   // Group by BOTH planId AND printNo
  //   final Map<String, ApiResponseData> latestResponsesMap = {};
  //
  //   for (final response in allResponses) {
  //     final planId = response.planId;
  //
  //     // Extract printNo from originalData
  //     final printNo = response.originalData is ImageUploaddata
  //         ? (response.originalData as ImageUploaddata).PrintNo?.toString() ?? ''
  //         : '';
  //
  //     // Create composite key: planId + printNo
  //     final compositeKey = "${planId}_${printNo}";
  //
  //     // Keep latest for each planId + printNo combination
  //     if (!latestResponsesMap.containsKey(compositeKey) ||
  //         response.responseTime.isAfter(latestResponsesMap[compositeKey]!.responseTime)) {
  //       latestResponsesMap[compositeKey] = response;
  //     }
  //   }
  //
  //   // Convert back to list and sort by responseTime (newest first)
  //   final uniqueResponses = latestResponsesMap.values.toList();
  //   uniqueResponses.sort((a, b) => b.responseTime.compareTo(a.responseTime));
  //
  //   return uniqueResponses;
  // }

  // Get responses for a specific plan ID
  // ====== REPLACE THIS ENTIRE METHOD IN ApiResponseRepository.dart ======

  Future<List<ApiResponseData>> loadUniqueResponses() async {
    await _openBox();

    final Map<String, ApiResponseData> latest = {};

    for (final response in _responseBox!.values) {

      String printNo = "";

      if (response.originalData is ImageUploaddata) {
        printNo =
            (response.originalData as ImageUploaddata).PrintNo?.trim() ?? "";
      }

      final key = "${response.planId}_$printNo";

      if (!latest.containsKey(key)) {

        latest[key] = response;

      } else {

        final old = latest[key]!;

        // Success always wins
        if (!old.isSuccess && response.isSuccess) {

          latest[key] = response;

        } else if (old.isSuccess == response.isSuccess &&
            response.responseTime.isAfter(old.responseTime)) {

          latest[key] = response;

        }
      }
    }

    return latest.values.toList()
      ..sort((a, b) => b.responseTime.compareTo(a.responseTime));
  }

  Future<List<ApiResponseData>> getResponsesForPlan(String planId) async {
    await _openBox();
    return _responseBox!.values
        .where((response) => response.planId == planId)
        .toList()
      ..sort((a, b) => b.responseTime.compareTo(a.responseTime)); // Latest first
  }

  // Get latest response for a specific plan
  Future<ApiResponseData?> getLatestResponseForPlan(String planId) async {
    await _openBox();
    final responses = await getResponsesForPlan(planId);
    return responses.isNotEmpty ? responses.first : null;
  }

  // Remove specific response by unique key
  Future<void> removeResponse(String uniqueKey) async {
    await _openBox();
    await _responseBox!.delete(uniqueKey);
  }

  // Remove all responses for a specific plan
  Future<void> removeAllResponsesForPlan(String planId) async {
    await _openBox();
    final keysToDelete = _responseBox!.keys
        .where((key) => _responseBox!.get(key)?.planId == planId)
        .toList();

    for (String key in keysToDelete) {
      await _responseBox!.delete(key);
    }
  }

  // Clear all responses
  Future<void> clearAllResponses() async {
    await _openBox();
    await _responseBox!.clear();
  }

  // NEW METHOD: Get failed responses only (unique per plan)
  // ====== REPLACE THIS METHOD IN ApiResponseRepository.dart ======

  Future<List<ApiResponseData>> getUniqueFailedResponses() async {
    await _openBox();
    final uniqueResponses = await loadUniqueResponses();
    return uniqueResponses
        .where((response) => !response.isSuccess)
        .toList();
  }

  // NEW METHOD: Get successful responses only (unique per plan)
  Future<List<ApiResponseData>> getUniqueSuccessfulResponses() async {
    await _openBox();
    final uniqueResponses = await loadUniqueResponses();
    return uniqueResponses
        .where((response) => response.isSuccess)
        .toList();
  }

  // Get failed responses only (all historical)
  Future<List<ApiResponseData>> getFailedResponses() async {
    await _openBox();
    return _responseBox!.values
        .where((response) => !response.isSuccess)
        .toList()
      ..sort((a, b) => b.responseTime.compareTo(a.responseTime));
  }

  // Get successful responses only (all historical)
  Future<List<ApiResponseData>> getSuccessfulResponses() async {
    await _openBox();
    return _responseBox!.values
        .where((response) => response.isSuccess)
        .toList()
      ..sort((a, b) => b.responseTime.compareTo(a.responseTime));
  }

  // Get response statistics
  Future<Map<String, int>> getResponseStats() async {
    await _openBox();
    final allResponses = _responseBox!.values.toList();

    return {
      'total': allResponses.length,
      'successful': allResponses.where((r) => r.isSuccess).length,
      'failed': allResponses.where((r) => !r.isSuccess).length,
    };
  }

  // NEW METHOD: Get unique response statistics
  Future<Map<String, int>> getUniqueResponseStats() async {
    final uniqueResponses = await loadUniqueResponses();

    return {
      'total': uniqueResponses.length,
      'successful': uniqueResponses.where((r) => r.isSuccess).length,
      'failed': uniqueResponses.where((r) => !r.isSuccess).length,
    };
  }

  // Update response status (for resend functionality)
  Future<void> updateResponseStatus(String planId, bool isSuccess, String message, int statusCode) async {
    await _openBox();
    // Find the latest response for this planId and update it
    final latestResponse = await getLatestResponseForPlan(planId);
    if (latestResponse != null) {
      // Create a new response record instead of updating the old one
      // This maintains the history of all attempts
      await saveApiResponse(ApiResponseData(
        planId: planId,
        originalData: latestResponse.originalData,
        isSuccess: isSuccess,
        responseMessage: message,
        responseTime: DateTime.now(),
        statusCode: statusCode,
        retryCount: latestResponse.retryCount + 1,
      ));
    }
  }

  // Update retry count
  Future<void> updateRetryCount(String planId) async {
    await _openBox();
    final latestResponse = await getLatestResponseForPlan(planId);
    if (latestResponse != null) {
      // This is already handled in updateResponseStatus method above
      // No additional action needed here
    }
  }
}