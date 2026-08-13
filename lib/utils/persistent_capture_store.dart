import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Moves a just-captured photo out of the OS-owned temp/cache directory into
/// the app's own permanent external-storage folder immediately after capture.
///
/// Captured photos sit on screen (as a thumbnail in a form slot) for a long
/// time before the user taps Submit — filling remarks, capturing other
/// slots, etc. While a photo's file lives in a temp/cache directory during
/// that window, Android (MIUI in particular) is free to reclaim that space
/// under the same low-memory condition that kills the app process, silently
/// wiping an already-captured photo even though the app still "remembers"
/// its path in the recovery draft. The `CIMTDWP` folder used at final-submit
/// time is never touched by that reclamation, so moving each photo there
/// right after capture (instead of waiting for Submit) makes it crash-safe.
class PersistentCaptureStore {
  static Future<String> persist(
    String sourcePath, {
    required String subfolder,
  }) async {
    try {
      final Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir == null) return sourcePath;

      final Directory dir = Directory(
        '${externalDir.path}/CIMTDWP/PendingCaptures/$subfolder',
      );
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final String destPath =
          '${dir.path}/ '
          '+${DateTime.now().microsecondsSinceEpoch}.jpg';

      final File source = File(sourcePath);
      try {
        await source.rename(destPath);
      } catch (_) {
        // rename() fails when source/destination are on different volumes
        // (e.g. plugin cache vs. external storage) — fall back to copy+delete.
        await source.copy(destPath);
        try {
          await source.delete();
        } catch (_) {}
      }

      return destPath;
    } catch (_) {
      // Best effort only — if persisting fails, keep working with the
      // original (still valid right now) path rather than losing the photo.
      return sourcePath;
    }
  }
}
