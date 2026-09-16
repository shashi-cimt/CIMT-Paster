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
import '../../widgets/common_app_bar.dart';
import '../../widgets/can_image_loader.dart';
import '../../widgets/app_snack_bar.dart';

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
    final responseItem = responseData.firstWhere((item) => item.planId == planId);
    print(' [_resendItem] Starting resend for planId: $planId');
    setState(() {
      resendingItems.add(planId);
      print(' [_resendItem] Added to resending items. Current set: ${resendingItems.length}');
    });

    try {

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

      String remarks = result['message'] ?? "";

      if (isSuccess) {
        // Move this print to Success tab
        await _apiResponseRepo.updateResponseStatus(
          planId,
          responseItem.originalData.PrintNo ?? "",
          true,
          remarks,
          200,
        );
      } else {
        // Keep in Failed tab
        await _apiResponseRepo.updateResponseStatus(
          planId,
          responseItem.originalData.PrintNo ?? "",
          false,
          remarks,
          400,
        );
      }

      loadResponseData();
      print(' [_resendItem] Response status updated');

      if (isSuccess) {
        print('🎉 [_resendItem] Resend SUCCESSFUL for planId: $planId');
        AppSnackBar.showSuccess(
          context,
          '${S.of(context).successfullyResentPlan} $planId!\n✅ Moved to Success tab',
        );
      } else {
        print(' [_resendItem] Resend FAILED for planId: $planId - $remarks');
        AppSnackBar.showError(
          context,
          '${S.of(context).resendFailedPlan} $planId: $remarks',
        );
      }
    } catch (e) {
      print(' [_resendItem] Error during resend: $e');
      String errorMessage = e.toString();
      await _apiResponseRepo.updateResponseStatus(
        planId,
        responseItem.originalData.PrintNo ?? "",
        false,
        errorMessage,
        0,
      );
      loadResponseData();

      AppSnackBar.showError(
        context,
        'Error during resend: $errorMessage',
      );
    } finally {
      setState(() {
        resendingItems.remove(planId);
        print(' [_resendItem] Removed from resending items. Remaining: ${resendingItems.length}');
      });
    }
  }



  void _openFullScreenImage(String title, String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext fullScreenContext) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.file(
                      File(imagePath),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Text(
                          "Failed to load image",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: Colors.black54,
                    child: Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                          onPressed: () => Navigator.pop(fullScreenContext),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showImagePopup(ApiResponseData responseData) {
    print(' [_showImagePopup] Showing image popup for plan: ${responseData.originalData.PlanCode}');
    final original = responseData.originalData;
    final List<Map<String, String>> images = [];

    if (original.CleanImage != null && original.CleanImage.toString().trim().isNotEmpty) {
      images.add({'title': 'Clean Wall', 'path': original.CleanImage.toString()});
    }
    if (original.WBImage != null && original.WBImage.toString().trim().isNotEmpty) {
      images.add({'title': 'White Base', 'path': original.WBImage.toString()});
    }
    if (original.SprayImage != null && original.SprayImage.toString().trim().isNotEmpty) {
      images.add({'title': 'Spray', 'path': original.SprayImage.toString()});
    }
    if (original.NearImage != null && original.NearImage.toString().trim().isNotEmpty) {
      images.add({'title': 'Near View', 'path': original.NearImage.toString()});
    }
    if (original.FarImage != null && original.FarImage.toString().trim().isNotEmpty) {
      images.add({'title': 'Far View', 'path': original.FarImage.toString()});
    }
    if (original.NewImage6 != null && original.NewImage6.toString().trim().isNotEmpty) {
      images.add({'title': 'Extra Photo 1', 'path': original.NewImage6.toString()});
    }
    if (original.NewImage7 != null && original.NewImage7.toString().trim().isNotEmpty) {
      images.add({'title': 'Extra Photo 2', 'path': original.NewImage7.toString()});
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(dialogContext).size.height * 0.75,
              maxWidth: 480,
            ),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.photo_library_outlined,
                          color: Color(0xFF1D4ED8),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Plan: ${original.PlanCode ?? responseData.planId}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                fontFamily: "Roboto",
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Print No: ${original.PrintNo ?? "N/A"} • ${images.length} Photos Captured',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                fontFamily: "Roboto",
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(dialogContext),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 14),

                  // Image content
                  Expanded(
                    child: images.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.image_not_supported_outlined, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 10),
                                Text(
                                  'No images found for this record',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            itemCount: images.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.95,
                            ),
                            itemBuilder: (context, index) {
                              final item = images[index];
                              final file = File(item['path']!);
                              final fileExists = file.existsSync();

                              return GestureDetector(
                                onTap: fileExists
                                    ? () => _openFullScreenImage(item['title']!, item['path']!)
                                    : null,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: fileExists
                                              ? Image.file(
                                                  file,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => Center(
                                                    child: Icon(Icons.broken_image_outlined, color: Colors.grey[400]),
                                                  ),
                                                )
                                              : Center(
                                                  child: Icon(Icons.broken_image_outlined, color: Colors.grey[400]),
                                                ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          left: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.65),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              item['title']!,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        if (fileExists)
                                          Positioned(
                                            bottom: 8,
                                            right: 8,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.6),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.zoom_in_rounded,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        S.of(context).close,
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showRemarksDialog(String planId) {
    print(' [_showRemarksDialog] Showing remarks dialog for planId: $planId');
    final responseItem = responseData.firstWhere(
      (item) => item.planId == planId,
      orElse: () => filteredResponseData.firstWhere((item) => item.planId == planId),
    );

    final isSuccess = responseItem.isSuccess;
    final planCode = responseItem.originalData.PlanCode ?? planId;
    final printNo = responseItem.originalData.PrintNo ?? '';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Header with Plan Info & Close
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSuccess ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                            color: isSuccess ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${S.of(context).responseDetails}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                  fontFamily: "Roboto",
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Plan: $planCode${printNo.isNotEmpty ? ' • Print: $printNo' : ''}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontFamily: "Roboto",
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(dialogContext),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 16),

                    // Metrics Grid (Status, HTTP Code, Retries)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Status pill
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      S.of(context).status,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isSuccess ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isSuccess ? S.of(context).success : S.of(context).failed,
                                        style: TextStyle(
                                          color: isSuccess ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Status Code
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      S.of(context).statusCode,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${responseItem.statusCode}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Retry Count
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Total Retries',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${responseItem.retryCount}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Time: ${responseItem.responseTime.toString()}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Server / Error Message section
                    const Text(
                      'Server Response Message',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSuccess ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSuccess ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                        ),
                      ),
                      child: SelectableText(
                        responseItem.responseMessage.trim().isEmpty
                            ? 'No message provided by server'
                            : responseItem.responseMessage,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: isSuccess ? const Color(0xFF166534) : const Color(0xFF991B1B),
                          fontFamily: "Roboto",
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Attempts History Button
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _showFullHistory(planId);
                        },
                        icon: const Icon(Icons.history_rounded, size: 18, color: Color(0xFF1E40AF)),
                        label: const Text(
                          'View Attempt History',
                          style: TextStyle(
                            color: Color(0xFF1E40AF),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF93C5FD)),
                          backgroundColor: const Color(0xFFEFF6FF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Action buttons (Resend if failed, Close)
                    Row(
                      children: [
                        if (!isSuccess) ...[
                          Expanded(
                            child: SizedBox(
                              height: 42,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                  _resendItem(planId);
                                },
                                icon: const Icon(Icons.replay_rounded, size: 16, color: Colors.white),
                                label: Text(
                                  S.of(context).resend,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC2626),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: SizedBox(
                            height: 42,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(
                                S.of(context).close,
                                style: const TextStyle(
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFullHistory(String planId) async {
    print(' [_showFullHistory] Showing full history for planId: $planId');

    try {
      final allResponsesForPlan =
          await _apiResponseRepo.getResponsesForPlan(planId);

      showDialog(
        context: context,
        builder: (BuildContext historyContext) {
          return Dialog(
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(historyContext).size.height * 0.75,
                maxWidth: 480,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.history_rounded,
                            color: Color(0xFF1D4ED8),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${S.of(context).completeHistory}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                  fontFamily: "Roboto",
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Plan: $planId • ${allResponsesForPlan.length} total attempt(s)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontFamily: "Roboto",
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(historyContext),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 14),
                    Expanded(
                      child: allResponsesForPlan.isEmpty
                          ? Center(
                              child: Text(
                                'No attempt history found',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            )
                          : ListView.builder(
                              itemCount: allResponsesForPlan.length,
                              itemBuilder: (context, index) {
                                final response = allResponsesForPlan[index];
                                String printNo = "";
                                String serverPlanId = "";

                                if (response.originalData is ImageUploaddata) {
                                  final data = response.originalData as ImageUploaddata;
                                  printNo = data.PrintNo ?? "";
                                  serverPlanId = data.ServerPlanId ?? "";
                                }

                                final isSuccess = response.isSuccess;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSuccess ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSuccess ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Attempt ${index + 1}${index == 0 ? ' (Latest)' : ''}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isSuccess ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              isSuccess ? 'Success' : 'Failed (Code ${response.statusCode})',
                                              style: TextStyle(
                                                color: isSuccess ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      if (printNo.isNotEmpty)
                                        Text('Print No: $printNo', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                                      if (serverPlanId.isNotEmpty)
                                        Text('Server Plan: $serverPlanId', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                                      Text('Time: ${response.responseTime}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                      const SizedBox(height: 4),
                                      Text(
                                        response.responseMessage.trim().isEmpty
                                            ? 'No details'
                                            : response.responseMessage,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isSuccess ? const Color(0xFF166534) : const Color(0xFF991B1B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(historyContext),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          S.of(context).close,
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (e, stackTrace) {
      print(' [_showFullHistory] Error loading history: $e');
      print(stackTrace);
    }
  }

  Future<bool> _onWillPop() async {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return false;
    }
    return true;
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: CanImageLoader(
                  spinnerSize: 52,
                  showBrand: true,
                  message: withEncryption
                      ? 'Creating Encrypted ZIP...'
                      : S.of(context).creatingZIPFile,
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

      AppSnackBar.showError(
        context,
        'Error creating ZIP: $e',
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
        AppSnackBar.showSuccess(
          context,
          isEncrypted
              ? 'Encrypted ZIP shared successfully!'
              : 'ZIP file shared successfully!',
        );
      } else if (result.status == ShareResultStatus.dismissed) {
        print(' [_shareFile] Share dismissed by user');
        AppSnackBar.showTopSnackBar(
          context,
          'Share cancelled',
          isError: false,
        );
      }
    } catch (e) {
      print(' [_shareFile] Error sharing file: $e');
      AppSnackBar.showError(
        context,
        'Error sharing file: $e',
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
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: CommonAppBar(
            title: S.of(context).resend,
            actions: const [
              CommonHomeButton(),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              tabs: [
                Tab(
                  icon: const Icon(Icons.error_outline),
                  text: S.of(context).failed,
                ),
                Tab(
                  icon: const Icon(Icons.check_circle_outline),
                  text: S.of(context).success,
                ),
              ],
            ),
          ),
          body: SafeArea(
            top: false,
            child: Container(
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
                              headingRowHeight: 44,
                              dataTextStyle: TextstyleGlobal.bodyTextStyleSeeplan,
                              showCheckboxColumn: false,
                              showBottomBorder: true,
                              columnSpacing: 12,
                              columns: [
                                if (isSuccessTab)
                                  DataColumn(label: Container(width: 50, child: Center(child: Text(S.of(context).canId, style: TextstyleGlobal.tableHeaderTextStyle)))),
                                DataColumn(label: Container(width: 50, child: Center(child: Text(S.of(context).village, style: TextstyleGlobal.tableHeaderTextStyle)))),
                                DataColumn(label: Container(width: 50, child: Center(child: Text(S.of(context).plan, style: TextstyleGlobal.tableHeaderTextStyle)))),
                                DataColumn(label: Container(width: 50, child: Center(child: Text(S.of(context).printNo, style: TextstyleGlobal.tableHeaderTextStyle)))),
                                DataColumn(label: Container(width: 65, child: Center(child: Text(S.of(context).images, style: TextstyleGlobal.tableHeaderTextStyle)))),
                                DataColumn(label: Container(width: 65, child: Center(child: Text(S.of(context).zip, style: TextstyleGlobal.tableHeaderTextStyle)))),
                                if (!isSuccessTab)
                                  DataColumn(label: Container(width: 75, child: Center(child: Text(S.of(context).action, style: TextstyleGlobal.tableHeaderTextStyle)))),
                                DataColumn(label: Container(width: 85, child: Center(child: Text(S.of(context).status, style: TextstyleGlobal.tableHeaderTextStyle)))),
                                DataColumn(label: Container(width: 70, child: Center(child: Text(S.of(context).details, style: TextstyleGlobal.tableHeaderTextStyle)))),
                              ],
                              rows: List.generate(
                                filteredResponseData.length,
                                (index) {
                                  final response = filteredResponseData[index];
                                  final planId = response.planId;
                                  final isResending = resendingItems.contains(planId);

                                  return DataRow(
                                    cells: [
                                      if (isSuccessTab)
                                        DataCell(Center(child: Container(width: 50, child: Text(response.originalData.printId ?? '', style: TextstyleGlobal.bodyTextStyleSeeplan)))),
                                      DataCell(Center(child: Container(width: 50, child: Text(response.originalData.VillageCode ?? '', style: TextstyleGlobal.bodyTextStyleSeeplan)))),
                                      DataCell(Center(child: Container(width: 50, child: Text(response.originalData.PlanCode ?? '', style: TextstyleGlobal.bodyTextStyleSeeplan)))),
                                      DataCell(Center(child: Container(width: 50, child: Text(response.originalData.PrintNo ?? '', style: TextstyleGlobal.bodyTextStyleSeeplan)))),

                                      // IMAGES BUTTON
                                      DataCell(
                                        Center(
                                          child: InkWell(
                                            onTap: () => _showImagePopup(response),
                                            borderRadius: BorderRadius.circular(6),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEFF6FF),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.image_outlined, size: 13, color: Color(0xFF1D4ED8)),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    S.of(context).view,
                                                    style: const TextStyle(
                                                      color: Color(0xFF1D4ED8),
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 11,
                                                      fontFamily: "Roboto",
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // ZIP BUTTON
                                      DataCell(
                                        Center(
                                          child: InkWell(
                                            onTap: _isCreatingZip ? null : () => _showShareOptionsDialog(response),
                                            borderRadius: BorderRadius.circular(6),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFECFDF5),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: const Color(0xFFA7F3D0), width: 1),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (_isCreatingZip)
                                                    const CanImageSpinner(
                                                      size: 13,
                                                      primaryColor: Color(0xFF047857),
                                                      accentColor: Color(0xFF10B981),
                                                    )
                                                  else
                                                    const Icon(Icons.folder_zip_outlined, color: Color(0xFF047857), size: 13),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    S.of(context).zip,
                                                    style: const TextStyle(
                                                      color: Color(0xFF047857),
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 11,
                                                      fontFamily: "Roboto",
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // RESEND ACTION BUTTON (Failed tab only)
                                      if (!isSuccessTab)
                                        DataCell(
                                          Center(
                                            child: InkWell(
                                              onTap: isResending ? null : () => _resendItem(planId),
                                              borderRadius: BorderRadius.circular(6),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                                                decoration: BoxDecoration(
                                                  color: isResending ? Colors.grey[200] : const Color(0xFFDC2626),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    if (isResending) ...[
                                                      const CanImageSpinner(
                                                        size: 11,
                                                        primaryColor: Colors.grey,
                                                        accentColor: Colors.white,
                                                      ),
                                                      const SizedBox(width: 4),
                                                    ] else ...[
                                                      const Icon(Icons.replay_rounded, size: 12, color: Colors.white),
                                                      const SizedBox(width: 3),
                                                    ],
                                                    Text(
                                                      isResending
                                                          ? S.of(context).sending
                                                          : S.of(context).resend,
                                                      style: TextStyle(
                                                        color: isResending ? Colors.grey[700] : Colors.white,
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 11,
                                                        fontFamily: "Roboto",
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                      // STATUS BADGE
                                      DataCell(
                                        Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                            decoration: BoxDecoration(
                                              color: response.isSuccess ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: response.isSuccess ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  response.isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                                  size: 12,
                                                  color: response.isSuccess ? const Color(0xFF166534) : const Color(0xFF991B1B),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  response.isSuccess ? S.of(context).success : S.of(context).failed,
                                                  style: TextStyle(
                                                    color: response.isSuccess ? const Color(0xFF166534) : const Color(0xFF991B1B),
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 11,
                                                    fontFamily: "Roboto",
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),

                                      // DETAILS BUTTON
                                      DataCell(
                                        Center(
                                          child: InkWell(
                                            onTap: () => _showRemarksDialog(planId),
                                            borderRadius: BorderRadius.circular(6),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.receipt_long_outlined, size: 13, color: Color(0xFF334155)),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    S.of(context).view,
                                                    style: const TextStyle(
                                                      color: Color(0xFF334155),
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 11,
                                                      fontFamily: "Roboto",
                                                    ),
                                                  ),
                                                ],
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