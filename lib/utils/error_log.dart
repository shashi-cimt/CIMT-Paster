import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

enum ErrorLevel {
  info,
  warning,
  error,
  critical,
}

class ErrorReportManager {
  static const String _errorFileName = 'error_reports.jsonl'; // JSON Lines format
  static const int _maxErrorEntries = 500; // Maximum entries to keep in file

  /// Store error report - each error on a new line
  static Future<String> storeErrorReport({
    required String error,
    required ErrorLevel level,
    String? stackTrace,
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      return await _storeErrorReportExternal(error, level, stackTrace, additionalInfo);
    } catch (e) {
      print('❌ Error in external error storage, using fallback: $e');
      return await _storeErrorReportFallback(error, level, stackTrace, additionalInfo);
    }
  }

  /// External storage method (app-specific, no permission needed)
  static Future<String> _storeErrorReportExternal(
      String error,
      ErrorLevel level,
      String? stackTrace,
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

    return await _appendErrorToFile(appDocDir, error, level, stackTrace, additionalInfo);
  }

  /// Fallback storage method (always available)
  static Future<String> _storeErrorReportFallback(
      String error,
      ErrorLevel level,
      String? stackTrace,
      Map<String, dynamic>? additionalInfo,
      ) async {
    try {
      // Use app documents directory (always accessible)
      Directory appDocDir = await getApplicationDocumentsDirectory();
      return await _appendErrorToFile(appDocDir, error, level, stackTrace, additionalInfo);
    } catch (e) {
      // If even that fails, try temporary directory
      Directory tempDir = await getTemporaryDirectory();
      return await _appendErrorToFile(tempDir, error, level, stackTrace, additionalInfo);
    }
  }

  /// Append error as a new line in the file
  static Future<String> _appendErrorToFile(
      Directory baseDir,
      String error,
      ErrorLevel level,
      String? stackTrace,
      Map<String, dynamic>? additionalInfo,
      ) async {
    // Create the nested folder structure for error logs
    Directory errorLogsDir = Directory('${baseDir.path}/Logs');

    if (!await errorLogsDir.exists()) {
      await errorLogsDir.create(recursive: true);
    }

    // Get device info
    Map<String, String> deviceInfo = await _getDeviceInfo();

    // Create error report data with proper structure
    Map<String, dynamic> errorReport = {
      'timestamp': DateTime.now().toIso8601String(),
      'level': level.name,
      'error': error,
      'stackTrace': stackTrace ?? 'No stack trace available',
      'deviceInfo': deviceInfo,
      'additionalInfo': additionalInfo ?? {},
      'storageLocation': baseDir.path,
    };

    // Define the full path for the single error report file
    String filePath = '${errorLogsDir.path}/$_errorFileName';
    File errorFile = File(filePath);

    // Convert error to compact JSON (single line)
    String compactJson = jsonEncode(errorReport);

    // Check if file exists and count lines
    int currentLineCount = 0;
    if (await errorFile.exists()) {
      try {
        String existingContent = await errorFile.readAsString();
        currentLineCount = existingContent.split('\n').where((line) => line.trim().isNotEmpty).length;
      } catch (e) {
        // print('⚠️ Error reading existing error file: $e');
      }
    }

    // If file is too large, trim old entries
    if (currentLineCount >= _maxErrorEntries) {
      await _trimOldEntries(errorFile, _maxErrorEntries - 1);
    }

    // Append new error as a new line
    await errorFile.writeAsString(
      '$compactJson\n',
      mode: FileMode.append,
      encoding: utf8,
      flush: true, // Ensure data is written immediately
    );

    // print('🎉 SUCCESS! Error report appended to: $filePath');
    // print('📊 Total errors in file: ${currentLineCount + 1}');
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

  /// Store a simple error message (convenience method)
  static Future<String> storeErrorMessage(
      String message, {
        ErrorLevel level = ErrorLevel.error,
      }) async {
    return await storeErrorReport(
      error: message,
      level: level,
      stackTrace: null,
      additionalInfo: null,
    );
  }

  /// Get basic device information for error reports
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

  /// Get the single error report file
  static Future<File?> getErrorReportFile() async {
    // Check external storage first
    try {
      Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        File externalFile = File('${externalDir.path}/CIMTDWP/Logs/$_errorFileName');
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
      File fallbackFile = File('${appDocDir.path}/Logs/$_errorFileName');
      if (await fallbackFile.exists()) {
        return fallbackFile;
      }
    } catch (e) {
      // print('Error accessing fallback storage: $e');
    }

    return null;
  }

  /// Get all error reports from the file (each line is one error)
  static Future<List<Map<String, dynamic>>> getAllErrorReports() async {
    try {
      File? errorFile = await getErrorReportFile();

      if (errorFile == null) {
        // print('📊 No error report file found');
        return [];
      }

      String content = await errorFile.readAsString();
      List<String> lines = content.split('\n').where((line) => line.trim().isNotEmpty).toList();

      List<Map<String, dynamic>> errors = [];

      for (String line in lines) {
        try {
          Map<String, dynamic> error = jsonDecode(line);
          errors.add(error);
        } catch (e) {
          // print('⚠️ Error parsing line: $e');
        }
      }

      // print('📊 Found ${errors.length} total error reports');
      return errors;
    } catch (e) {
      // print('❌ Error reading error reports: $e');
      return [];
    }
  }

  /// Get total error count without loading all errors
  static Future<int> getErrorCount() async {
    try {
      File? errorFile = await getErrorReportFile();

      if (errorFile == null) {
        return 0;
      }

      String content = await errorFile.readAsString();
      int count = content.split('\n').where((line) => line.trim().isNotEmpty).length;

      // print('📊 Total error count: $count');
      return count;
    } catch (e) {
      // print('❌ Error counting errors: $e');
      return 0;
    }
  }

  /// Clear old error reports (keep only last N entries)
  static Future<void> cleanupOldReports({int keepCount = 100}) async {
    try {
      File? errorFile = await getErrorReportFile();

      if (errorFile == null) {
        // print('📊 No error report file found');
        return;
      }

      String content = await errorFile.readAsString();
      List<String> lines = content.split('\n').where((line) => line.trim().isNotEmpty).toList();

      if (lines.length <= keepCount) {
        // print('📊 Found ${lines.length} reports, no cleanup needed (keeping $keepCount)');
        return;
      }

      // Keep only the last N lines
      List<String> recentLines = lines.sublist(lines.length - keepCount);

      // Rewrite file with recent lines
      await errorFile.writeAsString(
        recentLines.join('\n') + '\n',
        encoding: utf8,
        flush: true,
      );

      int deletedCount = lines.length - keepCount;
      // print('🧹 Cleanup complete: removed $deletedCount old reports, kept $keepCount recent ones');
    } catch (e) {
      // print('❌ Error cleaning up old reports: $e');
    }
  }

  /// Get error reports by level
  static Future<List<Map<String, dynamic>>> getErrorReportsByLevel(ErrorLevel level) async {
    List<Map<String, dynamic>> allReports = await getAllErrorReports();
    List<Map<String, dynamic>> filteredReports = allReports
        .where((report) => report['level'] == level.name)
        .toList();

    // print('📊 Found ${filteredReports.length} ${level.name} level reports');
    return filteredReports;
  }

  /// Get error statistics
  static Future<Map<String, int>> getErrorStatistics() async {
    Map<String, int> stats = {
      'info': 0,
      'warning': 0,
      'error': 0,
      'critical': 0,
      'total': 0,
    };

    List<Map<String, dynamic>> allReports = await getAllErrorReports();
    stats['total'] = allReports.length;

    for (var report in allReports) {
      String level = report['level'] ?? 'error';
      stats[level] = (stats[level] ?? 0) + 1;
    }

    // print('📊 Error Statistics: $stats');
    return stats;
  }

  /// Export all error reports to a timestamped file
  static Future<String?> exportAllErrors() async {
    try {
      List<Map<String, dynamic>> allErrors = await getAllErrorReports();

      if (allErrors.isEmpty) {
        print('⚠️ No errors to export');
        return null;
      }

      // Sort by timestamp (newest first)
      allErrors.sort((a, b) {
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
      String fileName = 'all_errors_export_$timestamp.json';
      String filePath = '${exportDir.path}/$fileName';

      File exportFile = File(filePath);

      // Pretty print for export
      JsonEncoder encoder = JsonEncoder.withIndent('  ');
      String prettyJson = encoder.convert(allErrors);

      await exportFile.writeAsString(
        prettyJson,
        encoding: utf8,
        flush: true,
      );

      // print('📦 Exported ${allErrors.length} errors to: $filePath');
      return filePath;
    } catch (e) {
      // print('❌ Error exporting errors: $e');
      return null;
    }
  }

  /// Clear all error reports
  static Future<bool> clearAllErrors() async {
    try {
      File? errorFile = await getErrorReportFile();

      if (errorFile != null && await errorFile.exists()) {
        await errorFile.delete();
        // print('🧹 All error reports cleared');
        return true;
      }

      // print('⚠️ No error file to clear');
      return false;
    } catch (e) {
      // print('❌ Error clearing error reports: $e');
      return false;
    }
  }

  /// Get error reports within a date range
  static Future<List<Map<String, dynamic>>> getErrorReportsByDateRange(
      DateTime startDate,
      DateTime endDate,
      ) async {
    List<Map<String, dynamic>> allReports = await getAllErrorReports();

    List<Map<String, dynamic>> filteredReports = allReports.where((report) {
      try {
        String timestampStr = report['timestamp'] ?? '';
        DateTime timestamp = DateTime.parse(timestampStr);
        return timestamp.isAfter(startDate) && timestamp.isBefore(endDate);
      } catch (e) {
        return false;
      }
    }).toList();

    // print('📊 Found ${filteredReports.length} reports between $startDate and $endDate');
    return filteredReports;
  }

  /// Get the most recent N error reports
  static Future<List<Map<String, dynamic>>> getRecentErrors({int count = 10}) async {
    List<Map<String, dynamic>> allReports = await getAllErrorReports();

    if (allReports.length <= count) {
      return allReports;
    }

    return allReports.sublist(allReports.length - count);
  }

  /// Read errors line by line (streaming - memory efficient for large files)
  static Stream<Map<String, dynamic>> streamErrorReports() async* {
    try {
      File? errorFile = await getErrorReportFile();

      if (errorFile == null) {
        return;
      }

      Stream<String> lines = errorFile.openRead()
          .transform(utf8.decoder)
          .transform(LineSplitter());

      await for (String line in lines) {
        if (line.trim().isEmpty) continue;

        try {
          Map<String, dynamic> error = jsonDecode(line);
          yield error;
        } catch (e) {
          // print('⚠️ Error parsing line: $e');
        }
      }
    } catch (e) {
      // print('❌ Error streaming error reports: $e');
    }
  }
}