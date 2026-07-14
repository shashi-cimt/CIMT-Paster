import 'dart:io';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class SyncCrashReportManager {
  static const String _crashFileName = 'sync_crash_reports.jsonl'; // JSON Lines format
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
      // print('❌ Error in external crash storage, using fallback: $e');
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
        // print('⚠️ Error reading existing crash file: $e');
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

    // print('🎉 SUCCESS! Sync crash report appended to: $filePath');
    // print('📊 Total crashes in file: ${currentLineCount + 1}');
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

      // print('🧹 Trimmed file to last $keepCount entries');
    } catch (e) {
      // print('⚠️ Error trimming old entries: $e');
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
      // print('🚨 Uncaught error: $error');

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

  /// Export crash reports to a single formatted text file
  static Future<String?> exportCrashReportsToText() async {
    try {
      List<File> reports = await getAllCrashReports();

      if (reports.isEmpty) {
        // print('📋 No crash reports to export.');
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
      String fileName = 'sync_crash_export_$timestamp.txt';
      String filePath = '${exportDir.path}/$fileName';
      File exportFile = File(filePath);

      // Build export content
      StringBuffer content = StringBuffer();
      content.writeln('═══════════════════════════════════════════════════════════');
      content.writeln('           SYNC CRASH REPORTS EXPORT');
      content.writeln('           Generated: ${DateTime.now().toIso8601String()}');
      content.writeln('           Total Reports: ${reports.length}');
      content.writeln('═══════════════════════════════════════════════════════════\n\n');

      for (int i = 0; i < reports.length; i++) {
        try {
          content.writeln('\n${'=' * 60}');
          content.writeln('REPORT ${i + 1}/${reports.length}');
          content.writeln('=' * 60);
          content.writeln(await _readFileContent(reports[i]));
          content.writeln('\n');
        } catch (e) {
          content.writeln('\n⚠️ Error processing report: $e\n');
        }
      }

      // Write to file
      await exportFile.writeAsString(content.toString(), encoding: utf8);

      // print('📤 Crash reports exported to: $filePath');
      return filePath;

    } catch (e) {
      // print('❌ Error exporting crash reports: $e');
      return null;
    }
  }

  static Future<String> _readFileContent(File file) async {
    return await file.readAsString();
  }

  static Future<List<File>> getAllCrashReports() async {
    List<File> allReports = [];

    // Check external storage first
    try {
      Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        Directory externalLogsDir = Directory('${externalDir.path}/CIMTDWP/Logs');
        if (await externalLogsDir.exists()) {
          List<FileSystemEntity> files = await externalLogsDir.list().toList();
          List<File> externalReports = files.whereType<File>()
              .where((file) => file.path.contains('sync_report_'))
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
      Directory fallbackDir = Directory('${appDocDir.path}/Logs');
      if (await fallbackDir.exists()) {
        List<FileSystemEntity> files = await fallbackDir.list().toList();
        List<File> fallbackReports = files.whereType<File>()
            .where((file) => file.path.contains('sync_report_'))
            .toList();
        allReports.addAll(fallbackReports);
      }
    } catch (e) {
      // print('Error accessing fallback storage: $e');
    }

    // print('📊 Found ${allReports.length} total sync crash reports');
    return allReports;
  }
}
