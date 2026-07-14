import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class SecurityValidationResult {
  final bool isDeveloperModeEnabled;
  final bool isMockLocationEnabled;
  final bool isLocationServicesEnabled;
  final String? error;

  SecurityValidationResult({
    required this.isDeveloperModeEnabled,
    required this.isMockLocationEnabled,
    required this.isLocationServicesEnabled,
    this.error,
  });

  bool get hasIssues => isDeveloperModeEnabled || isMockLocationEnabled || !isLocationServicesEnabled;

  List<String> get issuesList {
    List<String> issues = [];
    if (isDeveloperModeEnabled) issues.add("• Developer Mode is enabled");
    if (isMockLocationEnabled) issues.add("• Mock Location is enabled");
    if (!isLocationServicesEnabled) issues.add("• Location services are disabled");
    return issues;
  }
}

class SecurityService {
  static const platform = MethodChannel('com.canimage/device_policies');
  Timer? _periodicCheckTimer;

  Future<bool> checkDeveloperMode() async {
    try {
      final bool isDeveloperMode = await platform.invokeMethod('isDeveloperModeEnabled');
      // print("Developer Mode Check Result: $isDeveloperMode");
      return isDeveloperMode;
    } on PlatformException catch (e) {
      // print("Platform Exception checking developer mode: ${e.code} - ${e.message}");
      // Return true to be safe - if we can't check, assume it's enabled
      return true;
    } catch (e) {
      // print("Error checking developer mode: $e");
      // Return true to be safe - if we can't check, assume it's enabled
      return true;
    }
  }

  Future<bool> checkMockLocation() async {
    try {
      final bool isMockAllowed = await platform.invokeMethod('isMockLocationAllowed');
      // print("Mock Location Check Result: $isMockAllowed");
      return isMockAllowed;
    } on PlatformException catch (e) {
      // print("Platform Exception checking mock location: ${e.code} - ${e.message}");
      // Return true to be safe - if we can't check, assume it's enabled
      return true;
    } catch (e) {
      // print("Error checking mock location: $e");
      // Return true to be safe - if we can't check, assume it's enabled
      return true;
    }
  }

  Future<bool> checkLocationServicesEnabled() async {
    try {
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      // print("Location Services Check Result: $isEnabled");
      return isEnabled;
    } catch (e) {
      // print("Error checking location services: $e");
      // Return false to indicate location is not available
      return false;
    }
  }

  Future<SecurityValidationResult> performValidation() async {
    // print("=== Starting Security Validation ===");

    final isDeveloperMode = await checkDeveloperMode();
    final isMockLocation = await checkMockLocation();
    final isLocationEnabled = await checkLocationServicesEnabled();

    final result = SecurityValidationResult(
      isDeveloperModeEnabled: isDeveloperMode,
      isMockLocationEnabled: isMockLocation,
      isLocationServicesEnabled: isLocationEnabled,
    );

    // print("Validation Complete - Has Issues: ${result.hasIssues}");
    if (result.hasIssues) {
      // print("Issues Found: ${result.issuesList}");
    }

    return result;
  }

  void startPeriodicValidation(Function(SecurityValidationResult) onValidationResult) {
    // print("Starting periodic security validation (every 5 seconds)");
    _periodicCheckTimer?.cancel();

    // Perform immediate validation first
    performValidation().then((result) {
      onValidationResult(result);
    });

    // Then start periodic checks
    _periodicCheckTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      final result = await performValidation();
      onValidationResult(result);
    });
  }

  void stopPeriodicValidation() {
    // print("Stopping periodic security validation");
    _periodicCheckTimer?.cancel();
  }

  void dispose() {
    stopPeriodicValidation();
  }
}

final securityServiceProvider = Provider<SecurityService>((ref) {
  final service = SecurityService();
  ref.onDispose(() => service.dispose());
  return service;
});

class SecurityStateNotifier extends StateNotifier<SecurityValidationResult?> {
  final SecurityService _securityService;

  SecurityStateNotifier(this._securityService) : super(null) {
    // Perform initial validation immediately
    _performInitialValidation();
  }

  Future<void> _performInitialValidation() async {
    // print("Performing initial security validation");
    await validate();
  }

  Future<void> validate() async {
    final result = await _securityService.performValidation();
    state = result;
  }

  void startMonitoring() {
    // print("Starting security monitoring");
    _securityService.startPeriodicValidation((result) {
      state = result;
    });
  }

  void stopMonitoring() {
    _securityService.stopPeriodicValidation();
  }
}

final securityStateProvider = StateNotifierProvider<SecurityStateNotifier, SecurityValidationResult?>((ref) {
  final service = ref.watch(securityServiceProvider);
  return SecurityStateNotifier(service);
});