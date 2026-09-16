import 'package:canimage/Screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/can_image_loader.dart';
import '../../widgets/app_snack_bar.dart';
import '../../generated/l10n.dart';
import '../../utils/fonts.dart';
import '../../utils/textStyle.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  final Function(String) changeLanguage;

  const ForgotPasswordScreen({super.key, required this.changeLanguage});
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  String emailOrPhone = ''; // Variable to hold the email or phone number input
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,

        body: SingleChildScrollView(
          child: Container(
            decoration: const BoxDecoration(color: Colors.white),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 50),
                  child: Center(
                    child: CanImageLoader(
                      spinnerSize: 54,
                      showBrand: true,
                    ),
                  ),
                ),
                // Forgot Password header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            S.of(context).forgotPassword,
                            style: TextstyleGlobal.headerTextStyle
                        ),
                        const SizedBox(height: 10),
                        Text(
                            S.of(context).forgotText,
                            style: TextstyleGlobal.bodyTextStyle
                        ),
                        const SizedBox(height: 20),

                        // Email or Phone Number TextField
                        Text(S.of(context).phoneNo, style: TextstyleGlobal.labelTextStyle),
                        const SizedBox(height: 5),
                        TextField(
                          keyboardType: TextInputType.phone,
                          onChanged: (value) {
                            setState(() {
                              emailOrPhone = value;
                            });
                          },
                          maxLength: 10, // Enforcing 10 digits length
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
                        const SizedBox(height: 20),

                        // Button to submit the reset password request
                        ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  if (emailOrPhone.trim().length != 10) {
                                    AppSnackBar.showError(
                                      context,
                                      S.of(context).enterPhoneNo,
                                    );
                                    return;
                                  }
                                  setState(() {
                                    isLoading = true;
                                  });
                                  await Future.delayed(const Duration(seconds: 2));
                                  if (mounted) {
                                    setState(() {
                                      isLoading = false;
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Font.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(double.infinity, 10),
                          ),
                          child: Center(
                            child: isLoading
                                ? const CanImageSpinner(
                                    size: 22,
                                    primaryColor: Colors.white70,
                                    accentColor: Colors.white,
                                  )
                                : Text(
                                    S.of(context).resetPass,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 18, color: Colors.white, fontFamily: "Roboto"),
                                  ),
                          ),
                        ),
                        SizedBox(height: 20),

                        // Navigate back to Login screen
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                                width: 200,
                                child: Text(S.of(context).rememberPass, style: TextStyle(color: Font.neutralDarkColor, fontFamily: "Roboto"),)),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => LoginScreen(changeLanguage: widget.changeLanguage,)),
                                ); // Go back to the login screen
                              },
                              child: Container(
                                  width: 50,
                                  child: Text(S.of(context).login, style: TextStyle(color: Font.primaryColor, fontFamily: "Roboto"),)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )

              ],
            ),
          ),
        ),
      ),
    );
  }
}
