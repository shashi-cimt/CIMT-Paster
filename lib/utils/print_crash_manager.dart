import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class PrintCrashReportManager {
  static const String _crashFileName = 'print_reports.jsonl'; // JSON Lines format
  static const int _maxCrashEntries = 500; // Maximum entries to keep in file

  /// Store crash report in external storage with fallback
  /// [error] can be a String, Map, or any object with toJson() method
  static Future<String> storeCrashReport({
    required dynamic error,
    required String stackTrace,
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      return await _storeCrashReportExternal(error, stackTrace, additionalInfo);
    } catch (e) {
      // print(' Error in external crash storage, using fallback: $e');
      return await _storeCrashReportFallback(error, stackTrace, additionalInfo);
    }
  }

  /// External storage method (app-specific, no permission needed)
  static Future<String> _storeCrashReportExternal(
      dynamic error,
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

    return await _appendCrashToFile(appDocDir, error, stackTrace, additionalInfo);
  }

  /// Fallback storage method (always available)
  static Future<String> _storeCrashReportFallback(
      dynamic error,
      String stackTrace,
      Map<String, dynamic>? additionalInfo,
      ) async {
    try {
      // Use app documents directory (always accessible)
      Directory appDocDir = await getApplicationDocumentsDirectory();
      return await _appendCrashToFile(appDocDir, error, stackTrace, additionalInfo);
    } catch (e) {
      // If even that fails, try temporary directory
      Directory tempDir = await getTemporaryDirectory();
      return await _appendCrashToFile(tempDir, error, stackTrace, additionalInfo);
    }
  }

  /// Convert error to JSON-compatible format
  static dynamic _convertErrorToJson(dynamic error) {
    try {
      // If it's already a Map, return as is
      if (error is Map<String, dynamic>) {
        return error;
      }

      // If it's a String, return as is
      if (error is String) {
        return error;
      }

      // If it has a toJson method, use it
      if (error != null) {
        try {
          // Try to call toJson() method
          var toJsonMethod = error.toJson;
          if (toJsonMethod != null) {
            return toJsonMethod();
          }
        } catch (e) {
          // toJson method doesn't exist, continue
        }
      }

      // Try to convert to JSON directly
      try {
        return jsonDecode(jsonEncode(error));
      } catch (e) {
        // If all else fails, return toString()
        return error.toString();
      }
    } catch (e) {
      return error.toString();
    }
  }

  /// Append crash as a new line in the file
  static Future<String> _appendCrashToFile(
      Directory baseDir,
      dynamic error,
      String stackTrace,
      Map<String, dynamic>? additionalInfo,
      ) async {
    // Create the nested folder structure for crash logs
    Directory crashLogsDir = Directory('${baseDir.path}/Logs');

    if (!await crashLogsDir.exists()) {
      await crashLogsDir.create(recursive: true);
    }

    // Convert error to JSON-compatible format
    dynamic formattedError = _convertErrorToJson(error);

    // Get device info
    Map<String, String> deviceInfo = await _getDeviceInfo();

    // Create crash report data with structured error
    Map<String, dynamic> crashReport = {
      'timestamp': DateTime.now().toIso8601String(),
      'error': formattedError,
      'errorType': error.runtimeType.toString(),
      'stackTrace': stackTrace,
      'deviceInfo': deviceInfo,
      'additionalInfo': additionalInfo ?? {},
      'storageLocation': baseDir.path,
    };

    // Define the full path for the single crash report file
    String filePath = '${crashLogsDir.path}/$_crashFileName';
    File crashFile = File(filePath);

    // Convert crash to compact JSON (single line)
    String compactJson = jsonEncode(crashReport);

    // Check if file exists and count lines
    int currentLineCount = 0;
    if (await crashFile.exists()) {
      try {
        String existingContent = await crashFile.readAsString();
        currentLineCount = existingContent.split('\n').where((line) => line.trim().isNotEmpty).length;
      } catch (e) {
        print(' Error reading existing crash file: $e');
      }
    }

    // If file is too large, trim old entries
    if (currentLineCount >= _maxCrashEntries) {
      await _trimOldEntries(crashFile, _maxCrashEntries - 1);
    }

    // Append new crash as a new line
    await crashFile.writeAsString(
      '$compactJson\n',
      mode: FileMode.append,
      encoding: utf8,
      flush: true, // Ensure data is written immediately
    );

    // print(' SUCCESS! Print crash report appended to: $filePath');
    // print('Total crashes in file: ${currentLineCount + 1}');
    return filePath;
  }

  /// Trim old entries from the file, keeping only the last N entries
  static Future<void> _trimOldEntries(File file, int keepCount) async {
    try {
      String content = await file.readAsString();
      List<String> lines = content.split('\n').where((line) => line.trim().isNotEmpty).toList();

      if (lines.length <= keepCount) {
        return;
      }

      // Keep only the last N lines
      List<String> recentLines = lines.sublist(lines.length - keepCount);

      // Rewrite file with recent lines
      await file.writeAsString(
        recentLines.join('\n') + '\n',
        encoding: utf8,
        flush: true,
      );

      // print(' Trimmed file to last $keepCount entries');
    } catch (e) {
      // print(' Error trimming old entries: $e');
    }
  }

  /// Store a simple log message with external storage
  /// [message] can be a String, Map, or any object with toJson() method
  static Future<String> storeLogMessage(dynamic message) async {
    try {
      Directory? logDir;

      // Try to get external storage directory first
      try {
        Directory? externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          Directory cimtdwpDir = Directory('${externalDir.path}/CIMTDWP');
          if (await cimtdwpDir.exists() || await _canCreateDirectory(cimtdwpDir)) {
            logDir = Directory('${cimtdwpDir.path}/Logs');
          }
        }
      } catch (e) {
        // print('External storage not accessible: $e');
      }

      // Fallback to app documents directory
      if (logDir == null) {
        Directory appDocDir = await getApplicationDocumentsDirectory();
        logDir = Directory('${appDocDir.path}/Logs/Print Logs');
      }

      // Create the folder if it does not exist
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      // Convert message to JSON-compatible format
      dynamic formattedMessage = _convertErrorToJson(message);

      // Create log entry
      Map<String, dynamic> logEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'message': formattedMessage,
        'messageType': message.runtimeType.toString(),
      };

      // Generate filename with date
      String dateString = DateTime.now().toIso8601String().substring(0, 10);
      String fileName = 'print_app_log_$dateString.json';

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
          print(' Error reading existing log file: $e');
          // Continue with empty logs list
        }
      }

      existingLogs.add(logEntry);

      // Keep only last 100 log entries to prevent file from getting too large
      if (existingLogs.length > 100) {
        existingLogs = existingLogs.sublist(existingLogs.length - 100);
      }

      // Write updated logs to file
      await logFile.writeAsString(
        JsonEncoder.withIndent('  ').convert(existingLogs),
        encoding: utf8,
      );

      // print(' Print log message saved to: $filePath');
      return filePath;

    } catch (e) {
      // print(' Error storing log message: $e');
      // Don't throw here - logging should be non-blocking
      return 'Failed to store log: $e';
    }
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
        additionalInfo: {
          'type': 'Platform Dispatcher Error',
          'isolate': 'Main Isolate',
        },
      ).catchError((e) {
        // print('Failed to store platform error: $e');
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

  /// Get the single crash report file
  static Future<File?> getCrashReportFile() async {
    // Check external storage first
    try {
      Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        File externalFile = File('${externalDir.path}/CIMTDWP/Logs/$_crashFileName');
        if (await externalFile.exists()) {
          return externalFile;
        }
      }
    } catch (e) {
      // print('Error accessing external storage: $e');
    }

    // Check fallback storage
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      File fallbackFile = File('${appDocDir.path}/Logs/$_crashFileName');
      if (await fallbackFile.exists()) {
        return fallbackFile;
      }
    } catch (e) {
      // print('Error accessing fallback storage: $e');
    }

    return null;
  }

  /// Get all crash reports from the file (each line is one crash)
  static Future<List<Map<String, dynamic>>> getAllCrashReports() async {
    try {
      File? crashFile = await getCrashReportFile();

      if (crashFile == null) {
        // print(' No crash report file found');
        return [];
      }

      String content = await crashFile.readAsString();
      List<String> lines = content.split('\n').where((line) => line.trim().isNotEmpty).toList();

      List<Map<String, dynamic>> crashes = [];

      for (String line in lines) {
        try {
          Map<String, dynamic> crash = jsonDecode(line);
          crashes.add(crash);
        } catch (e) {
          // print(' Error parsing line: $e');
        }
      }

      // print('📊 Found ${crashes.length} total print crash reports');
      return crashes;
    } catch (e) {
      // print(' Error reading crash reports: $e');
      return [];
    }
  }

  /// Get total crash count without loading all crashes
  static Future<int> getCrashCount() async {
    try {
      File? crashFile = await getCrashReportFile();

      if (crashFile == null) {
        return 0;
      }

      String content = await crashFile.readAsString();
      int count = content.split('\n').where((line) => line.trim().isNotEmpty).length;

      // print(' Total crash count: $count');
      return count;
    } catch (e) {
      // print(' Error counting crashes: $e');
      return 0;
    }
  }

  /// Clear old crash reports (keep only last N entries)
  static Future<void> cleanupOldReports({int keepCount = 10}) async {
    try {
      File? crashFile = await getCrashReportFile();

      if (crashFile == null) {
        // print(' No crash report file found');
        return;
      }

      String content = await crashFile.readAsString();
      List<String> lines = content.split('\n').where((line) => line.trim().isNotEmpty).toList();

      if (lines.length <= keepCount) {
        // print(' Found ${lines.length} reports, no cleanup needed (keeping $keepCount)');
        return;
      }

      // Keep only the last N lines
      List<String> recentLines = lines.sublist(lines.length - keepCount);

      // Rewrite file with recent lines
      await crashFile.writeAsString(
        recentLines.join('\n') + '\n',
        encoding: utf8,
        flush: true,
      );

      int deletedCount = lines.length - keepCount;
      // print(' Cleanup complete: removed $deletedCount old reports, kept $keepCount recent ones');
    } catch (e) {
      // print(' Error cleaning up old reports: $e');
    }
  }

  /// Format crash report for console printing
  static String formatCrashReport(Map<String, dynamic> crashData) {
    StringBuffer buffer = StringBuffer();

    buffer.writeln('╔═══════════════════════════════════════════════════════╗');
    buffer.writeln('║              CRASH REPORT DETAILS                     ║');
    buffer.writeln('╚═══════════════════════════════════════════════════════╝');
    buffer.writeln();

    buffer.writeln(' Timestamp: ${crashData['timestamp'] ?? 'Unknown'}');
    buffer.writeln(' Storage Location: ${crashData['storageLocation'] ?? 'Unknown'}');
    buffer.writeln();

    buffer.writeln('─────────────────────────────────────────────────────────');
    buffer.writeln(' ERROR:');
    buffer.writeln('─────────────────────────────────────────────────────────');
    buffer.writeln(crashData['error'] ?? 'No error information');
    buffer.writeln();

    buffer.writeln('─────────────────────────────────────────────────────────');
    buffer.writeln(' STACK TRACE:');
    buffer.writeln('─────────────────────────────────────────────────────────');
    buffer.writeln(crashData['stackTrace'] ?? 'No stack trace available');
    buffer.writeln();

    if (crashData['deviceInfo'] != null) {
      buffer.writeln('─────────────────────────────────────────────────────────');
      buffer.writeln(' DEVICE INFO:');
      buffer.writeln('─────────────────────────────────────────────────────────');
      Map<String, dynamic> deviceInfo = crashData['deviceInfo'];
      deviceInfo.forEach((key, value) {
        buffer.writeln('  • $key: $value');
      });
      buffer.writeln();
    }

    if (crashData['additionalInfo'] != null &&
        (crashData['additionalInfo'] as Map).isNotEmpty) {
      buffer.writeln('─────────────────────────────────────────────────────────');
      buffer.writeln('ℹ  ADDITIONAL INFO:');
      buffer.writeln('─────────────────────────────────────────────────────────');
      Map<String, dynamic> additionalInfo = crashData['additionalInfo'];
      additionalInfo.forEach((key, value) {
        buffer.writeln('  • $key: $value');
      });
      buffer.writeln();
    }

    buffer.writeln('═══════════════════════════════════════════════════════════');

    return buffer.toString();
  }

  /// Print crash report from data
  static void printCrashReport(Map<String, dynamic> crashData) {
    String formattedReport = formatCrashReport(crashData);
    // print(formattedReport);
  }

  /// Print all crash reports
  static Future<void> printAllCrashReports() async {
    try {
      List<Map<String, dynamic>> reports = await getAllCrashReports();

      if (reports.isEmpty) {
        // print(' No crash reports found.');
        return;
      }

      // print('\n Found ${reports.length} crash report(s)\n');

      for (int i = 0; i < reports.length; i++) {
        // print('\n🔹 REPORT ${i + 1}/${reports.length}');
        printCrashReport(reports[i]);
        // print('\n');
      }

    } catch (e) {
      // print(' Error printing all crash reports: $e');
    }
  }

  /// Generate crash summary statistics
  static Future<Map<String, dynamic>> generateCrashSummary() async {
    try {
      List<Map<String, dynamic>> reports = await getAllCrashReports();

      if (reports.isEmpty) {
        return {
          'totalCrashes': 0,
          'message': 'No crash reports found',
        };
      }

      Map<String, int> errorTypes = {};
      Map<String, int> crashesByDay = {};
      String? oldestCrash;
      String? newestCrash;

      for (Map<String, dynamic> crashData in reports) {
        try {
          // Count error types
          String errorType = _extractErrorType(crashData['error'] ?? 'Unknown');
          errorTypes[errorType] = (errorTypes[errorType] ?? 0) + 1;

          // Track crashes by day
          String timestamp = crashData['timestamp'] ?? '';
          if (timestamp.isNotEmpty) {
            String day = timestamp.substring(0, 10);
            crashesByDay[day] = (crashesByDay[day] ?? 0) + 1;

            if (oldestCrash == null || timestamp.compareTo(oldestCrash) < 0) {
              oldestCrash = timestamp;
            }
            if (newestCrash == null || timestamp.compareTo(newestCrash) > 0) {
              newestCrash = timestamp;
            }
          }
        } catch (e) {
          // print(' Error processing crash report: $e');
        }
      }

      return {
        'totalCrashes': reports.length,
        'errorTypes': errorTypes,
        'crashesByDay': crashesByDay,
        'oldestCrash': oldestCrash,
        'newestCrash': newestCrash,
      };

    } catch (e) {
      // print(' Error generating crash summary: $e');
      return {'error': e.toString()};
    }
  }

  /// Print crash summary statistics
  static Future<void> printCrashSummary() async {
    Map<String, dynamic> summary = await generateCrashSummary();
    //
    // print('\n╔═══════════════════════════════════════════════════════╗');
    // print('║           CRASH REPORT SUMMARY                        ║');
    // print('╚═══════════════════════════════════════════════════════╝\n');
    //
    // print(' Total Crashes: ${summary['totalCrashes']}');

    if (summary['totalCrashes'] == 0) {
      // print('\n No crashes recorded!\n');
      return;
    }

    if (summary['oldestCrash'] != null) {
      // print(' First Crash: ${summary['oldestCrash']}');
    }
    if (summary['newestCrash'] != null) {
      // print(' Latest Crash: ${summary['newestCrash']}');
    }

    // print('\n─────────────────────────────────────────────────────────');
    // print(' Error Types:');
    // print('─────────────────────────────────────────────────────────');
    Map<String, int> errorTypes = summary['errorTypes'] ?? {};
    errorTypes.forEach((type, count) {
      double percentage = (count / summary['totalCrashes']) * 100;
      // print('  • $type: $count (${percentage.toStringAsFixed(1)}%)');
    });

    // print('\n─────────────────────────────────────────────────────────');
    // print(' Crashes by Day:');
    // print('─────────────────────────────────────────────────────────');
    Map<String, int> crashesByDay = summary['crashesByDay'] ?? {};
    List<String> sortedDays = crashesByDay.keys.toList()..sort();
    for (String day in sortedDays) {
      // print('  • $day: ${crashesByDay[day]} crash(es)');
    }

    // print('\n═══════════════════════════════════════════════════════════\n');
  }

  /// Export crash reports to a single formatted text file
  static Future<String?> exportCrashReportsToText() async {
    try {
      List<Map<String, dynamic>> reports = await getAllCrashReports();

      if (reports.isEmpty) {
        // print(' No crash reports to export.');
        return null;
      }

      // Get export directory
      Directory? externalDir = await getExternalStorageDirectory();
      Directory exportDir;

      if (externalDir != null) {
        exportDir = Directory('${externalDir.path}/CIMTDWP/Exports');
      } else {
        Directory appDocDir = await getApplicationDocumentsDirectory();
        exportDir = Directory('${appDocDir.path}/Exports');
      }

      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      // Create export file
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String fileName = 'crash_export_$timestamp.txt';
      String filePath = '${exportDir.path}/$fileName';
      File exportFile = File(filePath);

      // Build export content
      StringBuffer content = StringBuffer();
      content.writeln('═══════════════════════════════════════════════════════════');
      content.writeln('           CRASH REPORTS EXPORT');
      content.writeln('           Generated: ${DateTime.now().toIso8601String()}');
      content.writeln('           Total Reports: ${reports.length}');
      content.writeln('═══════════════════════════════════════════════════════════\n\n');

      for (int i = 0; i < reports.length; i++) {
        try {
          content.writeln('\n${'=' * 60}');
          content.writeln('REPORT ${i + 1}/${reports.length}');
          content.writeln('=' * 60);
          content.writeln(formatCrashReport(reports[i]));
          content.writeln('\n');
        } catch (e) {
          content.writeln('\n Error processing report: $e\n');
        }
      }

      // Write to file
      await exportFile.writeAsString(content.toString(), encoding: utf8);

      // print(' Crash reports exported to: $filePath');
      return filePath;

    } catch (e) {
      // print(' Error exporting crash reports: $e');
      return null;
    }
  }

  /// Export all crash reports to a timestamped JSON file
  static Future<String?> exportAllCrashes() async {
    try {
      List<Map<String, dynamic>> allCrashes = await getAllCrashReports();

      if (allCrashes.isEmpty) {
        // print(' No crashes to export');
        return null;
      }

      // Sort by timestamp (newest first)
      allCrashes.sort((a, b) {
        String timestampA = a['timestamp'] ?? '';
        String timestampB = b['timestamp'] ?? '';
        return timestampB.compareTo(timestampA);
      });

      // Create export file
      Directory? externalDir = await getExternalStorageDirectory();
      Directory exportDir;

      if (externalDir != null) {
        exportDir = Directory('${externalDir.path}/CIMTDWP/Exports');
      } else {
        Directory appDocDir = await getApplicationDocumentsDirectory();
        exportDir = Directory('${appDocDir.path}/Exports');
      }

      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String fileName = 'all_crashes_export_$timestamp.json';
      String filePath = '${exportDir.path}/$fileName';

      File exportFile = File(filePath);

      // Pretty print for export
      JsonEncoder encoder = JsonEncoder.withIndent('  ');
      String prettyJson = encoder.convert(allCrashes);

      await exportFile.writeAsString(
        prettyJson,
        encoding: utf8,
        flush: true,
      );

      // print(' Exported ${allCrashes.length} crashes to: $filePath');
      return filePath;
    } catch (e) {
      // print(' Error exporting crashes: $e');
      return null;
    }
  }

  /// Get latest crash report
  static Future<Map<String, dynamic>?> getLatestCrashReport() async {
    try {
      List<Map<String, dynamic>> reports = await getAllCrashReports();

      if (reports.isEmpty) {
        return null;
      }

      // The last line is the most recent
      return reports.last;

    } catch (e) {
      // print(' Error getting latest crash report: $e');
      return null;
    }
  }

  /// Print latest crash report
  static Future<void> printLatestCrashReport() async {
    Map<String, dynamic>? latestReport = await getLatestCrashReport();

    if (latestReport == null) {
      // print(' No crash reports found.');
      return;
    }

    // print('\n🔹 LATEST CRASH REPORT\n');
    printCrashReport(latestReport);
  }

  /// Extract error type from error message
  static String _extractErrorType(dynamic error) {
    String errorStr = error.toString();

    // Extract the first line or exception type
    String firstLine = errorStr.split('\n').first.trim();

    // Try to extract exception class name
    if (firstLine.contains(':')) {
      return firstLine.split(':').first.trim();
    }

    // If it's too long, truncate
    if (firstLine.length > 50) {
      return '${firstLine.substring(0, 47)}...';
    }

    return firstLine;
  }

  /// Clear all crash reports
  static Future<bool> clearAllCrashes() async {
    try {
      File? crashFile = await getCrashReportFile();

      if (crashFile != null && await crashFile.exists()) {
        await crashFile.delete();
        // print(' All crash reports cleared');
        return true;
      }

      // print('⚠ No crash file to clear');
      return false;
    } catch (e) {
      // print(' Error clearing crash reports: $e');
      return false;
    }
  }

  /// Get crash reports within a date range
  static Future<List<Map<String, dynamic>>> getCrashReportsByDateRange(
      DateTime startDate,
      DateTime endDate,
      ) async {
    List<Map<String, dynamic>> allReports = await getAllCrashReports();

    List<Map<String, dynamic>> filteredReports = allReports.where((report) {
      try {
        String timestampStr = report['timestamp'] ?? '';
        DateTime timestamp = DateTime.parse(timestampStr);
        return timestamp.isAfter(startDate) && timestamp.isBefore(endDate);
      } catch (e) {
        return false;
      }
    }).toList();

    // print(' Found ${filteredReports.length} reports between $startDate and $endDate');
    return filteredReports;
  }

  /// Get the most recent N crash reports
  static Future<List<Map<String, dynamic>>> getRecentCrashes({int count = 10}) async {
    List<Map<String, dynamic>> allReports = await getAllCrashReports();

    if (allReports.length <= count) {
      return allReports;
    }

    return allReports.sublist(allReports.length - count);
  }

  /// Read crashes line by line (streaming - memory efficient for large files)
  static Stream<Map<String, dynamic>> streamCrashReports() async* {
    try {
      File? crashFile = await getCrashReportFile();

      if (crashFile == null) {
        return;
      }

      Stream<String> lines = crashFile.openRead()
          .transform(utf8.decoder)
          .transform(LineSplitter());

      await for (String line in lines) {
        if (line.trim().isEmpty) continue;

        try {
          Map<String, dynamic> crash = jsonDecode(line);
          yield crash;
        } catch (e) {
          // print(' Error parsing line: $e');
        }
      }
    } catch (e) {
      // print(' Error streaming crash reports: $e');
    }
  }

  /// Get crash reports by error type
  static Future<List<Map<String, dynamic>>> getCrashReportsByErrorType(String errorType) async {
    List<Map<String, dynamic>> allReports = await getAllCrashReports();
    List<Map<String, dynamic>> filteredReports = allReports
        .where((report) => report['errorType']?.toString().contains(errorType) ?? false)
        .toList();

    // print(' Found ${filteredReports.length} crashes with error type: $errorType');
    return filteredReports;
  }

  /// Create a formatted UI widget for displaying crash report
  static Widget buildCrashReportWidget(Map<String, dynamic> crashData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            icon: Icons.access_time,
            title: 'Timestamp',
            content: crashData['timestamp'] ?? 'Unknown',
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.error_outline,
            title: 'Error',
            content: crashData['error']?.toString() ?? 'No error information',
            isError: true,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.code,
            title: 'Stack Trace',
            content: crashData['stackTrace'] ?? 'No stack trace available',
          ),
          if (crashData['deviceInfo'] != null) ...[
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.phone_android,
              title: 'Device Info',
              content: _formatMapAsString(crashData['deviceInfo']),
            ),
          ],
          if (crashData['additionalInfo'] != null &&
              (crashData['additionalInfo'] as Map).isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.info_outline,
              title: 'Additional Info',
              content: _formatMapAsString(crashData['additionalInfo']),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    bool isError = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: isError ? Colors.red : Colors.blue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                content,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatMapAsString(Map<String, dynamic> map) {
    StringBuffer buffer = StringBuffer();
    map.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    return buffer.toString().trim();
  }
}