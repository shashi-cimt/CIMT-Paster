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
      // Cancel any existing timers
      _tokenExpiryTimer?.cancel();
      _tokenExpiryTimer = null;

      // Strip "Bearer " if present before decoding JWT
      String rawToken = token.startsWith('Bearer ') ? token.substring(7).trim() : token.trim();

      // Decode JWT to get expiry time
      Map<String, dynamic> decodedToken = JwtDecoder.decode(rawToken);

      // JWT exp is in seconds since epoch
      int expTimestamp = decodedToken['exp'];
      _tokenExpiryTime = DateTime.fromMillisecondsSinceEpoch(expTimestamp * 1000);

      // Save token and expiry time
      await _saveTokenWithExpiry(rawToken, _tokenExpiryTime!);

      // Start monitoring
      _startTokenExpiryTimer();

      _isInitialized = true;
    } catch (e) {
      // Fallback: assume 1 hour expiry if JWT decode fails
      _tokenExpiryTime = DateTime.now().add(const Duration(hours: 1));
      String rawToken = token.startsWith('Bearer ') ? token.substring(7).trim() : token.trim();
      await _saveTokenWithExpiry(rawToken, _tokenExpiryTime!);
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
      final rawToken = await getRawToken();

      if (rawToken.isEmpty) {
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final expiryString = prefs.getString('token_expiry');

      if (expiryString == null || expiryString.isEmpty) {
        return false;
      }

      final expiryTime = DateTime.tryParse(expiryString);
      if (expiryTime == null) {
        return false;
      }

      final isValid = DateTime.now().isBefore(expiryTime);
      return isValid;
    } catch (e) {
      return false;
    }
  }

  // Start timer to auto-logout before token expires
  void _startTokenExpiryTimer() {
    _tokenExpiryTimer?.cancel();

    if (_tokenExpiryTime == null) {
      return;
    }

    final duration = _tokenExpiryTime!.difference(DateTime.now());

    if (duration.isNegative) {
      _handleTokenExpiry();
      return;
    }

    // Logout 30 seconds before actual expiry
    final logoutDuration = duration - const Duration(seconds: 30);

    if (logoutDuration.isNegative) {
      _handleTokenExpiry();
      return;
    }

    _tokenExpiryTimer = Timer(logoutDuration, () {
      _handleTokenExpiry();
    });
  }

  void _handleTokenExpiry() {
    logout('Your session has expired. Please login again.');
  }

  // Logout and clear all data
  Future<void> logout([String? message]) async {
    _tokenExpiryTimer?.cancel();
    _tokenExpiryTimer = null;
    _isInitialized = false;
    _tokenExpiryTime = null;

    // Clear all stored session data completely
    await clearUserSession();

    // Navigate to login screen if context is available
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
    }
  }

  void dispose() {
    // print(' Disposing TokenManager');
    _tokenExpiryTimer?.cancel();
    _isInitialized = false;
  }
}
