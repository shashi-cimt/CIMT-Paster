import 'dart:math';
import 'package:canimage/APIService/auth_service.dart';
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
import 'Hive_Database/execution_image_draft_db.dart';
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
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/l10n.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await Firebase.initializeApp();
  await _setupCrashlytics();
  /// New Developermode code add
  if (kReleaseMode) {
    FlutterError.onError =
        FirebaseCrashlytics.instance.recordFlutterFatalError;
  }
  ///

  try {
    Auth.initialize();
    await _initializeHive();
    runApp(ProviderScope(child: MyApp()));
  } catch (e, stackTrace) {
    await FirebaseCrashlytics.instance.recordError(
      e,
      stackTrace,
      fatal: false,
      information: [
        'Error during app initialization',
        'Phase: App Initialization',
        'Timestamp: ${DateTime.now().toIso8601String()}',
      ],
    );

    await CrashReportManager.storeCrashReport(
      error: "Error during app initialization: $e",
      stackTrace: stackTrace.toString(),
      additionalInfo: {
        'phase': 'App Initialization',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    runApp(ProviderScope(child: MyApp()));
  }
}

Future<void> _setupCrashlytics() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  CrashReportManager.setupGlobalErrorHandling();
  await CrashReportManager.storeLogMessage("App starting up...");
  await FirebaseCrashlytics.instance.setUserIdentifier("user_${DateTime.now().millisecondsSinceEpoch}");

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
  Hive.registerAdapter(ExecutionImageDraftAdapter());
  Hive.registerAdapter(SUPlanModelAdapter());
  Hive.registerAdapter(SUImageUploaddataAdapter());
  Hive.registerAdapter(OfflineCountAdapter());
  Hive.registerAdapter(RemarksAdapter());
  Hive.registerAdapter(ApiResponseDataAdapter());
  Hive.registerAdapter(PlanOfflineCountAdapter());
  Hive.registerAdapter(UploadCountDataAdapter()) ;
  Hive.registerAdapter(ReworkModelAdapter());
  Hive.registerAdapter(ReworkImageUploadDataAdapter());
  Hive.registerAdapter(LocationItemAdapter());
  Hive.registerAdapter(CapturedLocateAdapter());
  await Hive.openBox<CapturedLocate>('capturedLocates');
}

bool isManualSyncing = false;
bool isBackgroundSyncInProgress = false;  // NEW: Track background sync separately
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

  // NEW: Listen for connectivity changes
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

  // NEW: Update connection status and trigger sync when network comes back
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    bool wasConnected = _isConnected;
    _isConnected = results.any((result) =>
    result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet
    );

    // If connection was restored, trigger sync
    if (!wasConnected && _isConnected && !isManualSyncing) {
      // FirebaseCrashlytics.instance.log('Network connectivity restored, triggering sync');
      Future.delayed(Duration(seconds: 2), () {
        _checkAndSyncPendingUploads();
        _SUcheckAndSyncPendingUploads();
      });
    }
  }

  // NEW: Periodic sync every 5 minutes when connected
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(Duration(minutes: 5), (timer) async {
      if (_isConnected && !isManualSyncing) {
        // await FirebaseCrashlytics.instance.log('Periodic sync triggered');
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
      return false; // Manual sync is in progress
    }
    isBackgroundSyncInProgress = true;
    return true;
  }

  void releaseBackgroundSyncLock() {
    isBackgroundSyncInProgress = false;

    // Also update the provider
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
      // print(' Starting UI refresh notification...');

      final container = ProviderScope.containerOf(context, listen: false);

      // Reset background sync status
      container.read(backgroundSyncStatusProvider.notifier).state = false;
      // print('Reset background sync status');

      // Wait for state to propagate
      await Future.delayed(Duration(milliseconds: 500));

      // Update pending count with actual remaining count
      container.read(pendingSyncCountProviderPlan.notifier).state = remainingCount;
      // print(' Updated pendingSyncCountProviderPlan to: $remainingCount');

      // Increment completion counter to trigger listeners
      final currentValue = container.read(backgroundSyncCompletedProvider);
      final newValue = currentValue + 1;
      container.read(backgroundSyncCompletedProvider.notifier).state = newValue;
      // print(' Incremented backgroundSyncCompletedProvider: $currentValue -> $newValue');

      // Additional delay for UI propagation
      await Future.delayed(Duration(milliseconds: 500));

      // print(0 UI refresh notification completed');

    } catch (e) {
      // print(' Error in _notifyPrintSyncRefresh: $e');
      await FirebaseCrashlytics.instance.recordError(e, null, fatal: false);
    }
  }



  // UPDATED: Check network before syncing
  Future<void> _SUcheckAndSyncPendingUploads() async {
    if (isManualSyncing) return;

    // Check network connectivity first
    if (!_isConnected) {
      await FirebaseCrashlytics.instance.log('SU Sync skipped: No network connectivity');
      return;
    }

    try {
      final _hiveRepository = PostReccaImageUploadHiveRepository();
      final metadataList = await _hiveRepository.getAllMetadata();

      if (metadataList.isEmpty) {
        return; // Nothing to sync
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
    if (state == AppLifecycleState.paused && !isManualSyncing && _isConnected && _shouldSync()) {
      _checkAndSyncPendingUploads();
      _SUcheckAndSyncPendingUploads();
    }
    // Also check when app resumes
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

      navigatorKey: _navigatorKey, //
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
      // CRITICAL FIX: Use builder to wrap entire app
      // builder: (context, child) {
      //   return SecurityGuard(
      //     enablePeriodicCheck: true,
      //     onSecurityViolation: () {
      //       print('Security violation detected!');
      //       // Log to Crashlytics
      //       // FirebaseCrashlytics.instance.log('Security violation: Developer mode or mock location detected');
      //     },
      //     child: child ?? SizedBox.shrink(),
      //   );
      // },
      // Remove SecurityGuard from home - it's now wrapping everything via builder
      /// developer mode add on releaseMode
      builder: (context, child) {
        // 🔴 Only wrap in RELEASE mode
        if (kReleaseMode) {
          return SecurityGuard(
            enablePeriodicCheck: true,
            onSecurityViolation: () {
              // Log to Crashlytics in release only
              FirebaseCrashlytics.instance.log(
                'Security violation detected: Developer mode or mock location',
              );

              FirebaseCrashlytics.instance.recordError(
                Exception('Security violation detected'),
                StackTrace.current,
                fatal: false,
              );
            },
            child: child ?? const SizedBox.shrink(),
          );
        }

        // 🟢 Debug / Profile → normal app
        return child ?? const SizedBox.shrink();
      },
      ///
      home: SplashScreen(changeLanguage: _changeLanguage),
    );
  }
}