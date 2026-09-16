import 'dart:async';
import 'package:canimage/Screens/auth/registration_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../APIService/auth_service.dart';
import '../../generated/l10n.dart';
import '../../utils/DeviceIdManager.dart';
import '../../utils/crash_manager.dart';
import '../../utils/fonts.dart';
import '../../utils/inactivity_detector.dart';
import '../../utils/shared_preference.dart';
import '../../utils/token_manager.dart';
import '../../utils/uid_file_helper.dart';
import '../landing/landing_screen.dart';
import '../../widgets/can_image_loader.dart';
import '../../widgets/app_snack_bar.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final Function(String) changeLanguage;

  const LoginScreen({super.key, required this.changeLanguage});
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

final List<String> countryCodes = ['+91', '+65', '+1', '+44'];

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool isRememberMeChecked = false;
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String selectedCountryCode = countryCodes[0];
  bool isPasswordVisible = false;
  bool isLoading = false;
  String? userID;
  String? uidDetails;

  // NEW: Role selection variables
  String selectedRole = '';
  int selectedRoleId = 0;
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    userDetails();
    _loadRememberedData();
  }

  _loadRememberedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isRemembered = prefs.getBool('rememberMe') ?? false;

    if (isRemembered) {
      setState(() {
        phoneNumberController.text = prefs.getString('phoneNumber') ?? '';
        passwordController.text = prefs.getString('password') ?? '';
        isRememberMeChecked = true;
        // Load saved role if exists
        String? savedRole = prefs.getString('selectedRole');
        int? savedRoleId = prefs.getInt('selectedRoleId');
        if (savedRole != null && savedRoleId != null) {
          selectedRole = savedRole;
          selectedRoleId = savedRoleId;
        }
      });
    }
  }

  _saveRememberedData(String phoneNumber, String password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('rememberMe', isRememberMeChecked);
    if (isRememberMeChecked) {
      prefs.setString('phoneNumber', phoneNumber);
      prefs.setString('password', password);
      prefs.setString('selectedRole', selectedRole);
      prefs.setInt('selectedRoleId', selectedRoleId);
    } else {
      prefs.remove('phoneNumber');
      prefs.remove('password');
      prefs.remove('selectedRole');
      prefs.remove('selectedRoleId');
    }
  }

  void _showTopSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    AppSnackBar.showTopSnackBar(
      context,
      message,
      isError: isError,
      duration: const Duration(seconds: 3),
    );
  }

  void userDetails() async {
    userID = await getUserID();
    if (userID != null && userID!.isEmpty) {
      userID = null;
    }
  }

  // NEW: Get UID from role-specific folder based on selected role
  Future<String?> _getRoleSpecificUID(int roleId) async {
    try {
      Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        String folderName = (roleId == 6) ? 'CIMTDWP' : 'CIMTDWPSUP';
      String roleName = (roleId == 6) ? 'Pastor' : 'Supervisor';

        File uidFile = File('${externalDir.path}/$folderName/Appfiles/UID.txt');

        String? uid = UidFileHelper.canonicalize(
          await UidFileHelper.readRawUidContent(uidFile),
        );
        if (uid != null && uid.isNotEmpty) {
          return uid;
        }
      }

      // Fallback: check firstUID or DeviceIdManager
      String fallbackUid = await getFirstUID();
      if (fallbackUid.isNotEmpty) {
        return fallbackUid;
      }
      String deviceId = await DeviceIdManager.getDeviceId();
      if (deviceId.isNotEmpty) {
        return deviceId;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Refreshes UID.txt after a successful login so it always reflects the
  /// server's response: the login API is the source of truth for the
  /// account's UID, so it wins over whatever was previously on disk (e.g.
  /// a device-generated UID from before this account was linked, or a stale
  /// value left over from a reinstall).
  Future<void> _updateUidFileFromLoginResponse(
    int roleId,
    String uid,
    String userId,
  ) async {
    if (uid.isEmpty) return;

    try {
      Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir == null) return;

      String folderName = (roleId == 6) ? 'CIMTDWP' : 'CIMTDWPSUP';
      File uidFile = File('${externalDir.path}/$folderName/Appfiles/UID.txt');

      await UidFileHelper.writeUidWithUserId(uidFile, uid, userId);
    } catch (e) {
      debugPrint('Failed to update UID.txt after login: $e');
    }
  }

  // Login logic with role-based UID
  login(String phoneNo, String password) async {
    if (phoneNo.isEmpty) {
      _showTopSnackBar(S.of(context).loginNewValidVal);
      return;
    }
    if (password.length < 6) {
      _showTopSnackBar(S.of(context).loginPassVal);
      return;
    }
    if (selectedRoleId == 0) {
      _showTopSnackBar(S.of(context).selectRole);
      return;
    }

    setState(() {
      isLoading = true;
    });

    final maskedPhone = phoneNo.length >= 4
        ? 'xxxxxx${phoneNo.substring(phoneNo.length - 4)}'
        : phoneNo;
    unawaited(CrashReportManager.logUserEvent(
      'login_attempt',
      details: {
        'phone': maskedPhone,
        'role': selectedRole,
        'roleId': selectedRoleId,
      },
    ));

    // Get role-specific UID before login
    String? roleSpecificUID = await _getRoleSpecificUID(selectedRoleId);

    if (roleSpecificUID == null) {
      setState(() {
        isLoading = false;
      });
      await clearUserSession();
      unawaited(CrashReportManager.logUserEvent(
        'login_failed',
        details: {'phone': maskedPhone, 'reason': 'unable_to_get_uid'},
      ));
      _showErrorDialog('${S.of(context).unableUID}');
      return;
    }

    Auth()
        .login(phoneNo, password, (userID ?? '').toString(), roleSpecificUID)
        .then((value) async {
          setState(() {
            isLoading = false;
          });

          if (value != null) {
            if (value.isSuccess == true) {
              // Verify the role from API matches selected role
              int? apiRoleFlag = int.tryParse(value.data?.roleFlag?.toString() ?? '');

              if (apiRoleFlag != null && apiRoleFlag == selectedRoleId) {
                // Save all login data ONLY upon verified success
                _saveRememberedData(phoneNo, password);
                String token = value.data?.accessToken?.toString() ?? '';
                await setAuthToken(token);
                await setLoginUID(value.data?.uId?.toString() ?? '');
                await setUserIdLogin(value.data?.userId?.toString() ?? '');
                await setUserId(value.data?.userId?.toString() ?? '');
                await setroleFlag(apiRoleFlag.toString());
                await saveRoleName(value.data?.roleName?.toString() ?? selectedRole);
                await saveUserName(value.data?.fname?.toString() ?? '');

                final String responseUid =
                    (value.data?.uId != null && value.data!.uId!.isNotEmpty)
                    ? value.data!.uId!
                    : roleSpecificUID;
                await setFirstUID(responseUid);

                await _updateUidFileFromLoginResponse(
                  selectedRoleId,
                  responseUid,
                  value.data?.userId?.toString() ?? '',
                );

                unawaited(CrashReportManager.logUserEvent(
                  'login_success',
                  details: {
                    'phone': maskedPhone,
                    'role': selectedRole,
                    'roleId': apiRoleFlag,
                    'userId': value.data?.userId?.toString() ?? '',
                    'UID': responseUid,
                  },
                ));

                await TokenManager().initializeTokenMonitoring(token);

                _showTopSnackBar(
                  '${S.of(context).loggedIn} • ${S.of(context).role}: $selectedRole',
                  isError: false,
                );
                await Future.delayed(const Duration(milliseconds: 600));
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InactivityDetector(
                        child: LandingScreen(
                          changeLanguage: widget.changeLanguage,
                        ),
                      ),
                    ),
                  );
                }
              } else if (apiRoleFlag != null && apiRoleFlag != selectedRoleId) {
                // Role mismatch - Ensure NO session is stored
                await clearUserSession();
                String correctRole = (apiRoleFlag == 6)
                    ? 'Pastor'
                    : 'Supervisor';
                unawaited(CrashReportManager.logUserEvent(
                  'login_failed',
                  details: {
                    'phone': maskedPhone,
                    'reason': 'role_mismatch',
                    'selectedRole': selectedRole,
                    'accountRole': correctRole,
                  },
                ));
                _showErrorDialog(
                  '${S.of(context).accountRegistered} $correctRole. ${S.of(context).pleaseCorrectRole}',
                );
              } else {
                await clearUserSession();
                unawaited(CrashReportManager.logUserEvent(
                  'login_failed',
                  details: {
                    'phone': maskedPhone,
                    'reason': 'missing_role_info',
                  },
                ));
                _showErrorDialog('${S.of(context).roleInformation}');
              }
            } else {
              // Server rejected - Clear any partial session
              await clearUserSession();
              String errorMessage = (value.data?.message != null &&
                      value.data!.message!.trim().isNotEmpty)
                  ? value.data!.message!.trim()
                  : (value.displayMessage.isNotEmpty
                      ? value.displayMessage
                      : (value.message ?? S.of(context).phoneNumberIncorrect));
              unawaited(CrashReportManager.logUserEvent(
                'login_failed',
                details: {
                  'phone': maskedPhone,
                  'reason': 'server_rejected',
                  'message': errorMessage,
                },
              ));
              _showErrorDialog(errorMessage);
            }
          } else {
            // No server response - Clear session
            await clearUserSession();
            unawaited(CrashReportManager.logUserEvent(
              'login_failed',
              details: {'phone': maskedPhone, 'reason': 'no_server_response'},
            ));
            _showErrorDialog("${S.of(context).unableServer}");
          }
        })
        .catchError((e) async {
          await clearUserSession();
          if (mounted) {
            setState(() {
              isLoading = false;
            });
          }
          unawaited(CrashReportManager.logUserEvent(
            'login_failed',
            details: {
              'phone': maskedPhone,
              'reason': 'exception',
              'error': e.toString(),
            },
          ));
          _showErrorDialog("${S.of(context).errorOccurredLogin}");
        });
  }

  void _showErrorDialog(String message) {
    _showTopSnackBar(message);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          Fluttertoast.showToast(
            msg: "Press back again to exit",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.black87,
            textColor: Colors.white,
          );
        } else {
          SystemNavigator.pop();
        }
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
                  const SizedBox(height: 40),
                  // App Brand Logo
                  Center(
                    child: Image.asset(
                      'assets/logo.png',
                      height: 64,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Header & Greeting
                  Text(
                    S.of(context).letsSignIn,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.4,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    S.of(context).welcomeBack,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.1,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Field 1: Phone Number / User ID
                  Text(
                    S.of(context).phoneNo,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneNumberController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0F172A),
                      fontFamily: 'Roboto',
                    ),
                    decoration: InputDecoration(
                      counterText: '', // Clean UX: removes distracting counter
                      hintText: S.of(context).enterPhoneNo,
                      hintStyle: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
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
                        horizontal: 16,
                        vertical: 15,
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
                  const SizedBox(height: 18),

                  // Field 2: Password
                  Text(
                    S.of(context).password,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    obscureText: !isPasswordVisible,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0F172A),
                      fontFamily: 'Roboto',
                    ),
                    decoration: InputDecoration(
                      hintText: S.of(context).enterPass,
                      hintStyle: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
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
                        horizontal: 16,
                        vertical: 15,
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
                  const SizedBox(height: 18),

                  // Field 3: Role Selector (Tactile Segmented Pills)
                  Text(
                    S.of(context).role,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 8),
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
                            // Pastor (roleId = 6 -> CIMTDWP)
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
                                    duration: const Duration(milliseconds: 180),
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
                            // CanImage User / Supervisor (roleId = 7 -> CIMTDWPSUP)
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
                                    duration: const Duration(milliseconds: 180),
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
                  const SizedBox(height: 18),

                  // Remember Me
                  Row(
                    children: [
                      SizedBox(
                        height: 22,
                        width: 22,
                        child: Checkbox(
                          value: isRememberMeChecked,
                          onChanged: (value) {
                            setState(() {
                              isRememberMeChecked = value ?? false;
                            });
                          },
                          activeColor: Font.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          side: const BorderSide(
                            color: Color(0xFF94A3B8),
                            width: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isRememberMeChecked = !isRememberMeChecked;
                          });
                        },
                        child: Text(
                          S.of(context).rememberMe,
                          style: const TextStyle(
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w500,
                            fontSize: 13.5,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),

                  // Sign In Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              login(
                                phoneNumberController.text,
                                passwordController.text,
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
                              S.of(context).signIn,
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
                  const SizedBox(height: 24),

                  // Register Link (Fixing text-wrap and layout bug)
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          S.of(context).dontHaveAcc,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegistrationScreen(
                                  changeLanguage: widget.changeLanguage,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            S.of(context).registerBtn,
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
