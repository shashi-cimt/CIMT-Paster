//token store
import 'package:shared_preferences/shared_preferences.dart';

setFirstUID(String UID) async {
  // print("tokdata" + data);
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString('UIDFirst', UID);
}

Future<String> getFirstUID() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  if (prefs.getString('UIDFirst') != null &&
      prefs.getString('UIDFirst')!.isNotEmpty) {
    // print("MyAuthToken" + "Bearer "+prefs.getString('token').toString());
  } else {
    print("Token is  Empty");
  }
  return prefs.getString('UIDFirst') != null
      ? prefs.getString('UIDFirst').toString()
      : "";
}


setLoginUID(String UID) async {
  // print("tokdata" + data);
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString('UIDLogin', UID);
}

Future<String> getLoginUID() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  if (prefs.getString('UIDLogin') != null &&
      prefs.getString('UIDLogin')!.isNotEmpty) {
    // print("MyAuthToken" + "Bearer "+prefs.getString('token').toString());
  } else {
    print("Token is  Empty");
  }
  return prefs.getString('UIDLogin') != null
      ? prefs.getString('UIDLogin').toString()
      : "";
}


//token store
setAuthToken(String data) async {
  // print("tokdata" + data);
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString('token', data);
}

Future<String> getAuthToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  if (token != null && token.trim().isNotEmpty) {
    return "Bearer ${token.trim()}";
  }
  return "";
}

Future<String> getRawToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('token')?.trim() ?? "";
}

setUserId(String userID) async {
  // print("tokdata" + data);
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString('userID', userID);
}

Future<String> getUserID() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  if (prefs.getString('userID') != null &&
      prefs.getString('userID')!.isNotEmpty) {
    // print("MyAuthToken" + "Bearer "+prefs.getString('token').toString());
  } else {
    print("Token is  Empty");
  }
  return prefs.getString('userID') != null
      ? prefs.getString('userID').toString()
      : "";
}


setUserIdLogin(String userID) async {
  // print("tokdata" + data);
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString('userIDLogin', userID);
}

Future<String> getUserIDLogin() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  if (prefs.getString('userIDLogin') != null &&
      prefs.getString('userIDLogin')!.isNotEmpty) {
    // print("MyAuthToken" + "Bearer "+prefs.getString('token').toString());
  } else {
    print("Token is  Empty");
  }
  return prefs.getString('userIDLogin') != null
      ? prefs.getString('userIDLogin').toString()
      : "";
}


setroleFlag(String roleFladData) async {
  // print("tokdata" + data);
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString('roleFlag', roleFladData);
}

Future<String> getRoleFlag() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  if (prefs.getString('roleFlag') != null &&
      prefs.getString('roleFlag')!.isNotEmpty) {
    // print("MyAuthToken" + "Bearer "+prefs.getString('token').toString());
  } else {
    print("Token is  Empty");
  }
  return prefs.getString('roleFlag') != null
      ? prefs.getString('roleFlag').toString()
      : "";
}

// Save profile image path
setProfileImagePath(String imagePath) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString('profileImagePath', imagePath);
}

// Get profile image path
Future<String> getProfileImagePath() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('profileImagePath') ?? "";
}

// Clear profile image
clearProfileImagePath() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.remove('profileImagePath');
}

Future<void> saveUserName(String name) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString("fname", name);
}

Future<void> setFname(String name) => saveUserName(name);

Future<void> saveRoleName(String role) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString("roleName", role);
}

Future<void> setroleName(String role) => saveRoleName(role);

Future<String> getUserName() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString("fname") ?? '';
}

Future<String> getRoleName() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString("roleName") ?? '';
}

Future<String> getDeviceId() async {
  final prefs = await SharedPreferences.getInstance();

  if (prefs.getString('deviceId') != null &&
      prefs.getString('deviceId')!.isNotEmpty) {
    return prefs.getString('deviceId')!;
  } else {
    print("Device ID is Empty");
    return "";
  }
}

/// Completely clears all authentication and session data from SharedPreferences.
/// Preserves user preferences like 'language' and 'deviceId'.
Future<void> clearUserSession() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('token');
  await prefs.remove('token_expiry');
  await prefs.remove('auth_token');
  await prefs.remove('UIDFirst');
  await prefs.remove('UIDLogin');
  await prefs.remove('uId');
  await prefs.remove('login_uid');
  await prefs.remove('userID');
  await prefs.remove('userIDLogin');
  await prefs.remove('userId');
  await prefs.remove('user_id_login');
  await prefs.remove('roleFlag');
  await prefs.remove('role_flag');
  await prefs.remove('roleName');
  await prefs.remove('fname');
}