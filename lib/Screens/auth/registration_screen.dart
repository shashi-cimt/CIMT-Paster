import 'package:canimage/Screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../APIService/auth_service.dart';
import '../../Model/registration_model.dart';
import '../../generated/l10n.dart';
import '../../utils/fonts.dart';
import '../../utils/shared_preference.dart';
import '../../utils/textStyle.dart';

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

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        File tempImage = File(image.path);

        // Save to permanent location
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String profileDir = '${appDir.path}/profiles';
        await Directory(profileDir).create(recursive: true);

        final String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
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
      print('Error picking image: $e');
      _showToast('Failed to save image', Colors.red);
    }
  }
  // void _showImageSourceDialog() {
  //   showModalBottomSheet(
  //     context: context,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder: (BuildContext context) {
  //       return SafeArea(
  //         child: Wrap(
  //           children: [
  //             ListTile(
  //               leading: Icon(Icons.photo_camera, color: Colors.blue),
  //               title: Text('Take Photo'),
  //               onTap: () {
  //                 Navigator.pop(context);
  //                 _pickImage(ImageSource.camera);
  //               },
  //             ),
  //             ListTile(
  //               leading: Icon(Icons.photo_library, color: Colors.blue),
  //               title: Text('Choose from Gallery'),
  //               onTap: () {
  //                 Navigator.pop(context);
  //                 _pickImage(ImageSource.gallery);
  //               },
  //             ),
  //             if (_selectedImage != null)
  //               ListTile(
  //                 leading: Icon(Icons.delete, color: Colors.red),
  //                 title: Text('Remove Photo'),
  //                 onTap: () {
  //                   Navigator.pop(context);
  //                   setState(() {
  //                     _selectedImage = null;
  //                   });
  //                 },
  //               ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

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
        // print(' Unable to access external storage');
        return null;
      }

      // Determine folder based on role
      // roleId 6 = Pastor -> CIMTDWP
      // roleId 7 = Supervisor -> CIMTDWPSUP
      String folderName = (roleId == 6) ? 'CIMTDWP' : 'CIMTDWPSUP';
      String roleName = (roleId == 6) ? 'Pastor' : 'Supervisor';

      File uidFile = File('${externalDir.path}/$folderName/Appfiles/UID.txt');

      if (await uidFile.exists()) {
        String uid = await uidFile.readAsString();
        uid = uid.trim();

        if (uid.length == 16 && RegExp(r'^\d{16}$').hasMatch(uid)) {
          // print(' Retrieved $roleName UID: $uid from $folderName');
          return uid;
        } else {
          // print(' Invalid UID format in $folderName');
        }
      } else {
        // print(' UID file not found in $folderName');
      }

      return null;
    } catch (e) {
      // print(' Error getting role-specific UID: $e');
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
        // print(' Unable to access external storage directory');
        return null;
      }

      // roleId 6 = Pastor -> CIMTDWP
      // roleId 7 = Supervisor -> CIMTDWPSUP
      String folderName = (roleId == 6) ? 'CIMTDWP' : 'CIMTDWPSUP';

      // Main folder: /<externalDir>/<folderName>/Appfiles
      Directory roleDir = Directory('${externalDir.path}/$folderName/UserImage');
      if (!await roleDir.exists()) {
        await roleDir.create(recursive: true);
      }

      // Use UID as filename so it’s unique
      String ext = p.extension(imageFile.path); // e.g. .jpg / .png
      if (ext.isEmpty) ext = '.jpg';

      String targetPath = '${roleDir.path}/$uid$ext';
      File savedImage = await imageFile.copy(targetPath);

      // Optionally keep this path in SharedPreferences for later use
      await setProfileImagePath(savedImage.path);

      // print(' Saved profile image at: ${savedImage.path}');
      return savedImage;
    } catch (e) {
      // print(' Failed to save profile image to role folder: $e');
      return null;
    }
  }


  RegistrationAuthModel? registrationAuthModel;

  register(String firstname, String lastName, String phoneNo, String password, int roleId, File? profileImage,) async {
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
    if (profileImage == null || selectedRoleId == "null" || selectedRoleId == "") {
      _showToast("Please select the profile picture", Colors.red);
      return;
    }

    setState(() {
      isLoading = true;
    });

    // Get role-specific UID from the appropriate folder
    String? roleSpecificUID = await _getRoleSpecificUID(roleId);

    if (roleSpecificUID == null) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog('${S.of(context).unableUID}');
      return;
    }

    // Save the role-specific UID to shared preferences
    setFirstUID(roleSpecificUID);

    Auth().registration(firstname, lastName, phoneNo, password, roleSpecificUID, roleId.toString(),userImage: profileImage, ).then((value) async{
      setState(() {
        isLoading = false;
      });

      if (value != null) {
        registrationAuthModel = value;
        if (registrationAuthModel!.isSuccess == true && registrationAuthModel!.data?.userId != null) {
          setUserId(value.data!.userId.toString());

          String roleName = (roleId == 6) ? 'Pastor' : 'Supervisor';
          String folderName = (roleId == 6) ? 'CIMTDWP' : 'CIMTDWPSUP';
          if (profileImage != null) {
            await _saveProfileImageToRoleFolder(profileImage, roleId, roleSpecificUID);
          }

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(S.of(context).success, style: TextStyle(
                fontFamily: "Roboto",
                fontWeight: FontWeight.w600,
              )),
              content: Text(
                  "${S.of(context).registerSuccess}: ${value.data!.userId}\n"
                      "${S.of(context).role}: $roleName\n"
                      "${S.of(context).uid}: $roleSpecificUID",
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
                      MaterialPageRoute(builder: (context) => LoginScreen(changeLanguage: widget.changeLanguage,)),
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
        } else {
          String errorMessage = value.message ?? S.of(context).registrationFailed;
          _showErrorDialog(errorMessage);
        }
      } else {
        _showErrorDialog("${S.of(context).unableServer}");
      }
    }).catchError((e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog("${S.of(context).errorOccurredRegstration}");
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
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 1),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Padding(
                    //   padding: const EdgeInsets.only(top: 15, left: 20),
                    //   child: Container(
                    //     child: Image.asset(
                    //       'assets/logo.png',
                    //       fit: BoxFit.contain,
                    //     ),
                    //   ),
                    // ),
                    SizedBox(height: 10,),
                    Text(
                      S.of(context).registerBut,
                      style: TextstyleGlobal.headerTextStyle,
                    ),
                    SizedBox(height: 6),
                    Center(
                      child: Column(
                        children: [
                          SizedBox(height: 20),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer glow effect
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Font.primaryColor.withOpacity(0.3),
                                      Font.primaryColor.withOpacity(0.1),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                              // Profile Picture Circle
                              Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[100],
                                  border: Border.all(
                                    color: Font.primaryColor,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Font.primaryColor.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: Offset(0, 8),
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: _selectedImage != null
                                      ? Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                    width: 130,
                                    height: 130,
                                  )
                                      : Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.grey[200]!,
                                          Colors.grey[100]!,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      size: 70,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ),
                              ),
                              // Camera Icon Button with animation effect
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    width: 45,
                                    height: 45,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          Font.primaryColor,
                                          Font.primaryColor.withOpacity(0.8),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 4,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Font.primaryColor.withOpacity(0.5),
                                          blurRadius: 12,
                                          offset: Offset(0, 4),
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.camera_alt_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Text(
                            _selectedImage != null ? 'Tap camera to change photo' : 'Add your profile picture',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontFamily: "Roboto",
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_selectedImage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 16,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Photo selected',
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontSize: 12,
                                        fontFamily: "Roboto",
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),

                    // First Name TextField
                    Text(S.of(context).firstName, style: TextstyleGlobal.labelTextStyle),
                    SizedBox(height: 5),
                    TextField(
                      controller: firstNameController,
                      style: TextstyleGlobal.bodyTextStyle,
                      decoration: InputDecoration(
                        suffixIcon: Icon(Icons.account_circle, color: Font.primaryColor),
                        hintText: S.of(context).firstNameTxt,
                        hintStyle: TextstyleGlobal.bodyTextStyle,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                    ),
                    SizedBox(height: 6),

                    // Last Name TextField
                    Text(S.of(context).lastName, style: TextstyleGlobal.labelTextStyle),
                    SizedBox(height: 5),
                    TextField(
                      controller: lastNameController,
                      style: TextstyleGlobal.bodyTextStyle,
                      decoration: InputDecoration(
                        suffixIcon: Icon(Icons.account_circle, color: Font.primaryColor),
                        hintText: S.of(context).lastNameTxt,
                        hintStyle: TextstyleGlobal.bodyTextStyle,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                    ),
                    SizedBox(height: 6),

                    // Phone Number TextField
                    Text(S.of(context).phoneNoOnly, style: TextstyleGlobal.labelTextStyle),
                    SizedBox(height: 5),
                    TextField(
                      keyboardType: TextInputType.phone,
                      controller: phoneNumberController,
                      maxLength: 10,
                      style: TextstyleGlobal.bodyTextStyle,
                      decoration: InputDecoration(
                        hintText: S.of(context).phoneNoOnlyTxt,
                        hintStyle: TextstyleGlobal.bodyTextStyle,
                        suffixIcon: Icon(Icons.phone, color: Font.primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                    ),
                    SizedBox(height: 6),

                    // Password TextField
                    Text(S.of(context).password, style: TextstyleGlobal.labelTextStyle),
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
                    SizedBox(height: 6),

                    // Role Selection Radio Buttons
                    Text(S.of(context).role, style: TextstyleGlobal.labelTextStyle),
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
                              title: Text(S.of(context).pastor, style: TextstyleGlobal.bodyTextStyle),
                              value: '${S.of(context).pastor}',
                              groupValue: selectedRole,
                              activeColor: Font.primaryColor,
                              onChanged: (String? value) {
                                setState(() {
                                  selectedRole = value!;
                                  selectedRoleId = 6; // Pastor ID is 6 -> CIMTDWP folder
                                  // print('Selected: $selectedRole (ID: $selectedRoleId) -> CIMTDWP');
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                          // Supervisor Radio Button (roleId = 7, folder = CIMTDWPSUP)
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text(S.of(context).supervisor, style: TextstyleGlobal.bodyTextStyle),
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

                    SizedBox(height: 20),

                    // Register Button
                    ElevatedButton(
                      onPressed: () async {
                        register(
                            firstNameController.text,
                            lastNameController.text,
                            phoneNumberController.text,
                            passwordController.text,
                            selectedRoleId,
                            _selectedImage
                        );
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
                        S.of(context).registerBtn,
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontFamily: "Roboto"
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // Already have an account link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                            width: 200,
                            child: Text(S.of(context).alreadyAcct, style: TextstyleGlobal.bodyTextStyle)),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => LoginScreen(changeLanguage: widget.changeLanguage,)),
                            );
                          },
                          child: Container(
                              width: 50,
                              child: Text(S.of(context).login, style: TextStyle(color: Font.primaryColor, fontFamily: "Roboto"))),
                        ),
                      ],
                    ),
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