import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'dart:isolate';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../Hive_Database/execution_image_upload_db.dart';
import 'DeviceIdManager.dart';

class CrashReportManager {
  /// Store crash report in external storage with fallback
  /// Also sends to Firebase Crashlytics
  static Future<String> storeCrashReport({
    required String error,
    required String stackTrace,
    Map<String, dynamic>? additionalInfo,
    String? reason,
  }) async {
    String filePath = '';
    try {
      // 1. Store locally
      filePath = await _storeCrashReportExternal(error, stackTrace, additionalInfo);

      // 2. Send to Firebase Crashlytics
      await _sendToFirebaseCrashlytics(error, stackTrace, additionalInfo, reason);

      return filePath;
    } catch (e) {
      // print(' Error in external crash storage, using fallback: $e');
      try {
        filePath = await _storeCrashReportFallback(error, stackTrace, additionalInfo);
        // Still try to send to Firebase even if local storage fails
        await _sendToFirebaseCrashlytics(error, stackTrace, additionalInfo, reason);
        return filePath;
      } catch (e2) {
        // If even Firebase fails, just return the error
        return 'Failed to store crash report: $e2';
      }
    }
  }

  /// Store a simple log message with external storage
  /// Also sends to Firebase Crashlytics log
  static Future<String> storeLogMessage(String message) async {
    String filePath = '';
    try {
      // 1. Store locally
      filePath = await _storeLogMessageLocal(message);

      // 2. Send to Firebase Crashlytics log
      await _sendToFirebaseLog(message);

      return filePath;
    } catch (e) {
      // print(' Error storing log message: $e');
      // Don't throw here - logging should be non-blocking
      return 'Failed to store log: $e';
    }
  }

  /// Store log message only locally (without Firebase)
  static Future<String> _storeLogMessageLocal(String message) async {
    try {
      Directory? logDir;

      // Try to get external storage directory first
      try {
        Directory? externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          Directory cimtdwpDir = Directory('${externalDir.path}/CIMTDWP');
          if (await cimtdwpDir.exists() || await _canCreateDirectory(cimtdwpDir)) {
            logDir = Directory('${cimtdwpDir.path}/Logs/AppLogs');
          }
        }
      } catch (e) {
        // External storage not accessible
      }

      // Fallback to app documents directory
      if (logDir == null) {
        Directory appDocDir = await getApplicationDocumentsDirectory();
        logDir = Directory('${appDocDir.path}/Logs/AppLogs');
      }

      // Create the folder if it does not exist
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      // Create log entry
      Map<String, dynamic> logEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'message': message,
      };

      // Generate filename with date
      String dateString = DateTime.now().toIso8601String().substring(0, 10);
      String fileName = 'app_log_$dateString.json';

      // Define the full path where the log will be stored
      String filePath = '${logDir.path}/$fileName';
      File logFile = File(filePath);

      // Append to existing log file or create new one
      List<Map<String, dynamic>> existingLogs = [];
      if (await logFile.exists()) {
        try {
          String existingContent = await logFile.readAsString();
          List<dynamic> decoded = jsonDecode(existingContent);
          existingLogs = decoded.cast<Map<String, dynamic>>();
        } catch (e) {
          // Continue with empty logs list
        }
      }

      existingLogs.add(logEntry);

      // Keep only last 1000 log entries to prevent file from getting too large
      if (existingLogs.length > 1000) {
        existingLogs = existingLogs.sublist(existingLogs.length - 1000);
      }

      // Write updated logs to file
      await logFile.writeAsString(
        JsonEncoder.withIndent('  ').convert(existingLogs),
        encoding: utf8,
      );

