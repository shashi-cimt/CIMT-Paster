import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:image/image.dart' as img;

/// Bakes a JPEG's EXIF orientation into its physical pixels so the image is
/// physically upright on disk, matching how the camera was held (portrait or landscape),
/// independent of whether a given viewer honors the EXIF tag.
class ImageOrientationUtils {
  ImageOrientationUtils._();

  /// Normalizes an image file on disk in place:
  /// - Bakes EXIF orientation into physical pixel data so it displays upright
  ///   as captured by the camera without altering the natural aspect ratio.
  /// - Leaves normal orientation (tag 1) files untouched for optimal performance.
  /// - Safe: Returns original file path if file does not exist or decoding fails.
  static Future<String> normalizeImageFile(File file) async {
    try {
      if (!await file.exists()) {
        return file.path;
      }

      final Uint8List rawBytes = await file.readAsBytes();
      if (rawBytes.isEmpty) {
        return file.path;
      }

      // Fast check: If already normal orientation (1) or absent, no baking is needed.
      final int exifTag = _readJpegOrientationTag(rawBytes);
      if (exifTag == 1) {
        return file.path;
      }

      // Execute in background isolate via compute to prevent UI jank
      final Uint8List normalizedBytes = await compute(ensurePortraitJpeg, rawBytes);

      if (normalizedBytes.isNotEmpty && normalizedBytes.length != rawBytes.length) {
        await file.writeAsBytes(normalizedBytes, flush: true);
      }
      return file.path;
    } catch (_) {
      // Non-fatal: if normalization fails, fallback to the original file
      return file.path;
    }
  }

  /// Rotates an image file by 90 degrees clockwise on disk and saves it back.
  static Future<bool> rotateImageFile90(File file) async {
    try {
      if (!await file.exists()) return false;
      final Uint8List rawBytes = await file.readAsBytes();
      if (rawBytes.isEmpty) return false;
      final Uint8List rotated = await compute(_rotate90Jpeg, rawBytes);
      if (rotated.isNotEmpty) {
        await file.writeAsBytes(rotated, flush: true);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

/// Bakes EXIF orientation into physical pixels so the image is upright as captured.
/// Top-level function suitable for [compute].
Uint8List ensurePortraitJpeg(Uint8List rawBytes) {
  try {
    final int exifTag = _readJpegOrientationTag(rawBytes);

    // Fast-path: If EXIF orientation is already normal (1), return rawBytes immediately.
    if (exifTag == 1) {
      return rawBytes;
    }

    final img.Image? decoded = img.decodeImage(rawBytes);
    if (decoded == null) return rawBytes;

    // Bake EXIF orientation into the pixels so it is physically upright
    // without altering the natural aspect ratio (portrait stays portrait, landscape stays landscape).
    final img.Image upright = img.bakeOrientation(decoded);

    // Encode as high-quality JPEG
    return Uint8List.fromList(img.encodeJpg(upright, quality: 95));
  } catch (_) {
    return rawBytes;
  }
}

/// Rotates JPEG bytes 90 degrees clockwise in background isolate.
Uint8List _rotate90Jpeg(Uint8List rawBytes) {
  try {
    final img.Image? decoded = img.decodeImage(rawBytes);
    if (decoded == null) return rawBytes;
    final img.Image rotated = img.copyRotate(decoded, angle: 90);
    return Uint8List.fromList(img.encodeJpg(rotated, quality: 95));
  } catch (_) {
    return rawBytes;
  }
}

/// Backwards compatibility helper for existing callers.
Uint8List? bakeJpegOrientation(Uint8List rawBytes) {
  return ensurePortraitJpeg(rawBytes);
}


/// Reads the EXIF "Orientation" tag (0x0112) straight out of the JPEG's
/// APP1 segment by walking markers, without decoding any pixel data.
int _readJpegOrientationTag(Uint8List bytes) {
  if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) return 1;

  final ByteData data = ByteData.sublistView(bytes);
  int offset = 2;

  while (offset + 4 <= bytes.length) {
    if (bytes[offset] != 0xFF) break;
    final int marker = bytes[offset + 1];
    offset += 2;

    // Start-of-scan / end-of-image
    if (marker == 0xDA || marker == 0xD9) break;

    if (offset + 2 > bytes.length) break;
    final int segmentLength = data.getUint16(offset);
    if (segmentLength < 2) break;

    if (marker == 0xE1) {
      final int exifStart = offset + 2;
      if (exifStart + 6 <= bytes.length &&
          bytes[exifStart] == 0x45 && // E
          bytes[exifStart + 1] == 0x78 && // x
          bytes[exifStart + 2] == 0x69 && // i
          bytes[exifStart + 3] == 0x66 && // f
          bytes[exifStart + 4] == 0x00 &&
          bytes[exifStart + 5] == 0x00) {
        return _readOrientationFromTiff(data, bytes, exifStart + 6);
      }
    }

    offset += segmentLength;
  }

  return 1;
}

int _readOrientationFromTiff(ByteData data, Uint8List bytes, int tiffStart) {
  if (tiffStart + 8 > bytes.length) return 1;

  final bool littleEndian =
      bytes[tiffStart] == 0x49 && bytes[tiffStart + 1] == 0x49;
  final Endian endian = littleEndian ? Endian.little : Endian.big;

  final int ifd0Offset = tiffStart + data.getUint32(tiffStart + 4, endian);
  if (ifd0Offset + 2 > bytes.length) return 1;

  final int entryCount = data.getUint16(ifd0Offset, endian);
  int entryOffset = ifd0Offset + 2;

  for (int i = 0; i < entryCount; i++) {
    if (entryOffset + 12 > bytes.length) break;
    final int tag = data.getUint16(entryOffset, endian);
    if (tag == 0x0112) {
      return data.getUint16(entryOffset + 8, endian);
    }
    entryOffset += 12;
  }

  return 1;
}
