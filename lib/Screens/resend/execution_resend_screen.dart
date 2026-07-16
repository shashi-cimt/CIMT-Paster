import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:archive/archive.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:crypto/crypto.dart';
import '../../APIService/auth_service.dart';
import '../../Hive_Database/execution_image_upload_db.dart';
import '../../Hive_Database/resend_db.dart';
import '../../Repository/execution_resend_repository.dart';
import '../../generated/l10n.dart';
import '../../utils/fonts.dart';
import '../../utils/shared_preference.dart';
import '../../utils/textStyle.dart';
import '../landing/landing_screen.dart';

class ResendScreen extends ConsumerStatefulWidget {
  final Function(String) changeLanguage;

  const ResendScreen({super.key, required this.changeLanguage});

  @override
  _ResendScreenState createState() => _ResendScreenState();
}

class _ResendScreenState extends ConsumerState<ResendScreen> with SingleTickerProviderStateMixin {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String? uidDetails;
  List<ApiResponseData> responseData = [];
  List<ApiResponseData> filteredResponseData = [];
  Set<String> resendingItems = <String>{};
  final ApiResponseRepository _apiResponseRepo = ApiResponseRepository();

  late TabController _tabController;

  // Add encryption variables
  bool _isCreatingZip = false;
  final String encryptionPassword = "CIMTDWP_Secure_2024";

