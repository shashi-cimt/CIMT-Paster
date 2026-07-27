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

  static String? parseUid(String content) {
    content = content.trim();
    if (content.isEmpty) return null;

    String candidate = content;
    for (final line in content.split('\n')) {
      final l = line.trim();
      if (l.startsWith('UID=')) {
        candidate = l.substring(4).trim();
        break;
      }
    }

    if (candidate.length == 16 && RegExp(r'^\d{16}$').hasMatch(candidate)) {
      return candidate;
    }
    return null;
  }

  static String? parseDeviceId(String content) {
    for (final line in content.split('\n')) {
      final l = line.trim();
      if (l.startsWith('DEVICE_ID=')) {
        final id = l.substring(10).trim();
        return id.isEmpty ? null : id;
      }
    }
    return null;
  }

  static Future<String?> readUidFromFile(File uidFile) async {
    if (!await uidFile.exists()) return null;
    return parseUid(await uidFile.readAsString());
  }

  static Future<String?> readDeviceIdFromFile(File uidFile) async {
    if (!await uidFile.exists()) return null;
    return parseDeviceId(await uidFile.readAsString());
  }
}
