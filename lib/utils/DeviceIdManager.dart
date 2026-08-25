import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdManager {
  DeviceIdManager._();

  static const String _deviceIdKey = "device_id";

  static String deviceId = "";

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    deviceId = prefs.getString(_deviceIdKey) ?? "";

    if (deviceId.isEmpty) {
      deviceId = await _getPlatformDeviceId();
      await prefs.setString(_deviceIdKey, deviceId);
    }
  }

  static Future<String> getDeviceId() async {
    if (deviceId.isNotEmpty) {
      return deviceId;
    }

    final prefs = await SharedPreferences.getInstance();

    deviceId = prefs.getString(_deviceIdKey) ?? "";

    if (deviceId.isEmpty) {
      deviceId = await _getPlatformDeviceId();
      await prefs.setString(_deviceIdKey, deviceId);
    }

    return deviceId;
  }

  static Future<String> _getPlatformDeviceId() async {
    if (Platform.isAndroid) {
      return await _getAndroidId();
    }

    if (Platform.isIOS) {
      final deviceInfo = DeviceInfoPlugin();
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? "";
    }

    return "";
  }

  static Future<String> _getAndroidId() async {
    try {
      const androidIdPlugin = AndroidId();
      final id = await androidIdPlugin.getId();
      return id ?? "UNKNOWN_DEVICE";
    } catch (e) {
      return "UNKNOWN_DEVICE";
    }
  }
}