  @override
  void initState() {
    print(' [initState] ResendScreen initialized');
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      print(' [TabController Listener] Tab index changed to: ${_tabController.index}');
      if (!_tabController.indexIsChanging) {
        loadResponseData();
        _searchController.clear();
        print(' [TabController Listener] Search cleared and data reloaded');
      }
    });

    _searchController.addListener(_filterData);
    loadResponseData();
    userDetails();
    print(' [initState] Setup complete');
  }

  void userDetails() async{
    print(' [userDetails] Fetching user UID...');
    try {
      uidDetails = await getFirstUID();
      print(' [userDetails] UID fetched: $uidDetails');
    } catch (e) {
      print(' [userDetails] Error fetching UID: $e');
    }
  }

  // UPDATED: More robust data loading with proper status filtering
  void loadResponseData() async {
    print(' [loadResponseData] Loading response data... Tab index: ${_tabController.index}');
    try {
      List<ApiResponseData> responses;

      if (_tabController.index == 0) {
        // Failed tab - get ONLY items where the LATEST response is failed
        print(' [loadResponseData] Loading FAILED responses');
        responses = await _apiResponseRepo.getUniqueFailedResponses();
        print(' [loadResponseData] Failed responses fetched: ${responses.length}');
        // Double check: filter out any items that have succeeded in their latest attempt
        responses = responses.where((item) => !item.isSuccess).toList();
        print(' [loadResponseData] After success filter: ${responses.length}');
      } else {
        // Success tab - get ONLY items where the LATEST response is successful
        print(' [loadResponseData] Loading SUCCESS responses');
        responses = await _apiResponseRepo.loadUniqueResponses();
        print(' [loadResponseData] Success responses fetched: ${responses.length}');
        // Filter to only show successful items
        responses = responses.where((item) => item.isSuccess).toList();
        print(' [loadResponseData] After success filter: ${responses.length}');
      }

      setState(() {
        responseData = responses;
        filteredResponseData = responses;
        print(' [loadResponseData] Data loaded successfully. Total: ${responseData.length}');
      });
    } catch (e) {
      print(' [loadResponseData] Error loading data: $e');
    }
  }

  void _filterData() {
    print(' [_filterData] Filtering data... Search query: "${_searchController.text}"');
    final query = _searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      print(' [_filterData] Query empty, showing all data');
      setState(() {
        filteredResponseData = responseData;
      });
      print(' [_filterData] Filtered data count: ${filteredResponseData.length}');
      return;
    }

    setState(() {
      filteredResponseData = responseData.where((item) {
        final villageCode = item.originalData.VillageCode?.toLowerCase() ?? '';
        final planCode = item.originalData.PlanCode?.toLowerCase() ?? '';
        final printNo = item.originalData.PrintNo?.toLowerCase() ?? '';
        final address = item.originalData.Address?.toLowerCase() ?? '';
        final planId = item.planId.toLowerCase();
        final status = item.isSuccess ? 'success' : 'failed';

        final matches = villageCode.contains(query) ||
            planCode.contains(query) ||
            printNo.contains(query) ||
            address.contains(query) ||
            planId.contains(query) ||
            status.contains(query);

        if (matches) {
          print(' [_filterData] Match found: ${item.originalData.PrintNo} - $status');
        }
        return matches;
      }).toList();
      print(' [_filterData] Filtered data count: ${filteredResponseData.length} out of ${responseData.length}');
    });
  }

  void _clearSearch() {
    print(' [_clearSearch] Clearing search');
    _searchController.clear();
    setState(() {
      filteredResponseData = responseData;
    });
    print(' [_clearSearch] Search cleared, data restored: ${filteredResponseData.length} items');
  }

  @override
  void dispose() {
    print(' [dispose] Cleaning up resources');
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
    print(' [dispose] Resources disposed');
  }

  // UPDATED: Improved resend logic with better status handling
  void _resendItem(String planId) async {
    print(' [_resendItem] Starting resend for planId: $planId');
    setState(() {
      resendingItems.add(planId);
      print(' [_resendItem] Added to resending items. Current set: ${resendingItems.length}');
    });

    try {
      final responseItem = responseData.firstWhere((item) => item.planId == planId);
      print(' [_resendItem] Found response item: ${responseItem.originalData.PlanCode}');

      final apiService = Auth();
      print(' [_resendItem] Calling API to resend plan metadata...');

      //  Use the new resend method
      Map<String, dynamic> result = await apiService.resendPlanMetadata(responseItem.originalData);
      if (result['success'] == true &&
          result['data'] != null &&
          result['data'] is Map<String, dynamic>) {

        final serverData = result['data'] as Map<String, dynamic>;

        responseItem.originalData.printId =
            serverData['printId']?.toString();

        print(" Updated CAN ID : ${responseItem.originalData.printId}");
      }
      print(' [_resendItem] API Response: success=${result['success']}, message=${result['message']}');

      bool isSuccess = result['success'] ?? false;
      String remarks = result['message'] ?? (isSuccess
          ? S.of(context).successfullyResentData
          : S.of(context).resendFailed);
      int statusCode = isSuccess ? 200 : 400;

      print(' [_resendItem] Updating response status in database...');
      await _apiResponseRepo.updateResponseStatus(planId, isSuccess, remarks, statusCode);
      loadResponseData();
      print(' [_resendItem] Response status updated');

      if (isSuccess) {
        print('🎉 [_resendItem] Resend SUCCESSFUL for planId: $planId');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${S.of(context).successfullyResentPlan} $planId!\n✅ Moved to Success tab'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ));
      } else {
        print(' [_resendItem] Resend FAILED for planId: $planId - $remarks');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${S.of(context).resendFailedPlan} $planId: $remarks'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ));
      }
    } catch (e) {
      print(' [_resendItem] Error during resend: $e');
      String errorMessage = e.toString();
      await _apiResponseRepo.updateResponseStatus(planId, false, errorMessage, 0);
      loadResponseData();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error during resend: $errorMessage'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ));
    } finally {
      setState(() {
        resendingItems.remove(planId);
        print(' [_resendItem] Removed from resending items. Remaining: ${resendingItems.length}');
      });
    }
  }



  void _showImagePopup(ApiResponseData responseData) {
    print(' [_showImagePopup] Showing image popup for plan: ${responseData.originalData.PlanCode}');
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
                  'Images for Plan: ${responseData.originalData.PlanCode}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (responseData.originalData.CleanImage != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(responseData.originalData.CleanImage.toString()),
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        if (responseData.originalData.WBImage != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(responseData.originalData.WBImage.toString()),
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        if (responseData.originalData.SprayImage != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(responseData.originalData.SprayImage.toString()),
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        if (responseData.originalData.NearImage != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(responseData.originalData.NearImage.toString()),
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        if (responseData.originalData.FarImage != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(responseData.originalData.FarImage.toString()),
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        if (responseData.originalData.NewImage6 != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(responseData.originalData.NewImage6.toString()),
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        if (responseData.originalData.NewImage7 != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(responseData.originalData.NewImage7.toString()),
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
                  onPressed: () {
                    print(' [_showImagePopup] Closing image popup');
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

  void _showRemarksDialog(String planId) {
    print(' [_showRemarksDialog] Showing remarks dialog for planId: $planId');
    final responseItem = responseData.firstWhere((item) => item.planId == planId);
    print(' [_showRemarksDialog] Found item: ${responseItem.originalData.PlanCode}, success: ${responseItem.isSuccess}');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${S.of(context).responseDetails} $planId',style: TextStyle(
            color: Font.neutralDarkColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            fontFamily: "Roboto",
          ),),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('${S.of(context).status}: ', style: TextStyle(
                        color: Font.neutralDarkColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        fontFamily: "Roboto",
                      ),),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: responseItem.isSuccess ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          responseItem.isSuccess ? S.of(context).success : S.of(context).failed,
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text('${S.of(context).lastResponseTime}: ', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('${responseItem.responseTime.toString()}'),
                  SizedBox(height: 12),
                  Text('${S.of(context).statusCode}: ', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('${responseItem.statusCode}'),
                  SizedBox(height: 12),
                  Text('${S.of(context).totalRetryCount}:', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('${responseItem.retryCount}'),
                  SizedBox(height: 12),
                  Text('${S.of(context).latestMessage}: ', style: TextStyle(fontWeight: FontWeight.w600)),
                  Container(
                    width: double.maxFinite,
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      responseItem.responseMessage,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      print(' [_showRemarksDialog] Navigating to full history');
                      _showFullHistory(planId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: Text(
                      S.of(context).viewAttemptsHistory,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                print(' [_showRemarksDialog] Closing remarks dialog');
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showFullHistory(String planId) async {
    print(' [_showFullHistory] Showing full history for planId: $planId');

    try {
      final allResponsesForPlan =
      await _apiResponseRepo.getResponsesForPlan(planId);

      print("======================================================");
      print(" PLAN ID : $planId");
      print(" TOTAL ATTEMPTS : ${allResponsesForPlan.length}");

      for (int i = 0; i < allResponsesForPlan.length; i++) {
        final response = allResponsesForPlan[i];

        String printNo = "";
        String serverPlanId = "";

        if (response.originalData is ImageUploaddata) {
          final data = response.originalData as ImageUploaddata;

          printNo = data.PrintNo ?? "";
          serverPlanId = data.ServerPlanId ?? "";
        }

        print("---------------------------------------------");
        print("Attempt      : ${i + 1}");
        print("PlanId       : ${response.planId}");
        print("ServerPlanId : $serverPlanId");
        print("Print No     : $printNo");
        print("Success      : ${response.isSuccess}");
        print("Status Code  : ${response.statusCode}");
        print("Time         : ${response.responseTime}");
        print("Message      : ${response.responseMessage}");
      }

      print("======================================================");

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              '${S.of(context).completeHistory} $planId',
              style: TextStyle(
                color: Font.neutralDarkColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                fontFamily: "Roboto",
              ),
            ),
            content: Container(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.6,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${S.of(context).totalAttempts}: ${allResponsesForPlan.length}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 16),

                    ...allResponsesForPlan.asMap().entries.map((entry) {
                      int index = entry.key;
                      ApiResponseData response = entry.value;

                      String printNo = "";
                      String serverPlanId = "";

                      if (response.originalData is ImageUploaddata) {
                        final data = response.originalData as ImageUploaddata;
                        printNo = data.PrintNo ?? "";
                        serverPlanId = data.ServerPlanId ?? "";
                      }

                      print(
                          " UI Attempt ${index + 1} -> "
                              "Plan=${response.planId} "
                              "ServerPlan=$serverPlanId "
                              "Print=$printNo "
                              "Success=${response.isSuccess}");

                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: response.isSuccess
                              ? Colors.green[50]
                              : Colors.red[50],
                          border: Border.all(
                            color: response.isSuccess
                                ? Colors.green
                                : Colors.red,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${S.of(context).attempt} ${index + 1} ${index == 0 ? '(${S.of(context).latest})' : ''}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text("Print No : $printNo"),
                            Text("Server Plan : $serverPlanId"),
                            Text('${S.of(context).time}: ${response.responseTime}'),
                            Text('${S.of(context).status}: ${response.isSuccess ? 'Success' : 'Failed'}'),
                            Text('${S.of(context).code}: ${response.statusCode}'),
                            Text('${S.of(context).message}: ${response.responseMessage}'),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  print(' [_showFullHistory] Closing history dialog');
                  Navigator.of(context).pop();
                },
                child: Text(S.of(context).close),
              ),
            ],
          );
        },
      );
    } catch (e, stackTrace) {
      print(' [_showFullHistory] Error loading history: $e');
      print(stackTrace);
    }
  }

  Future<bool> _onWillPop() async {
    print(' [_onWillPop] Back button pressed, navigating to LandingScreen');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LandingScreen(changeLanguage: widget.changeLanguage)),
    );
    print(' [_onWillPop] Navigation triggered');
    return false;
  }

  List<int> _encryptFileBytes(List<int> fileBytes) {
    print(' [_encryptFileBytes] Encrypting ${fileBytes.length} bytes');
    try {
      final keyBytes = sha256.convert(utf8.encode(encryptionPassword)).bytes;
      final key = encrypt_pkg.Key(Uint8List.fromList(keyBytes));
      final iv = encrypt_pkg.IV.fromLength(16);

      final encrypter = encrypt_pkg.Encrypter(
          encrypt_pkg.AES(key, mode: encrypt_pkg.AESMode.cbc)
      );

      final encrypted = encrypter.encryptBytes(fileBytes, iv: iv);

      final combined = <int>[];
      combined.addAll(iv.bytes);
      combined.addAll(encrypted.bytes);
      print(' [_encryptFileBytes] Encryption complete. Output size: ${combined.length} bytes');
      return combined;
    } catch (e) {
      print(' [_encryptFileBytes] Error encrypting file: $e');
      return fileBytes;
    }
  }

  void _showShareOptionsDialog(ApiResponseData responseData) {
    print(' [_showShareOptionsDialog] Showing share options for plan: ${responseData.originalData.PlanCode}');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Share Options',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              fontFamily: "Roboto",
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Choose how to share:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                              fontFamily: "Roboto",
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      ' Normal: Share ZIP as-is\n Encrypted: Secure with password',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
                        fontFamily: "Roboto",
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              InkWell(
                onTap: () {
                  print(' [_showShareOptionsDialog] Normal ZIP sharing selected');
                  Navigator.pop(context);
                  _createZipAndShare(responseData, withEncryption: false);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.share, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Share Normal ZIP',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          fontFamily: "Roboto",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
              InkWell(
                onTap: () {
                  print(' [_showShareOptionsDialog] Encrypted ZIP sharing selected');
                  Navigator.pop(context);
                  _createZipAndShare(responseData, withEncryption: true);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Share Encrypted ZIP',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          fontFamily: "Roboto",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                print(' [_showShareOptionsDialog] Closing share options dialog');
                Navigator.pop(context);
              },
              child: Text(
                S.of(context).close,
                style: TextStyle(color: Font.primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createZipAndShare(ApiResponseData responseData, {bool withEncryption = false}) async {
    print(' [_createZipAndShare] Creating ZIP for plan: ${responseData.originalData.PlanCode}, encryption: $withEncryption');

    setState(() {
      _isCreatingZip = true;
      print(' [_createZipAndShare] ZIP creation status: true');
    });

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(withEncryption
                        ? 'Creating Encrypted ZIP...'
                        : S.of(context).creatingZIPFile),
                  ],
                ),
              ),
            ),
          );
        },
      );

      final archive = Archive();
      final data = responseData.originalData;
      print(' [_createZipAndShare] Archive created, preparing data...');

      Map<String, dynamic> planData = {
        'ServerPlanId': data.ServerPlanId?.toString() ?? 'N/A',
        'VillageCode': data.VillageCode?.toString() ?? 'N/A',
        'PlanCode': data.PlanCode?.toString() ?? 'N/A',
        'PrintNo': data.PrintNo?.toString() ?? 'N/A',
        'Address': data.Address?.toString() ?? 'N/A',
        'ExecutionDate': data.ExecutionDate is DateTime
            ? (data.ExecutionDate as DateTime).toIso8601String()
            : (data.ExecutionDate?.toString() ?? 'N/A'),
        'UploadDate': data.UploadDate is DateTime
            ? (data.UploadDate as DateTime).toIso8601String()
            : (data.UploadDate?.toString() ?? 'N/A'),
        'Clean_Latitude': data.CleanLatitude?.toString() ?? 'N/A',
        'Clean_Longitude': data.CleanLongitude?.toString() ?? 'N/A',
        'WB_Latitude': data.WBLatitude?.toString() ?? 'N/A',
        'WB_Longitude': data.WBLongitude?.toString() ?? 'N/A',
        'Spray_Latitude': data.SprayLatitude?.toString() ?? 'N/A',
        'Spray_Longitude': data.SprayLongitude?.toString() ?? 'N/A',
        'Near_Latitude': data.NearLatitude?.toString() ?? 'N/A',
        'Near_Longitude': data.NearLongitude?.toString() ?? 'N/A',
        'Far_Latitude': data.FarLatitude?.toString() ?? 'N/A',
        'Far_Longitude': data.FarLongitude?.toString() ?? 'N/A',
        'New6_Latitude': data.New6Latitude?.toString() ?? 'N/A',
        'New6_Longitude': data.New6Longitude?.toString() ?? 'N/A',
        'New7_Latitude': data.New7Latitude?.toString() ?? 'N/A',
        'New7_Longitude': data.New7Longitude?.toString() ?? 'N/A',
        'NetworkStatus': data.networkFlagString?.toString() ?? 'N/A',
        'UID': uidDetails
      };

      String jsonContent = JsonEncoder.withIndent('  ').convert(planData);
      List<int> jsonBytes = utf8.encode(jsonContent);
      print(' [_createZipAndShare] JSON data prepared, size: ${jsonBytes.length} bytes');

      if (withEncryption) {
        jsonBytes = _encryptFileBytes(jsonBytes);
        archive.addFile(ArchiveFile(
          'plan_data.json.encrypted',
          jsonBytes.length,
          jsonBytes,
        ));
        print(' [_createZipAndShare] JSON data encrypted and added to archive');
      } else {
        archive.addFile(ArchiveFile(
          'plan_data.json',
          jsonContent.length,
          jsonContent.codeUnits,
        ));
        print(' [_createZipAndShare] JSON data added to archive');
      }

      List<String?> imagePaths = [
        data.CleanImage,
        data.WBImage,
        data.SprayImage,
        data.NearImage,
        data.FarImage,
        data.NewImage6,
        data.NewImage7,
      ];

      List<String> imageNames = [
        'CleanImage.png',
        'WBImage.png',
        'SprayImage.png',
        'NearImage.png',
        'FarImage.png',
        'NewImage6.png',
        'NewImage7.png',
      ];

      int imageCount = 0;
      for (int i = 0; i < imagePaths.length; i++) {
        if (imagePaths[i] != null && imagePaths[i]!.isNotEmpty) {
          print(' [_createZipAndShare] Processing image ${imageNames[i]}');
          try {
            final file = File(imagePaths[i]!);
            if (await file.exists()) {
              List<int> bytes = await file.readAsBytes();
              print(' [_createZipAndShare] Image ${imageNames[i]} size: ${bytes.length} bytes');

              if (withEncryption) {
                bytes = _encryptFileBytes(bytes);
                archive.addFile(ArchiveFile(
                  imageNames[i] + '.encrypted',
                  bytes.length,
                  bytes,
                ));
                print(' [_createZipAndShare] Image ${imageNames[i]} encrypted and added');
              } else {
                archive.addFile(ArchiveFile(
                  imageNames[i],
                  bytes.length,
                  bytes,
                ));
                print(' [_createZipAndShare] Image ${imageNames[i]} added');
              }
              imageCount++;
            } else {
              print(' [_createZipAndShare] Image ${imageNames[i]} file not found');
            }
          } catch (e) {
            print(' [_createZipAndShare] Error adding image ${imageNames[i]}: $e');
          }
        }
      }

      if (withEncryption) {
        String encryptionInfo = '''
Encrypted Plan Data
===================
Encryption Date: ${DateTime.now().toString()}
Files Encrypted: ${imageCount + 1} (${imageCount} images + 1 JSON)
Encryption Method: AES-256-CBC

To decrypt these files:
1. Use the decryption password provided separately
2. Each file has .encrypted extension
3. Original file structure is preserved

Note: Keep the password secure and do not share publicly.
''';
        var infoBytes = utf8.encode(encryptionInfo);
        archive.addFile(ArchiveFile('ENCRYPTION_INFO.txt', infoBytes.length, infoBytes));
        print(' [_createZipAndShare] Encryption info file added');
      }

      print(' [_createZipAndShare] Encoding ZIP archive...');
      var zipData = ZipEncoder().encode(archive);
      if (zipData == null) {
        throw Exception('Failed to create ZIP file');
      }
      print(' [_createZipAndShare] ZIP encoding complete, size: ${zipData.length} bytes');

      final tempDir = await getTemporaryDirectory();
      final zipFileName = 'Plan_${data.ServerPlanId}_${data.VillageCode}_${data.PlanCode}_${data.PrintNo}${withEncryption ? '_encrypted' : ''}.zip';
      final zipFile = File('${tempDir.path}/$zipFileName');
      await zipFile.writeAsBytes(zipData);
      print(' [_createZipAndShare] ZIP file saved: ${zipFile.path}');

      Navigator.pop(context);
      print(' [_createZipAndShare] Sharing ZIP file...');

      await _shareFile(
          zipFile.path,
          'Plan ${data.PlanCode} - ${data.VillageCode}',
          withEncryption
      );

    } catch (e) {
      print(' [_createZipAndShare] Error creating ZIP: $e');
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating ZIP: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isCreatingZip = false;
        print(' [_createZipAndShare] ZIP creation status: false');
      });
    }
  }

  Future<void> _shareFile(String filePath, String text, bool isEncrypted) async {
    print(' [_shareFile] Sharing file: $filePath, isEncrypted: $isEncrypted');
    try {
      final file = XFile(filePath);
      print(' [_shareFile] XFile created: ${file.path}');

      final result = await Share.shareXFiles(
        [file],
        text: isEncrypted
            ? '$text\n\n Encrypted ZIP - Password required for decryption\nExported on ${DateTime.now().toString()}'
            : '$text\nExported on ${DateTime.now().toString()}',
        subject: isEncrypted ? 'Encrypted Plan Data ZIP' : 'Plan Data ZIP File',
      );

      print(' [_shareFile] Share result status: ${result.status}');

      if (result.status == ShareResultStatus.success) {
        print(' [_shareFile] Share successful');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEncrypted
                ? 'Encrypted ZIP shared successfully!'
                : 'ZIP file shared successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (result.status == ShareResultStatus.dismissed) {
        print(' [_shareFile] Share dismissed by user');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Share cancelled'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print(' [_shareFile] Error sharing file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing file: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print(' [build] Building ResendScreen UI');
    final theme = Theme.of(context);
    final isSuccessTab = _tabController.index == 1;
    print(' [build] Current tab: ${_tabController.index == 0 ? "Failed" : "Success"}');
    print(' [build] Data count: ${filteredResponseData.length} filtered out of ${responseData.length} total');

    return WillPopScope(
      onWillPop: _onWillPop,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Font.primaryColor,
            title: Text(
                S.of(context).resend,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    letterSpacing: 1,
                    fontFamily: "Roboto"
                )
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
              onPressed: () {
                print(' [AppBar] Back button pressed');
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LandingScreen(changeLanguage: widget.changeLanguage))
                );
              },
            ),
            actions: [
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
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              tabs: [
                Tab(
                  icon: Icon(Icons.error_outline),
                  text: S.of(context).failed,
                ),
                Tab(
                  icon: Icon(Icons.check_circle_outline),
                  text: S.of(context).success,
                ),
              ],
            ),
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
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 45,
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.search_sharp, color: Font.primaryLightColor),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey),
                                onPressed: _clearSearch,
                              )
                                  : null,
                              hintText: S.of(context).searchPrintNoStatus,
                              hintStyle: TextStyle(fontSize: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Font.primaryLightColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Font.primaryColor, width: 2),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_searchController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          'Found ${filteredResponseData.length} result(s)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Font.neutralDarkColor,
                          ),
                        ),
                        if (filteredResponseData.length < responseData.length)
                          Text(
                            ' out of ${responseData.length}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),

                Expanded(
                  child: filteredResponseData.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          _searchController.text.isNotEmpty
                              ? 'No results found for "${_searchController.text}"'
                              : 'No data available',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_searchController.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: TextButton(
                              onPressed: _clearSearch,
                              child: Text('Clear Search'),
                            ),
                          ),
                      ],
                    ),
                  )
                      : Scrollbar(
                    controller: _verticalScrollController,
                    thumbVisibility: true,
                    child: Scrollbar(
                      controller: _horizontalScrollController,
                      thumbVisibility: true,
                      notificationPredicate: (notif) => notif.depth == 1,
                      child: SingleChildScrollView(
                        controller: _verticalScrollController,
                        child: SingleChildScrollView(
                          controller: _horizontalScrollController,
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                            child: DataTable(
                              dataRowMaxHeight: double.infinity,
                              headingRowColor: MaterialStateProperty.all(Font.primaryColor),
                              headingTextStyle: TextstyleGlobal.tableHeaderTextStyle,
                              headingRowHeight: 40,
                              dataTextStyle: TextstyleGlobal.bodyTextStyleSeeplan,
                              showCheckboxColumn: true,
                              showBottomBorder: true,
                              columnSpacing: 10,
                              columns: [
                                if (isSuccessTab)
                                  DataColumn(label: Container(width: 50, child: Center(child: Text(S.of(context).canId, style: TextstyleGlobal.tableHeaderTextStyle)))),
                                DataColumn(label: Container(width: 50, child: Center(child: Text(S.of(context).village, style: TextstyleGlobal.tableHeaderTextStyle)))),
                                DataColumn(label: Container(width: 50, child: Center(child: Text(S.of(context).plan, style: TextstyleGlobal.tableHeaderTextStyle)))),
                                DataColumn(label: Container(width: 50, child: Center(child: Text(S.of(context).printNo, style: TextstyleGlobal.tableHeaderTextStyle)))),
                                DataColumn(label: Container(width: 60, child: Center(child: Text(S.of(context).images, style: TextstyleGlobal.tableHeaderTextStyle)))),
                                DataColumn(label: Container(width: 60, child: Center(child: Text(S.of(context).zip, style: TextstyleGlobal.tableHeaderTextStyle)))),
                                DataColumn(label: Container(width: 60, child: Center(child: Text(S.of(context).action, style: TextstyleGlobal.tableHeaderTextStyle)))),
                                DataColumn(label: Container(width: 80, child: Center(child: Text(S.of(context).status, style: TextstyleGlobal.tableHeaderTextStyle)))),
                                DataColumn(label: Container(width: 70, child: Center(child: Text(S.of(context).details, style: TextstyleGlobal.tableHeaderTextStyle)))),
                              ],
                              rows: List.generate(
                                filteredResponseData.length,
                                    (index) {
                                  final response = filteredResponseData[index];
                                  final planId = response.planId;
                                  final isResending = resendingItems.contains(planId);
                                  final isFailed = !response.isSuccess;

                                  return DataRow(
                                    cells: [
                                      if (isSuccessTab)
                                        DataCell(Center(child: Container(width: 50, child: Text(response.originalData.printId ?? '', style: TextstyleGlobal.bodyTextStyleSeeplan)))),
                                      DataCell(Center(child: Container(width: 50, child: Text(response.originalData.VillageCode ?? '', style: TextstyleGlobal.bodyTextStyleSeeplan)))),
                                      DataCell(Center(child: Container(width: 50, child: Text(response.originalData.PlanCode ?? '', style: TextstyleGlobal.bodyTextStyleSeeplan)))),
                                      DataCell(Center(child: Container(width: 50, child: Text(response.originalData.PrintNo ?? '', style: TextstyleGlobal.bodyTextStyleSeeplan)))),
                                      DataCell(
                                        GestureDetector(
                                          onTap: () => _showImagePopup(response),
                                          child: Center(
                                            child: Container(
                                              width: 60,
                                              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                              decoration: BoxDecoration(color: Font.primaryLightColor, borderRadius: BorderRadius.circular(4)),
                                              child: Text(
                                                S.of(context).view,
                                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 10, fontFamily: "Roboto"),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: GestureDetector(
                                            onTap: _isCreatingZip ? null : () {
                                              _showShareOptionsDialog(response);
                                            },
                                            child: Container(
                                              width: 60,
                                              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                              decoration: BoxDecoration(
                                                color: _isCreatingZip ? Colors.grey : Colors.green,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  if (_isCreatingZip)
                                                    SizedBox(
                                                      width: 10,
                                                      height: 10,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                      ),
                                                    )
                                                  else
                                                    Icon(Icons.folder_zip, color: Colors.white, size: 12),
                                                  SizedBox(width: 2),
                                                  Text(
                                                    S.of(context).zip,
                                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 10, fontFamily: "Roboto"),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: _tabController.index == 0   //  Only show in Failed tab
                                              ? Container(
                                            width: 60,
                                            child: GestureDetector(
                                              onTap: isResending ? null : () => _resendItem(planId),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                                                decoration: BoxDecoration(
                                                  color: isResending
                                                      ? Colors.grey
                                                      : (isFailed ? Colors.red : Colors.blue),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    if (isResending) ...[
                                                      SizedBox(
                                                        width: 6,
                                                        height: 6,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                        ),
                                                      ),
                                                      SizedBox(width: 2),
                                                    ],
                                                    Text(
                                                      isResending
                                                          ? S.of(context).sending
                                                          : S.of(context).resend,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 8,
                                                        fontFamily: "Roboto",
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          )
                                              : SizedBox.shrink(), //  Hide in Success tab
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Text(
                                            response.isSuccess ? S.of(context).success : S.of(context).failed,
                                            style: TextStyle(color: response.isSuccess ? Colors.green : Colors.red, fontWeight: FontWeight.w600, fontSize: 12, fontFamily: "Roboto"),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Center(
                                          child: Container(
                                            width: 70,
                                            child: GestureDetector(
                                              onTap: () => _showRemarksDialog(planId),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[600],
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  S.of(context).view,
                                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 10, fontFamily: "Roboto"),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}