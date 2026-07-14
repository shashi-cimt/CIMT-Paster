import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:android_intent_plus/android_intent.dart';
import '../generated/l10n.dart';
import 'security_service.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../utils/base.dart';
import '../utils/shared_preference.dart';

class SecurityGuard extends ConsumerStatefulWidget {
  final Widget child;
  final bool enablePeriodicCheck;
  final VoidCallback? onSecurityViolation;

  const SecurityGuard({
    Key? key,
    required this.child,
    this.enablePeriodicCheck = true,
    this.onSecurityViolation,
  }) : super(key: key);

  @override
  ConsumerState<SecurityGuard> createState() => _SecurityGuardState();
}

class _SecurityGuardState extends ConsumerState<SecurityGuard> with WidgetsBindingObserver {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // print("SecurityGuard: initState called");

    // Add observer to detect when app comes back to foreground
    WidgetsBinding.instance.addObserver(this);

    // Initialize security check immediately
    _initializeSecurity();
  }

  void _initializeSecurity() {
    if (_isInitialized) return;
    _isInitialized = true;

    // print("SecurityGuard: Initializing security checks");

    // Perform immediate validation after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // print("SecurityGuard: Running immediate validation");
        ref.read(securityStateProvider.notifier).validate();

        // Start periodic monitoring if enabled
        if (widget.enablePeriodicCheck) {
          // print("SecurityGuard: Starting periodic monitoring");
          ref.read(securityStateProvider.notifier).startMonitoring();
        }
      }
    });
  }

  @override
  void dispose() {
    // print("SecurityGuard: dispose called");
    WidgetsBinding.instance.removeObserver(this);
    if (widget.enablePeriodicCheck) {
      ref.read(securityStateProvider.notifier).stopMonitoring();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // print("SecurityGuard: App lifecycle state changed to $state");

    // When app comes back to foreground, recheck security immediately
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        // print("SecurityGuard: App resumed, rechecking security");
        Future.delayed(Duration(milliseconds: 300), () {
          if (mounted) {
            ref.read(securityStateProvider.notifier).validate();
          }
        });
      }
    }
  }

  // NEW: Method to send developer mode log to API
  Future<void> _sendDevModeLog() async {
    try {
      String getToken = await getAuthToken();

      String uid = await getFirstUID(); // You can make this dynamic if needed
      String fetchDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // print("SecurityGuard: Sending developer mode log to API");

      Dio dio = Dio();
      Response response = await dio.get(
        "${APIURLs.baseURL}api/Master/DevMode-Logs?UID=$uid&FetchDate=$fetchDate",
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': getToken,
          },
        ),
      );

      if (response.statusCode == 200) {
        // print("SecurityGuard: Developer mode log sent successfully");
        // print("Response: ${response.data}");
      } else {
        // print("SecurityGuard: Failed to send developer mode log - Status: ${response.statusCode}");
      }
    } catch (e) {
      // print("SecurityGuard: Error sending developer mode log: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final securityState = ref.watch(securityStateProvider);

    // Use overlay instead of dialog - no Navigator needed!
    if (securityState != null && securityState.hasIssues) {
      // print("SecurityGuard: Showing security overlay (hasIssues: true)");
      widget.onSecurityViolation?.call();

      // NEW: Send API log when developer mode is detected
      if (securityState.isDeveloperModeEnabled) {
        // print("SecurityGuard: Developer mode detected, sending API log");
        _sendDevModeLog();
      }

      return Stack(
        children: [
          // Original app content (dimmed and non-interactive)
          IgnorePointer(
            child: widget.child,
          ),
          // Security overlay blocking everything
          Container(
            color: Colors.black.withOpacity(0.9),
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Card(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 64,
                        ),
                        SizedBox(height: 16),
                        Text(
                          S.of(context).securityWarning,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          S.of(context).securityIssuesDetected,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ...securityState.issuesList.map((issue) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  issue.replaceAll('• ', ''),
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    S.of(context).howToFix,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              if (securityState.isDeveloperModeEnabled ||
                                  securityState.isMockLocationEnabled) ...[
                                Text(
                                  '1. ${S.of(context).tapOpenSettings}\n'
                                      '2. ${S.of(context).turnOFFDeveloperOptions}\n'
                                      '3. ${S.of(context).turnOFFMockLocation}\n'
                                      '4. ${S.of(context).returnApp}',
                                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                ),
                              ],
                              if (!securityState.isLocationServicesEnabled) ...[
                                Text(
                                  '1. ${S.of(context).tapOpenSettings}\n'
                                      '2. ${S.of(context).turnONLocationServices}\n'
                                      '3. ${S.of(context).returnApp}',
                                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton.icon(
                                icon: Icon(Icons.exit_to_app, size: 18),
                                label: Text(S.of(context).exitApp),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: () {
                                  // print("SecurityGuard: User pressed Exit App");
                                  SystemNavigator.pop();
                                },
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: Icon(Icons.settings, size: 18),
                                label: Text(S.of(context).settings),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: () async {
                                  // print("SecurityGuard: User pressed Open Settings");
                                  await _openRelevantSettings(securityState);
                                },
                              ),
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
        ],
      );
    }

    // print("SecurityGuard: No security issues, showing normal content");
    return widget.child;
  }

  // Open Developer Options settings
  Future<void> _openDeveloperOptions() async {
    try {
      // print("SecurityGuard: Opening Developer Options");
      final AndroidIntent intent = AndroidIntent(
        action: 'android.settings.APPLICATION_DEVELOPMENT_SETTINGS',
      );
      await intent.launch();
    } catch (e) {
      // print('Error opening developer options: $e');
      await _openGeneralSettings();
    }
  }

  // Open Location Settings
  Future<void> _openLocationSettings() async {
    try {
      // print("SecurityGuard: Opening Location Settings");
      final AndroidIntent intent = AndroidIntent(
        action: 'android.settings.LOCATION_SOURCE_SETTINGS',
      );
      await intent.launch();
    } catch (e) {
      // print('Error opening location settings: $e');
      await _openGeneralSettings();
    }
  }

  // Open General Settings as fallback
  Future<void> _openGeneralSettings() async {
    try {
      // print("SecurityGuard: Opening General Settings");
      final AndroidIntent intent = AndroidIntent(
        action: 'android.settings.SETTINGS',
      );
      await intent.launch();
    } catch (e) {
      // print('Error opening settings: $e');
    }
  }

  // Determine which settings page to open based on issues
  Future<void> _openRelevantSettings(SecurityValidationResult result) async {
    if (result.isDeveloperModeEnabled || result.isMockLocationEnabled) {
      await _openDeveloperOptions();
    } else if (!result.isLocationServicesEnabled) {
      await _openLocationSettings();
    } else {
      await _openGeneralSettings();
    }
  }
}