      // print(' Log message saved to: $filePath');
      return filePath;

    } catch (e) {
      // print(' Error storing log message: $e');
      // Don't throw here - logging should be non-blocking
      return 'Failed to store log: $e';
    }
  }

  /// Send log message to Firebase Crashlytics
  static Future<void> _sendToFirebaseLog(String message) async {
    try {
      // Add timestamp to log
      final timestamp = DateTime.now().toIso8601String();
      final logEntry = "$timestamp | $message";

      // Send to Firebase Crashlytics log
      FirebaseCrashlytics.instance.log(logEntry);

      // Also set as custom key for easier filtering
      FirebaseCrashlytics.instance.setCustomKey(
        'last_log',
        message.length > 100 ? message.substring(0, 100) : message,
      );
    } catch (e) {
      // Silently fail - don't crash the app
      // print("Failed to send log to Firebase: $e");
    }
  }

  /// Send crash report to Firebase Crashlytics
  static Future<void> _sendToFirebaseCrashlytics(
      String error,
      String stackTrace,
      Map<String, dynamic>? additionalInfo,
      String? reason,
      ) async {
    try {
      final timestamp = DateTime.now().toIso8601String();

      // 1. Log the error to Firebase logs
      FirebaseCrashlytics.instance.log("""
========================================
 CRASH REPORT - $timestamp
========================================
ERROR: $error
REASON: ${reason ?? 'No reason provided'}
ADDITIONAL INFO: ${additionalInfo?.toString() ?? 'None'}
========================================
""");

      // 2. Set custom keys for better filtering
      FirebaseCrashlytics.instance.setCustomKey(
        'last_error',
        error.length > 100 ? error.substring(0, 100) : error,
      );
      FirebaseCrashlytics.instance.setCustomKey(
        'last_error_time',
        timestamp,
      );

      if (additionalInfo != null) {
        additionalInfo.forEach((key, value) {
          final String strValue = value.toString();
          FirebaseCrashlytics.instance.setCustomKey(
            'error_$key',
            strValue.length > 100 ? strValue.substring(0, 100) : strValue,
          );
        });
      }

      // 3. Record as Non-Fatal exception in Crashlytics
      // This will appear in the Crashlytics console under "Non-Fatal Issues"
      await FirebaseCrashlytics.instance.recordError(
        Exception(error),
        StackTrace.fromString(stackTrace),
        reason: reason ?? "Application Crash",
        fatal: false,
      );

      // print(' Crash report sent to Firebase Crashlytics');
    } catch (e) {
      // Silently fail - don't crash the app
      // print("Failed to send crash report to Firebase: $e");
    }
  }

  /// External storage method (app-specific, no permission needed)
  static Future<String> _storeCrashReportExternal(
      String error,
      String stackTrace,
      Map<String, dynamic>? additionalInfo,
      ) async {
    // Get external storage directory (app-specific, no permission needed)
    Directory? externalDir = await getExternalStorageDirectory();
    if (externalDir == null) {
      throw 'Unable to access external storage directory';
    }

    // Create CIMTDWP folder in app-specific external storage
    Directory appDocDir = Directory('${externalDir.path}/CIMTDWP');
    if (!await appDocDir.exists()) {
      await appDocDir.create(recursive: true);
    }

    return await _writeCrashFile(appDocDir, error, stackTrace, additionalInfo);
  }

  /// Fallback storage method (always available)
  static Future<String> _storeCrashReportFallback(
      String error,
      String stackTrace,
      Map<String, dynamic>? additionalInfo,
      ) async {
    try {
      // Use app documents directory (always accessible)
      Directory appDocDir = await getApplicationDocumentsDirectory();
      return await _writeCrashFile(appDocDir, error, stackTrace, additionalInfo);
    } catch (e) {
      // If even that fails, try temporary directory
      Directory tempDir = await getTemporaryDirectory();
      return await _writeCrashFile(tempDir, error, stackTrace, additionalInfo);
    }
  }

  /// Write crash file to specified directory
  static Future<String> _writeCrashFile(
      Directory baseDir,
      String error,
      String stackTrace,
      Map<String, dynamic>? additionalInfo,
      ) async {
    // Create the nested folder structure for crash logs
    Directory crashLogsDir = Directory('${baseDir.path}/Logs/AppLogs');

    if (!await crashLogsDir.exists()) {
      await crashLogsDir.create(recursive: true);
    }

    // Create crash report data
    Map<String, dynamic> crashReport = {
      'timestamp': DateTime.now().toIso8601String(),
      'error': error,
      'stackTrace': stackTrace,
      'deviceInfo': await _getDeviceInfo(),
      'additionalInfo': additionalInfo ?? {},
      'storageLocation': baseDir.path,
    };

    // Generate filename with timestamp
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    String fileName = 'crash_report_$timestamp.json';

    // Define the full path where the crash report will be stored
    String filePath = '${crashLogsDir.path}/$fileName';
    File crashFile = File(filePath);

    // Write crash report to file
    await crashFile.writeAsString(
      JsonEncoder.withIndent('  ').convert(crashReport),
      encoding: utf8,
    );

    // print(' SUCCESS! Crash report saved to: $filePath');
    return filePath;
  }

  /// Check if we can create a directory
  static Future<bool> _canCreateDirectory(Directory dir) async {
    try {
      await dir.create(recursive: true);
      return await dir.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get basic device information for crash reports
  static Future<Map<String, String>> _getDeviceInfo() async {
    try {
      return {
        'platform': Platform.operatingSystem,
        'version': Platform.operatingSystemVersion,
        'locale': Platform.localeName,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {'error': 'Could not retrieve device info: $e'};
    }
  }

  /// Enhanced global error handlers with better crash capture
  static void setupGlobalErrorHandling() {
    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) async {
      // Present the error to console first
      FlutterError.presentError(details);

      // Store crash report asynchronously
      try {
        await storeCrashReport(
          error: details.exception.toString(),
          stackTrace: details.stack.toString(),
          reason: "Flutter Framework Error",
          additionalInfo: {
            'library': details.library ?? 'Unknown library',
            'context': details.context?.toString() ?? 'No context',
            'informationCollector': details.informationCollector?.toString() ?? 'No info collector',
          },
        );
      } catch (e) {
        // print('Failed to store Flutter error: $e');
      }
    };

    // Handle other uncaught errors in the root isolate
    PlatformDispatcher.instance.onError = (error, stack) {
      // print(' Uncaught error: $error');

      // Store crash report asynchronously
      storeCrashReport(
        error: error.toString(),
        stackTrace: stack.toString(),
        reason: "Uncaught Platform Error",
        additionalInfo: {
          'type': 'Platform Dispatcher Error',
          'isolate': 'Main Isolate',
        },
      ).catchError((e) {
        print('Failed to store platform error: $e');
      });

      return true;
    };

    // Handle errors in other isolates
    Isolate.current.addErrorListener(
      RawReceivePort((pair) async {
        final List<dynamic> errorAndStacktrace = pair;
        try {
          await storeCrashReport(
            error: errorAndStacktrace.first.toString(),
            stackTrace: errorAndStacktrace.last.toString(),
            reason: "Isolate Error",
            additionalInfo: {
              'type': 'Isolate Error',
              'isolate': Isolate.current.debugName ?? 'Unknown Isolate',
            },
          );
        } catch (e) {
          // print('Failed to store isolate error: $e');
        }
      }).sendPort,
    );
  }

  /// Get all crash reports with external storage support
  static Future<List<File>> getAllCrashReports() async {
    List<File> allReports = [];

    // Check external storage first
    try {
      Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        Directory externalLogsDir = Directory('${externalDir.path}/CIMTDWP/Logs/AppLogs');
        if (await externalLogsDir.exists()) {
          List<FileSystemEntity> files = await externalLogsDir.list().toList();
          List<File> externalReports = files.whereType<File>()
              .where((file) => file.path.contains('crash_report_'))
              .toList();
          allReports.addAll(externalReports);
        }
      }
    } catch (e) {
      // print('Error accessing external storage: $e');
    }

    // Check fallback storage
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      Directory fallbackDir = Directory('${appDocDir.path}/Logs/AppLogs');
      if (await fallbackDir.exists()) {
        List<FileSystemEntity> files = await fallbackDir.list().toList();
        List<File> fallbackReports = files.whereType<File>()
            .where((file) => file.path.contains('crash_report_'))
            .toList();
        allReports.addAll(fallbackReports);
      }
    } catch (e) {
      // print('Error accessing fallback storage: $e');
    }

    // print(' Found ${allReports.length} total crash reports');
    return allReports;
  }

  /// Clear old crash reports (keep only last 10) with external storage support
  static Future<void> cleanupOldReports({int keepCount = 10}) async {
    try {
      List<File> reports = await getAllCrashReports();

      if (reports.length <= keepCount) {
        // print(' Found ${reports.length} reports, no cleanup needed (keeping $keepCount)');
        return;
      }

      // Sort by modification time (newest first)
      reports.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      // Delete old reports
      int deletedCount = 0;
      for (int i = keepCount; i < reports.length; i++) {
        try {
          await reports[i].delete();
          deletedCount++;
        } catch (e) {
          // print('⚠ Failed to delete report ${reports[i].path}: $e');
        }
      }

      // print(' Cleanup complete: deleted $deletedCount old reports, kept $keepCount recent ones');
    } catch (e) {
      // print(' Error cleaning up old reports: $e');
    }
  }

  /// Get the latest crash report
  static Future<Map<String, dynamic>?> getLatestCrashReport() async {
    try {
      List<File> reports = await getAllCrashReports();

      if (reports.isEmpty) {
        return null;
      }

      // Sort by modification time (newest first)
      reports.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      // Read the latest report
      String content = await reports.first.readAsString();
      Map<String, dynamic> report = jsonDecode(content);

      return report;
    } catch (e) {
      // print('Error getting latest crash report: $e');
      return null;
    }
  }

  /// Records one user-activity event (login, logout, screen opened, image
  /// captured/removed, etc.) as JSON with a timestamp, so what the user did
  /// in the app — not just errors — can be reviewed afterward. Separate
  /// file from crash_report_*.json (errors), app_log_*.json (free-text
  /// messages), and print_submission_log_*.json (completed submissions).
  static Future<String> logUserEvent(String event, {Map<String, dynamic>? details}) async {
    try {
      Directory? logDir;

      try {
        Directory? externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          Directory cimtdwpDir = Directory('${externalDir.path}/CIMTDWP');
          if (await cimtdwpDir.exists() || await _canCreateDirectory(cimtdwpDir)) {
            logDir = Directory('${cimtdwpDir.path}/Logs/AppLogs');
          }
        }
      } catch (e) {
        // External storage not accessible
      }

      if (logDir == null) {
        Directory appDocDir = await getApplicationDocumentsDirectory();
        logDir = Directory('${appDocDir.path}/Logs/AppLogs');
      }

      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      Map<String, dynamic> logEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'event': event,
        'details': details ?? {},
      };

      String dateString = DateTime.now().toIso8601String().substring(0, 10);
      String fileName = 'user_activity_log_$dateString.json';
      String filePath = '${logDir.path}/$fileName';
      File logFile = File(filePath);

      List<Map<String, dynamic>> existingLogs = [];
      if (await logFile.exists()) {
        try {
          List<dynamic> decoded = jsonDecode(await logFile.readAsString());
          existingLogs = decoded.cast<Map<String, dynamic>>();
        } catch (e) {
          // Continue with empty logs list
        }
      }

      existingLogs.add(logEntry);

      // Keep only last 3000 entries to prevent the file from growing unbounded
      if (existingLogs.length > 3000) {
        existingLogs = existingLogs.sublist(existingLogs.length - 3000);
      }

      await logFile.writeAsString(
        JsonEncoder.withIndent('  ').convert(existingLogs),
        encoding: utf8,
      );

      return filePath;
    } catch (e) {
      return 'Failed to store user activity log: $e';
    }
  }

  /// Resolves the same Logs/AppLogs directory the other log*/store* methods
  /// use, with the same external-storage-then-app-documents fallback.
  static Future<Directory> _resolveAppLogsDir() async {
    Directory? logDir;

    try {
      Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        Directory cimtdwpDir = Directory('${externalDir.path}/CIMTDWP');
        if (await cimtdwpDir.exists() || await _canCreateDirectory(cimtdwpDir)) {
          logDir = Directory('${cimtdwpDir.path}/Logs/AppLogs');
        }
      }
    } catch (e) {
      // External storage not accessible
    }

    if (logDir == null) {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      logDir = Directory('${appDocDir.path}/Logs/AppLogs');
    }

    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }

    return logDir;
  }

  /// Formats a timestamp the same way the legacy native app's log files did:
  /// "Thu Jul 30 17:19:39 GMT+05:30 2026".
  static String _legacyTimestamp(DateTime dt) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final weekday = weekdays[dt.weekday - 1];
    final month = months[dt.month - 1];
    final time = '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
    final offset = dt.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final offHours = offset.abs().inHours.toString().padLeft(2, '0');
    final offMinutes = (offset.abs().inMinutes % 60).toString().padLeft(2, '0');
    return '$weekday $month ${dt.day} $time GMT$sign$offHours:$offMinutes ${dt.year}';
  }

  /// Legacy log files prefixed locally-stored image paths with the
  /// "file:" URI scheme — replicated here for format parity.
  static String _legacyFileUri(String? path) {
    if (path == null || path.isEmpty) return '';
    return path.startsWith('file:') ? path : 'file:$path';
  }

  static Future<Map<String, String>> _deviceAndAppInfo() async {
    String appVersion = '';
    String androidVersion = '';
    String deviceId = '';
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.version;
    } catch (_) {}
    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        androidVersion = androidInfo.version.sdkInt.toString();
      }
    } catch (_) {}
    try {
      deviceId = await DeviceIdManager.getDeviceId();
    } catch (_) {}
    return {
      'appVersion': appVersion,
      'androidVersion': androidVersion,
      'deviceId': deviceId,
    };
  }

  /// Appends a snapshot of the currently-pending (not-yet-synced) print
  /// records to AllDBPrints.txt — same file name and field names as the
  /// legacy native app's local execution DB table dump.
  static Future<void> logAllDBPrints(List<ImageUploaddata> pendingRecords) async {
    try {
      final logDir = await _resolveAppLogsDir();
      final file = File('${logDir.path}/AllDBPrints.txt');

      final entries = <Map<String, dynamic>>[];
      for (var i = 0; i < pendingRecords.length; i++) {
        final m = pendingRecords[i];
        entries.add({
          'DATAID': (i + 1).toString(),
          'SERVERID': m.ServerPlanId ?? '',
          'SERVERPLANID': m.PlanCode ?? '',
          'PRINTNO': m.PrintNo ?? '',
          'CLEANIMAGE': _legacyFileUri(m.CleanImage),
          'WBIMAGE': _legacyFileUri(m.WBImage),
          'SPRAYIMAGE': _legacyFileUri(m.SprayImage),
          'NEARIMAGE': _legacyFileUri(m.NearImage),
          'FARIMAGE': _legacyFileUri(m.FarImage),
          'LAT': m.CleanLatitude ?? '',
          'LNG': m.CleanLongitude ?? '',
          'ADDRESS': m.Address ?? '',
          'EXECUTIONDATE': m.ExecutionDate ?? '',
          'FLAG': '0',
          'VILLAGECODE': m.VillageCode ?? '',
          'SIXTHIMAGE': _legacyFileUri(m.NewImage6),
          'SEVENTHIMAGE': _legacyFileUri(m.NewImage7),
          'LOCATION': '${m.CleanLatitude ?? ''},${m.CleanLongitude ?? ''},0.0,0.0,0.0',
        });
      }

      final line = '${_legacyTimestamp(DateTime.now())} -- ${jsonEncode(entries)}\n\n';
      await file.writeAsString(line, mode: FileMode.append, encoding: utf8);
    } catch (e) {
      // Best-effort logging only; never let logging break the submit flow.
    }
  }

  /// Appends a snapshot to AllPrints.txt — same file name, field names, and
  /// "Android version / App Version" header the legacy app used.
  static Future<void> logAllPrints(List<ImageUploaddata> pendingRecords) async {
    try {
      final logDir = await _resolveAppLogsDir();
      final file = File('${logDir.path}/AllPrints.txt');
      final info = await _deviceAndAppInfo();

      final entries = <Map<String, dynamic>>[];
      for (final m in pendingRecords) {
        entries.add({
          'id': m.ServerPlanId ?? '',
          'planid': m.PlanCode ?? '',
          'Printno': m.PrintNo ?? '',
          'CleanImage': _legacyFileUri(m.CleanImage),
          'CleanImagePath': m.CleanImage ?? '',
          'WBImage': _legacyFileUri(m.WBImage),
          'WBImagePath': m.WBImage ?? '',
          'SprayImage': _legacyFileUri(m.SprayImage),
          'SprayImagePath': m.SprayImage ?? '',
          'NearImage': _legacyFileUri(m.NearImage),
          'NearImagePath': m.NearImage ?? '',
          'FarImage': _legacyFileUri(m.FarImage),
          'FarImagePath': m.FarImage ?? '',
          'newImage6': _legacyFileUri(m.NewImage6),
          'newImage6Path': m.NewImage6 ?? '',
          'newImage7': _legacyFileUri(m.NewImage7),
          'newImage7Path': m.NewImage7 ?? '',
          'Latitude': m.CleanLatitude ?? '',
          'Longitude': m.CleanLongitude ?? '',
          'ExecutionDate': m.ExecutionDate ?? '',
          'UploadDate': m.UploadDate ?? '',
          // True IMEI is not obtainable on modern Android without a
          // privileged/carrier permission; the app's own device UID is
          // used here instead so each device is still distinguishable.
          'imei': info['deviceId'],
          'VillageCode': m.VillageCode ?? '',
          'Address': m.Address ?? '',
        });
      }

      final line = '${_legacyTimestamp(DateTime.now())} -- '
          'Android version = ${info['androidVersion']} -- '
          'App Version : ${info['appVersion']} --  ${jsonEncode(entries)}\n\n';
      await file.writeAsString(line, mode: FileMode.append, encoding: utf8);
    } catch (e) {
      // Best-effort logging only; never let logging break the submit flow.
    }
  }

  /// Appends a snapshot to HMData.txt — same file name and field names
  /// (including the legacy "Upload Date" key with a space, and "null" as a
  /// literal string for a blank address) as the legacy pending-sync queue.
  ///
  /// Disabled: kept as a no-op so existing call sites still compile.
  // static Future<void> logHMData(List<ImageUploaddata> pendingRecords) async {
  //   return;
  //   // try {
  //   //   final logDir = await _resolveAppLogsDir();
  //   //   final file = File('${logDir.path}/HMData.txt');
  //   //
  //   //   final entries = <Map<String, dynamic>>[];
  //   //   for (var i = 0; i < pendingRecords.length; i++) {
  //   //     final m = pendingRecords[i];
  //   //     entries.add({
  //   //       'localid': (i + 1).toString(),
  //   //       'id': m.ServerPlanId ?? '',
  //   //       'planid': m.PlanCode ?? '',
  //   //       'Printno': m.PrintNo ?? '',
  //   //       'CleanImage': _legacyFileUri(m.CleanImage),
  //   //       'WBImage': _legacyFileUri(m.WBImage),
  //   //       'SprayImage': _legacyFileUri(m.SprayImage),
  //   //       'NearImage': _legacyFileUri(m.NearImage),
  //   //       'FarImage': _legacyFileUri(m.FarImage),
  //   //       'Latitude': m.CleanLatitude ?? '',
  //   //       'Longitude': m.CleanLongitude ?? '',
  //   //       'Address': (m.Address == null || m.Address!.isEmpty) ? 'null' : m.Address,
  //   //       'ExecutionDate': m.ExecutionDate ?? '',
  //   //       'Upload Date': m.UploadDate ?? '',
  //   //       'flag': '0',
  //   //       'VillageCode': m.VillageCode ?? '',
  //   //       'newImage6': _legacyFileUri(m.NewImage6),
  //   //       'newImage7': _legacyFileUri(m.NewImage7),
  //   //       'CurrentLocation': '${m.CleanLatitude ?? ''},${m.CleanLongitude ?? ''},0.0,0.0,0.0',
  //   //     });
  //   //   }
  //   //
  //   //   final line = '\n${_legacyTimestamp(DateTime.now())} -- ${jsonEncode(entries)}\n';
  //   //   await file.writeAsString(line, mode: FileMode.append, encoding: utf8);
  //   // } catch (e) {
  //   //   // Best-effort logging only; never let logging break the submit flow.
  //   // }
  // }

  /// Appends one free-text trace line to DWPError.txt — same file name and
  /// "timestamp -- message" / "tag" shape as the legacy step-by-step trace
  /// of the image capture flow and any errors hit along the way.
  static Future<void> logDWPTrace(String message, {String tag = 'DWP P ExecuteActivity'}) async {
    try {
      final logDir = await _resolveAppLogsDir();
      final file = File('${logDir.path}/DWPError.txt');
      final line = '${_legacyTimestamp(DateTime.now())} -- $message\n$tag\n';
      await file.writeAsString(line, mode: FileMode.append, encoding: utf8);
    } catch (e) {
      // Best-effort logging only; never let logging break the capture flow.
    }
  }

  /// Records a structured JSON snapshot of a completed print/plan
  /// submission — what got submitted (plan/print/village/address), the
  /// GPS reading behind each captured image, network status, and the
  /// device/user identity (UID.txt content) at that moment. Separate from
  /// crash_report_*.json (errors) and app_log_*.json (free-text messages)
  /// so submissions can be audited on their own.
  static Future<String> storePrintSubmissionLog(Map<String, dynamic> data) async {
    try {
      Directory? logDir;

      try {
        Directory? externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          Directory cimtdwpDir = Directory('${externalDir.path}/CIMTDWP');
          if (await cimtdwpDir.exists() || await _canCreateDirectory(cimtdwpDir)) {
            logDir = Directory('${cimtdwpDir.path}/Logs/AppLogs');
          }
        }
      } catch (e) {
        // External storage not accessible
      }

      if (logDir == null) {
        Directory appDocDir = await getApplicationDocumentsDirectory();
        logDir = Directory('${appDocDir.path}/Logs/AppLogs');
      }

      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      Map<String, dynamic> logEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        ...data,
      };

      String dateString = DateTime.now().toIso8601String().substring(0, 10);
      String fileName = 'print_submission_log_$dateString.json';
      String filePath = '${logDir.path}/$fileName';
      File logFile = File(filePath);

      List<Map<String, dynamic>> existingLogs = [];
      if (await logFile.exists()) {
        try {
          List<dynamic> decoded = jsonDecode(await logFile.readAsString());
          existingLogs = decoded.cast<Map<String, dynamic>>();
        } catch (e) {
          // Continue with empty logs list
        }
      }

      existingLogs.add(logEntry);

      // Keep only last 2000 entries to prevent the file from growing unbounded
      if (existingLogs.length > 2000) {
        existingLogs = existingLogs.sublist(existingLogs.length - 2000);
      }

      await logFile.writeAsString(
        JsonEncoder.withIndent('  ').convert(existingLogs),
        encoding: utf8,
      );

      return filePath;
    } catch (e) {
      return 'Failed to store print submission log: $e';
    }
  }

  /// Get logs for a specific date
  static Future<List<Map<String, dynamic>>> getLogsForDate(DateTime date) async {
    try {
      String dateString = date.toIso8601String().substring(0, 10);
      String fileName = 'app_log_$dateString.json';

      List<File> allLogs = [];

      // Check external storage
      try {
        Directory? externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          File logFile = File('${externalDir.path}/CIMTDWP/Logs/AppLogs/$fileName');
          if (await logFile.exists()) {
            allLogs.add(logFile);
          }
        }
      } catch (e) {
        // External storage not accessible
      }

      // Check fallback storage
      try {
        Directory appDocDir = await getApplicationDocumentsDirectory();
        File logFile = File('${appDocDir.path}/Logs/AppLogs/$fileName');
        if (await logFile.exists()) {
          allLogs.add(logFile);
        }
      } catch (e) {
        // Fallback storage not accessible
      }

      if (allLogs.isEmpty) {
        return [];
      }

      // Read the log file
      String content = await allLogs.first.readAsString();
      List<dynamic> decoded = jsonDecode(content);
      return decoded.cast<Map<String, dynamic>>();

    } catch (e) {
      // print('Error getting logs for date: $e');
      return [];
    }
  }
}