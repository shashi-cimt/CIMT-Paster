import 'package:canimage/Screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                      'assets/logo.png1',
                      fit: BoxFit.contain,
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
                        SizedBox(height: 10),
                        Text(
                            S.of(context).forgotText,
                            style: TextstyleGlobal.bodyTextStyle
                        ),
                        SizedBox(height: 20),

                        // Email or Phone Number TextField
                        Text(S.of(context).phoneNo, style: TextstyleGlobal.labelTextStyle),
                        SizedBox(height: 5),
                        TextField(
                          keyboardType: TextInputType.phone,
                          onChanged: (value) {
                            setState(() {
                              // You can add logic to handle changes if needed
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
                        SizedBox(height: 20),

                        // Button to submit the reset password request
                        ElevatedButton(
                          onPressed: () {

                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Font.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: Size(double.infinity, 10),
                          ),
                          child: Center(
                            child: Text(
                              S.of(context).resetPass,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18, color: Colors.white, fontFamily: "Roboto"),
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
