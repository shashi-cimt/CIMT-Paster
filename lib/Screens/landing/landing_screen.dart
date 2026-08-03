
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
import '../../utils/shared_preference.dart';
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

class _LandingScreenState extends ConsumerState<LandingScreen> with WidgetsBindingObserver {
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
      List<ImageUploaddata> metadata = await ExecutionImageUploadHiveRepository().loadMetadata();

      // Load from resend Hive (failed items)
      final apiResponseRepo = ApiResponseRepository();
      List<ApiResponseData> failedResponses = await apiResponseRepo.getUniqueFailedResponses();
      failedResponses = failedResponses.where((item) => !item.isSuccess).toList();

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
      total = planCount + failedResendCount;
    } else if (roleFlag == "7") {
      total = SUPlanCount ;
    }
    return total;
  }

  void loadSyncData() async {
    List<ImageUploaddata> metadata = await ExecutionImageUploadHiveRepository().loadMetadata();
    planCount = metadata.length;
  }

  void loadSyncDataSU() async {
    List<SUImageUploaddata> metadata = await PostReccaImageUploadHiveRepository().loadSUMetadata();
    SUPlanCount = metadata.length;
  }

  void roleFlagData() async {
    roleFlag = await getRoleFlag();
  }

  void _initializeData() {}

  void _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    ref.read(pendingSyncCountProvider.notifier).state = 0;
    ref.read(pendingSyncCountProviderPlan.notifier).state = 0;
    Fluttertoast.showToast(
      msg: S.of(context).logoutTxt,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(changeLanguage: widget.changeLanguage),
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
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).selectLanguage, style: TextstyleGlobal.headerTextStyle.copyWith(fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption('en', 'English'),
              _buildLanguageOption('hi', 'Hindi'),
              _buildLanguageOption('gu', 'Gujarati'),
              _buildLanguageOption('ta', 'Tamil'),
              _buildLanguageOption('mr', 'Marathi'),
              _buildLanguageOption('bn', 'Bengali'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(S.of(context).close, style: TextStyle(color: Font.primaryColor)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageOption(String languageCode, String languageName) {
    return ListTile(
      dense: true,
      leading: _selectedLanguage == languageCode
          ? Icon(Icons.check, color: Font.primaryColor)
          : SizedBox(width: 24),
      title: Text(languageName, style: TextstyleGlobal.bodyTextStyle),
      onTap: () {
        _changeLanguage(languageCode);
        Navigator.pop(context);
      },
    );
  }

  void _showAboutDialog() async {
    String profileImagePath = await getProfileImagePath();
    File? profileImage;
    if (profileImagePath.isNotEmpty && File(profileImagePath).existsSync()) {
      profileImage = File(profileImagePath);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Font.primaryColor.withOpacity(0.05),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Font.primaryColor,
                        Font.primaryColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 15,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: profileImage != null
                                  ? Image.file(
                                profileImage,
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                              )
                                  : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.grey[300]!,
                                      Colors.grey[200]!,
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text(
                        userName?.trim().isNotEmpty == true ? userName! : "N/A",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Roboto",
                        ),
                      ),
                      Text(
                        userName?.trim().isNotEmpty == true ? roleName! : "N/A",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Roboto",
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildInfoCard(
                        icon: Icons.info_outline,
                        iconColor: Colors.blue,
                        title: S.of(context).appVersion,
                          value: "$appVersion ($buildNumber)",
                      ),
                      SizedBox(height: 12),
                      _buildInfoCard(
                        icon: Icons.person_outline,
                        iconColor: Colors.green,
                        title: S.of(context).userId,
                        value: userID ?? 'N/A',
                      ),
                      SizedBox(height: 12),
                      _buildInfoCard(
                        icon: Icons.key                ,
                        iconColor: Colors.orange,
                        title: S.of(context).uid,
                        value: uidDetails ?? 'N/A',
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
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: iconColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: "Roboto",
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.black87,
                    fontFamily: "Roboto",
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("${S.of(context).logout}!!!", style: TextstyleGlobal.headerTextStyle.copyWith(fontSize: 18)),
          content: Text(S.of(context).wantToLogout, style: TextstyleGlobal.bodyTextStyle),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(S.of(context).noDashboard, style: TextStyle(color: Font.primaryColor)),
            ),
            TextButton(
              onPressed: () {
                _logout();
              },
              child: Text(S.of(context).yesDashboard, style: TextStyle(color: Font.primaryColor)),
            ),
          ],
        );
      },
    );
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
      String zipPath = '${tempDir.path}/logs_$timestamp${withEncryption ? '_encrypted' : ''}.zip';
      var archive = Archive();
      int totalFiles = 0;
      for (String folderName in foldersToZip) {
        Directory folder = Directory('${logDir.path}/$folderName');
        if (await folder.exists()) {
          List<FileSystemEntity> files = folder.listSync(recursive: true);
          for (var entity in files) {
            if (entity is File) {
              var file = entity;
              String relativePath = file.path.replaceFirst('${logDir.path}/', '');
              List<int> fileBytes = await file.readAsBytes();
              if (withEncryption) {
                fileBytes = _encryptFileBytes(fileBytes);
                relativePath = relativePath + '.encrypted';
              }
              archive.addFile(ArchiveFile(relativePath, fileBytes.length, fileBytes));
              totalFiles++;
            }
          }
        }
      }
      if (totalFiles == 0) {
        throw Exception(S.of(context).noLogFilesFoundFolders);
      }
      if (withEncryption) {
        String encryptionInfo = '''
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
        archive.addFile(ArchiveFile('ENCRYPTION_INFO.txt', infoBytes.length, infoBytes));
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
          encrypt_pkg.AES(key, mode: encrypt_pkg.AESMode.cbc)
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
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(S.of(context).logs, style: TextstyleGlobal.headerTextStyle.copyWith(fontSize: 18)),
              Row(
                children: [
                  IconButton(
                    icon: _isEncrypting
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    )
                        : Icon(Icons.lock, color: Colors.orange),
                    onPressed: _isEncrypting || _isZipping ? null : () {
                      Navigator.pop(context);
                      _shareLogsZip(withEncryption: true);
                    },
                    tooltip: 'Share Encrypted Logs',
                  ),
                  IconButton(
                    icon: _isZipping
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Font.primaryColor),
                      ),
                    )
                        : Icon(Icons.share, color: Font.primaryColor),
                    onPressed: _isZipping || _isEncrypting ? null : () {
                      Navigator.pop(context);
                      _shareLogsZip(withEncryption: false);
                    },
                    tooltip: 'Share Logs',
                  ),
                ],
              ),
            ],
          ),
          content: Container(
            height: 250,
            width: double.maxFinite,
            child: Column(
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
                              'Export Options:',
                              style: TextstyleGlobal.bodyTextStyle.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        ' Normal: Share logs as-is\n Encrypted: Secure logs with password protection',
                        style: TextstyleGlobal.bodyTextStyle.copyWith(
                          fontSize: 11,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<List<FileSystemEntity>>(
                    future: _getLogFiles(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Text(
                            S.of(context).noLogFilesFound,
                            style: TextstyleGlobal.bodyTextStyle.copyWith(fontSize: 12),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          FileSystemEntity file = snapshot.data![index];
                          String fileName = file.path.split('/').last;
                          return ListTile(
                            dense: true,
                            leading: Icon(Icons.insert_drive_file, size: 20, color: Font.primaryColor),
                            title: Text(
                              fileName,
                              style: TextstyleGlobal.bodyTextStyle.copyWith(fontSize: 11),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(S.of(context).close, style: TextStyle(color: Font.primaryColor)),
            ),
          ],
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
          .where((entity) => entity is File && entity.path.split('/').last != 'HMData.txt')
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentScreen = ref.watch(currentScreenProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final pendingCount = ref.watch(pendingSyncCountProvider);

    return SafeArea(
      child: Scaffold(
        appBar: currentScreen == 'plans' || currentScreen == 'dashboard'
            ? null
            : AppBar(
          backgroundColor: Font.primaryColor,
          leading: Icon(Icons.accessibility_new_rounded, color: Font.primaryColor),
          leadingWidth: 0,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical:4 ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(0),
                ),
                child: SizedBox(
                  height: 40,
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
              InkWell(
                onTap: () {
                  _showLogoutDialog();
                },
                child: Container(
                  height: 35,
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Icon(Icons.power_settings_new, color: Font.orangeColor)),
                ),
              ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Font.blueColor),
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
                      MaterialPageRoute(builder: (context) => ResendScreen(changeLanguage: widget.changeLanguage)),
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
                        Icon(Icons.info_outline, color: Font.primaryColor),
                        SizedBox(width: 12),
                        Text(S.of(context).about, style: TextstyleGlobal.bodyTextStyle),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'language',
                    child: Row(
                      children: [
                        Icon(Icons.language, color: Font.primaryColor),
                        SizedBox(width: 12),
                        Text(S.of(context).language, style: TextstyleGlobal.bodyTextStyle),
                      ],
                    ),
                  ),
                  if (roleFlag == "6")
                    PopupMenuItem(
                      value: 'resend',
                      child: Row(
                        children: [
                          Icon(Icons.refresh, color: Font.primaryColor),
                          SizedBox(width: 12),
                          Text(S.of(context).resend, style: TextstyleGlobal.bodyTextStyle),
                        ],
                      ),
                    ),
                  PopupMenuItem<String>(
                    value: 'logs',
                    child: Row(
                      children: [
                        Icon(Icons.list_alt, color: Font.primaryColor),
                        SizedBox(width: 12),
                        Text(S.of(context).logs, style: TextstyleGlobal.bodyTextStyle),
                      ],
                    ),
                  ),
                ];
              },
            )
          ],
        ),
        body: isLoading
            ? _buildLoadingScreen()
            : _buildCurrentScreen(context, ref, currentScreen),
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
        child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
      ),
    );
  }

  Widget _buildCurrentScreen(BuildContext context, WidgetRef ref, String screen) {
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
    final user = ref.watch(userProvider);
    final notificationCount = ref.watch(notificationCountProvider);

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Font.pureWhiteColor, Font.pureWhiteColor, Font.pureWhiteColor],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
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
                SizedBox(height: 20),
                Expanded(child: _buildMainContent(context, ref)),
                _buildFooter(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showPendingSyncDialog(int pendingCount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
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
                            final uploadRepository = ExecutionImageUploadHiveRepository();
                            final pendingUploads = await uploadRepository.getAllMetadata();

                            final today = DateTime.now();
                            final todayDate = DateTime(today.year, today.month, today.day);

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
                                  ? SUSeePlanScreen(changeLanguage: widget.changeLanguage)
                                  : SeePlanScreen(changeLanguage: widget.changeLanguage),
                            ),
                          );

                          if (mounted) {
                            refreshPendingCounts();
                          }
                        }
                    ),
                  ),
                  roleFlag == "6"
                      ? Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: _buildNavigationButton(
                      title: roleFlag == "7" ? "Work Completion Certificate" : S.of(context).dashboard,
                      icon: Icons.dashboard,
                      color: Font.blueColor,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => roleFlag == "7"
                                ? WCCSeePlanScreen(changeLanguage: widget.changeLanguage)
                                : DashboardPage(changeLanguage: widget.changeLanguage),
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
                              builder: (context) => ReworkScreen(changeLanguage: widget.changeLanguage),
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
                                ? SUMapScreen(changeLanguage: widget.changeLanguage)
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
                            builder: (context) => HelpSupportScreen(changeLanguage: widget.changeLanguage),
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
                                ? SUPrintSyncScreen(changeLanguage: widget.changeLanguage)
                                : PrintSyncScreen(changeLanguage: widget.changeLanguage),
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
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Font.whiteblue,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                textStyle: TextStyle(fontFamily: 'Roboto'),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 24,color: Font.primaryColor,),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            color: Font.primaryColor,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Font.orangeColor,),
                ],
              ),
            ),
          ),
        ],
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
        ],
      ),
    );
  }
}