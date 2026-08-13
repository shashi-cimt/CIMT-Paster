import 'package:geolocator/geolocator.dart';
import 'location_config.dart';

/// Where a [RawLocationSample] came from. Kept explicit end-to-end (buffer,
/// evidence, logs) so a forensic review can never mistake a fallback for a
/// live reading.
enum LocationSource {
  positionStream,
  currentPosition,
  lastKnown,
  image1Fallback,
  cachedBestFix,
  referencePoint,
}

extension LocationSourceLabel on LocationSource {
  String get label {
    switch (this) {
      case LocationSource.positionStream:
        return 'POSITION_STREAM';
      case LocationSource.currentPosition:
        return 'CURRENT_POSITION';
      case LocationSource.lastKnown:
        return 'LAST_KNOWN';
      case LocationSource.image1Fallback:
        return 'IMAGE1_FALLBACK';
      case LocationSource.cachedBestFix:
        return 'CACHED_BEST_FIX';
      case LocationSource.referencePoint:
        return 'REFERENCE_POINT';
    }
  }
}

/// Internal trust classification for a single sample, combining accuracy
/// AND freshness — an old high-accuracy fix is not "GOOD" forever.
enum LocationQuality { good, acceptable, poor, stale, invalid }

/// One raw GPS reading plus everything needed to judge whether it should be
/// trusted later: where it came from, how old it is, and (once evaluated)
/// whether it looks like an outlier relative to its neighbors.
///
/// Never mutated except [isOutlier], which is recomputed as new samples
/// arrive in the rolling buffer — the raw lat/lng/accuracy themselves are
/// immutable, so raw evidence is never silently altered.
class RawLocationSample {
  final String sessionId;
  final LocationSource source;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double speed;
  final double speedAccuracy;
  final double heading;
  final double altitude;
  final bool isMocked;

  /// Device/GPS-reported fix time.
  final DateTime fixTimestamp;

  /// When the app actually ingested this sample.
  final DateTime receivedAt;

  bool isOutlier;

  RawLocationSample({
    required this.sessionId,
    required this.source,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.speed,
    required this.speedAccuracy,
    required this.heading,
    required this.altitude,
    required this.isMocked,
    required this.fixTimestamp,
    DateTime? receivedAt,
    this.isOutlier = false,
  }) : receivedAt = receivedAt ?? DateTime.now();

  factory RawLocationSample.fromPosition(
    Position position, {
    required String sessionId,
    required LocationSource source,
    DateTime? receivedAt,
  }) {
    return RawLocationSample(
      sessionId: sessionId,
      source: source,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      speed: position.speed,
      speedAccuracy: position.speedAccuracy,
      heading: position.heading,
      altitude: position.altitude,
      isMocked: position.isMocked,
      fixTimestamp: position.timestamp,
      receivedAt: receivedAt,
    );
  }

  /// A fixed non-GPS point (e.g. the plan's server-provided coordinate) used
  /// as a comparison baseline. Treated as maximally fresh/accurate since it
  /// is not itself a device fix subject to drift.
  factory RawLocationSample.referencePoint({
    required double latitude,
    required double longitude,
    required String sessionId,
  }) {
    final now = DateTime.now();
    return RawLocationSample(
      sessionId: sessionId,
      source: LocationSource.referencePoint,
      latitude: latitude,
      longitude: longitude,
      accuracy: 1.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      heading: 0.0,
      altitude: 0.0,
      isMocked: false,
      fixTimestamp: now,
      receivedAt: now,
    );
  }

  /// Treats (0,0) — "Null Island" — as never a legitimate fallback/reading.
  bool get isZeroIsland => latitude.abs() < 1e-7 && longitude.abs() < 1e-7;

  int ageMsAt(DateTime reference) =>
      reference.difference(fixTimestamp).inMilliseconds.abs();

  LocationQuality qualityAt(DateTime reference) {
    if (isZeroIsland) return LocationQuality.invalid;
    if (accuracy.isNaN || accuracy.isInfinite || accuracy <= 0) {
      return LocationQuality.invalid;
    }
    final ageMs = ageMsAt(reference);
    if (ageMs > LocationConfig.staleAgeMs) return LocationQuality.stale;
    if (accuracy <= LocationConfig.goodAccuracyMeters &&
        ageMs <= LocationConfig.freshAgeMs) {
      return LocationQuality.good;
    }
    if (accuracy <= LocationConfig.acceptableAccuracyMeters &&
        ageMs <= LocationConfig.acceptableAgeMs) {
      return LocationQuality.acceptable;
    }
    return LocationQuality.poor;
  }

  Map<String, dynamic> toLogFields(DateTime reference) => {
        'session': sessionId,
        'lat': latitude.toStringAsFixed(7),
        'lng': longitude.toStringAsFixed(7),
        'accuracy': accuracy.toStringAsFixed(1),
        'speed': speed.toStringAsFixed(2),
        'speedAccuracy': speedAccuracy.toStringAsFixed(2),
        'heading': heading.toStringAsFixed(1),
        'altitude': altitude.toStringAsFixed(1),
        'isMocked': isMocked,
        'source': source.label,
        'fixTs': fixTimestamp.toIso8601String(),
        'receivedAt': receivedAt.toIso8601String(),
        'ageMs': ageMsAt(reference),
        'quality': qualityAt(reference).name.toUpperCase(),
        'outlier': isOutlier,
      };
}
