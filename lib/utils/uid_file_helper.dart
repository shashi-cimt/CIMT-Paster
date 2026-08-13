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

  /// Collapses a "`<deviceUid>`|`<userId>`" value down to exactly one pipe,
  /// keeping the first segment as the device uid and the last as the userId.
  /// Guards against stale files that already stacked multiple "|userId"
  /// segments (e.g. "RP1A.200720.011|20487|20487") before the write-side fix,
  /// so reads never re-propagate that duplication into a fresh API call.
  static String? canonicalize(String? content) {
    if (content == null) return null;

    final normalized = _normalizeUidValue(content, preservePipe: true);
    if (normalized == null) return null;
    if (!normalized.contains('|')) return normalized;

    final parts = normalized.split('|').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return null;
    if (parts.length == 1) return parts.first;

    return '${parts.first}|${parts.last}';
  }

  static Future<String?> readDeviceIdFromFile(File uidFile) async {
    if (!await uidFile.exists()) return null;
    return parseDeviceId(await uidFile.readAsString());
  }

  /// Returns the userId portion of a "`<deviceUid>`|`<userId>`" mapping
  /// written after a successful registration or login, or null if the file
  /// doesn't have one yet (e.g. a freshly regenerated UID.txt after the app
  /// was reinstalled).
  static String? parseUserId(String content) {
    content = content.trim();
    if (!content.contains('|')) return null;

    final parts = content.split('|');
    if (parts.length < 2) return null;

    final userId = parts.last.trim();
    return userId.isEmpty ? null : userId;
  }

  static Future<String?> readUserIdFromFile(File uidFile) async {
    if (!await uidFile.exists()) return null;
    return parseUserId(await uidFile.readAsString());
  }

  /// Writes/updates UID.txt with the "`<deviceUid>`|`<userId>`" mapping —
  /// the same format registration writes on first success — so a reinstall
  /// followed by a re-login on the same device repairs the file instead of
  /// leaving it without a userId.
  static Future<void> writeUidWithUserId(File uidFile, String deviceUid, String userId) async {
    // deviceUid may already be in "deviceUid|userId" form if it was read back
    // from a UID.txt written by a previous registration/login — keep only the
    // bare device-uid portion so re-saving doesn't stack another "|userId"
    // onto it (e.g. "deviceUid|20493|20493").
    final bareDeviceUid = deviceUid.contains('|') ? deviceUid.split('|').first.trim() : deviceUid;

    await uidFile.parent.create(recursive: true);
    await uidFile.writeAsString('$bareDeviceUid|$userId');
  }
}
