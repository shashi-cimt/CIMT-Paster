import 'dart:math';
import 'package:camera/camera.dart';
import 'package:canimage/APIService/auth_service.dart';
import 'package:canimage/utils/DeviceIdManager.dart';
import 'package:canimage/utils/crash_manager.dart';
import 'package:canimage/utils/security_guard_widget.dart' show SecurityGuard;
import 'package:canimage/utils/shared_preference.dart';
import 'package:canimage/utils/token_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Hive_Database/Map_pointer_locate_db.dart';
import 'Hive_Database/Rework_image_upload_db.dart';
import 'Hive_Database/execution_seeplan_location_db.dart';
import 'Hive_Database/post_recca_image_upload_db.dart';
import 'Hive_Database/post_recca_seePlan_db.dart';
import 'Hive_Database/execution_image_upload_db.dart';
import 'Hive_Database/offline_count_db.dart';
import 'Hive_Database/plan_offline_count_db.dart';
import 'Hive_Database/remarks_db.dart';
import 'Hive_Database/resend_db.dart';
import 'Hive_Database/execution_seeplan_db.dart';
import 'Hive_Database/rework_db.dart';
import 'Hive_Database/upload_count_db.dart';
import 'Hive_Database/village_artwork_db.dart';
import 'Repository/execution_image_upload_repository.dart';
import 'Repository/post_recca_image_upload_repository.dart';
import 'Repository/execution_resend_repository.dart';
import 'Screens/splash_screen.dart';
import 'Screens/ExecutionSeePlans/execution_upload_see_plan.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/l10n.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

List<CameraDescription>? cameras;

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await DeviceIdManager.init();
    print("Device ID initialized: ${await DeviceIdManager.getDeviceId()}");

    // ========== INITIALIZE CAMERAS BEFORE APP STARTS ==========
    try {
      cameras = await availableCameras();
      if (cameras != null && cameras!.isNotEmpty) {
        print("📷 Found ${cameras!.length} cameras");
        for (var cam in cameras!) {
          print("   - ${cam.name} (${cam.lensDirection})");
        }
      } else {
        print(" No cameras found on device");
        cameras = [];
      }
    } catch (e) {
      print(" Error initializing cameras: $e");
      cameras = [];
    }

    // ========== INITIALIZE FIREBASE ==========
    await Firebase.initializeApp();

    // ========== SETUP CRASHLYTICS ==========
    await _setupCrashlytics();

    // ========== INITIALIZE AUTH ==========
    Auth.initialize();

    // ========== INITIALIZE HIVE ==========
    await _initializeHive();

    // ========== SET PREFERRED ORIENTATIONS ==========
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // ========== RUN APP ==========
    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  }, (error, stack) async {
    await CrashReportManager.storeCrashReport(
      error: error.toString(),
      stackTrace: stack.toString(),
    );
  });
}

Future<void> _setupCrashlytics() async {
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    CrashReportManager.storeCrashReport(
      error: errorDetails.exceptionAsString(),
      stackTrace: errorDetails.stack?.toString() ?? StackTrace.current.toString(),
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    CrashReportManager.storeCrashReport(
      error: error.toString(),
      stackTrace: stack.toString(),
    );
    return true;
  };

  CrashReportManager.setupGlobalErrorHandling();
  await CrashReportManager.storeLogMessage("App starting up...");
  await FirebaseCrashlytics.instance.setUserIdentifier("user_${DateTime.now().millisecondsSinceEpoch}");

  await _reportUnresolvedCameraMarker();

  if (kDebugMode) {
    // await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  } else {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  }
}

Future<void> _initializeHive() async {
  await Hive.initFlutter();
  Hive.registerAdapter(PlanItemAdapter());
  Hive.registerAdapter(VillageArtworkAdapter());
  Hive.registerAdapter(ImageUploaddataAdapter());
  Hive.registerAdapter(SUPlanModelAdapter());
  Hive.registerAdapter(SUImageUploaddataAdapter());
  Hive.registerAdapter(OfflineCountAdapter());
  Hive.registerAdapter(RemarksAdapter());
  Hive.registerAdapter(ApiResponseDataAdapter());
  Hive.registerAdapter(PlanOfflineCountAdapter());
  Hive.registerAdapter(UploadCountDataAdapter());
  Hive.registerAdapter(ReworkModelAdapter());
  Hive.registerAdapter(ReworkImageUploadDataAdapter());
  Hive.registerAdapter(LocationItemAdapter());
  Hive.registerAdapter(CapturedLocateAdapter());
  await Hive.openBox<CapturedLocate>('capturedLocates');
}

Future<void> _reportUnresolvedCameraMarker() async {
  try {
    final docs = await getApplicationDocumentsDirectory();
    final file = File('${docs.path}/CIMTDWP/last_camera_action.json');
    if (await file.exists()) {
      final content = await file.readAsString();
      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(content);
      } catch (e) {
        data = {'raw': content};
      }

      try {
        await FirebaseCrashlytics.instance.setCustomKey('camera_marker_unresolved', true);
        await FirebaseCrashlytics.instance.log('Unresolved camera marker found at startup');
        await FirebaseCrashlytics.instance.recordError(
          Exception('Unresolved camera-in-flight detected at startup'),
          StackTrace.current,
          fatal: false,
        );
      } catch (e) {
        await CrashReportManager.storeLogMessage('Crashlytics record failed for unresolved marker: $e');
      }

      await CrashReportManager.storeCrashReport(
        error: 'Unresolved camera marker at startup',
        stackTrace: content,
        additionalInfo: data,
      );
    } else {
      try {
        await FirebaseCrashlytics.instance.setCustomKey('camera_marker_unresolved', false);
      } catch (e) {}
    }
  } catch (e) {
    await CrashReportManager.storeLogMessage('Failed to check camera marker at startup: $e');
  }
}

