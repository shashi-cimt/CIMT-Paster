import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:ui';
import 'package:canimage/Screens/home/dashboard_screen.dart';
import 'package:canimage/Screens/printSync/post_recca_print_sync_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive.dart';
import '../../Hive_Database/post_recca_image_upload_db.dart';
import '../../Hive_Database/execution_image_upload_db.dart';
import '../../Hive_Database/resend_db.dart';
import '../../Repository/execution_image_upload_repository.dart';
import '../../Repository/post_recca_image_upload_repository.dart';
import '../../Repository/execution_resend_repository.dart';
import '../../generated/l10n.dart';
import '../../utils/DeviceIdManager.dart';
import '../../utils/fonts.dart';
import '../../utils/security_guard_widget.dart';
import '../../utils/server_manager.dart';
import '../../utils/shared_preference.dart';
import '../../utils/token_manager.dart';
import '../../utils/textStyle.dart';
import '../ExecutionSeePlans/execution_map_screen.dart';
import '../ExecutionSeePlans/execution_see_plans.dart';
import '../ExecutionSeePlans/execution_sub_map_screen.dart';
import '../PostReccaPostPlan/post_recca_map_screen.dart';
import '../PostReccaPostPlan/post_recca_see_plans.dart';
import '../Rework/rework_see_plans.dart';
import '../WCC/wcc_screen.dart';
import '../auth/helpsupportscreen.dart';
import '../auth/login_screen.dart';
import '../printSync/execution_print_sync_screen.dart';
import '../resend/execution_resend_screen.dart';
import '../../widgets/can_image_loader.dart';

// State Management with Riverpod
final currentScreenProvider = StateProvider<String>((ref) => 'landing');
final userProvider = StateProvider<User?>((ref) => null);

// Additional providers for better state management
final isLoadingProvider = StateProvider<bool>((ref) => false);
final selectedPlanProvider = StateProvider<String?>((ref) => null);
final notificationCountProvider = StateProvider<int>((ref) => 5);
String? userName;
String? roleName;
String? userid;
String appVersion = "";
String buildNumber = "";

class User {
  final String name;
  final String email;
  final String? profileImage;

  User({required this.name, required this.email, this.profileImage});
}

class LandingScreen extends ConsumerStatefulWidget {
  final Function(String) changeLanguage;

  const LandingScreen({super.key, required this.changeLanguage});

  @override
  _LandingScreenState createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen>
    with WidgetsBindingObserver {
  var roleFlag;
  Locale _locale = Locale('en');
  String _selectedLanguage = 'en';
  int planCount = 0;
  int SUPlanCount = 0;
  int failedResendCount = 0;
  String? userID;
  String? uidDetails;

  bool _isZipping = false;
  bool _isEncrypting = false;
  final String encryptionPassword = "CIMTDWP_Secure_2024";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    roleFlagData();
    _loadLanguagePreference();
    loadUserData();
    loadSyncData();
    loadSyncDataSU();
    userDetails();
    _loadAppInfo();
    refreshPendingCounts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();

    setState(() {
      appVersion = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        refreshPendingCounts();
      }
    }
  }

  void loadUserData() async {
    userName = await getUserName();
    roleName = await getRoleName();
    userid = await getUserID();
    setState(() {});
  }

  void userDetails() async {
    userID = await getUserID();
    uidDetails = await getFirstUID();
  }

  Future<void> refreshPendingCounts() async {
    try {
      // Load from execution Hive
      List<ImageUploaddata> metadata =
          await ExecutionImageUploadHiveRepository().loadMetadata();

      // Load from resend Hive (failed items)
      final apiResponseRepo = ApiResponseRepository();
      List<ApiResponseData> failedResponses = await apiResponseRepo
          .getUniqueFailedResponses();
      failedResponses = failedResponses
          .where((item) => !item.isSuccess)
          .toList();

      if (mounted) {
        setState(() {
          planCount = metadata.length;
          failedResendCount = failedResponses.length;
        });
      }
    } catch (e) {
      print("Error refreshing counts: $e");
    }
  }

