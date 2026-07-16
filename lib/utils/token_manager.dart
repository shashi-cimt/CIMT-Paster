import 'dart:async';
import 'package:canimage/utils/shared_preference.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../Screens/auth/login_screen.dart';

class TokenManager {
  static final TokenManager _instance = TokenManager._internal();
  factory TokenManager() => _instance;
  TokenManager._internal();

  Timer? _tokenExpiryTimer;
  DateTime? _tokenExpiryTime;
  bool _isInitialized = false;

  GlobalKey<NavigatorState>? navigatorKey;

  // Initialize token monitoring after login
  Future<void> initializeTokenMonitoring(String token) async {
    try {
      // print('🔧 Initializing token monitoring...');

      // Cancel any existing timers
      _tokenExpiryTimer?.cancel();

      // Decode JWT to get expiry time
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

      // JWT exp is in seconds since epoch
      int expTimestamp = decodedToken['exp'];
      _tokenExpiryTime = DateTime.fromMillisecondsSinceEpoch(expTimestamp * 1000);

      // Save token and expiry time
      await _saveTokenWithExpiry(token, _tokenExpiryTime!);

      // Start monitoring
      _startTokenExpiryTimer();

      _isInitialized = true;

      // print(' Token monitoring initialized. Expires at: $_tokenExpiryTime');
    } catch (e) {
      // print(' Error initializing token monitoring: $e');
      // Fallback: assume 1 hour expiry if JWT decode fails
      _tokenExpiryTime = DateTime.now().add(Duration(hours: 1));
      await _saveTokenWithExpiry(token, _tokenExpiryTime!);
      _startTokenExpiryTimer();
      _isInitialized = true;
    }
  }

  Future<void> _saveTokenWithExpiry(String token, DateTime expiryTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token_expiry', expiryTime.toIso8601String());
  }

  // Check if token is still valid
  Future<bool> isTokenValid() async {
    try {
      final token = await getAuthToken();

      if (token == null || token.isEmpty) {
        // print(' Token is null or empty');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final expiryString = prefs.getString('token_expiry');

      if (expiryString == null) {
        // print(' Token expiry not found in preferences');
        return false;
      }

      final expiryTime = DateTime.parse(expiryString);
      final isValid = DateTime.now().isBefore(expiryTime);

      if (!isValid) {
        // print(' Token has expired');
      }

      return isValid;
    } catch (e) {
      // print(' Error checking token validity: $e');
      return false;
    }
  }

  // Start timer to auto-logout before token expires
  void _startTokenExpiryTimer() {
    _tokenExpiryTimer?.cancel();

    if (_tokenExpiryTime == null) {
      // print(' Cannot start token expiry timer - expiry time is null');
      return;
    }

    final duration = _tokenExpiryTime!.difference(DateTime.now());

    if (duration.isNegative) {
      // print(' Token already expired');
      _handleTokenExpiry();
      return;
    }

    // Logout 30 seconds before actual expiry
    final logoutDuration = duration - const Duration(seconds: 30);

    if (logoutDuration.isNegative) {
      // print(' Token expiring very soon');
      _handleTokenExpiry();
      return;
    }

    _tokenExpiryTimer = Timer(logoutDuration, () {
      // print(' Token expiry timer triggered');
      _handleTokenExpiry();
    });

    // print(' Token expiry timer set for ${logoutDuration.inMinutes} minutes ${logoutDuration.inSeconds % 60} seconds');
  }

  void _handleTokenExpiry() {
    // print(' Token expired - logging out');
    logout('Your session has expired. Please login again.');
  }

  // Logout and clear all data
  Future<void> logout([String? message]) async {
    // print(' Logging out... Reason: ${message ?? "Manual logout"}');

    _tokenExpiryTimer?.cancel();
    _isInitialized = false;
    _tokenExpiryTime = null;

    // Clear all stored data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('token_expiry');
    await prefs.remove('login_uid');
    await prefs.remove('user_id_login');
    await prefs.remove('role_flag');
    await prefs.remove('first_uid');

    // print(' All session data cleared');

    // Navigate to login screen
    final context = navigatorKey?.currentContext;
    if (context != null && context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => LoginScreen(
            changeLanguage: (String lang) {},
          ),
        ),
            (route) => false,
      );
    } else {
      // print(' Cannot navigate to login - context is null or not mounted');
    }
  }

  void dispose() {
    // print(' Disposing TokenManager');
    _tokenExpiryTimer?.cancel();
    _isInitialized = false;
  }
}
