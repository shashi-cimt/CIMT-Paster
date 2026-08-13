import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Bakes a JPEG's EXIF orientation into its pixel data so the file is
/// physically upright on disk, independent of whether a given viewer honors
/// the EXIF tag. Returns null if the bytes aren't a decodable JPEG.
///
/// Skips the decode/encode round trip entirely when the EXIF tag already
/// says "normal" (1) or is absent — which is the common case, since most
/// devices' native camera/picker pipeline already writes upright pixels.
/// Only pays for the full decode+encode (a slow, non-hardware-accelerated
/// pure-Dart JPEG codec) when the tag says the pixels are actually rotated.
///
/// Top-level (not a class member) so it can be handed to `compute()`, which
/// runs it on a background isolate.
Uint8List? bakeJpegOrientation(Uint8List rawBytes) {
  if (_readJpegOrientationTag(rawBytes) == 1) {
    return rawBytes;
  }

  final img.Image? decoded = img.decodeJpg(rawBytes);
  if (decoded == null) return null;

  final img.Image upright = img.bakeOrientation(decoded);
  return img.encodeJpg(upright, quality: 95);
}

/// Reads the EXIF "Orientation" tag (0x0112) straight out of the JPEG's
/// APP1 segment by walking markers, without decoding any pixel data — a
/// header-only scan of a few hundred bytes instead of a full-image decode.
/// Returns 1 ("normal"/no rotation) if the tag or EXIF segment is missing,
/// which is the correct default per the EXIF spec.
int _readJpegOrientationTag(Uint8List bytes) {
  if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) return 1;

  final ByteData data = ByteData.sublistView(bytes);
  int offset = 2;

  while (offset + 4 <= bytes.length) {
    if (bytes[offset] != 0xFF) break;
    final int marker = bytes[offset + 1];
    offset += 2;

    // Start-of-scan / end-of-image: pixel data follows, no more metadata.
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
