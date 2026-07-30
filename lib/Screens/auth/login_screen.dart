import 'package:canimage/Screens/auth/registration_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../APIService/auth_service.dart';
import '../../generated/l10n.dart';
import '../../utils/fonts.dart';
import '../../utils/inactivity_detector.dart';
import '../../utils/shared_preference.dart';
import '../../utils/textStyle.dart';
import '../../utils/token_manager.dart';
import '../../utils/uid_file_helper.dart';
import '../landing/landing_screen.dart';
import 'forgot_password.dart';

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

  void userDetails() async {
    userID = await getUserID();
  }

  // NEW: Get UID from role-specific folder based on selected role
  Future<String?> _getRoleSpecificUID(int roleId) async {
    try {
      Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        // print(' Unable to access external storage');
        return null;
      }

      // Determine folder based on role
      // roleId 6 = Pastor -> CIMTDWP
      // roleId 7 = Supervisor -> CIMTDWPSUP
      String folderName = (roleId == 6) ? 'CIMTDWP' : 'CIMTDWPSUP';
      String roleName = (roleId == 6) ? 'Pastor' : 'Supervisor';

      File uidFile = File('${externalDir.path}/$folderName/Appfiles/UID.txt');

      String? uid = await UidFileHelper.readRawUidContent(uidFile);
      if (uid != null) {
        // print(' Retrieved $roleName UID: $uid from $folderName');
        return uid;
      } else {
        // print(' UID file missing or invalid in $folderName');
      }

      return null;
    } catch (e) {
      // print(' Error getting role-specific UID: $e');
      return null;
    }
  }

  // Login logic with role-based UID
  login(String phoneNo, String password) async {
    if (phoneNo.isEmpty) {
      _showToast(S.of(context).loginNewValidVal, Colors.red);
      return;
    }
    if (password.length < 6) {
      _showToast(S.of(context).loginPassVal, Colors.red);
      return;
    }
    if (selectedRoleId == 0) {
      _showToast(S.of(context).selectRole, Colors.red);
      return;
    }

    setState(() {
      isLoading = true;
    });

    // Get role-specific UID before login
    String? roleSpecificUID = await _getRoleSpecificUID(selectedRoleId);

    if (roleSpecificUID == null) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog('${S.of(context).unableUID}');
      return;
    }

    Auth().login(phoneNo, password, userID.toString(), roleSpecificUID).then((value) async {
      setState(() {
        isLoading = false;
      });

      if (value != null) {
        if (value.isSuccess == true) {
          // Verify the role from API matches selected role
          int? apiRoleFlag = int.parse(value.data!.roleFlag.toString());

          if (apiRoleFlag != null && apiRoleFlag == selectedRoleId) {
            // Save all login data
            _saveRememberedData(phoneNo, password);
            String token = value.data?.accessToken?.toString() ?? '';
            setAuthToken(value.data?.accessToken?.toString() ?? '');
            setLoginUID(value.data?.uId?.toString() ?? '');
            setUserIdLogin(value.data?.userId?.toString() ?? '');
            // Landing screen's "User ID" card reads the 'userID' key (set at
            // registration time), not 'userIDLogin' — keep it in sync here so
            // it always reflects the most recent login response, for both
            // Pastor and CanImage User (Supervisor) roles.
            setUserId(value.data?.userId?.toString() ?? '');
            setroleFlag(apiRoleFlag.toString());
            setFirstUID(roleSpecificUID);

            await TokenManager().initializeTokenMonitoring(token);

            //  Start inactivity timer
            // TokenManager().startInactivityTimer();

            String folderName = (selectedRoleId == 6) ? 'CIMTDWP' : 'CIMTDWPSUP';

            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text(S.of(context).success, style: TextStyle(
                  fontFamily: "Roboto",
                  fontWeight: FontWeight.w600,
                )),
                content: Text(
                    '${S.of(context).loggedIn}\n'
                        '${S.of(context).role}: $selectedRole\n'
                        '${S.of(context).uid}: $roleSpecificUID\n',
                    style: TextStyle(
                      fontFamily: "Roboto",
                      color: Colors.grey[600],
                    )
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => InactivityDetector(child: LandingScreen(changeLanguage: widget.changeLanguage))),
                      );
                    },
                    child: Text(S.of(context).ok, style: TextStyle(
                      fontFamily: "Roboto",
                      color: Font.primaryColor,
                    )),
                  ),
                ],
              ),
            );
          } else if (apiRoleFlag != null && apiRoleFlag != selectedRoleId) {
            // Role mismatch
            String correctRole = (apiRoleFlag == 6) ? 'Pastor' : 'Supervisor';
            _showErrorDialog('${S.of(context).accountRegistered} $correctRole. ${S.of(context).pleaseCorrectRole}');
          } else {
            _showErrorDialog('${S.of(context).roleInformation}');
          }
        } else {
          String errorMessage = value.message ?? "${S.of(context).phoneNumberIncorrect}";
          _showErrorDialog(errorMessage);
        }
      } else {
        _showErrorDialog("${S.of(context).unableServer}");
      }
    }).catchError((e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog("${S.of(context).errorOccurredLogin}");
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(S.of(context).failure, style: TextStyle(
          fontFamily: "Roboto",
          fontWeight: FontWeight.w600,
        )),
        content: Text(message, style: TextStyle(
          fontFamily: "Roboto",
          color: Colors.grey[600],
        )),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(S.of(context).ok, style: TextStyle(
              fontFamily: "Roboto",
              color: Font.primaryColor,
            )),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(color: Colors.white),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 50),
                  child: Container(
                    width: 250,
                    height: 100,
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(S.of(context).letsSignIn, style: TextstyleGlobal.headerTextStyle),
                        SizedBox(height: 10),
                        Text(S.of(context).welcomeBack, style: TextstyleGlobal.bodyTextStyle),
                        SizedBox(height: 20),

                        // NEW: Role Selection


                        Text(S.of(context).phoneNo, style: TextstyleGlobal.labelTextStyle.copyWith(fontWeight: FontWeight.w600)),
                        SizedBox(height: 5),
                        TextField(
                          controller: phoneNumberController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          style: TextStyle(fontSize: 14, color: Font.neutralDarkColor, fontFamily: 'Roboto'),
                          decoration: InputDecoration(
                            hintText: S.of(context).enterPhoneNo,
                            hintStyle: TextStyle(color: Font.neutralDarkColor, fontFamily: "Roboto"),
                            suffixIcon: Icon(Icons.account_circle_outlined, color: Font.primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            fillColor: Colors.white,
                            filled: true,
                          ),
                        ),

                        Text(S.of(context).password, style: TextstyleGlobal.labelTextStyle.copyWith(fontWeight: FontWeight.w600)),
                        SizedBox(height: 5),
                        TextField(
                          controller: passwordController,
                          obscureText: !isPasswordVisible,
                          style: TextstyleGlobal.bodyTextStyle,
                          decoration: InputDecoration(
                            hintText: S.of(context).enterPass,
                            hintStyle: TextstyleGlobal.bodyTextStyle,
                            suffixIcon: IconButton(
                              icon: Icon(
                                isPasswordVisible ? Icons.lock_open : Icons.lock,
                                color: Font.primaryColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  isPasswordVisible = !isPasswordVisible;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            fillColor: Colors.white,
                            filled: true,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(S.of(context).role, style: TextstyleGlobal.labelTextStyle.copyWith(fontWeight: FontWeight.w600)),
                        SizedBox(height: 5),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              // Pastor Radio Button (roleId = 6, folder = CIMTDWP)
                              Expanded(
                                child: RadioListTile<String>(
                                  title: Text(S.of(context).pastor, style: TextstyleGlobal.bodyTextStyle1),
                                  value: '${S.of(context).pastor}',
                                  groupValue: selectedRole,
                                  activeColor: Font.primaryColor,
                                  onChanged: (String? value) {
                                    setState(() {
                                      selectedRole = value!;
                                      selectedRoleId = 6; // Pastor ID is 6 -> CIMTDWP folder
                                      // print(' Selected: $selectedRole (ID: $selectedRoleId) -> CIMTDWP');
                                    });
                                  },
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                ),
                              ),
                              // Supervisor Radio Button (roleId = 7, folder = CIMTDWPSUP)
                              Expanded(
                                child: RadioListTile<String>(
                                  title: Text(S.of(context).supervisor, style: TextstyleGlobal.bodyTextStyle1),
                                  contentPadding: EdgeInsets.zero,
                                  value: '${S.of(context).supervisor}',
                                  groupValue: selectedRole,
                                  activeColor: Font.primaryColor,
                                  onChanged: (String? value) {
                                    setState(() {
                                      selectedRole = value!;
                                      selectedRoleId = 7; // Supervisor ID is 7 -> CIMTDWPSUP folder
                                      // print(' Selected: $selectedRole (ID: $selectedRoleId) -> CIMTDWPSUP');
                                    });
                                  },
                                  dense: false,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: isRememberMeChecked,
                              onChanged: (value) {
                                setState(() {
                                  isRememberMeChecked = value!;
                                });
                              },
                              activeColor: Font.primaryColor,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            Container(
                              width: 120,
                              child: Text(
                                S.of(context).rememberMe,
                                style: TextStyle(
                                  color: Font.primaryColor,
                                  fontFamily: "Roboto",
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            // Spacer(),
                            // GestureDetector(
                            //   onTap: () {
                            //     Navigator.pushReplacement(
                            //       context,
                            //       MaterialPageRoute(builder: (context) => ForgotPasswordScreen(changeLanguage: widget.changeLanguage,)),
                            //     );
                            //   },
                            //   child: Container(
                            //     width: 120,
                            //     child: Text(
                            //       S.of(context).forgotPassLogin,
                            //       style: TextStyle(
                            //         color: Font.primaryColor,
                            //         fontSize: 13,
                            //         fontFamily: "Roboto",
                            //       ),
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            login(phoneNumberController.text, passwordController.text);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Font.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: Size(double.infinity, 10),
                          ),
                          child: isLoading
                              ? CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                              : Text(
                            S.of(context).signIn,
                            style: TextStyle(fontSize: 18, color: Colors.white, fontFamily: "Roboto"),
                          ),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              S.of(context).dontHaveAcc,
                              style: TextStyle(color: Font.neutralDarkColor, fontFamily: "Roboto", fontSize: 13),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => RegistrationScreen(changeLanguage: widget.changeLanguage,)),
                                );
                              },
                              child: Container(
                                width: 80,
                                child: Text(
                                  S.of(context).registerBtn,
                                  style: TextStyle(color: Font.primaryColor, fontFamily: "Roboto", fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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