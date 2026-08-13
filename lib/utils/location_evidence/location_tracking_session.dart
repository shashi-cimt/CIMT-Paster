import 'dart:async';
import 'dart:math';

import 'package:geolocator/geolocator.dart';

import 'gps_session_logger.dart';
import 'location_config.dart';
import 'location_sample.dart';
import 'movement_classifier.dart';

/// The trustworthy evidence snapshot behind one captured image (or a
/// submit/recovery event): the raw sample obtained around that moment, the
/// best-selected trusted sample from the rolling buffer, and how many
/// samples were available when the choice was made.
class CapturedLocationEvidence {
  final RawLocationSample? raw;
  final RawLocationSample? trusted;
  final int samplesConsidered;
  final LocationSource selectedSource;

  const CapturedLocationEvidence({
    required this.raw,
    required this.trusted,
    required this.samplesConsidered,
    required this.selectedSource,
  });

  bool get isValid => trusted != null && !trusted!.isZeroIsland;
  double get latitude => trusted?.latitude ?? raw?.latitude ?? 0.0;
  double get longitude => trusted?.longitude ?? raw?.longitude ?? 0.0;
}

/// Owns ONE continuous GPS session for a 7-image capture workflow: a single
/// position stream, a small time-bounded rolling buffer of raw samples, and
/// the evidence snapshots taken at Image 1/3/7 (and Submit/recovery) so
/// movement between them can be evaluated from more than a single pair of
/// coordinates.
///
/// A screen creates exactly one of these in initState and disposes it in
/// dispose() — it replaces the previous bare `_latestPosition` +
/// `StreamSubscription<Position>` fields, it does not add a second stream.
class LocationTrackingSession {
  LocationTrackingSession() : sessionId = _generateSessionId();

  final String sessionId;
  final List<RawLocationSample> _buffer = [];
  final GpsSessionLogger _logger = GpsSessionLogger();
  final Map<int, CapturedLocationEvidence> _imageEvidence = {};
  CapturedLocationEvidence? _submitEvidence;
  StreamSubscription<Position>? _sub;

  static String _generateSessionId() {
    final rand = Random();
    return 'LOC${DateTime.now().millisecondsSinceEpoch}${rand.nextInt(9000) + 1000}';
  }