bool isManualSyncing = false;
bool isBackgroundSyncInProgress = false;
bool isPrintSyncInProgress = false;
bool isSyncAllInProgress = false;
final backgroundSyncCompletedProvider = StateProvider<int>((ref) => 0);
final backgroundSyncStatusProvider = StateProvider<bool>((ref) => false);
final pendingSyncCountProviderPlan = StateProvider<int>((ref) => 0);

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final Auth _apiService = Auth();
  final ExecutionImageUploadHiveRepository _hiveRepository =
  ExecutionImageUploadHiveRepository();
  final PostReccaImageUploadHiveRepository _suHiveRepository =
  PostReccaImageUploadHiveRepository();
  Locale _locale = Locale('en');

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isConnected = false;
  Timer? _syncTimer;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  DateTime? _lastSyncTime;
  static const Duration _minSyncInterval = Duration(minutes: 3);

  @override
  void initState() {
    super.initState();
    TokenManager().navigatorKey = _navigatorKey;
    WidgetsBinding.instance.addObserver(this);
    _initConnectivity();
    _startConnectivityListener();
    _startPeriodicSync();
    _loadLanguagePreference();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    TokenManager().dispose();
    super.dispose();
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      await FirebaseCrashlytics.instance.recordError(e, null, fatal: false);
    }
  }

  void _startConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
          (List<ConnectivityResult> results) {
        _updateConnectionStatus(results);
      },
      onError: (error) async {
        await FirebaseCrashlytics.instance.recordError(error, null, fatal: false);
      },
    );
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    bool wasConnected = _isConnected;
    _isConnected = results.any((result) =>
    result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet);

    if (!wasConnected && _isConnected && !isManualSyncing) {
      if (!UploadSeePlanScreen.isCameraActive) {
        Future.delayed(Duration(seconds: 2), () {
          _checkAndSyncPendingUploads();
          _SUcheckAndSyncPendingUploads();
        });
      } else {
        print(" Camera is active, skipping connectivity-triggered sync");
      }
    }
  }

  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(Duration(minutes: 5), (timer) async {
      if (UploadSeePlanScreen.isCameraActive) {
        print(" Camera is active, skipping periodic sync");
        return;
      }

      if (_isConnected && !isManualSyncing) {
        _checkAndSyncPendingUploads();
        _SUcheckAndSyncPendingUploads();
      }
    });
  }

  bool _shouldSync() {
    if (_lastSyncTime == null) return true;
    return DateTime.now().difference(_lastSyncTime!) > _minSyncInterval;
  }

  Future<bool> acquireBackgroundSyncLock() async {
    if (isPrintSyncInProgress || isSyncAllInProgress) {
      return false;
    }
    isBackgroundSyncInProgress = true;
    return true;
  }

  void releaseBackgroundSyncLock() {
    isBackgroundSyncInProgress = false;

    try {
      final container = ProviderScope.containerOf(context, listen: false);
      container.read(backgroundSyncStatusProvider.notifier).state = false;
    } catch (e) {
      // print(' Error updating background sync status provider: $e');
    }
  }

  Future<void> _checkAndSyncPendingUploads() async {
    // Try to acquire lock
    if (!await acquireBackgroundSyncLock()) {
      return;
    }

    try {
      // Check network
      if (!_isConnected) {
        return;
      }

      // Check authentication
      final tokenCheck = await getAuthToken();
      if (tokenCheck == null || tokenCheck.isEmpty) {
        return;
      }

      // Small delay to ensure app stability
      await Future.delayed(Duration(seconds: 2));

      // Load metadata ONCE at the start
      final metadataList = await _hiveRepository.getAllMetadata();

      if (metadataList.isEmpty) {
        return;
      }

      _lastSyncTime = DateTime.now();

      // Update UI state
      try {
        final container = ProviderScope.containerOf(context, listen: false);
        container.read(backgroundSyncStatusProvider.notifier).state = true;
      } catch (e) {
        // print(' Error updating sync status: $e');
      }

      // Track which items were successfully synced
      Set<String> successfullyDeletedKeys = {};
      int successCount = 0;
      int failureCount = 0;

      // Call API with all metadata
      dynamic result = await _apiService.syncAllPlanMetadata(metadataList);

      if (result is Map<String, dynamic>) {
        if (result.containsKey('results') && result['results'] is List) {
          List<dynamic> results = result['results'];

          for (var planResult in results) {
            if (planResult is Map<String, dynamic> && planResult.containsKey('planId')) {
              String planId = planResult['planId'].toString();
              bool planSuccess = planResult['success'] ?? false;
              String? printIdFromResponse;

              if (planResult.containsKey('data') && planResult['data'] is Map<String, dynamic>) {
                printIdFromResponse = planResult['data']['printId']?.toString();
              }

              // Find matching metadata
              String responsePrintNo = '';

              if (planResult['data'] != null) {
                responsePrintNo =
                    planResult['data']['printNo']?.toString().trim().toUpperCase() ?? '';
              }

              var metadata = metadataList.firstWhere(
                    (item) =>
                item.ServerPlanId == planId &&
                    (item.PrintNo ?? '').trim().toUpperCase() == responsePrintNo,
                orElse: () {
                  throw Exception(
                    'Metadata not found for PlanId=$planId PrintNo=$responsePrintNo',
                  );
                },
              );

              String printNo = metadata.PrintNo.toString();
              String uniqueKey = "${planId}_${printNo}";

              if (planSuccess) {
                successCount++;

                // CRITICAL: Delete from Hive immediately after success
                try {
                  await _hiveRepository.deleteMetadata(
                    planId,
                    metadata.PrintNo!,
                  );
                  successfullyDeletedKeys.add(uniqueKey);
                  // print(' Deleted $uniqueKey from Hive');
                } catch (deleteError) {
                  // print(' Error deleting $uniqueKey: $deleteError');
                }

                // Save response
                final apiResponseRepo = ApiResponseRepository();
                print("==============");
                print("Matched Print : ${metadata.PrintNo}");
                print("Response Print: $responsePrintNo");
                print("PlanId        : $planId");
                print("==============");
                await apiResponseRepo.saveApiResponse(ApiResponseData(
                  planId: planId,
                  originalData: metadata,
                  isSuccess: true,
                  responseMessage: 'Background sync: Success',
                  responseTime: DateTime.now(),
                  statusCode: 200,
                ));
              } else {
                failureCount++;
                // print(' Sync failed for print $printNo');
              }
            }
          }
        }
      }

      // print(' Background sync completed: $successCount success, $failureCount failed');
      await FirebaseCrashlytics.instance.log(
          'Background sync: $successCount success, $failureCount failed'
      );

      // Wait for all Hive operations to complete
      await Future.delayed(Duration(milliseconds: 1500));

      // Verify deletions
      final remainingItems = await _hiveRepository.getAllMetadata();
      // print(' Items remaining in Hive: ${remainingItems.length}');

      // Notify UI to refresh
      _notifyPrintSyncRefresh(remainingItems.length);

      // Show toast only if there were items to sync
      if (metadataList.isNotEmpty) {
        String message;
        if (successCount > 0 && failureCount == 0) {
          message = "✓ All $successCount prints synced & cleared";
        } else if (successCount > 0 && failureCount > 0) {
          message = "✓ $successCount synced, ✗ $failureCount failed";
        } else {
          message = "✗ All $failureCount prints failed";
        }

        Fluttertoast.showToast(
          msg: message,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: successCount > 0 ? Colors.green : Colors.red,
          textColor: Colors.white,
        );
      }

    } catch (e, stackTrace) {
      // print(' Background sync error: $e');
      await FirebaseCrashlytics.instance.recordError(e, stackTrace, fatal: false);

      Fluttertoast.showToast(
        msg: "Background sync failed: ${e.toString().substring(0, min(50, e.toString().length))}",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      // print(' Releasing background sync lock');
      releaseBackgroundSyncLock();
    }
  }

  void _notifyPrintSyncRefresh(int remainingCount) async {
    try {
      final container = ProviderScope.containerOf(context, listen: false);

      container.read(backgroundSyncStatusProvider.notifier).state = false;

      await Future.delayed(Duration(milliseconds: 500));

      container.read(pendingSyncCountProviderPlan.notifier).state = remainingCount;

      final currentValue = container.read(backgroundSyncCompletedProvider);
      final newValue = currentValue + 1;
      container.read(backgroundSyncCompletedProvider.notifier).state = newValue;

      await Future.delayed(Duration(milliseconds: 500));

    } catch (e) {
      print(' Error in _notifyPrintSyncRefresh: $e');
      await FirebaseCrashlytics.instance.recordError(e, null, fatal: false);
    }
  }

  Future<void> _SUcheckAndSyncPendingUploads() async {
    if (UploadSeePlanScreen.isCameraActive) {
      print(" Camera is active, skipping SU background sync");
      return;
    }

    if (isManualSyncing) return;

    if (!_isConnected) {
      await FirebaseCrashlytics.instance.log('SU Sync skipped: No network connectivity');
      return;
    }

    try {
      final metadataList = await _suHiveRepository.getAllMetadata();

      if (metadataList.isEmpty) {
        return;
      }

      await FirebaseCrashlytics.instance.log('Starting SU background sync for ${metadataList.length} items');
      await _apiService.syncAllMetadata(metadataList);
      await FirebaseCrashlytics.instance.log('SU background sync completed');
    } catch (e, stackTrace) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        fatal: false,
        information: [
          'SU Background sync error',
          'Function: _SUcheckAndSyncPendingUploads',
        ],
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (UploadSeePlanScreen.isCameraActive) {
      print(" Camera is active, skipping lifecycle sync");
      return;
    }

    if (state == AppLifecycleState.paused && !isManualSyncing && _isConnected && _shouldSync()) {
      _checkAndSyncPendingUploads();
      _SUcheckAndSyncPendingUploads();
    }
    else if (state == AppLifecycleState.resumed && !isManualSyncing && _isConnected && _shouldSync()) {
      Future.delayed(Duration(seconds: 1), () {
        _checkAndSyncPendingUploads();
        _SUcheckAndSyncPendingUploads();
      });
    }
  }

  void _changeLanguage(String languageCode) {
    setState(() {
      _locale = Locale(languageCode);
    });
  }

  void _loadLanguagePreference() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedLanguage = prefs.getString('language');

      setState(() {
        _locale = savedLanguage != null ? Locale(savedLanguage) : Locale('en');
      });
    } catch (e, stackTrace) {
      await FirebaseCrashlytics.instance.recordError(e, stackTrace, fatal: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Can Image',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      locale: _locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        S.delegate,
      ],
      supportedLocales: [
        Locale('en', ''),
        Locale('hi', ''),
        Locale('mr', ''),
        Locale('bn', ''),
        Locale('ta', ''),
        Locale('gu', ''),
      ],
      builder: (context, child) {
        if (kReleaseMode) {
          return SecurityGuard(
            enablePeriodicCheck: true,
            onSecurityViolation: () {
              try {
                FirebaseCrashlytics.instance.log(
                  'Security violation detected: Developer mode or mock location',
                );

                FirebaseCrashlytics.instance
                    .recordError(
                  Exception('Security violation detected'),
                  StackTrace.current,
                  fatal: false,
                )
                    .catchError((e) {
                  CrashReportManager.storeLogMessage(
                      'Crashlytics.recordError failed: $e');
                });
              } catch (e) {
                CrashReportManager.storeLogMessage(
                    'Security violation logging failed: $e');
              }
            },
            child: child ?? const SizedBox.shrink(),
          );
        }

        return child ?? const SizedBox.shrink();
      },
      home: SplashScreen(changeLanguage: _changeLanguage),
    );
  }
}