import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Iteratively compresses an image to land within [targetMinKB, targetMaxKB]
/// by stepping down JPEG quality and, once quality alone isn't enough,
/// dimensions too. PNG has no comparable lossy quality knob, so JPEG is used
/// regardless of the source format.
///
/// Always returns the closest result found within [maxAttempts] tries — it
/// never returns null, but throws if compression itself fails outright.
class ImageCompressionHelper {
  ImageCompressionHelper._();

  static Future<Uint8List> compressToTargetSize(
    Uint8List imageBytes, {
    int targetMinKB = 300,
    int targetMaxKB = 500,
    int startQuality = 95,
    int startDimension = 2000,
    int maxAttempts = 15,
  }) async {
    final int targetMinBytes = targetMinKB * 1024;
    final int targetMaxBytes = targetMaxKB * 1024;

    int quality = startQuality;
    int minWidth = startDimension;
    int minHeight = startDimension;

    Uint8List? bestBytes;
    int? bestSize;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      if (attempt > 0) {
        if (quality > 30) {
          quality = (startQuality - (attempt * 3)).clamp(30, startQuality);
        }
        if (quality < 70 && minWidth > 800) {
          minWidth = (minWidth * 0.92).round();
          minHeight = (minHeight * 0.92).round();
        }
      }

      final compressed = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: minWidth,
        minHeight: minHeight,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      if (compressed == null) continue;

      final size = compressed.length;

      // Exact hit — stop immediately.
      if (size >= targetMinBytes && size <= targetMaxBytes) {
        return compressed;
      }

      if (bestSize == null) {
        bestBytes = compressed;
        bestSize = size;
      } else if (size < targetMinBytes && size > bestSize) {
        // Closer to the range from below than anything seen so far.
        bestBytes = compressed;
        bestSize = size;
      } else if (size > targetMaxBytes && size < bestSize) {
        // Closer to the range from above than anything seen so far.
        bestBytes = compressed;
        bestSize = size;
      }
    }

    if (bestBytes == null) {
      throw 'Image compression failed';
    }

    return bestBytes;
  }
}