  int getTotalPendingCount() {
    int total = 0;
    if (roleFlag == "6") {
      total = planCount
      //    + failedResendCount
      ;
    } else if (roleFlag == "7") {
      total = SUPlanCount;
    }
    return total;
  }

  void loadSyncData() async {
    List<ImageUploaddata> metadata = await ExecutionImageUploadHiveRepository()
        .loadMetadata();
    planCount = metadata.length;
  }

  void loadSyncDataSU() async {
    List<SUImageUploaddata> metadata =
        await PostReccaImageUploadHiveRepository().loadSUMetadata();
    SUPlanCount = metadata.length;
  }

  void roleFlagData() async {
    roleFlag = await getRoleFlag();
  }

  void _initializeData() {}

  void _logout() async {
    ServerManager.resetAll();
    await TokenManager().logout();
    userName = null;
    roleName = null;
    userid = null;
    ref.read(pendingSyncCountProvider.notifier).state = 0;
    ref.read(pendingSyncCountProviderPlan.notifier).state = 0;
    ref.read(userProvider.notifier).state = null;
    Fluttertoast.showToast(
      msg: S.of(context).logoutTxt,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LoginScreen(changeLanguage: widget.changeLanguage),
      ),
      (Route<dynamic> route) => false,
    );
  }

  void _changeLanguage(String languageCode) async {
    setState(() {
      _locale = Locale(languageCode);
      _selectedLanguage = languageCode;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
    widget.changeLanguage(languageCode);
  }

  void _loadLanguagePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedLanguage = prefs.getString('language');
    if (savedLanguage != null) {
      setState(() {
        _locale = Locale(savedLanguage);
        _selectedLanguage = savedLanguage;
      });
    } else {
      setState(() {
        _locale = Locale('en');
        _selectedLanguage = 'en';
      });
    }
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Font.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.translate_rounded,
                              color: Font.primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  S.of(context).selectLanguage,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: "Roboto",
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Text(
                                  'Choose your preferred language',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                    fontFamily: "Roboto",
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF64748B),
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 18,
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 12),
                _buildLanguageOption('en', 'English', 'English'),
                _buildLanguageOption('hi', 'हिन्दी', 'Hindi'),
                _buildLanguageOption('gu', 'ગુજરાતી', 'Gujarati'),
                _buildLanguageOption('ta', 'தமிழ்', 'Tamil'),
                _buildLanguageOption('mr', 'मराठी', 'Marathi'),
                _buildLanguageOption('bn', 'বাংলা', 'Bengali'),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      S.of(context).close,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        fontFamily: "Roboto",
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(
    String languageCode,
    String nativeName,
    String englishName,
  ) {
    final bool isSelected = _selectedLanguage == languageCode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _changeLanguage(languageCode);
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? Font.primaryColor.withOpacity(0.08)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Font.primaryColor : const Color(0xFFE2E8F0),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        nativeName,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: isSelected
                              ? Font.primaryColor
                              : const Color(0xFF1E293B),
                          fontFamily: "Roboto",
                        ),
                      ),
                      if (nativeName != englishName) ...[
                        const SizedBox(width: 8),
                        Text(
                          '($englishName)',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isSelected
                                ? Font.primaryColor.withOpacity(0.8)
                                : const Color(0xFF64748B),
                            fontFamily: "Roboto",
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: isSelected
                      ? Font.primaryColor
                      : const Color(0xFF94A3B8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 92,
      height: 92,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF475569), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.person_rounded, size: 48, color: Colors.white),
      ),
    );
  }

  void _showAboutDialog() async {
    String profileImagePath = await getProfileImagePath();
    File? profileImage;
    if (profileImagePath.isNotEmpty) {
      final file = File(profileImagePath);
      if (file.existsSync() && file.lengthSync() > 0) {
        profileImage = file;
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          elevation: 12,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with Gradient
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Font.primaryColor, const Color(0xFF1E40AF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Avatar
                          Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: profileImage != null
                                  ? Image.file(
                                      profileImage,
                                      fit: BoxFit.cover,
                                      width: 92,
                                      height: 92,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              _buildDefaultAvatar(),
                                    )
                                  : _buildDefaultAvatar(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            userName?.trim().isNotEmpty == true
                                ? userName!
                                : "User",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              fontFamily: "Roboto",
                              letterSpacing: 0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              roleName?.trim().isNotEmpty == true
                                  ? roleName!
                                  : "User",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                fontFamily: "Roboto",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Close button on top-right of header
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Material(
                        color: Colors.transparent,
                        child: IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          onPressed: () => Navigator.pop(dialogContext),
                          splashRadius: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                // Details Card List
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildInfoCard(
                        icon: Icons.info_outline_rounded,
                        iconColor: const Color(0xFF2563EB),
                        title: S.of(context).appVersion,
                        value: "$appVersion ($buildNumber)",
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        icon: Icons.person_outline_rounded,
                        iconColor: const Color(0xFF10B981),
                        title: S.of(context).userId,
                        value: userID ?? 'N/A',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        icon: Icons.key_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        title: S.of(context).uid,
                        value: uidDetails ?? 'N/A',
                        onCopy: uidDetails != null && uidDetails!.isNotEmpty
                            ? () {
                                Clipboard.setData(
                                  ClipboardData(text: uidDetails!),
                                );
                                Fluttertoast.showToast(
                                  msg: "UID copied to clipboard",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                );
                              }
                            : null,
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Font.primaryColor,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            S.of(context).close,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: "Roboto",
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    VoidCallback? onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                    fontFamily: "Roboto",
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                    fontFamily: "Roboto",
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onCopy != null)
            Material(
              color: Colors.transparent,
              child: IconButton(
                icon: const Icon(
                  Icons.copy_rounded,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
                tooltip: "Copy",
                splashRadius: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onCopy,
              ),
            ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.power_settings_new_rounded,
                        color: Colors.red.shade600,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  S.of(context).logout,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: "Roboto",
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  S.of(context).wantToLogout,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.grey.shade600,
                    fontFamily: "Roboto",
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          S.of(context).noDashboard,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            fontFamily: "Roboto",
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _logout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          S.of(context).yesDashboard,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            fontFamily: "Roboto",
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _showExitConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Font.primaryColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Font.primaryColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.exit_to_app_rounded,
                        color: Font.primaryColor,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  S.of(context).exitApp,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: "Roboto",
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Are you sure you want to exit?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.grey.shade600,
                    fontFamily: "Roboto",
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          S.of(context).noDashboard,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            fontFamily: "Roboto",
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Font.primaryColor,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          S.of(context).yesDashboard,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            fontFamily: "Roboto",
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _handleBackPress() async {
    // 1. If any modal or screen on top can pop, pop it
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return false;
    }

    // 2. If user is inside a sub-tab (plans, dashboard, etc.), return to landing tab
    final currentScreen = ref.read(currentScreenProvider);
    if (currentScreen != 'landing') {
      ref.read(currentScreenProvider.notifier).state = 'landing';
      return false;
    }

    // 3. Show exit confirmation dialog
    final bool? shouldExit = await _showExitConfirmationDialog();
    if (shouldExit == true) {
      await SystemNavigator.pop();
      return true;
    }
    return false;
  }

  Future<String?> _zipLogsFolder({bool withEncryption = false}) async {
    try {
      Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        throw Exception('External storage directory not found');
      }
      Directory cimtdwpDir = Directory('${externalDir.path}/CIMTDWP');
      Directory logDir = Directory('${cimtdwpDir.path}/Logs/');
      if (!await logDir.exists()) {
        throw Exception('Logs directory not found');
      }
      List<String> foldersToZip = ['AppLogs', 'Print Logs', 'Sync Logs'];
      Directory tempDir = await getTemporaryDirectory();
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String zipPath =
          '${tempDir.path}/logs_$timestamp${withEncryption ? '_encrypted' : ''}.zip';
      var archive = Archive();
      int totalFiles = 0;
      for (String folderName in foldersToZip) {
        Directory folder = Directory('${logDir.path}/$folderName');
        if (await folder.exists()) {
          List<FileSystemEntity> files = folder.listSync(recursive: true);
          for (var entity in files) {
            if (entity is File) {
              var file = entity;
              String relativePath = file.path.replaceFirst(
                '${logDir.path}/',
                '',
              );
              List<int> fileBytes = await file.readAsBytes();
              if (withEncryption) {
                fileBytes = _encryptFileBytes(fileBytes);
                relativePath = relativePath + '.encrypted';
              }
              archive.addFile(
                ArchiveFile(relativePath, fileBytes.length, fileBytes),
              );
              totalFiles++;
            }
          }
        }
      }
      if (totalFiles == 0) {
        throw Exception(S.of(context).noLogFilesFoundFolders);
      }
      if (withEncryption) {
        String encryptionInfo =
            '''
Encrypted Log Files
===================
Encryption Date: ${DateTime.now().toString()}
Files Encrypted: $totalFiles
Encryption Method: AES-256-CBC

To decrypt these files:
1. Use the decryption password provided separately
2. Each file has .encrypted extension
3. Original file structure is preserved

Note: Keep the password secure and do not share publicly.
''';
        var infoBytes = utf8.encode(encryptionInfo);
        archive.addFile(
          ArchiveFile('ENCRYPTION_INFO.txt', infoBytes.length, infoBytes),
        );
      }
      var zipData = ZipEncoder().encode(archive);
      if (zipData != null) {
        File zipFile = File(zipPath);
        await zipFile.writeAsBytes(zipData);
        return zipPath;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  List<int> _encryptFileBytes(List<int> fileBytes) {
    try {
      final keyBytes = sha256.convert(utf8.encode(encryptionPassword)).bytes;
      final key = encrypt_pkg.Key(Uint8List.fromList(keyBytes));
      final iv = encrypt_pkg.IV.fromLength(16);
      final encrypter = encrypt_pkg.Encrypter(
        encrypt_pkg.AES(key, mode: encrypt_pkg.AESMode.cbc),
      );
      final encrypted = encrypter.encryptBytes(fileBytes, iv: iv);
      final combined = <int>[];
      combined.addAll(iv.bytes);
      combined.addAll(encrypted.bytes);
      return combined;
    } catch (e) {
      return fileBytes;
    }
  }

  Future<void> _shareLogsZip({bool withEncryption = false}) async {
    setState(() {
      if (withEncryption) {
        _isEncrypting = true;
      } else {
        _isZipping = true;
      }
    });
    try {
      String? zipPath = await _zipLogsFolder(withEncryption: withEncryption);
      if (zipPath != null) {
        await Share.shareXFiles(
          [XFile(zipPath)],
          subject: withEncryption
              ? 'Encrypted Logs - ${S.of(context).addPhoto}'
              : S.of(context).addPhoto,
          text: withEncryption
              ? 'Encrypted logs exported on ${DateTime.now().toString()}\nPassword required for decryption.'
              : 'Logs exported on ${DateTime.now().toString()}',
        );
        Fluttertoast.showToast(
          msg: withEncryption
              ? 'Encrypted logs shared successfully'
              : S.of(context).logsSharedSuccessfully,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } else {
        Fluttertoast.showToast(
          msg: S.of(context).failedLogsZipFile,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error sharing logs: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        _isZipping = false;
        _isEncrypting = false;
      });
    }
  }

  void _showLogs() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Font.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.article_rounded,
                              color: Font.primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  S.of(context).logs,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: "Roboto",
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Text(
                                  'Diagnostics & crash reports',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                    fontFamily: "Roboto",
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF64748B),
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 18,
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Share Action Cards
                Row(
                  children: [
                    // Standard Share
                    Expanded(
                      child: InkWell(
                        onTap: _isZipping || _isEncrypting
                            ? null
                            : () {
                                Navigator.pop(dialogContext);
                                _shareLogsZip(withEncryption: false);
                              },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Font.primaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Font.primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              _isZipping
                                  ? const CanImageSpinner(size: 22)
                                  : Icon(
                                      Icons.share_rounded,
                                      color: Font.primaryColor,
                                      size: 22,
                                    ),
                              const SizedBox(height: 6),
                              Text(
                                "Share Logs",
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Font.primaryColor,
                                  fontFamily: "Roboto",
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                "Standard Zip",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF64748B),
                                  fontFamily: "Roboto",
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Encrypted Share
                    Expanded(
                      child: InkWell(
                        onTap: _isEncrypting || _isZipping
                            ? null
                            : () {
                                Navigator.pop(dialogContext);
                                _shareLogsZip(withEncryption: true);
                              },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFFCD34D)),
                          ),
                          child: Column(
                            children: [
                              _isEncrypting
                                  ? const CanImageSpinner(size: 22)
                                  : const Icon(
                                      Icons.lock_rounded,
                                      color: Color(0xFFD97706),
                                      size: 22,
                                    ),
                              const SizedBox(height: 6),
                              const Text(
                                "Encrypted",
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFD97706),
                                  fontFamily: "Roboto",
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                "Password Protected",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF92400E),
                                  fontFamily: "Roboto",
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Security Note Banner
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.shield_outlined,
                        size: 16,
                        color: Color(0xFF475569),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Encrypted export secures log files with AES-256 password protection.",
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF475569),
                            fontFamily: "Roboto",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Log Files Title
                const Text(
                  "Recent Files",
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                    fontFamily: "Roboto",
                  ),
                ),
                const SizedBox(height: 6),

                // File list container
                Container(
                  height: 170,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: FutureBuilder<List<FileSystemEntity>>(
                    future: _getLogFiles(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CanImageSpinner(size: 28),
                        );
                      }
                      if (snapshot.hasError ||
                          !snapshot.hasData ||
                          snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.folder_open_rounded,
                                size: 36,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                S.of(context).noLogFilesFound,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontFamily: "Roboto",
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        itemCount: snapshot.data!.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        itemBuilder: (context, index) {
                          FileSystemEntity file = snapshot.data![index];
                          String fileName = file.path.split('/').last;
                          final bool isCrash = fileName.toLowerCase().contains(
                            'crash',
                          );
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            leading: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: isCrash
                                    ? Colors.red.shade50
                                    : Font.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isCrash
                                    ? Icons.bug_report_rounded
                                    : Icons.insert_drive_file_rounded,
                                size: 16,
                                color: isCrash
                                    ? Colors.red.shade600
                                    : Font.primaryColor,
                              ),
                            ),
                            title: Text(
                              fileName,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                                fontFamily: "Roboto",
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      S.of(context).close,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        fontFamily: "Roboto",
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<FileSystemEntity>> _getLogFiles() async {
    try {
      Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir == null) return [];
      Directory cimtdwpDir = Directory('${externalDir.path}/CIMTDWP');
      Directory logDir = Directory('${cimtdwpDir.path}/Logs/');
      if (!await logDir.exists()) return [];
      List<FileSystemEntity> allFiles = [];
      List<String> foldersToShow = ['AppLogs', 'Print Logs', 'Sync Logs'];
      for (String folderName in foldersToShow) {
        Directory folder = Directory('${logDir.path}/$folderName');
        if (await folder.exists()) {
          allFiles.addAll(folder.listSync(recursive: true));
        }
      }
      return allFiles
          .where(
            (entity) =>
                entity is File && entity.path.split('/').last != 'HMData.txt',
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentScreen = ref.watch(currentScreenProvider);
    final isLoading = ref.watch(isLoadingProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        await _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: currentScreen == 'plans' || currentScreen == 'dashboard'
            ? null
            : AppBar(
                backgroundColor: Font.primaryColor,
                elevation: 0,
                leading: Icon(
                  Icons.accessibility_new_rounded,
                  color: Font.primaryColor,
                ),
                leadingWidth: 0,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: SizedBox(
                        height: 38,
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  if (currentScreen != 'dashboard')
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Center(
                        child: Tooltip(
                          message: S.of(context).logout,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _showLogoutDialog,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.35),
                                    width: 1.2,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.power_settings_new_rounded,
                                    color: Font.orangeColor,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  PopupMenuButton<String>(
                    icon: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.35),
                          width: 1.2,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.more_vert_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    color: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    offset: const Offset(0, 44),
                    onSelected: (String value) {
                      switch (value) {
                        case 'about':
                          _showAboutDialog();
                          break;
                        case 'language':
                          _showLanguageDialog();
                          break;
                        case 'resend':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ResendScreen(
                                changeLanguage: widget.changeLanguage,
                              ),
                            ),
                          );
                          break;
                        case 'logs':
                          _showLogs();
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return [
                        PopupMenuItem<String>(
                          value: 'about',
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Font.primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                S.of(context).about,
                                style: TextstyleGlobal.bodyTextStyle,
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'language',
                          child: Row(
                            children: [
                              Icon(
                                Icons.language,
                                color: Font.primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                S.of(context).language,
                                style: TextstyleGlobal.bodyTextStyle,
                              ),
                            ],
                          ),
                        ),
                        if (roleFlag == "6")
                          PopupMenuItem(
                            value: 'resend',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.refresh,
                                  color: Font.primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  S.of(context).resend,
                                  style: TextstyleGlobal.bodyTextStyle,
                                ),
                              ],
                            ),
                          ),
                        PopupMenuItem<String>(
                          value: 'logs',
                          child: Row(
                            children: [
                              Icon(
                                Icons.list_alt,
                                color: Font.primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                S.of(context).logs,
                                style: TextstyleGlobal.bodyTextStyle,
                              ),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                  const SizedBox(width: 4),
                ],
              ),
        body: SafeArea(
          top: false,
          child: isLoading
              ? _buildLoadingScreen()
              : _buildCurrentScreen(context, ref, currentScreen),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Font.pureWhiteColor, Font.pureWhiteColor],
        ),
      ),
      child: Center(
        child: CanImageLoader(
          spinnerSize: 58,
          showBrand: true,
          message: S.of(context).loading,
        ),
      ),
    );
  }

  Widget _buildCurrentScreen(
    BuildContext context,
    WidgetRef ref,
    String screen,
  ) {
    switch (screen) {
      case 'landing':
        return _buildLandingPage(context, ref);
      case 'dashboard':
        return DashboardPage(changeLanguage: widget.changeLanguage);
      case 'plans':
        return SeePlanScreen(changeLanguage: widget.changeLanguage);
      case 'map':
        return SeePlanScreen(changeLanguage: widget.changeLanguage);
      case 'support':
        return SeePlanScreen(changeLanguage: widget.changeLanguage);
      default:
        return _buildLandingPage(context, ref);
    }
  }

  Widget _buildLandingPage(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${S.of(context).pendingSyncCount} ${getTotalPendingCount()}',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: "Roboto",
                color: Font.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(child: _buildMainContent(context, ref)),
          _buildFooter(context),
        ],
      ),
    );
  }

  void _showPendingSyncDialog(int pendingCount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(Icons.cloud_upload, color: Colors.orange[700], size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  S.of(context).pendingUploads,
                  style: TextStyle(
                    fontFamily: "Roboto",
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: Font.blueColor,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${S.of(context).youhave} $pendingCount ${S.of(context).pendingSynced}',
                style: TextStyle(
                  fontFamily: "Roboto",
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        S.of(context).pleaseSyncAllPending,
                        style: TextStyle(
                          fontFamily: "Roboto",
                          fontSize: 13,
                          color: Colors.orange[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                S.of(context).ok,
                style: TextStyle(
                  fontFamily: "Roboto",
                  color: Font.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMainContent(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: _buildNavigationButton(
                      title: S.of(context).seePlan,
                      icon: Icons.layers,
                      color: Font.blueColor,
                      onTap: () async {
                        if (roleFlag == "6") {
                          final uploadRepository =
                              ExecutionImageUploadHiveRepository();
                          final pendingUploads = await uploadRepository
                              .getAllMetadata();

                          final today = DateTime.now();
                          final todayDate = DateTime(
                            today.year,
                            today.month,
                            today.day,
                          );

                          bool hasOldPending = pendingUploads.any((item) {
                            if (item.createdAt == null) return false;

                            final uploadDate = DateTime(
                              item.createdAt!.year,
                              item.createdAt!.month,
                              item.createdAt!.day,
                            );

                            return uploadDate.isBefore(todayDate);
                          });

                          if (hasOldPending) {
                            _showPendingSyncDialog(pendingUploads.length);
                            return;
                          }
                        }

                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => roleFlag == "7"
                                ? SUSeePlanScreen(
                                    changeLanguage: widget.changeLanguage,
                                  )
                                : SeePlanScreen(
                                    changeLanguage: widget.changeLanguage,
                                  ),
                          ),
                        );

                        if (mounted) {
                          refreshPendingCounts();
                        }
                      },
                    ),
                  ),
                  roleFlag == "6"
                      ? Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: _buildNavigationButton(
                            title: roleFlag == "7"
                                ? "Work Completion Certificate"
                                : S.of(context).dashboard,
                            icon: Icons.dashboard,
                            color: Font.blueColor,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => roleFlag == "7"
                                      ? WCCSeePlanScreen(
                                          changeLanguage: widget.changeLanguage,
                                        )
                                      : DashboardPage(
                                          changeLanguage: widget.changeLanguage,
                                        ),
                                ),
                              );
                              if (mounted) {
                                refreshPendingCounts();
                              }
                            },
                          ),
                        )
                      : SizedBox.shrink(),
                  if (roleFlag == "6")
                    Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: _buildNavigationButton(
                        title: S.of(context).rework,
                        icon: Icons.refresh,
                        color: Colors.red,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReworkScreen(
                                changeLanguage: widget.changeLanguage,
                              ),
                            ),
                          );
                          if (mounted) {
                            refreshPendingCounts();
                          }
                        },
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: _buildNavigationButton(
                      title: S.of(context).seeMap,
                      icon: Icons.map_sharp,
                      color: Color(0xFF3B82F6),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => roleFlag == "7"
                                ? SUMapScreen(
                                    changeLanguage: widget.changeLanguage,
                                  )
                                : SubMapScreen(
                                    planCode: '',
                                    VillageCode: '',
                                    ServerID: '',
                                    changeLanguage: widget.changeLanguage,
                                    height: "",
                                    width: "",
                                    villageName: "",
                                    brand: "",
                                    tensil: '',
                                    artworkId: "",
                                  ),
                          ),
                        );
                        if (mounted) {
                          refreshPendingCounts();
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: _buildNavigationButton(
                      title: S.of(context).helpSupport,
                      icon: Icons.headset_mic,
                      color: Color(0xFF3B82F6),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HelpSupportScreen(
                              changeLanguage: widget.changeLanguage,
                            ),
                          ),
                        );
                        if (mounted) {
                          refreshPendingCounts();
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: _buildNavigationButton(
                      title: S.of(context).printSync,
                      icon: Icons.sync,
                      color: Color(0xFF3B82F6),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => roleFlag == "7"
                                ? SUPrintSyncScreen(
                                    changeLanguage: widget.changeLanguage,
                                  )
                                : PrintSyncScreen(
                                    changeLanguage: widget.changeLanguage,
                                  ),
                          ),
                        );
                        if (mounted) {
                          refreshPendingCounts();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Font.primaryColor.withOpacity(0.06),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: Font.primaryColor.withOpacity(0.08),
          highlightColor: Font.primaryColor.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Font.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(icon, size: 22, color: Font.primaryColor),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: Font.primaryColor,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Font.orangeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: Font.orangeColor,
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

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Text(
              S.of(context).copyRights,
              style: TextStyle(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                fontFamily: 'Roboto',
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            S.of(context).version,
            style: TextStyle(
              color: Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              fontFamily: 'Roboto',
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
