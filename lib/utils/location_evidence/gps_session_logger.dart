import 'dart:async';

import '../crash_manager.dart';
import 'location_config.dart';
import 'location_sample.dart';
import 'movement_classifier.dart';

/// Appends one line per event to `gps_tracking_log_<date>.jsonl` via
/// [CrashReportManager], so a vendor dispute can be reconstructed from raw
/// samples, not just the final verdict. Writes are batched in memory and
/// flushed on a short timer (or forced at submit/dispose) so this never
/// performs a synchronous disk write per GPS sample.
class GpsSessionLogger {
  final List<String> _pendingLines = [];
  DateTime? _lastSampleLogAt;
  Timer? _flushTimer;

  String _kv(Map<String, dynamic> fields) =>
      fields.entries.map((e) => '${e.key}=${e.value}').join(' ');

  void logSample(RawLocationSample sample, DateTime referenceTime) {
    final now = DateTime.now();
    if (_lastSampleLogAt != null &&
        now.difference(_lastSampleLogAt!).inMilliseconds <
            LocationConfig.gpsSampleLogMinIntervalMs) {
      return;
    }
    _lastSampleLogAt = now;
    _enqueue('[GPS_SAMPLE] ${_kv(sample.toLogFields(referenceTime))}');
  }

  void logImageLocation({
    required String sessionId,
    required String imageLabel,
    required RawLocationSample? raw,
    required RawLocationSample? selected,
    required int samplesConsidered,
  }) {
    final now = DateTime.now();
    _enqueue('[IMAGE_LOCATION] ${_kv({
          'session': sessionId,
          'image': imageLabel,
          'captureTime': now.toIso8601String(),
          'rawLat': raw?.latitude.toStringAsFixed(7) ?? 'null',
          'rawLng': raw?.longitude.toStringAsFixed(7) ?? 'null',
          'rawAccuracy': raw?.accuracy.toStringAsFixed(1) ?? 'null',
          'selectedLat': selected?.latitude.toStringAsFixed(7) ?? 'null',
          'selectedLng': selected?.longitude.toStringAsFixed(7) ?? 'null',
          'selectedAccuracy': selected?.accuracy.toStringAsFixed(1) ?? 'null',
          'selectedAgeMs': selected != null ? selected.ageMsAt(now) : 'null',
          'selectedSource': selected?.source.label ?? 'null',
          'selectedQuality':
              selected?.qualityAt(now).name.toUpperCase() ?? 'null',
          'samplesConsidered': samplesConsidered,
        })}');
  }

  void logDistanceCheck({
    required String sessionId,
    required String from,
    required String to,
    required MovementEvaluation result,
  }) {
    _enqueue('[DISTANCE_CHECK] ${_kv({
          'session': sessionId,
          'from': from,
          'to': to,
          'rawDistanceMeters': result.rawDistanceMeters.toStringAsFixed(1),
          'trustedDistanceMeters':
              result.trustedDistanceMeters.toStringAsFixed(1),
          'thresholdMeters': result.thresholdMeters.toStringAsFixed(0),
        })}');
  }

  void logMovementResult({
    required String sessionId,
    required String from,
    required String to,
    required MovementEvaluation result,
  }) {
    _enqueue('[MOVEMENT_RESULT] ${_kv({
          'session': sessionId,
          'from': from,
          'to': to,
          'classification': result.classification.name.toUpperCase(),
          'confidence': result.confidence,
          'trustedDistanceMeters':
              result.trustedDistanceMeters.toStringAsFixed(1),
          'goodSamples': result.goodSamples,
          'poorSamples': result.poorSamples,
          'outliers': result.outlierSamples,
          'trajectoryDetected': result.trajectoryDetected,
          'trajectorySupportingSamples': result.trajectorySupportingSamples,
          'shouldBlock': result.shouldBlock,
          'reason': '"${result.reason}"',
        })}');
  }

  void _enqueue(String line) {
    _pendingLines.add(line);
    _flushTimer ??= Timer(
      Duration(seconds: LocationConfig.logFlushDelaySeconds),
      flush,
    );
  }

  /// Forces any buffered lines to disk immediately. Call this at points
  /// where the evidence must be durably persisted before the caller moves
  /// on — right before a print submission record is written, and on
  /// session dispose.
  Future<void> flush() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    if (_pendingLines.isEmpty) return;
    final lines = List<String>.from(_pendingLines);
    _pendingLines.clear();
    await CrashReportManager.appendGpsTrackingLines(lines);
  }

  Future<void> dispose() async {
    await flush();
  }
}
