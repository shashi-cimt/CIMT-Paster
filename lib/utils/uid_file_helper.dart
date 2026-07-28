import 'dart:io';

/// Parses UID.txt, which stores the app-generated UID and this device's
/// Android ID, one per line:
///   UID=`<16 digit uid>`
///   DEVICE_ID=`<android id>`
///
/// Files written before the device id was added contain only the bare
/// 16-digit UID (no "UID=" prefix) — that legacy format is still accepted
/// so upgrading the app doesn't strand existing installs.
class UidFileHelper {
  UidFileHelper._();

  static String? _normalizeUidValue(String? value, {bool preservePipe = false}) {
    if (value == null) return null;

    String normalized = value.trim();
    if (normalized.isEmpty) return null;

    while (normalized.startsWith('=')) {
      normalized = normalized.substring(1).trim();
    }

    if (normalized.startsWith('UID=')) {
      normalized = normalized.substring(4).trim();
    } else if (normalized.startsWith('ANDROID_ID=')) {
      normalized = normalized.substring('ANDROID_ID='.length).trim();
    } else if (normalized.startsWith('DEVICE_ID=')) {
      normalized = normalized.substring('DEVICE_ID='.length).trim();
    }

    if (!preservePipe && normalized.contains('|')) {
      normalized = normalized.split('|').first.trim();
    }

    return normalized.isEmpty ? null : normalized;
  }

  static String? parseUid(String content) {
    content = content.trim();
    if (content.isEmpty) return null;

    for (final line in content.split('\n')) {
      final l = line.trim();
      if (l.isEmpty) continue;

      final normalized = _normalizeUidValue(l);
      if (normalized != null) {
        if (normalized.length == 16 && RegExp(r'^\d{16}$').hasMatch(normalized)) {
          return normalized;
        }
        return normalized;
      }
    }

    return null;
  }

  static String? parseDeviceId(String content) {
    for (final line in content.split('\n')) {
      final l = line.trim();
      if (l.startsWith('DEVICE_ID=')) {
        return _normalizeUidValue(l.substring('DEVICE_ID='.length));
      }
    }
    return null;
  }

  static Future<String?> readUidFromFile(File uidFile) async {
    if (!await uidFile.exists()) return null;
    return parseUid(await uidFile.readAsString());
  }

  static Future<String?> readRawUidContent(File uidFile) async {
    if (!await uidFile.exists()) return null;
    final content = (await uidFile.readAsString()).trim();
    return _normalizeUidValue(content, preservePipe: true);
  }

  static Future<String?> readDeviceIdFromFile(File uidFile) async {
    if (!await uidFile.exists()) return null;
    return parseDeviceId(await uidFile.readAsString());
  }
}