  /// Starts the continuous background stream. Safe to call once per screen
  /// instance; does not block the caller and never waits for a fix.
  Future<void> start() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      await _sub?.cancel();
      _sub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 1,
        ),
      ).listen(
        (position) => _ingest(RawLocationSample.fromPosition(
          position,
          sessionId: sessionId,
          source: LocationSource.positionStream,
        )),
        onError: (_) {},
      );
    } catch (_) {
      // Best effort only; acquireGateSample() falls back to an on-demand
      // fetch if the stream never produces a reading.
    }
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    await _logger.dispose();
  }

  /// Forces any buffered log lines to disk now — call right before a print
  /// submission record is written so the GPS evidence for that print is
  /// durably persisted at the same moment.
  Future<void> flushLogs() => _logger.flush();

  void _ingest(RawLocationSample sample) {
    _buffer.add(sample);

    final cutoff =
        DateTime.now().subtract(Duration(seconds: LocationConfig.rollingWindowSeconds));
    _buffer.removeWhere((s) => s.receivedAt.isBefore(cutoff));
    if (_buffer.length > LocationConfig.maxBufferSize) {
      _buffer.removeRange(0, _buffer.length - LocationConfig.maxBufferSize);
    }

    recomputeOutliers(_buffer);
    _logger.logSample(sample, DateTime.now());
  }

  /// Best trustworthy sample in the buffer as of [referenceTime]: prefers
  /// non-outlier, non-mocked samples, then ranks by quality tier, then by
  /// freshness, then by raw accuracy. Never returns (0,0).
  RawLocationSample? _selectBestPosition(DateTime referenceTime) {
    final candidates = _buffer.where((s) => !s.isZeroIsland).toList();
    if (candidates.isEmpty) return null;

    final trustedPool =
        candidates.where((s) => !s.isOutlier && !s.isMocked).toList();
    final pool = trustedPool.isNotEmpty ? trustedPool : candidates;

    pool.sort((a, b) {
      final qa = a.qualityAt(referenceTime).index;
      final qb = b.qualityAt(referenceTime).index;
      if (qa != qb) return qa.compareTo(qb);
      final ageA = a.ageMsAt(referenceTime);
      final ageB = b.ageMsAt(referenceTime);
      if ((ageA - ageB).abs() > 1000) return ageA.compareTo(ageB);
      return a.accuracy.compareTo(b.accuracy);
    });

    return pool.first;
  }

  /// Mirrors the previous `_getLatestLocation()`: returns the best sample
  /// already collected in the background without waiting, and only falls
  /// back to a single blocking fetch (tagged CURRENT_POSITION, never
  /// mistaken for a live stream reading in the logs) if the stream hasn't
  /// produced anything usable yet. Used to gate camera-open (unchanged
  /// "unable to get GPS" behavior) and to seed the buffer before a capture.
  Future<RawLocationSample?> acquireGateSample() async {
    final best = _selectBestPosition(DateTime.now());
    if (best != null) return best;
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );
      final sample = RawLocationSample.fromPosition(
        position,
        sessionId: sessionId,
        source: LocationSource.currentPosition,
      );
      _ingest(sample);
      return sample;
    } catch (_) {
      return null;
    }
  }

  CapturedLocationEvidence? imageEvidence(int imageIndex) =>
      _imageEvidence[imageIndex];

  CapturedLocationEvidence? get submitEvidence => _submitEvidence;

  /// Snapshots the best trustworthy evidence for [imageIndex] (0-based: 0 =
  /// Image 1 ... 6 = Image 7) right after the shutter actually fires — not
  /// when the camera button was tapped — so a slow-opening camera can't
  /// silently attribute a stale position to the photo. [gateSample] (from
  /// [acquireGateSample], taken at tap-time) is used only as a last-resort
  /// fallback if the buffer produced nothing better in the meantime.
  CapturedLocationEvidence recordImageCapture(
    int imageIndex, {
    RawLocationSample? gateSample,
    required String imageLabel,
  }) {
    final now = DateTime.now();
    final trusted = _selectBestPosition(now) ?? gateSample;
    final raw = gateSample ?? trusted;
    final evidence = CapturedLocationEvidence(
      raw: raw,
      trusted: trusted,
      samplesConsidered: _buffer.length,
      selectedSource: trusted?.source ?? LocationSource.currentPosition,
    );
    _imageEvidence[imageIndex] = evidence;
    _logger.logImageLocation(
      sessionId: sessionId,
      imageLabel: imageLabel,
      raw: raw,
      selected: trusted,
      samplesConsidered: evidence.samplesConsidered,
    );
    return evidence;
  }

  /// Independent on-demand fetch at Submit time — same business behavior as
  /// before (a fresh fix is required to submit), but now tagged/logged and
  /// folded into the same evaluator instead of being a bare, unlogged call.
  Future<CapturedLocationEvidence> recordSubmitCapture() async {
    RawLocationSample? sample;
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );
      sample = RawLocationSample.fromPosition(
        position,
        sessionId: sessionId,
        source: LocationSource.currentPosition,
      );
      _ingest(sample);
    } catch (_) {
      // Evidence stays null; caller shows the existing "unable to get
      // current location" toast exactly as before.
    }
    final evidence = CapturedLocationEvidence(
      raw: sample,
      trusted: sample,
      samplesConsidered: _buffer.length,
      selectedSource: sample?.source ?? LocationSource.currentPosition,
    );
    _submitEvidence = evidence;
    _logger.logImageLocation(
      sessionId: sessionId,
      imageLabel: 'SUBMIT',
      raw: sample,
      selected: sample,
      samplesConsidered: evidence.samplesConsidered,
    );
    return evidence;
  }

  /// Backfills evidence for a photo recovered after a process kill (e.g.
  /// MIUI killing the app while the native camera had focus). Tagged
  /// CACHED_BEST_FIX and marked as a recovery read throughout the logs so
  /// this reading — captured potentially long after the actual photo — is
  /// never mistaken for a live, in-the-moment GPS fix.
  Future<CapturedLocationEvidence> recordRecoveryCapture(
    int imageIndex, {
    required String imageLabel,
  }) async {
    RawLocationSample? sample;
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );
      sample = RawLocationSample.fromPosition(
        position,
        sessionId: sessionId,
        source: LocationSource.cachedBestFix,
      );
      _ingest(sample);
    } catch (_) {}
    final evidence = CapturedLocationEvidence(
      raw: sample,
      trusted: sample,
      samplesConsidered: _buffer.length,
      selectedSource: LocationSource.cachedBestFix,
    );
    _imageEvidence[imageIndex] = evidence;
    _logger.logImageLocation(
      sessionId: sessionId,
      imageLabel: '${imageLabel}_RECOVERY',
      raw: sample,
      selected: sample,
      samplesConsidered: evidence.samplesConsidered,
    );
    return evidence;
  }

  /// Evaluates movement between two arbitrary samples (e.g. the plan's
  /// fixed reference point vs. a tap-time gate sample, before Image 1 has
  /// even been captured) using the current rolling buffer as supporting
  /// context, and logs [DISTANCE_CHECK]/[MOVEMENT_RESULT].
  MovementEvaluation evaluateAgainstSample({
    required RawLocationSample baseline,
    required RawLocationSample target,
    required double thresholdMeters,
    required String fromLabel,
    required String toLabel,
  }) {
    final result = classifyMovement(
      baseline: baseline,
      targetRaw: target,
      targetTrusted: target,
      windowSamples: List.unmodifiable(_buffer),
      thresholdMeters: thresholdMeters,
      referenceTime: DateTime.now(),
    );
    _logger.logDistanceCheck(
        sessionId: sessionId, from: fromLabel, to: toLabel, result: result);
    _logger.logMovementResult(
        sessionId: sessionId, from: fromLabel, to: toLabel, result: result);
    return result;
  }

  /// Evaluates movement between two already-captured image evidences (e.g.
  /// Image 1 -> Image 3) using their trusted positions.
  MovementEvaluation? evaluateImageMovement({
    required int baselineIndex,
    required int targetIndex,
    required double thresholdMeters,
    required String fromLabel,
    required String toLabel,
  }) {
    final baseline = _imageEvidence[baselineIndex]?.trusted;
    final target = _imageEvidence[targetIndex];
    if (baseline == null || target?.trusted == null) return null;
    return evaluateAgainstSample(
      baseline: baseline,
      target: target!.trusted!,
      thresholdMeters: thresholdMeters,
      fromLabel: fromLabel,
      toLabel: toLabel,
    );
  }

  /// Evaluates movement between a captured image baseline and the Submit-
  /// time evidence.
  MovementEvaluation? evaluateSubmitMovement({
    required int baselineIndex,
    required double thresholdMeters,
    required String fromLabel,
  }) {
    final baseline = _imageEvidence[baselineIndex]?.trusted;
    final target = _submitEvidence?.trusted;
    if (baseline == null || target == null) return null;
    return evaluateAgainstSample(
      baseline: baseline,
      target: target,
      thresholdMeters: thresholdMeters,
      fromLabel: fromLabel,
      toLabel: 'SUBMIT',
    );
  }
}
