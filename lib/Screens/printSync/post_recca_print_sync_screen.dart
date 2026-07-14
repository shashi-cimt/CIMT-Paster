  import 'dart:io';
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import '../../APIService/auth_service.dart';
  import '../../Hive_Database/post_recca_image_upload_db.dart';
  import '../../Repository/post_recca_image_upload_repository.dart';
  import '../../generated/l10n.dart';
  import '../../main.dart';
  import '../../utils/fonts.dart';
import '../../utils/textStyle.dart';
import '../landing/landing_screen.dart';

  final pendingSyncCountProvider = StateProvider<int>((ref) => 0);
  
  class SUSyncStatus {
    final String planId;
    final bool isSuccess;
    final String remarks;
    final DateTime timestamp;
  
    SUSyncStatus({
      required this.planId,
      required this.isSuccess,
      required this.remarks,
      required this.timestamp,
    });
  }
  
  class SUPrintSyncScreen extends ConsumerStatefulWidget {
    final Function(String) changeLanguage;
  
    const SUPrintSyncScreen({super.key, required this.changeLanguage});
    @override
    _SUPrintSyncScreenState createState() => _SUPrintSyncScreenState();
  }
  
  class _SUPrintSyncScreenState extends ConsumerState<SUPrintSyncScreen> {
    final ScrollController _scrollController = ScrollController();
    final TextEditingController _searchController = TextEditingController();
  
    List<SUImageUploaddata> loadedMetadata = [];
    List<SUImageUploaddata> filteredMetadata = [];
    String _searchQuery = '';
    bool isLoading = false;
    bool isLoadingSync = false;
    bool isRefreshing = false;
    Set<String> syncingItems = <String>{};
  
    Map<String, SUSyncStatus> syncStatusMap = {};
  
    @override
    void initState() {
      super.initState();
      loadSyncData();
    }
  
    void loadSyncData() async {
      List<SUImageUploaddata> metadata = await PostReccaImageUploadHiveRepository().loadSUMetadata();
      setState(() {
        loadedMetadata = metadata;
        filteredMetadata = metadata;
      });
    }
  
    void _filterData(String query) {
      setState(() {
        _searchQuery = query;
        if (query.isEmpty) {
          filteredMetadata = loadedMetadata;
        } else {
          final lowercaseQuery = query.toLowerCase();
          filteredMetadata = loadedMetadata.where((metadata) {
            return metadata.villageCode.toLowerCase().contains(lowercaseQuery) ||
                metadata.planCode.toLowerCase().contains(lowercaseQuery) ||
                metadata.printId.toLowerCase().contains(lowercaseQuery);
          }).toList();
        }
      });
    }
  
    void _clearSearch() {
      _searchController.clear();
      _filterData('');
    }
  
    @override
    void dispose() {
      _scrollController.dispose();
      _searchController.dispose();
      super.dispose();
    }
  

    void _syncPrint(String planId) async {
      setState(() {
        syncingItems.add(planId);
      });

      try {
        final apiService = Auth();
        var metadata = loadedMetadata.firstWhere((item) => item.printId == planId);

        dynamic result = await apiService.uploadMetadata(metadata);
        bool success;
        String remarks = '';

        if (result is bool) {
          success = result;
          remarks = success ? S.of(context).successfullySynced : '${S.of(context).failedToSync} - ${S.of(context).unKnownError}';
        } else if (result is Map<String, dynamic>) {
          success = result['success'] ?? false;
          remarks = result['message'] ?? result['error'] ?? S.of(context).noDetailsProvided;
        } else {
          success = false;
          remarks = 'Unexpected response format';
        }

        setState(() {
          syncStatusMap[planId] = SUSyncStatus(
            planId: planId,
            isSuccess: success,
            remarks: remarks,
            timestamp: DateTime.now(),
          );
        });

        loadSyncData();

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${S.of(context).syncPlan} $planId!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${S.of(context).failedSyncPlan} $planId: $remarks'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ));
        }
      } catch (e) {
        String errorMessage = e.toString();

        // Check if it's a duplicate error
        bool isDuplicateError = errorMessage.contains('DUPLICATE_IMAGE_ERROR');

        setState(() {
          syncStatusMap[planId] = SUSyncStatus(
            planId: planId,
            isSuccess: isDuplicateError, // Treat duplicate as "success" since data is on server
            remarks: isDuplicateError
                ? S.of(context).alreadyUploadedServer
                : errorMessage,
            timestamp: DateTime.now(),
          );
        });

        // Refresh the list to show updated data (duplicate entry removed)
        loadSyncData();

        if (isDuplicateError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${S.of(context).print} $planId ${S.of(context).alreadyOnServer}'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $errorMessage'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ));
        }
      } finally {
        setState(() {
          syncingItems.remove(planId);
        });
      }
    }

    // void _syncAllPrints() async {
    //   setState(() {
    //     isLoading = true;
    //     isManualSyncing = true;
    //   });
    //
    //   try {
    //     final apiService = Auth();
    //     dynamic result = await apiService.syncAllMetadata(loadedMetadata);
    //     bool success;
    //     String remarks = '';
    //
    //     if (result is bool) {
    //       success = result;
    //       remarks = success ? 'All plans synced successfully' : 'Failed to sync all plans - Unknown error';
    //     } else if (result is Map<String, dynamic>) {
    //       success = result['success'] ?? false;
    //       remarks = result['message'] ?? result['error'] ?? 'No details provided';
    //
    //       if (result.containsKey('results') && result['results'] is List) {
    //         List<dynamic> results = result['results'];
    //         for (var planResult in results) {
    //           if (planResult is Map<String, dynamic> && planResult.containsKey('planId')) {
    //             String planId = planResult['planId'].toString();
    //             bool planSuccess = planResult['success'] ?? false;
    //             String planRemarks = planResult['message'] ?? planResult['error'] ?? 'No details';
    //
    //             setState(() {
    //               syncStatusMap[planId] = SUSyncStatus(
    //                 planId: planId,
    //                 isSuccess: planSuccess,
    //                 remarks: planRemarks,
    //                 timestamp: DateTime.now(),
    //               );
    //             });
    //           }
    //         }
    //       } else {
    //         for (var metadata in loadedMetadata) {
    //           String planId = metadata.printId.toString();
    //           setState(() {
    //             syncStatusMap[planId] = SUSyncStatus(
    //               planId: planId,
    //               isSuccess: success,
    //               remarks: remarks,
    //               timestamp: DateTime.now(),
    //             );
    //           });
    //         }
    //       }
    //     } else {
    //       success = false;
    //       remarks = 'Unexpected response format';
    //     }
    //
    //     loadSyncData();
    //
    //     if (success) {
    //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    //         content: Text(S.of(context).syncAllPlan),
    //         backgroundColor: Colors.green,
    //         duration: Duration(seconds: 2),
    //       ));
    //     } else {
    //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    //         content: Text('${S.of(context).failedSyncAllPlan}: $remarks'),
    //         backgroundColor: Colors.red,
    //         duration: Duration(seconds: 3),
    //       ));
    //     }
    //   } catch (e) {
    //     for (var metadata in loadedMetadata) {
    //       String planId = metadata.printId.toString();
    //       setState(() {
    //         syncStatusMap[planId] = SUSyncStatus(
    //           planId: planId,
    //           isSuccess: false,
    //           remarks: 'Exception: ${e.toString()}',
    //           timestamp: DateTime.now(),
    //         );
    //       });
    //     }
    //
    //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    //       content: Text('Error: $e'),
    //       backgroundColor: Colors.red,
    //       duration: Duration(seconds: 3),
    //     ));
    //   } finally {
    //     setState(() {
    //       isLoading = false;
    //       isManualSyncing = false;
    //     });
    //   }
    // }
    void _syncAllPrints() async {
      setState(() {
        isLoading = true;
        isManualSyncing = true;
      });

      try {
        final apiService = Auth();
        dynamic result = await apiService.syncAllMetadata(loadedMetadata);
        bool success;
        String remarks = '';

        if (result is bool) {
          success = result;
          remarks = success ? S.of(context).allPlansSyncedSuccessfully : '${S.of(context).failedSyncAllPlan} - ${S.of(context).unKnownError}';
        } else if (result is Map<String, dynamic>) {
          success = result['success'] ?? false;
          remarks = result['message'] ?? result['error'] ?? S.of(context).noDetailsProvided;

          if (result.containsKey('results') && result['results'] is List) {
            List<dynamic> results = result['results'];
            for (var planResult in results) {
              if (planResult is Map<String, dynamic> && planResult.containsKey('planId')) {
                String planId = planResult['planId'].toString();
                bool planSuccess = planResult['success'] ?? false;
                String planRemarks = planResult['message'] ?? planResult['error'] ?? 'No details';

                setState(() {
                  syncStatusMap[planId] = SUSyncStatus(
                    planId: planId,
                    isSuccess: planSuccess,
                    remarks: planRemarks,
                    timestamp: DateTime.now(),
                  );
                });
              }
            }
          } else {
            for (var metadata in loadedMetadata) {
              String planId = metadata.printId.toString();
              setState(() {
                syncStatusMap[planId] = SUSyncStatus(
                  planId: planId,
                  isSuccess: success,
                  remarks: remarks,
                  timestamp: DateTime.now(),
                );
              });
            }
          }
        } else {
          success = false;
          remarks = 'Unexpected response format';
        }

        loadSyncData();

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(S.of(context).syncAllPlan),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${S.of(context).failedSyncAllPlan}: $remarks'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ));
        }
      } catch (e) {
        int duplicateCount = 0;
        int errorCount = 0;

        for (var metadata in loadedMetadata) {
          String planId = metadata.printId.toString();
          String errorMessage = e.toString();

          // Check if it's a duplicate error
          bool isDuplicateError = errorMessage.contains('DUPLICATE_IMAGE_ERROR');

          if (isDuplicateError) {
            duplicateCount++;
          } else {
            errorCount++;
          }

          setState(() {
            syncStatusMap[planId] = SUSyncStatus(
              planId: planId,
              isSuccess: isDuplicateError, // Treat duplicate as "success" since data is on server
              remarks: isDuplicateError
                  ? S.of(context).alreadyUploadedServer
                  : errorMessage,
              timestamp: DateTime.now(),
            );
          });
        }

        // Refresh the list to show updated data (duplicate entries removed)
        loadSyncData();

        // Show appropriate message based on error types
        if (duplicateCount > 0 && errorCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$duplicateCount ${S.of(context).printsAlreadyOnServer}'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ));
        } else if (duplicateCount > 0 && errorCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$duplicateCount ${S.of(context).duplicatesRemoved}. $errorCount ${S.of(context).errorsOccurred}.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ));
        }
      } finally {
        setState(() {
          isLoading = false;
          isManualSyncing = false;
        });
      }
    }
    void _showImagePopup(SUImageUploaddata metadata) {
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
                    '${S.of(context).imagePrintNo}: ${metadata.printId}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(metadata.nearImagePath.toString()),
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(metadata.farImagePath.toString()),
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
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
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LandingScreen(changeLanguage: widget.changeLanguage,)),
      );
      return false;
    }
  
    Widget _buildLazyDataList() {
      double screenWidth = MediaQuery.of(context).size.width;
      bool isTablet = screenWidth > 600;
  
      return Column(
        children: [
          // Table Header
          Container(
            color: Font.primaryColor,
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 16 : 10,
              vertical: isTablet ? 12 : 10,
            ),
            child: Row(
              children: [
                Expanded(flex: 12, child: Text(S.of(context).village, style: TextstyleGlobal.tableHeaderTextStyle, textAlign: TextAlign.center)),
                Expanded(flex: 12, child: Text(S.of(context).plan, style: TextstyleGlobal.tableHeaderTextStyle, textAlign: TextAlign.center)),
                Expanded(flex: 12, child: Text(S.of(context).printID, style: TextstyleGlobal.tableHeaderTextStyle, textAlign: TextAlign.center)),
                Expanded(flex: 15, child: Text(S.of(context).images, style: TextstyleGlobal.tableHeaderTextStyle, textAlign: TextAlign.center)),
                Expanded(flex: 15, child: Text(S.of(context).action, style: TextstyleGlobal.tableHeaderTextStyle, textAlign: TextAlign.center))
              ],
            ),
          ),
  
          // Lazy Loading List
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
                final planId = metadata.printId.toString();
                final isThisItemSyncing = syncingItems.contains(planId);
                final syncStatus = syncStatusMap[planId];
  
                return Container(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
                    color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 16 : 10,
                    vertical: isTablet ? 12 : 10,
                  ),
                  child: Row(
                    children: [
                      // Village Code
                      Expanded(
                        flex: 12,
                        child: Text(
                          metadata.villageCode,
                          style: TextstyleGlobal.bodyTextStyleSeeplan,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Plan Code
                      Expanded(
                        flex: 12,
                        child: Text(
                          metadata.planCode,
                          style: TextstyleGlobal.bodyTextStyleSeeplan,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Print ID
                      Expanded(
                        flex: 12,
                        child: Text(
                          metadata.printId,
                          style: TextstyleGlobal.bodyTextStyleSeeplan,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Images Button
                      Expanded(
                        flex: 15,
                        child: Center(
                          child: GestureDetector(
                            onTap: () => _showImagePopup(metadata),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
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
                      // Action Button
                      Expanded(
                        flex: 15,
                        child: Center(
                          child: GestureDetector(
                            onTap: isThisItemSyncing ? null : () => _syncPrint(planId),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                              decoration: BoxDecoration(
                                color: isThisItemSyncing ? Colors.grey : Font.accentColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isThisItemSyncing) ...[
                                    SizedBox(
                                      width: 8,
                                      height: 8,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                  ],
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
      final theme = Theme.of(context);
  
      return WillPopScope(
        onWillPop: _onWillPop,
        child: SafeArea(
          child: Scaffold(
            backgroundColor: theme.colorScheme.surface,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Font.primaryColor,
              title: Text(
                S.of(context).printSync,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  letterSpacing: 1,
                  fontFamily: "Roboto",
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LandingScreen(changeLanguage: widget.changeLanguage,)),
                  );
                },
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.home, color: Colors.white),
                  onPressed: () {
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
                  // Search and Sync All
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
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                ],
                                Text(
                                  isLoading ? S.of(context).uploading : S.of(context).syncAll,
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
  
                  // Search Results Count
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
  
                  // Data List
                  Expanded(child: _buildLazyDataList()),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }