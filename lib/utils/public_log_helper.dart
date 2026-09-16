import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'app_storage_helper.dart';
import 'DeviceIdManager.dart';

/// Helper for mirroring app logs, crashes, submissions, and sync events to the
/// public, user-accessible storage folder:
/// `/storage/emulated/0/CIMT/Logs/`
///
/// Features:
/// - Legacy AllPrints format matching native Android app:
///   `Thu Sep 11 14:55:00 GMT+05:30 2026 -- Android version = 33 -- App Version : 3.0.0 -- [{"printType":"normal"/"rework", ...}]`
/// - Separated folders by role: `CIMT/Logs/Paster/` and `CIMT/Logs/Supervisor/`
/// - Dedicated Rework prints log (`Rework_Prints.txt`)
/// - Individual print log in each print folder (`printlogs.txt`)
/// - Auto-cleanup completely disabled as per user instruction.
class PublicLogHelper {
  PublicLogHelper._();

  static final DateFormat _fileDateFmt = DateFormat('yyyy-MM-dd');
  static final DateFormat _entryTimeFmt = DateFormat('yyyy-MM-dd HH:mm:ss');

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

  static String _legacyFileUri(String? path) {
    if (path == null || path.isEmpty) return '';
    return path.startsWith('file:') ? path : 'file:$path';
  }

  static String _cleanFilePath(String? path) {
    if (path == null || path.isEmpty) return '';
    return path.startsWith('file:') ? path.substring(5) : path;
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

  /// Formats print submission data using the exact legacy AllPrints format,
  /// with the addition of the requested 'printType' ('rework' or 'normal').
  static Future<String> _formatLegacyPrintLog(
    DateTime now,
    Map<String, dynamic> data, {
    required bool isRework,
  }) async {
    final info = await _deviceAndAppInfo();

    final String cleanImage = _cleanFilePath(data['CleanImage']?.toString());
    final String wbImage = _cleanFilePath(data['WBImage']?.toString());
    final String sprayImage = _cleanFilePath(data['SprayImage']?.toString());
    final String nearImage = _cleanFilePath((data['NearImage'] ?? data['nearImagePath'])?.toString());
    final String farImage = _cleanFilePath((data['FarImage'] ?? data['farImagePath'])?.toString());
    final String new6Image = _cleanFilePath(data['NewImage6']?.toString());
    final String new7Image = _cleanFilePath(data['NewImage7']?.toString());

    final entry = {
      'printType': isRework ? 'rework' : 'normal',
      'id': (data['serverPlanId'] ?? data['ServerPlanId'] ?? data['printId'] ?? '').toString(),
      'planid': (data['planId'] ?? data['PlanCode'] ?? data['planCode'] ?? '').toString(),
      'Printno': (data['printName'] ?? data['printNo'] ?? data['PrintNo'] ?? '').toString(),
      'CleanImage': _legacyFileUri(cleanImage),
      'CleanImagePath': cleanImage,
      'WBImage': _legacyFileUri(wbImage),
      'WBImagePath': wbImage,
      'SprayImage': _legacyFileUri(sprayImage),
      'SprayImagePath': sprayImage,
      'NearImage': _legacyFileUri(nearImage),
      'NearImagePath': nearImage,
      'FarImage': _legacyFileUri(farImage),
      'FarImagePath': farImage,
      'newImage6': _legacyFileUri(new6Image),
      'newImage6Path': new6Image,
      'newImage7': _legacyFileUri(new7Image),
      'newImage7Path': new7Image,
      'Latitude': (data['Clean_Latitude'] ?? data['Near_Latitude'] ?? data['nearLatitude'] ?? data['Latitude'] ?? '').toString(),
      'Longitude': (data['Clean_Longitude'] ?? data['Near_Longitude'] ?? data['nearLongitude'] ?? data['Longitude'] ?? '').toString(),
      'ExecutionDate': (data['executionDate'] ?? data['ExecutionDate'] ?? '').toString(),
      'UploadDate': (data['uploadDate'] ?? data['UploadDate'] ?? now.toIso8601String()).toString(),
      'imei': (data['deviceUid'] ?? data['UID'] ?? data['uid'] ?? info['deviceId'] ?? '').toString(),
      'VillageCode': (data['villageCode'] ?? data['VillageCode'] ?? '').toString(),
      'Address': (data['address'] ?? data['Address'] ?? '').toString(),
    };

    return '${_legacyTimestamp(now)} -- '
        'Android version = ${info['androidVersion']} -- '
        'App Version : ${info['appVersion']} --  ${jsonEncode([entry])}\n\n';
  }

  /// Appends a general app / network log entry to:
  /// `/storage/emulated/0/CIMT/Logs/{Role}/AppLogs/app_log_YYYY-MM-DD.txt`
  static Future<void> writeAppLog(String message, {String tag = 'APP_LOG'}) async {
    try {
      final now = DateTime.now();
      final dir = await AppStorageHelper.getPublicLogsDirectory(subFolder: 'AppLogs');
      final file = File('${dir.path}/app_log_${_fileDateFmt.format(now)}.txt');

      final buffer = StringBuffer()
        ..writeln('======================================================================')
        ..writeln('[${_entryTimeFmt.format(now)}] [$tag]')
        ..writeln(message.trim())
        ..writeln('----------------------------------------------------------------------\n');

      await file.writeAsString(buffer.toString(), mode: FileMode.append, encoding: utf8);
    } catch (_) {
      // Best-effort logging only; never let logging break main app flow.
    }
  }

  /// Appends a user activity event (login, logout, screen navigation, image actions) to:
  /// `/storage/emulated/0/CIMT/Logs/{Role}/AppLogs/activity_log_YYYY-MM-DD.txt`
  static Future<void> writeUserActivity(String event, {Map<String, dynamic>? details}) async {
    try {
      final now = DateTime.now();
      final dir = await AppStorageHelper.getPublicLogsDirectory(subFolder: 'AppLogs');
      final file = File('${dir.path}/activity_log_${_fileDateFmt.format(now)}.txt');

      final buffer = StringBuffer()
        ..writeln('[${_entryTimeFmt.format(now)}] EVENT: $event');
      if (details != null && details.isNotEmpty) {
        buffer.writeln('DETAILS: ${jsonEncode(details)}');
      }
      buffer.writeln();

      await file.writeAsString(buffer.toString(), mode: FileMode.append, encoding: utf8);
    } catch (_) {
      // Best-effort logging only.
    }
  }

  /// Appends a crash or severe error report to:
  /// `/storage/emulated/0/CIMT/Logs/{Role}/Crashes/crash_YYYY-MM-DD.txt`
  static Future<void> writeCrash(
    String error,
    String stackTrace, {
    String? reason,
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      final now = DateTime.now();
      final dir = await AppStorageHelper.getPublicLogsDirectory(subFolder: 'Crashes');
      final file = File('${dir.path}/crash_${_fileDateFmt.format(now)}.txt');

      final buffer = StringBuffer()
        ..writeln('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!')
        ..writeln('CRASH REPORT: ${_entryTimeFmt.format(now)}')
        ..writeln('REASON: ${reason ?? 'Unhandled Error'}')
        ..writeln('ERROR: $error');

      if (additionalInfo != null && additionalInfo.isNotEmpty) {
        buffer.writeln('ADDITIONAL INFO: ${jsonEncode(additionalInfo)}');
      }

      if (stackTrace.trim().isNotEmpty) {
        buffer.writeln('STACK TRACE:');
        buffer.writeln(stackTrace.trim());
      }
      buffer.writeln('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');

      await file.writeAsString(buffer.toString(), mode: FileMode.append, encoding: utf8);
    } catch (_) {
      // Best-effort logging only.
    }
  }

  /// Appends a print submission audit record using the exact legacy format:
  /// 1. `/storage/emulated/0/CIMT/Logs/{Role}/All_Prints.txt`
  /// 2. `/storage/emulated/0/CIMT/Logs/{Role}/Rework_Prints.txt` (if rework)
  /// 3. `/storage/emulated/0/CIMT/Logs/{Role}/Execution_Prints.txt` (if regular execution)
  /// 4. `/storage/emulated/0/CIMT/Logs/All_Prints.txt` (global cumulative)
  /// 5. `/storage/emulated/0/CIMT/Logs/Rework_Prints.txt` (if rework, global)
  /// 6. Individual print folder: `CIMT/{Role}/{ProjectId}/{PlanId}/{VillageCode}/{PrintName}/printlogs.txt`
  static Future<void> writeSubmission(Map<String, dynamic> data) async {
    try {
      final now = DateTime.now();
      final String role = await AppStorageHelper.resolveRoleFolder(
        data['roleFolder']?.toString() ?? data['role']?.toString(),
      );
      final String uploadType = (data['uploadType'] ?? '').toString().toLowerCase();
      final bool isRework = uploadType.contains('rework') || data['isRework'] == true;

      // Format in the exact legacy AllPrints line format with 'printType': 'rework' | 'normal'
      final String legacyLine = await _formatLegacyPrintLog(
        now,
        data,
        isRework: isRework,
      );

      // 1. Role-specific directory: /storage/emulated/0/CIMT/Logs/{Role}/
      try {
        final roleLogsDir = await AppStorageHelper.getPublicLogsDirectory(roleFolder: role);

        // 1a. Role All_Prints.txt
        final roleAllPrints = File('${roleLogsDir.path}/All_Prints.txt');
        await roleAllPrints.writeAsString(legacyLine, mode: FileMode.append, encoding: utf8);

        // 1b. Role Rework_Prints.txt or Execution_Prints.txt
        if (isRework) {
          final reworkFile = File('${roleLogsDir.path}/Rework_Prints.txt');
          await reworkFile.writeAsString(legacyLine, mode: FileMode.append, encoding: utf8);
        } else if (!role.toLowerCase().contains('sup')) {
          final execFile = File('${roleLogsDir.path}/Execution_Prints.txt');
          await execFile.writeAsString(legacyLine, mode: FileMode.append, encoding: utf8);
        }

        // 1c. Submissions daily log for this role
        final subDir = await AppStorageHelper.getPublicLogsDirectory(roleFolder: role, subFolder: 'Submissions');
        final dailyFile = File('${subDir.path}/submissions_${_fileDateFmt.format(now)}.txt');
        await dailyFile.writeAsString(legacyLine, mode: FileMode.append, encoding: utf8);
      } catch (_) {}

      // 2. Root logs directory: /storage/emulated/0/CIMT/Logs/
      try {
        final rootLogsDir = await AppStorageHelper.getPublicLogsDirectory(rootOnly: true);

        // 2a. Global All_Prints.txt
        final rootAllPrints = File('${rootLogsDir.path}/All_Prints.txt');
        await rootAllPrints.writeAsString(legacyLine, mode: FileMode.append, encoding: utf8);

        // 2b. Global Rework_Prints.txt (if rework)
        if (isRework) {
          final rootReworkPrints = File('${rootLogsDir.path}/Rework_Prints.txt');
          await rootReworkPrints.writeAsString(legacyLine, mode: FileMode.append, encoding: utf8);
        }
      } catch (_) {}

      // 3. Individual print folder log: CIMT/{Role}/{ProjectId}/{PlanId}/{VillageCode}/{PrintName}/printlogs.txt
      try {
        final printDir = await _resolveIndividualPrintFolder(data);
        if (printDir != null) {
          final individualLogFile = File('${printDir.path}/printlogs.txt');
          await individualLogFile.writeAsString(legacyLine, mode: FileMode.append, encoding: utf8);
        }
      } catch (_) {}

    } catch (_) {
      // Best-effort logging only.
    }
  }

  /// Resolves the specific print directory under CIMT/Paster/... or CIMT/Supervisor/...
  static Future<Directory?> _resolveIndividualPrintFolder(Map<String, dynamic> data) async {
    // 1. First check if any image path already contains the folder
    final candidatePaths = [
      data['CleanImage'],
      data['NearImage'],
      data['nearImagePath'],
      data['WBImage'],
      data['SprayImage'],
      data['FarImage'],
      data['farImagePath'],
      data['NewImage6'],
      data['NewImage7'],
    ];

    for (final rawPath in candidatePaths) {
      if (rawPath is String && rawPath.trim().isNotEmpty) {
        String cleanPath = rawPath.trim();
        if (cleanPath.startsWith('file:')) {
          cleanPath = cleanPath.substring(5);
        }
        final file = File(cleanPath);
        final parentDir = file.parent;
        if (parentDir.path.contains('/CIMT/')) {
          if (!await parentDir.exists()) {
            await parentDir.create(recursive: true);
          }
          return parentDir;
        }
      }
    }

    // 2. Fallback: resolve using AppStorageHelper.getPrintFolder
    try {
      final role = data['roleFolder'] ?? data['role'] ?? data['Role'];
      final projectId = data['projectId'] ?? data['ProjectId'] ?? data['projectID'];
      final planId = data['PlanCode'] ?? data['planCode'] ?? data['planId'] ?? data['PlanId'];
      final planServerId = data['ServerPlanId'] ?? data['serverPlanId'] ?? data['printId'];
      final villageCode = data['VillageCode'] ?? data['villageCode'];
      final printName = data['printName'] ?? data['PrintNo'] ?? data['printNo'];

      if (villageCode != null &&
          printName != null &&
          villageCode.toString().trim().isNotEmpty &&
          printName.toString().trim().isNotEmpty) {
        return await AppStorageHelper.getPrintFolder(
          roleFolder: role?.toString(),
          projectId: projectId?.toString(),
          planServerId: planServerId?.toString(),
          planId: planId?.toString(),
          villageCode: villageCode.toString().trim(),
          printName: printName.toString().trim(),
        );
      }
    } catch (_) {}

    return null;
  }

  /// Backfill helper: Scans existing private submission logs and ensures any
  /// missing printlogs.txt or CIMT/Logs/ entries are generated in public storage.
  static Future<void> syncExistingSubmissions() async {
    try {
      final Directory? extDir = await getExternalStorageDirectory();
      if (extDir == null) return;
      final List<Directory> checkDirs = [
        Directory('${extDir.path}/CIMTDWP/Logs/AppLogs'),
        Directory('${extDir.path}/CIMTDWPSUP/Logs/AppLogs'),
      ];

      for (final dir in checkDirs) {
        if (!await dir.exists()) continue;
        final entities = await dir.list().toList();
        for (final entity in entities) {
          if (entity is File && entity.path.contains('print_submission_log_')) {
            try {
              final content = await entity.readAsString();
              final decoded = jsonDecode(content);
              if (decoded is List) {
                for (final item in decoded) {
                  if (item is Map<String, dynamic>) {
                    final printDir = await _resolveIndividualPrintFolder(item);
                    if (printDir != null) {
                      final printLogFile = File('${printDir.path}/printlogs.txt');
                      if (!await printLogFile.exists()) {
                        await writeSubmission(item);
                      }
                    }
                  }
                }
              }
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
  }

  /// Appends background sync or auto-resend events to:
  /// `/storage/emulated/0/CIMT/Logs/{Role}/Sync/sync_YYYY-MM-DD.txt`
  static Future<void> writeSyncLog(String message, {String tag = 'SYNC'}) async {
    try {
      final now = DateTime.now();
      final dir = await AppStorageHelper.getPublicLogsDirectory(subFolder: 'Sync');
      final file = File('${dir.path}/sync_${_fileDateFmt.format(now)}.txt');

      final buffer = StringBuffer()
        ..writeln('[${_entryTimeFmt.format(now)}] [$tag] $message');

      await file.writeAsString(buffer.toString(), mode: FileMode.append, encoding: utf8);
    } catch (_) {
      // Best-effort logging only.
    }
  }

  /// Appends GPS evidence lines to:
  /// `/storage/emulated/0/CIMT/Logs/{Role}/GPS/gps_tracking_YYYY-MM-DD.txt`
  static Future<void> writeGpsLines(List<String> lines) async {
    if (lines.isEmpty) return;
    try {
      final now = DateTime.now();
      final dir = await AppStorageHelper.getPublicLogsDirectory(subFolder: 'GPS');
      final file = File('${dir.path}/gps_tracking_${_fileDateFmt.format(now)}.txt');

      final buffer = StringBuffer();
      for (final line in lines) {
        buffer.writeln('[${_entryTimeFmt.format(now)}] $line');
      }

      await file.writeAsString(buffer.toString(), mode: FileMode.append, encoding: utf8);
    } catch (_) {
      // Best-effort logging only.
    }
  }

  /// Appends raw text content to target file under `/storage/emulated/0/CIMT/Logs/{Role}/{subFolder}/{filename}`
  static Future<void> appendRaw(String subFolder, String filename, String content) async {
    try {
      final dir = await AppStorageHelper.getPublicLogsDirectory(subFolder: subFolder);
      final file = File('${dir.path}/$filename');
      await file.writeAsString(content, mode: FileMode.append, encoding: utf8);
    } catch (_) {
      // Best-effort logging only.
    }
  }

  /// Auto-delete is completely disabled as requested by user:
  /// "aur koi file auto dlete nhi hoga theek hai"
  static Future<void> cleanupOldLogs({int daysToKeep = 30}) async {
    // Permanently disabled: no log files will ever be auto-deleted.
    return;
  }
}
