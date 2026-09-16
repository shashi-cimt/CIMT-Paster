import 'dart:io';
import 'package:canimage/Screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../APIService/auth_service.dart';
import '../../Model/registration_model.dart';
import '../../generated/l10n.dart';
import '../../utils/crash_manager.dart';
import '../../utils/fonts.dart';
import '../../utils/image_orientation_utils.dart';
import '../../utils/shared_preference.dart';
import '../../utils/uid_file_helper.dart';
import '../../widgets/can_image_loader.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  final Function(String) changeLanguage;

  const RegistrationScreen({super.key, required this.changeLanguage});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

final List<String> countryCodes = ['+91', '+65', '+1', '+44'];
bool isRememberMeChecked = false;

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  String selectedCountryCode = countryCodes[0];
  String? getUIDNumber;
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController uidController = TextEditingController();
  bool isPasswordVisible = false;
  bool isLoading = false;

  String selectedRole = '';
  int selectedRoleId = 0;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadSavedProfileImage();
  }

  Future<void> _loadSavedProfileImage() async {
    String savedImagePath = await getProfileImagePath();
    if (savedImagePath.isNotEmpty && File(savedImagePath).existsSync()) {
      setState(() {
        _selectedImage = File(savedImagePath);
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        _showToast(
          'Camera permission is required to take profile photo',
          Colors.red,
        );
        return;
      }
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        File tempImage = File(image.path);

        // Normalize orientation to vertical portrait and bake EXIF tags
        await ImageOrientationUtils.normalizeImageFile(tempImage);

        // Save to permanent location
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String profileDir = '${appDir.path}/profiles';
        await Directory(profileDir).create(recursive: true);

        final String fileName =
            'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String newPath = '$profileDir/$fileName';

        final File newImage = await tempImage.copy(newPath);

        setState(() {
          _selectedImage = newImage;
        });

        // Save to SharedPreferences
        await setProfileImagePath(newPath);

        _showToast('Profile picture saved!', Colors.green);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showToast('Failed to save image', Colors.red);
    }
  }

  Future<void> _deleteProfileImage() async {
    try {
      if (_selectedImage != null && await _selectedImage!.exists()) {
        await _selectedImage!.delete();
      }
    } catch (e) {
      debugPrint('Error deleting local profile image: $e');
    }
    await setProfileImagePath('');
    setState(() {
      _selectedImage = null;
    });
    _showToast('Profile photo removed', Colors.black87);
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Wrap(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Font.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.photo_camera_rounded,
                      color: Font.primaryColor,
                    ),
                  ),
                  title: const Text(
                    'Take Photo',
                    style: TextStyle(
                      fontFamily: "Roboto",
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Font.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.photo_library_rounded,
                      color: Font.primaryColor,
                    ),
                  ),
                  title: const Text(
                    'Choose from Gallery',
                    style: TextStyle(
                      fontFamily: "Roboto",
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (_selectedImage != null)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                      ),
                    ),
                    title: const Text(
                      'Remove Photo',
                      style: TextStyle(
                        fontFamily: "Roboto",
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _deleteProfileImage();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  _showToast(String message, Color color) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: color,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  // NEW: Get UID from role-specific folder (CIMTDWP for Pastor, CIMTDWPSUP for Supervisor)
  Future<String?> _getRoleSpecificUID(int roleId) async {
    try {
      Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        return null;
      }

      // Determine folder based on role
      // roleId 6 = Pastor -> CIMTDWP
      // roleId 7 = Supervisor -> CIMTDWPSUP
      String folderName = (roleId == 6) ? 'CIMTDWP' : 'CIMTDWPSUP';
      File uidFile = File('${externalDir.path}/$folderName/Appfiles/UID.txt');

      String? uid = UidFileHelper.canonicalize(
        await UidFileHelper.readRawUidContent(uidFile),
      );
      if (uid != null && uid.isNotEmpty) {
        return uid;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<File?> _saveProfileImageToRoleFolder(
    File imageFile,
    int roleId,
    String uid,
  ) async {
    try {
      Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        return null;
      }

      String folderName = (roleId == 6) ? 'CIMTDWP' : 'CIMTDWPSUP';
      Directory roleDir = Directory(
        '${externalDir.path}/$folderName/UserImage',
      );
      if (!await roleDir.exists()) {
        await roleDir.create(recursive: true);
      }

      String ext = p.extension(imageFile.path);
      if (ext.isEmpty) ext = '.jpg';

      String targetPath = '${roleDir.path}/$uid$ext';
      File savedImage = await imageFile.copy(targetPath);

      await setProfileImagePath(savedImage.path);
      return savedImage;
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveUidWithUserId(
    String androidId,
    String userId,
    int roleId,
  ) async {
    try {
      Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        return;
      }

      String folderName = (roleId == 6) ? 'CIMTDWP' : 'CIMTDWPSUP';
      Directory roleDir = Directory('${externalDir.path}/$folderName/Appfiles');
      if (!await roleDir.exists()) {
        await roleDir.create(recursive: true);
      }

      final bareAndroidId = androidId.contains('|')
          ? androidId.split('|').first.trim()
          : androidId;

      File uidFile = File('${roleDir.path}/UID.txt');
      await uidFile.writeAsString('$bareAndroidId|$userId');
    } catch (e) {
      debugPrint('Failed to save UID mapping: $e');
    }
  }

  Future<String?> _getSavedUserIdForDevice(String androidId, int roleId) async {
    try {
      Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        return null;
      }

      String folderName = (roleId == 6) ? 'CIMTDWP' : 'CIMTDWPSUP';
      File uidFile = File('${externalDir.path}/$folderName/Appfiles/UID.txt');
      if (!await uidFile.exists()) {
        return null;
      }

      final content = await uidFile.readAsString();
      if (content.contains('|')) {
        final parts = content.split('|');
        if (parts.length >= 2) {
          final savedAndroidId = parts.first.trim();
          final savedUserId = parts.last.trim();

          final bareAndroidId = androidId.contains('|')
              ? androidId.split('|').first.trim()
              : androidId;

          if (savedAndroidId == bareAndroidId && savedUserId.isNotEmpty) {
            return savedUserId;
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('Failed to read UID mapping: $e');
      return null;
    }
  }

  RegistrationAuthModel? registrationAuthModel;

  register(
    String firstname,
    String lastName,
    String phoneNo,
    String password,
    int roleId,
    File? profileImage,
  ) async {
    if (firstname.isEmpty) {
      _showToast(S.of(context).firstNameVal, Colors.red);
      return;
    }
    if (lastName.isEmpty) {
      _showToast(S.of(context).lastNameVal, Colors.red);
      return;
    }
    if (phoneNo.length != 10) {
      _showToast(S.of(context).loginPhVal, Colors.red);
      return;
    }
    if (password.length < 6) {
      _showToast(S.of(context).loginPassVal, Colors.red);
      return;
    }
    if (roleId == 0) {
      _showToast(S.of(context).selectRole, Colors.red);
      return;
    }
    if (profileImage == null) {
      _showToast("Please select the profile picture", Colors.red);
      return;
    }

    setState(() {
      isLoading = true;
    });

    final maskedPhone = phoneNo.length >= 4
        ? 'xxxxxx${phoneNo.substring(phoneNo.length - 4)}'
        : phoneNo;
    await CrashReportManager.logUserEvent(
      'registration_attempt',
      details: {'phone': maskedPhone, 'roleId': roleId},
    );

    // Get role-specific UID from the appropriate folder
    String? roleSpecificUID = await _getRoleSpecificUID(roleId);

    if (roleSpecificUID == null) {
      setState(() {
        isLoading = false;
      });
      await CrashReportManager.logUserEvent(
        'registration_failed',
        details: {'phone': maskedPhone, 'reason': 'unable_to_get_uid'},
      );
      _showErrorDialog('${S.of(context).unableUID}');
      return;
    }

    final existingUserId = await _getSavedUserIdForDevice(
      roleSpecificUID,
      roleId,
    );
    if (existingUserId != null && existingUserId.isNotEmpty) {
      setState(() {
        isLoading = false;
      });
      await CrashReportManager.logUserEvent(
        'registration_failed',
        details: {
          'phone': maskedPhone,
          'reason': 'device_already_registered',
          'UID': roleSpecificUID,
        },
      );
      _showErrorDialog('This device is Already Register ');
      return;
    }

    // Save the role-specific UID to shared preferences
    setFirstUID(roleSpecificUID);

    Auth()
        .registration(
          firstname,
          lastName,
          phoneNo,
          password,
          roleSpecificUID,
          roleId.toString(),
          userImage: profileImage,
        )
        .then((value) async {
          setState(() {
            isLoading = false;
          });

          if (value != null) {
            registrationAuthModel = value;
            if (registrationAuthModel!.isSuccess == true &&
                registrationAuthModel!.data?.userId != null) {
              setUserId(value.data!.userId.toString());

              String roleName = (roleId == 6) ? 'Pastor' : 'Supervisor';
              if (profileImage != null) {
                await _saveProfileImageToRoleFolder(
                  profileImage,
                  roleId,
                  roleSpecificUID,
                );
              }

              await _saveUidWithUserId(
                roleSpecificUID,
                value.data!.userId.toString(),
                roleId,
              );

              await CrashReportManager.logUserEvent(
                'registration_success',
                details: {
                  'phone': maskedPhone,
                  'role': roleName,
                  'roleId': roleId,
                  'userId': value.data!.userId.toString(),
                  'UID': roleSpecificUID,
                },
              );

              if (!mounted) return;
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    S.of(context).success,
                    style: const TextStyle(
                      fontFamily: "Roboto",
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  content: Text(
                    "${S.of(context).registerSuccess}: ${value.data!.userId}\n"
                    "${S.of(context).role}: $roleName\n"
                    "${S.of(context).uid}: $roleSpecificUID",
                    style: TextStyle(
                      fontFamily: "Roboto",
                      color: Colors.grey[600],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        _navigateToLogin();
                      },
                      child: Text(
                        S.of(context).ok,
                        style: TextStyle(
                          fontFamily: "Roboto",
                          color: Font.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              String errorMessage =
                  value.message ?? S.of(context).registrationFailed;
              CrashReportManager.logUserEvent(
                'registration_failed',
                details: {
                  'phone': maskedPhone,
                  'reason': 'server_rejected',
                  'message': errorMessage,
                },
              );
              _showErrorDialog(errorMessage);
            }
          } else {
            CrashReportManager.logUserEvent(
              'registration_failed',
              details: {'phone': maskedPhone, 'reason': 'no_server_response'},
            );
            _showErrorDialog("${S.of(context).unableServer}");
          }
        })
        .catchError((e) {
          setState(() {
            isLoading = false;
          });
          CrashReportManager.logUserEvent(
            'registration_failed',
            details: {
              'phone': maskedPhone,
              'reason': 'exception',
              'error': e.toString(),
            },
          );
          _showErrorDialog("${S.of(context).errorOccurredRegstration}");
        });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          S.of(context).failure,
          style: const TextStyle(
            fontFamily: "Roboto",
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(fontFamily: "Roboto", color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              S.of(context).ok,
              style: TextStyle(fontFamily: "Roboto", color: Font.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToLogin() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              LoginScreen(changeLanguage: widget.changeLanguage),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _navigateToLogin();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Top Navigation Bar: Back arrow and Brand Logo
                  Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: _navigateToLogin,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Image.asset(
                        'assets/logo.png',
                        height: 38,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Header
                  Text(
                    S.of(context).registerBut,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.4,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Please enter your details to create an Account.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.1,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Profile Picture Section
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            GestureDetector(
                              onTap: _showImagePickerOptions,
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFF8FAFC),
                                  border: Border.all(
                                    color: Font.primaryColor,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Font.primaryColor
                                          .withValues(alpha: 0.18),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: _selectedImage != null
                                      ? Image.file(
                                          _selectedImage!,
                                          fit: BoxFit.cover,
                                          width: 90,
                                          height: 90,
                                        )
                                      : const Icon(
                                          Icons.person_rounded,
                                          size: 50,
                                          color: Color(0xFF94A3B8),
                                        ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _showImagePickerOptions,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Font.primaryColor,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.18),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_selectedImage == null)
                          const Text(
                            'Add profile picture',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        else
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: Colors.green.shade600,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Photo added',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 12,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '•',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _deleteProfileImage,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.delete_outline_rounded,
                                      size: 14,
                                      color: Colors.red.shade600,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Remove',
                                      style: TextStyle(
                                        color: Colors.red.shade600,
                                        fontSize: 12,
                                        fontFamily: 'Roboto',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // First Name & Last Name (Side by Side)
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              S.of(context).firstName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                                fontFamily: 'Roboto',
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: firstNameController,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF0F172A),
                                fontFamily: 'Roboto',
                              ),
                              decoration: InputDecoration(
                                hintText: S.of(context).firstNameTxt,
                                hintStyle: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 13.5,
                                  fontFamily: 'Roboto',
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 13,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                    width: 1.2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Font.primaryColor,
                                    width: 1.6,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              S.of(context).lastName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                                fontFamily: 'Roboto',
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: lastNameController,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF0F172A),
                                fontFamily: 'Roboto',
                              ),
                              decoration: InputDecoration(
                                hintText: S.of(context).lastNameTxt,
                                hintStyle: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 13.5,
                                  fontFamily: 'Roboto',
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 13,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                    width: 1.2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Font.primaryColor,
                                    width: 1.6,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Phone Number
                  Text(
                    S.of(context).phoneNoOnly,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: phoneNumberController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0F172A),
                      fontFamily: 'Roboto',
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: S.of(context).phoneNoOnlyTxt,
                      hintStyle: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13.5,
                        fontFamily: 'Roboto',
                      ),
                      prefixIcon: const Icon(
                        Icons.phone_iphone_rounded,
                        size: 20,
                        color: Color(0xFF64748B),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Font.primaryColor,
                          width: 1.6,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Password
                  Text(
                    S.of(context).password,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: passwordController,
                    obscureText: !isPasswordVisible,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0F172A),
                      fontFamily: 'Roboto',
                    ),
                    decoration: InputDecoration(
                      hintText: S.of(context).enterPass,
                      hintStyle: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13.5,
                        fontFamily: 'Roboto',
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        size: 20,
                        color: Color(0xFF64748B),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          size: 20,
                          color: const Color(0xFF64748B),
                        ),
                        onPressed: () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Font.primaryColor,
                          width: 1.6,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Role (Segmented Pill Selector)
                  Text(
                    S.of(context).role,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Builder(
                    builder: (context) {
                      final bool isPastorSelected = selectedRoleId == 6 ||
                          (selectedRole.isNotEmpty &&
                              selectedRole == S.of(context).pastor);
                      final bool isSupervisorSelected = selectedRoleId == 7 ||
                          (selectedRole.isNotEmpty &&
                              selectedRole == S.of(context).supervisor);

                      return Container(
                        height: 48,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            // Pastor (roleId = 6)
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(9),
                                  onTap: () {
                                    setState(() {
                                      selectedRole = S.of(context).pastor;
                                      selectedRoleId = 6;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 180),
                                    curve: Curves.easeInOut,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isPastorSelected
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(9),
                                      boxShadow: isPastorSelected
                                          ? [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.06),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          isPastorSelected
                                              ? Icons.check_circle_rounded
                                              : Icons.circle_outlined,
                                          size: 16,
                                          color: isPastorSelected
                                              ? Font.primaryColor
                                              : const Color(0xFF94A3B8),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            S.of(context).pastor,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isPastorSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                              color: isPastorSelected
                                                  ? Font.primaryColor
                                                  : const Color(0xFF64748B),
                                              fontFamily: 'Roboto',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // CanImage User / Supervisor (roleId = 7)
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(9),
                                  onTap: () {
                                    setState(() {
                                      selectedRole = S.of(context).supervisor;
                                      selectedRoleId = 7;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 180),
                                    curve: Curves.easeInOut,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSupervisorSelected
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(9),
                                      boxShadow: isSupervisorSelected
                                          ? [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.06),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          isSupervisorSelected
                                              ? Icons.check_circle_rounded
                                              : Icons.circle_outlined,
                                          size: 16,
                                          color: isSupervisorSelected
                                              ? Font.primaryColor
                                              : const Color(0xFF94A3B8),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            S.of(context).supervisor,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isSupervisorSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                              color: isSupervisorSelected
                                                  ? Font.primaryColor
                                                  : const Color(0xFF64748B),
                                              fontFamily: 'Roboto',
                                            ),
                                          ),
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

                  const SizedBox(height: 26),

                  // Register Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              register(
                                firstNameController.text,
                                lastNameController.text,
                                phoneNumberController.text,
                                passwordController.text,
                                selectedRoleId,
                                _selectedImage,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Font.primaryColor,
                        disabledBackgroundColor:
                            Font.primaryColor.withValues(alpha: 0.65),
                        foregroundColor: Colors.white,
                        elevation: 1,
                        shadowColor: Font.primaryColor.withValues(alpha: 0.35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const CanImageSpinner(
                              size: 22,
                              primaryColor: Colors.white70,
                              accentColor: Colors.white,
                            )
                          : Text(
                              S.of(context).registerBtn,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.3,
                                fontFamily: 'Roboto',
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Footer: Already have an account? Login
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          S.of(context).alreadyAcct,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: _navigateToLogin,
                          child: Text(
                            S.of(context).login,
                            style: TextStyle(
                              color: Font.primaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}
