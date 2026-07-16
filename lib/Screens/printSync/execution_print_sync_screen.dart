

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../APIService/auth_service.dart';
import '../../Hive_Database/execution_image_upload_db.dart';
import '../../Hive_Database/resend_db.dart';
import '../../Repository/execution_image_upload_repository.dart';
import '../../Repository/execution_resend_repository.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../utils/fonts.dart';
import '../../utils/textStyle.dart';
import '../landing/landing_screen.dart';

final pendingSyncCountProviderPlan = StateProvider<int>((ref) => 0);

// ADD: Provider to track background sync status
final backgroundSyncStatusProvider = StateProvider<bool>((ref) => false);

class SyncStatus {
  final String planId;
  final bool isSuccess;
  final String remarks;
  final DateTime timestamp;

  SyncStatus({
    required this.planId,
    required this.isSuccess,
    required this.remarks,
    required this.timestamp,
  });
}

class PrintSyncScreen extends ConsumerStatefulWidget {
  final Function(String) changeLanguage;

  const PrintSyncScreen({super.key, required this.changeLanguage});
  @override
  _PrintSyncScreenState createState() => _PrintSyncScreenState();
}

class _PrintSyncScreenState extends ConsumerState<PrintSyncScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<ImageUploaddata> loadedMetadata = [];
  List<ImageUploaddata> filteredMetadata = [];
  String _searchQuery = '';
  bool isLoading = false;
  bool isLoadingSync = false;
  bool isRefreshing = false;

  int? _previousBackgroundSyncCompleted;
  bool? _previousBackgroundSyncStatus;

  Map<String, SyncStatus> syncStatusMap = {};
  Set<String> syncingItems = <String>{};

  // Progress tracking
  Map<String, double> individualSyncProgress = {};
  double syncAllProgress = 0.0;
  int totalItemsToSync = 0;
  int completedSyncs = 0;

  @override
  void initState() {
    print(' [initState] PrintSyncScreen initialized');
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print(' [initState] Post-frame callback triggered');
      if (mounted) {
        print(' [initState] Setting background sync status and loading data');
        ref.read(backgroundSyncStatusProvider.notifier).state = isBackgroundSyncInProgress;
        loadSyncData();
      }
    });
  }


  void loadSyncData() async {
    print(' [loadSyncData] Starting data load at ${DateTime.now()}');

    if (!mounted) {
      print(' [loadSyncData] Widget not mounted, skipping load');
      return;
    }

    print(' [loadSyncData] Current mounted state: $mounted');

    setState(() {
      isRefreshing = true;
      print(' [loadSyncData] Refresh state set to true');
    });

    try {
      await Future.delayed(Duration(milliseconds: 400));
      print(' [loadSyncData] Loading metadata from Hive...');

      List<ImageUploaddata> metadata = await ExecutionImageUploadHiveRepository().loadMetadata();

      print(' [loadSyncData] Loaded ${metadata.length} items from Hive');

      if (mounted) {
        print(' [loadSyncData] Updating UI state');
        setState(() {
          loadedMetadata = metadata;
          print(' [loadSyncData] loadedMetadata set with ${metadata.length} items');

          if (_searchQuery.isEmpty) {
            filteredMetadata = metadata;
            print(' [loadSyncData] No search query, showing all ${metadata.length} items');
          } else {
            filteredMetadata = loadedMetadata.where((item) {
              final lowercaseQuery = _searchQuery.toLowerCase();
              return item.VillageCode?.toLowerCase().contains(lowercaseQuery) == true ||
                  item.PlanCode?.toLowerCase().contains(lowercaseQuery) == true ||
                  item.PrintNo?.toString().contains(lowercaseQuery) == true;
            }).toList();
            print(' [loadSyncData] Filtered to ${filteredMetadata.length} items matching "$_searchQuery"');
          }

          isRefreshing = false;
          print(' [loadSyncData] Refresh state set to false');
        });

        ref.read(pendingSyncCountProviderPlan.notifier).state = metadata.length;
        print(' [loadSyncData] Pending sync count updated to ${metadata.length}');

        print(' [loadSyncData] UI updated: ${metadata.length} total, ${filteredMetadata.length} filtered');
      } else {
        print(' [loadSyncData] Widget not mounted after data load');
      }
    } catch (e) {
      print(' [loadSyncData] Error loading sync data: $e');
      if (mounted) {
        setState(() {
          isRefreshing = false;
          loadedMetadata = [];
          filteredMetadata = [];
        });
        print(' [loadSyncData] Reset state due to error');
      }
    }
  }

  @override
  void didChangeDependencies() {
    print(' [didChangeDependencies] Dependencies changed');
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        print(' [didChangeDependencies] Post-frame callback - reloading data');
        loadSyncData();
      }
    });
  }

  void _filterData(String query) {
    print(' [_filterData] Filtering data with query: "$query"');
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        filteredMetadata = loadedMetadata;
        print(' [_filterData] Query empty, showing all ${loadedMetadata.length} items');
      } else {
        final lowercaseQuery = query.toLowerCase();
        filteredMetadata = loadedMetadata.where((metadata) {
          final matches = metadata.VillageCode?.toLowerCase().contains(lowercaseQuery) == true ||
              metadata.PlanCode?.toLowerCase().contains(lowercaseQuery) == true ||
              metadata.PrintNo?.toString().contains(lowercaseQuery) == true;
          if (matches) {
            print(' [_filterData] Match found: ${metadata.PlanCode} - ${metadata.PrintNo}');
          }
          return matches;
        }).toList();
        print(' [_filterData] Filtered to ${filteredMetadata.length} items out of ${loadedMetadata.length}');
      }
    });
  }

  void _clearSearch() {
    print(' [_clearSearch] Clearing search');
    _searchController.clear();
    _filterData('');
    print(' [_clearSearch] Search cleared');
  }

  @override
  void dispose() {
    print(' [dispose] Cleaning up resources');
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
    print(' [dispose] Resources disposed');
  }

  String _createUniqueSyncKey(String serverPlanId, String printNo) {
    final key = "${serverPlanId}_${printNo}";
    print(' [_createUniqueSyncKey] Created key: $key');
    return key;
  }

  void _updateIndividualProgress(String uniqueKey, double progress) {
    print(' [_updateIndividualProgress] Updating progress for $uniqueKey: ${(progress * 100).toInt()}%');
    setState(() {
      individualSyncProgress[uniqueKey] = progress;
    });
  }

  Future<bool> hasInternetConnection() async {
    print(' [hasInternetConnection] Checking internet connection...');
    try {
      final result = await InternetAddress.lookup('google.com');
      final hasInternet = result.isNotEmpty && result.first.rawAddress.isNotEmpty;
      print(' [hasInternetConnection] Internet available: $hasInternet');
      return hasInternet;
    } on SocketException {
      print(' [hasInternetConnection] No internet connection (SocketException)');
      return false;
    }
  }

  // ========== REPLACE THIS METHOD IN PrintSyncScreen.dart ==========

  void _syncPrint(String planId) async {
    print(' [_syncPrint] Starting sync for planId: $planId');

    final hasInternet = await hasInternetConnection();

    if (!hasInternet) {
      print(' [_syncPrint] No internet connection');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(" No internet connection. Please check your network and try again."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (isBackgroundSyncInProgress) {
      print(' [_syncPrint] Background sync in progress, cannot sync');
      Fluttertoast.showToast(
        msg: "Cannot sync: Background sync is in progress",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.orange,
      );
      return;
    }

    if (isPrintSyncInProgress || isSyncAllInProgress) {
      print(' [_syncPrint] Sync already in progress');
      Fluttertoast.showToast(
        msg: "Sync already in progress",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    isPrintSyncInProgress = true;
    ref.read(backgroundSyncStatusProvider.notifier).state = true;
    print(' [_syncPrint] Print sync started, global sync flag set');

    var metadata = loadedMetadata.firstWhere((item) => item.ServerPlanId == planId);
    print(' [_syncPrint] Found metadata: PlanCode=${metadata.PlanCode}, PrintNo=${metadata.PrintNo}');

    String uniqueKey = _createUniqueSyncKey(metadata.ServerPlanId.toString(), metadata.PrintNo.toString());

    setState(() {
      syncingItems.add(uniqueKey);
      individualSyncProgress[uniqueKey] = 0.0;
      print(' [_syncPrint] Added to syncing items: ${syncingItems.length} items now syncing');
    });

    try {
      // ==========  CHECK: Already synced? ==========
      print(' [_syncPrint] Checking if already synced...');
      final apiResponseRepo = ApiResponseRepository();
      final existingResponses = await apiResponseRepo.loadAllResponses();
      print(' [_syncPrint] Found ${existingResponses.length} existing responses');

      final alreadySynced = existingResponses.any((r) =>
      r.planId == planId &&
          r.originalData.PrintNo == metadata.PrintNo &&
          r.isSuccess == true
      );

      if (alreadySynced) {
        print(" [_syncPrint] ALREADY SYNCED: $planId - ${metadata.PrintNo}");

        // Delete from Hive
        await ExecutionImageUploadHiveRepository().deleteMetadata(
            metadata.ServerPlanId.toString(),
            metadata.PrintNo.toString()
        );
        print(' [_syncPrint] Deleted metadata from Hive');

        // Show message
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(' Already synced: ${metadata.PrintNo}'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ));

        // Reload data
        loadSyncData();

        // Remove from syncing list
        setState(() {
          syncingItems.remove(uniqueKey);
          individualSyncProgress.remove(uniqueKey);
          print('🧹 [_syncPrint] Removed from syncing items');
        });

        isPrintSyncInProgress = false;
        ref.read(backgroundSyncStatusProvider.notifier).state = false;
        print(' [_syncPrint] Sync complete (already synced)');
        return;
      }

      // ========== PROCEED WITH SYNC ==========
      print(' [_syncPrint] Proceeding with sync...');
      final apiService = Auth();

      print(' [_syncPrint] Simulating progress 0-30%');
      for (int i = 0; i <= 30; i++) {
        await Future.delayed(Duration(milliseconds: 30));
        _updateIndividualProgress(uniqueKey, i / 100.0);
      }

      if (!await hasInternetConnection()) {
        print(' [_syncPrint] Internet connection lost');
        throw Exception("No internet connection");
      }

      print(' [_syncPrint] Calling API to upload plan metadata...');
      dynamic result = await apiService.uploadPlanMetadata(metadata);
      print(' [_syncPrint] API response received: ${result.runtimeType}');

      print(' [_syncPrint] Simulating progress 31-90%');
      for (int i = 31; i <= 90; i++) {
        await Future.delayed(Duration(milliseconds: 20));
        _updateIndividualProgress(uniqueKey, i / 100.0);
      }

      bool success;
      String remarks = '';
      String? printIdFromResponse;

      if (result is Map<String, dynamic>) {
        success = result['success'] ?? false;
        remarks = result['message'] ?? result['error'] ?? 'No details';
        print(' [_syncPrint] Result parsed: success=$success, remarks=$remarks');

        if (result.containsKey('data') && result['data'] is Map<String, dynamic>) {
          printIdFromResponse = result['data']['printId']?.toString();
          print(' [_syncPrint] PrintId from response: $printIdFromResponse');
        }
      } else {
        success = false;
        remarks = 'Unexpected response format';
        print(' [_syncPrint] Unexpected response format: ${result.runtimeType}');
      }

      print(' [_syncPrint] Saving API response to database...');
      await apiResponseRepo.saveApiResponse(ApiResponseData(
        planId: planId,
        originalData: metadata,
        isSuccess: success,
        responseMessage: remarks,
        responseTime: DateTime.now(),
        statusCode: success ? 200 : 400,
      ));
      print(' [_syncPrint] API response saved');

      _updateIndividualProgress(uniqueKey, 1.0);
      await Future.delayed(Duration(milliseconds: 300));

      print(' [_syncPrint] Reloading sync data...');
      loadSyncData();

      if (success) {
        print(' [_syncPrint] Sync SUCCESSFUL for $planId');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(' Synced Print ${metadata.PrintNo} - CAN ID: ${printIdFromResponse ?? "N/A"}'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ));
      } else {
        print(' [_syncPrint] Sync FAILED for $planId: $remarks');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(' Failed to sync Print ${metadata.PrintNo}: $remarks'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ));
      }

    } catch (e) {
      print(' [_syncPrint] Print sync error: $e');

      String message = e.toString();

      if (message.contains("No internet")) {
        message = " No internet connection. Please check your network.";
        print(' [_syncPrint] Internet error detected');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );

    } finally {
      setState(() {
        syncingItems.remove(uniqueKey);
        individualSyncProgress.remove(uniqueKey);
        print(' [_syncPrint] Cleaned up syncing state');
      });
      isPrintSyncInProgress = false;
      ref.read(backgroundSyncStatusProvider.notifier).state = false;
      print(' [_syncPrint] Sync process completed');
    }
  }

  Future<void> _simulateProgress(String uniqueKey, int start, int end, Duration interval) async {
    print(' [_simulateProgress] Simulating progress for $uniqueKey: $start% to $end%');
    for (int i = start + 1; i <= end; i++) {
      await Future.delayed(interval);
      if (!syncingItems.contains(uniqueKey)) {
        print('⚠ [_simulateProgress] Item removed from syncing list, stopping progress simulation');
        break;
      }
      _updateIndividualProgress(uniqueKey, i / 100.0);
    }
    print(' [_simulateProgress] Progress simulation complete');
  }

  // Add this method and call it from initState
  void debugPrintAllResponses() async {
    print(' [debugPrintAllResponses] Debugging all responses');
    final all = await ApiResponseRepository().loadAllResponses();
    print(" ===== ALL RESPONSES IN DB ===== ");
    print("Total: ${all.length}");
    final Set<String> uniqueKeys = {};
    for (var r in all) {
      final key = "${r.planId}_${r.originalData.PrintNo}";
      print("  $key - Success: ${r.isSuccess} - Time: ${r.responseTime}");
      if (r.isSuccess) {
        uniqueKeys.add(key);
      }
    }
    print(" Unique successful prints: ${uniqueKeys.length}");
    print(" ===== END ===== ");
  }

  // ========== REPLACE THIS METHOD IN PrintSyncScreen.dart ==========

  // ========== REPLACE THIS ENTIRE METHOD ==========

  void _syncAllPrints() async {
    print(' [_syncAllPrints] Starting sync all prints');
    print(' [_syncAllPrints] Loaded metadata count: ${loadedMetadata.length}');

    if (!await hasInternetConnection()) {
      print(' [_syncAllPrints] No internet connection');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            " No internet connection. Please check your network and try again.",
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );

      return;
    }

    if (isBackgroundSyncInProgress) {
      print(' [_syncAllPrints] Background sync in progress, cannot start');
      Fluttertoast.showToast(
        msg: "Cannot sync: Background sync is in progress. Please wait...",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.orange,
      );
      return;
    }

    if (isPrintSyncInProgress || isSyncAllInProgress) {
      print(' [_syncAllPrints] Sync already in progress');
      Fluttertoast.showToast(
        msg: "Sync already in progress",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    isSyncAllInProgress = true;
    ref.read(backgroundSyncStatusProvider.notifier).state = true;
    print(' [_syncAllPrints] Sync all started, global sync flag set');

    Fluttertoast.showToast(
      msg: "Sync All Started",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );

    setState(() {
      isLoading = true;
      syncAllProgress = 0.0;
      totalItemsToSync = loadedMetadata.length;
      completedSyncs = 0;
      print(' [_syncAllPrints] State updated: isLoading=true, totalItems=$totalItemsToSync');
    });

    try {
      final apiService = Auth();
      final apiResponseRepo = ApiResponseRepository();

      // ========== FIX: Filter out already synced prints ==========
      print(' [_syncAllPrints] Checking for already synced items...');
      final existingResponses = await apiResponseRepo.loadAllResponses();
      final alreadySyncedKeys = <String>{};

      for (var response in existingResponses) {
        if (response.isSuccess) {
          String printNo = '';
          if (response.originalData is ImageUploaddata) {
            printNo = (response.originalData as ImageUploaddata).PrintNo?.toString() ?? '';
          }
          String key = "${response.planId}_$printNo";
          alreadySyncedKeys.add(key);
          print(' [_syncAllPrints] Already synced: $key');
        }
      }
      print(' [_syncAllPrints] Found ${alreadySyncedKeys.length} already synced items');

      List<ImageUploaddata> itemsToSync = [];
      for (var metadata in loadedMetadata) {
        String key = "${metadata.ServerPlanId}_${metadata.PrintNo}";
        if (alreadySyncedKeys.contains(key)) {
          print(" [_syncAllPrints] SKIPPING ALREADY SYNCED: $key");
          // Delete from Hive
          await ExecutionImageUploadHiveRepository().deleteMetadata(
              metadata.ServerPlanId.toString(),
              metadata.PrintNo.toString()
          );
          print(' [_syncAllPrints] Deleted already synced metadata: $key');
        } else {
          itemsToSync.add(metadata);
          print(' [_syncAllPrints] Item to sync: ${metadata.PlanCode} - ${metadata.PrintNo}');
        }
      }

      print(" [_syncAllPrints] Items to sync: ${itemsToSync.length} (out of ${loadedMetadata.length})");

      // If nothing to sync, show message and return
      if (itemsToSync.isEmpty) {
        print(' [_syncAllPrints] All items already synced, nothing to do');
        setState(() {
          isLoading = false;
          syncAllProgress = 0.0;
        });
        isSyncAllInProgress = false;
        ref.read(backgroundSyncStatusProvider.notifier).state = false;

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(' All prints already synced!'),
          backgroundColor: Colors.green,
        ));

        loadSyncData();
        return;
      }

      // ========== PROCEED WITH SYNC ==========
      print(' [_syncAllPrints] Progress 0-30%');
      for (int i = 0; i <= 30; i++) {
        await Future.delayed(Duration(milliseconds: 30));
        setState(() => syncAllProgress = i / 100.0);
      }

      print(' [_syncAllPrints] Calling API to sync all plans...');
      dynamic result = await apiService.syncAllPlanMetadata(itemsToSync);
      print(' [_syncAllPrints] API response received: ${result.runtimeType}');

      bool success;
      String remarks = '';

      setState(() => syncAllProgress = 0.70);
      print(' [_syncAllPrints] Progress set to 70%');

      if (result is Map<String, dynamic>) {
        success = result['success'] ?? false;
        remarks = result['message'] ?? result['error'] ?? S.of(context).noDetailsProvided;
        print(' [_syncAllPrints] Result parsed: success=$success, remarks=$remarks');

        if (result.containsKey('results') && result['results'] is List) {
          List<dynamic> results = result['results'];
          int processedCount = 0;
          int totalResults = results.length;
          print(' [_syncAllPrints] Processing ${totalResults} individual results');

          for (var planResult in results) {
            if (planResult is Map<String, dynamic> && planResult.containsKey('planId')) {
              String planId = planResult['planId'].toString();
              bool planSuccess = planResult['success'] ?? false;
              String planRemarks = planResult['message'] ?? planResult['error'] ?? 'No details';
              int statusCode = planResult['statusCode'] ?? (planSuccess ? 200 : 400);
              String? printIdFromResponse;

              if (planResult.containsKey('data') && planResult['data'] is Map<String, dynamic>) {
                printIdFromResponse = planResult['data']['printId']?.toString();
              }

              var metadata = loadedMetadata.firstWhere(
                    (item) => item.ServerPlanId == planId,
                orElse: () => loadedMetadata.first,
              );

              if (planSuccess && printIdFromResponse != null) {
                metadata.printId = printIdFromResponse;
                print(' [_syncAllPrints] Updated printId for $planId: $printIdFromResponse');
              }

              setState(() {
                syncStatusMap[planId] = SyncStatus(
                  planId: planId,
                  isSuccess: planSuccess,
                  remarks: planRemarks,
                  timestamp: DateTime.now(),
                );
              });

              await apiResponseRepo.saveApiResponse(ApiResponseData(
                planId: planId,
                originalData: metadata,
                isSuccess: planSuccess,
                responseMessage: planRemarks,
                responseTime: DateTime.now(),
                statusCode: statusCode,
              ));
              print(' [_syncAllPrints] Saved response for $planId: success=$planSuccess');

              processedCount++;
              double itemProgress = (processedCount / totalResults) * 20;
              setState(() => syncAllProgress = 0.70 + (itemProgress / 100.0));
              print(' [_syncAllPrints] Progress: ${(syncAllProgress * 100).toInt()}% ($processedCount/$totalResults)');
            }
          }
        } else {
          print(' [_syncAllPrints] No results list in response, processing as batch');
          for (var metadata in itemsToSync) {
            String planId = metadata.ServerPlanId.toString();
            setState(() {
              syncStatusMap[planId] = SyncStatus(
                planId: planId,
                isSuccess: success,
                remarks: remarks,
                timestamp: DateTime.now(),
              );
            });

            await apiResponseRepo.saveApiResponse(ApiResponseData(
              planId: planId,
              originalData: metadata,
              isSuccess: success,
              responseMessage: remarks,
              responseTime: DateTime.now(),
              statusCode: success ? 200 : 400,
            ));
          }
          setState(() => syncAllProgress = 0.90);
          print(' [_syncAllPrints] Batch processing complete, progress set to 90%');
        }
      } else {
        success = false;
        remarks = 'Unexpected response format';
        print(' [_syncAllPrints] Unexpected response format: ${result.runtimeType}');

        for (var metadata in itemsToSync) {
          String planId = metadata.ServerPlanId.toString();
          setState(() {
            syncStatusMap[planId] = SyncStatus(
              planId: planId,
              isSuccess: false,
              remarks: remarks,
              timestamp: DateTime.now(),
            );
          });

          await apiResponseRepo.saveApiResponse(ApiResponseData(
            planId: planId,
            originalData: metadata,
            isSuccess: false,
            responseMessage: remarks,
            responseTime: DateTime.now(),
            statusCode: 0,
          ));
        }
        setState(() => syncAllProgress = 0.90);
        print(' [_syncAllPrints] Error processing, progress set to 90%');
      }

      setState(() => syncAllProgress = 0.90);
      await Future.delayed(Duration(milliseconds: 100));
      setState(() => syncAllProgress = 0.95);
      print(' [_syncAllPrints] Progress set to 95%');

      print(' [_syncAllPrints] Final progress 96-100%');
      for (int i = 96; i <= 100; i++) {
        await Future.delayed(Duration(milliseconds: 20));
        setState(() => syncAllProgress = i / 100.0);
      }

      await Future.delayed(Duration(milliseconds: 200));
      print(' [_syncAllPrints] Reloading sync data...');
      loadSyncData();

      if (success) {
        print('🎉 [_syncAllPrints] Sync all SUCCESSFUL');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(S.of(context).syncAllPlan),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ));
      } else {
        print(' [_syncAllPrints] Sync all FAILED: $remarks');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${S.of(context).failedSyncAllPlan}: $remarks'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ));
      }

      Fluttertoast.showToast(
        msg: "Sync All Completed",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      print(' [_syncAllPrints] Sync all error: $e');

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ));

      Fluttertoast.showToast(
        msg: "Sync All Failed",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } finally {
      setState(() {
        isLoading = false;
        syncAllProgress = 0.0;
        print(' [_syncAllPrints] Reset loading state');
      });
      isSyncAllInProgress = false;
      ref.read(backgroundSyncStatusProvider.notifier).state = false;
      print(' [_syncAllPrints] Sync all process completed');
    }
  }

  void _showImagePopup(ImageUploaddata metadata) {
    print(' [_showImagePopup] Showing image popup for ${metadata.PlanCode}');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.5,
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  '${S.of(context).imagePrintNo}: ${metadata.PlanCode}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (metadata.CleanImage != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(File(metadata.CleanImage!), width: 150, height: 150, fit: BoxFit.cover),
                            ),
                          ),
                        if (metadata.WBImage != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(File(metadata.WBImage!), width: 150, height: 150, fit: BoxFit.cover),
                            ),
                          ),
                        if (metadata.SprayImage != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(File(metadata.SprayImage!), width: 150, height: 150, fit: BoxFit.cover),
                            ),
                          ),
                        if (metadata.NearImage != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(File(metadata.NearImage!), width: 150, height: 150, fit: BoxFit.cover),
                            ),
                          ),
                        if (metadata.FarImage != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(File(metadata.FarImage!), width: 150, height: 150, fit: BoxFit.cover),
                            ),
                          ),
                        if (metadata.NewImage6 != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(File(metadata.NewImage6!), width: 150, height: 150, fit: BoxFit.cover),
                            ),
                          ),
                        if (metadata.NewImage7 != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(File(metadata.NewImage7!), width: 150, height: 150, fit: BoxFit.cover),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    print('🔵 [_showImagePopup] Closing image popup');
                    Navigator.pop(context);
                  },
                  child: Text(S.of(context).close),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    print(' [_onWillPop] Back button pressed, navigating to LandingScreen');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LandingScreen(changeLanguage: widget.changeLanguage,)),
    );
    print(' [_onWillPop] Navigation triggered');
    return false;
  }

  Widget _buildLazyDataList() {
    print(' [_buildLazyDataList] Building data list');
    double screenWidth = MediaQuery.of(context).size.width;
    bool isTablet = screenWidth > 600;
    print(' [_buildLazyDataList] Screen width: $screenWidth, isTablet: $isTablet');

    // Watch the background sync status
    final isBackgroundSyncing = ref.watch(backgroundSyncStatusProvider);
    print(' [_buildLazyDataList] Background syncing: $isBackgroundSyncing');

    return Column(
      children: [
        Container(
          color: Font.primaryColor,
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 20 : 12,
            vertical: isTablet ? 12 : 10,
          ),
          child: Row(
            children: [
              Expanded(flex: 15, child: Text(S.of(context).village, style: TextstyleGlobal.tableHeaderTextStyle)),
              Expanded(flex: 15, child: Text(S.of(context).plan, style: TextstyleGlobal.tableHeaderTextStyle, textAlign: TextAlign.center)),
              Expanded(flex: 15, child: Text(S.of(context).printNo, style: TextstyleGlobal.tableHeaderTextStyle, textAlign: TextAlign.center)),
              Expanded(flex: 20, child: Text(S.of(context).images, style: TextstyleGlobal.tableHeaderTextStyle, textAlign: TextAlign.center)),
              Expanded(flex: 20, child: Text(S.of(context).action, style: TextstyleGlobal.tableHeaderTextStyle, textAlign: TextAlign.center)),
            ],
          ),
        ),
        Expanded(
          child: filteredMetadata.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty ? 'No data available' : 'No results found for "$_searchQuery"',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600], fontFamily: "Roboto"),
                ),
              ],
            ),
          )
              : ListView.builder(
            controller: _scrollController,
            itemCount: filteredMetadata.length,
            itemBuilder: (context, index) {
              final metadata = filteredMetadata[index];
              final planId = metadata.ServerPlanId.toString();
              final printNo = metadata.PrintNo.toString();
              final uniqueKey = _createUniqueSyncKey(planId, printNo);
              final isThisItemSyncing = syncingItems.contains(uniqueKey);
              final progress = individualSyncProgress[uniqueKey] ?? 0.0;

              return Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
                  color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 20 : 12,
                  vertical: isTablet ? 14 : 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 15,
                      child: Text(
                        metadata.VillageCode?.toString() ?? '',
                        style: TextstyleGlobal.bodyTextStyleSeeplan,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 15,
                      child: Text(
                        metadata.PlanCode?.toString() ?? '',
                        style: TextstyleGlobal.bodyTextStyleSeeplan,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 15,
                      child: Text(
                        metadata.PrintNo?.toString() ?? '',
                        style: TextstyleGlobal.bodyTextStyleSeeplan,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 20,
                      child: Center(
                        child: GestureDetector(
                          onTap: () => _showImagePopup(metadata),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Font.primaryLightColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              S.of(context).view,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                                fontFamily: "Roboto",
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 20,
                      child: Center(
                        child: GestureDetector(
                          onTap: (isThisItemSyncing || isBackgroundSyncing) ? null : () => _syncPrint(planId),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                            decoration: BoxDecoration(
                              color: (isThisItemSyncing || isBackgroundSyncing) ? Colors.grey : Font.accentColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isThisItemSyncing) ...[
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      value: progress,
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      backgroundColor: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    '${(progress * 100).toInt()}%',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                      fontFamily: "Roboto",
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    S.of(context).sync,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                      fontFamily: "Roboto",
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    print(' [build] Building PrintSyncScreen UI');
    final theme = Theme.of(context);
    // Watch the background sync status
    final isBackgroundSyncing = ref.watch(backgroundSyncStatusProvider);
    final backgroundSyncCount = ref.watch(backgroundSyncCompletedProvider);
    final backgroundSyncCompleted = ref.watch(backgroundSyncCompletedProvider);

    print(' [build] Background syncing: $isBackgroundSyncing, Completed: $backgroundSyncCompleted');
    print(' [build] Data count: ${filteredMetadata.length} filtered out of ${loadedMetadata.length} total');

    // MOVED: Listen to provider changes inside build method
    // Detect changes in background sync completion
    if (_previousBackgroundSyncCompleted != null &&
        _previousBackgroundSyncCompleted != backgroundSyncCompleted) {
      print(' [build] Background sync completed: $_previousBackgroundSyncCompleted -> $backgroundSyncCompleted');

      Future.delayed(Duration(milliseconds: 800), () {
        if (mounted) {
          print(' [build] Reloading data after background sync...');
          loadSyncData();
        }
      });
    }
    _previousBackgroundSyncCompleted = backgroundSyncCompleted;

    // Detect changes in background sync status
    if (_previousBackgroundSyncStatus != null &&
        _previousBackgroundSyncStatus == true &&
        isBackgroundSyncing == false) {
      print(' [build] Background sync status: true -> false');

      Future.delayed(Duration(milliseconds: 1000), () {
        if (mounted) {
          print(' [build] Reloading after status change...');
          loadSyncData();
        }
      });
    }
    _previousBackgroundSyncStatus = isBackgroundSyncing;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Font.primaryColor,
            title: Row(
              children: [
                Text(
                  S.of(context).printSync,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    letterSpacing: 1,
                    fontFamily: "Roboto",
                  ),
                ),
                if (isBackgroundSyncing) ...[
                  SizedBox(width: 8),
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ],
              ],
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
              onPressed: () {
                print(' [AppBar] Back button pressed');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LandingScreen(changeLanguage: widget.changeLanguage,)),
                );
              },
            ),
            actions: [
              IconButton(
                icon: Icon(
                    isRefreshing ? Icons.refresh : Icons.refresh_outlined,
                    color: Colors.white
                ),
                onPressed: isRefreshing ? null : () {
                  print(' [AppBar] Manual refresh triggered');
                  loadSyncData();
                },
                tooltip: 'Refresh',
              ),
              IconButton(
                icon: Icon(Icons.home, color: Colors.white),
                onPressed: () {
                  print(' [AppBar] Home button pressed');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LandingScreen(changeLanguage: widget.changeLanguage)),
                  );
                },
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Font.pureWhiteColor, Font.pureWhiteColor, Font.pureWhiteColor],
              ),
            ),
            child: Column(
              children: [

                if (isBackgroundSyncing)
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    color: Colors.orange[100],
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Background sync in progress...',
                            style: TextStyle(
                              color: Colors.orange[900],
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              fontFamily: "Roboto",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 45,
                          child: TextField(
                            controller: _searchController,
                            onChanged: _filterData,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.search_sharp, color: Font.primaryLightColor),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                icon: Icon(Icons.clear, color: Font.primaryLightColor),
                                onPressed: _clearSearch,
                              )
                                  : null,
                              hintText: S.of(context).search,
                              hintStyle: TextStyle(fontSize: 12, color: Colors.grey[600], fontFamily: "Roboto"),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Font.primaryLightColor, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                              ),
                            ),
                            style: TextStyle(fontSize: 14, fontFamily: "Roboto"),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      // UPDATED: Only show Sync All button when background sync is NOT running
                      if (!isBackgroundSyncing)
                        GestureDetector(
                          onTap: isLoading ? null : _syncAllPrints,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: isLoading ? Colors.grey : Font.accentColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isLoading) ...[
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      value: syncAllProgress,
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      backgroundColor: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '${(syncAllProgress * 100).toInt()}%',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      fontFamily: "Roboto",
                                    ),
                                  ),
                                ] else ...[
                                  Icon(Icons.sync, color: Colors.white, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    S.of(context).syncAll,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      fontFamily: "Roboto",
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      if (isBackgroundSyncing)
                        Tooltip(
                          message: "Background sync in progress",
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.sync, color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  "Syncing...",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    fontFamily: "Roboto",
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                if (_searchQuery.isNotEmpty && filteredMetadata.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          'Showing ${filteredMetadata.length} of ${loadedMetadata.length} results',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: "Roboto",
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                Expanded(child: _buildLazyDataList()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}