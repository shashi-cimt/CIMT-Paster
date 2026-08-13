import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import 'location_config.dart';
import 'location_sample.dart';

/// A GPS coordinate shift is not automatically physical movement. This is
/// the evidence-based verdict on *why* a distance changed, kept separate
/// from the raw/trusted distance numbers and from the business threshold
/// check — those are combined by the caller, not baked in here.
enum MovementClassification { stationary, moved, gpsDrift, gpsUnreliable }

class MovementEvaluation {
  final MovementClassification classification;
  final String confidence; // 'low' | 'medium' | 'high'
  final String reason;
  final double rawDistanceMeters;
  final double trustedDistanceMeters;
  final double thresholdMeters;
  final int goodSamples;
  final int poorSamples;
  final int outlierSamples;
  final bool trajectoryDetected;
  final int trajectorySupportingSamples;

  MovementEvaluation({
    required this.classification,
    required this.confidence,
    required this.reason,
    required this.rawDistanceMeters,
    required this.trustedDistanceMeters,
    required this.thresholdMeters,
    required this.goodSamples,
    required this.poorSamples,
    required this.outlierSamples,
    required this.trajectoryDetected,
    required this.trajectorySupportingSamples,
  });

  bool get exceedsThreshold => trustedDistanceMeters > thresholdMeters;

  /// The only condition that should ever interrupt the field worker: a
  /// confident MOVED verdict that also breaches the business threshold.
  /// GPS_DRIFT and GPS_UNRELIABLE never block on their own — they are
  /// forensic signal, not a gate, per the production requirement that
  /// normal GPS fluctuation must never stall capture.
  bool get shouldBlock =>
      classification == MovementClassification.moved && exceedsThreshold;
}

class _TrajectoryResult {
  final bool detected;
  final int supportingSamples;
  const _TrajectoryResult(this.detected, this.supportingSamples);
}

double _median(List<double> values) {
  final sorted = List<double>.from(values)..sort();
  final n = sorted.length;
  if (n == 0) return 0;
  if (n.isOdd) return sorted[n ~/ 2];
  return (sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2;
}

/// Marks samples in [buffer] as outliers relative to their neighbors.
///
/// A sample is only an outlier if it is far from the rest of the window
/// AND lacks corroboration from nearby-in-time samples. A run of samples
/// that all agree with each other (a real trajectory) is never flagged,
/// even though it may be far from older samples in the window.
void recomputeOutliers(List<RawLocationSample> buffer) {
  final valid = buffer.where((s) => !s.isZeroIsland).toList();
  for (final sample in valid) {
    final neighbors = valid.where((other) => !identical(other, sample)).toList();
    if (neighbors.isEmpty) {
      sample.isOutlier = false;
      continue;
    }
    final medianLat = _median(neighbors.map((n) => n.latitude).toList());
    final medianLng = _median(neighbors.map((n) => n.longitude).toList());
    final distFromMedian = Geolocator.distanceBetween(
      sample.latitude,
      sample.longitude,
      medianLat,
      medianLng,
    );

    final support = neighbors
        .where((n) => Geolocator.distanceBetween(
                  sample.latitude,
                  sample.longitude,
                  n.latitude,
                  n.longitude,
                ) <=
                LocationConfig.outlierJumpMeters)
        .length;

    sample.isOutlier = distFromMedian > LocationConfig.outlierJumpMeters &&
        support < (LocationConfig.minTrajectorySamplesForMoved - 1);
  }
}

/// Looks for a continuous run of non-outlier samples whose distance from
/// [baseline] grows steadily over realistic timestamps — evidence of actual
/// device movement rather than a single noisy jump.
_TrajectoryResult _detectTrajectory(
  RawLocationSample baseline,
  List<RawLocationSample> samples,
) {
  final usable = samples.where((s) => !s.isOutlier && !s.isZeroIsland).toList()
    ..sort((a, b) => a.fixTimestamp.compareTo(b.fixTimestamp));
  if (usable.length < LocationConfig.minTrajectorySamplesForMoved) {
    return const _TrajectoryResult(false, 0);
  }

  int longestRun = 1;
  int currentRun = 1;
  for (var i = 1; i < usable.length; i++) {
    final prev = usable[i - 1];
    final curr = usable[i];
    final gapMs = curr.fixTimestamp.difference(prev.fixTimestamp).inMilliseconds;
    if (gapMs < 0 || gapMs > 10000) {
      currentRun = 1;
      continue;
    }

    final prevDist = Geolocator.distanceBetween(
        baseline.latitude, baseline.longitude, prev.latitude, prev.longitude);
    final currDist = Geolocator.distanceBetween(
        baseline.latitude, baseline.longitude, curr.latitude, curr.longitude);

    // Small negative wobble tolerated as GPS noise; a real walking
    // trajectory is not perfectly monotonic sample-to-sample.
    if (currDist >= prevDist - 3.0) {
      currentRun++;
    } else {
      currentRun = 1;
    }
    if (currentRun > longestRun) longestRun = currentRun;
  }

  final firstDist = Geolocator.distanceBetween(
      baseline.latitude, baseline.longitude, usable.first.latitude, usable.first.longitude);
  final lastDist = Geolocator.distanceBetween(
      baseline.latitude, baseline.longitude, usable.last.latitude, usable.last.longitude);
  final netGrowth = lastDist - firstDist;

  final detected = longestRun >= LocationConfig.minTrajectorySamplesForMoved &&
      netGrowth >= 8.0;
  return _TrajectoryResult(detected, longestRun);
}

/// Classifies whether a distance shift between [baseline] and the target
/// sample represents real device movement, GPS drift/outlier noise, or
/// evidence too weak to say either way. Uses [windowSamples] (the rolling
/// buffer around the target capture) to look for a supporting trajectory
/// and outlier behavior rather than trusting a single pair of coordinates.
MovementEvaluation classifyMovement({
  required RawLocationSample baseline,
  required RawLocationSample targetRaw,
  required RawLocationSample? targetTrusted,
  required List<RawLocationSample> windowSamples,
  required double thresholdMeters,
  required DateTime referenceTime,
}) {
  final trusted = targetTrusted ?? targetRaw;

  final rawDistance = Geolocator.distanceBetween(
      baseline.latitude, baseline.longitude, targetRaw.latitude, targetRaw.longitude);
  final trustedDistance = Geolocator.distanceBetween(
      baseline.latitude, baseline.longitude, trusted.latitude, trusted.longitude);

  final relevant = windowSamples.where((s) => !s.isZeroIsland).toList();
  final goodCount =
      relevant.where((s) => s.qualityAt(referenceTime) == LocationQuality.good).length;
  final poorCount = relevant.where((s) {
    final q = s.qualityAt(referenceTime);
    return q == LocationQuality.poor || q == LocationQuality.stale;
  }).length;
  final outlierCount = relevant.where((s) => s.isOutlier).length;

  MovementEvaluation result({
    required MovementClassification classification,
    required String confidence,
    required String reason,
    bool trajectoryDetected = false,
    int trajectorySupportingSamples = 0,
  }) {
    return MovementEvaluation(
      classification: classification,
      confidence: confidence,
      reason: reason,
      rawDistanceMeters: rawDistance,
      trustedDistanceMeters: trustedDistance,
      thresholdMeters: thresholdMeters,
      goodSamples: goodCount,
      poorSamples: poorCount,
      outlierSamples: outlierCount,
      trajectoryDetected: trajectoryDetected,
      trajectorySupportingSamples: trajectorySupportingSamples,
    );
  }

  if (baseline.isMocked || trusted.isMocked) {
    return result(
      classification: MovementClassification.gpsUnreliable,
      confidence: 'low',
      reason: 'mocked/simulated location detected',
    );
  }

  final baselineQuality = baseline.qualityAt(referenceTime);
  final targetQuality = trusted.qualityAt(referenceTime);
  if (baselineQuality == LocationQuality.invalid ||
      targetQuality == LocationQuality.invalid) {
    return result(
      classification: MovementClassification.gpsUnreliable,
      confidence: 'low',
      reason: 'invalid coordinate or accuracy '
          '(baseline=${baselineQuality.name}, target=${targetQuality.name})',
    );
  }

  final trajectory = _detectTrajectory(baseline, relevant);

  // Noise floor scales with the worse of the two accuracies involved, so a
  // pair of 3m fixes is held to a tighter standard than a pair of 18m fixes.
  final noiseFloor = math.max(baseline.accuracy, trusted.accuracy).clamp(8.0, 40.0);

  if (trustedDistance <= noiseFloor && !trajectory.detected) {
    return result(
      classification: MovementClassification.stationary,
      confidence: 'high',
      reason: 'distance (${trustedDistance.toStringAsFixed(1)}m) within GPS '
          'noise floor (${noiseFloor.toStringAsFixed(0)}m), no supporting trajectory',
    );
  }

  if (trajectory.detected &&
      trajectory.supportingSamples >= LocationConfig.minTrajectorySamplesForMoved) {
    final confidence = (goodCount >= 3 && outlierCount == 0) ? 'high' : 'medium';
    return result(
      classification: MovementClassification.moved,
      confidence: confidence,
      reason: 'continuous trajectory of ${trajectory.supportingSamples} '
          'consecutive samples supports physical movement',
      trajectoryDetected: true,
      trajectorySupportingSamples: trajectory.supportingSamples,
    );
  }

  final poorEvidence = targetQuality == LocationQuality.poor ||
      targetQuality == LocationQuality.stale ||
      baselineQuality == LocationQuality.poor ||
      baselineQuality == LocationQuality.stale ||
      relevant.length < 2;

  if (poorEvidence) {
    return result(
      classification: MovementClassification.gpsUnreliable,
      confidence: 'low',
      reason: 'insufficient/low-quality samples to confirm movement '
          '(target=${targetQuality.name}, baseline=${baselineQuality.name}, '
          'samples=${relevant.length})',
    );
  }

  return result(
    classification: MovementClassification.gpsDrift,
    confidence: 'medium',
    reason: 'distance shift of ${trustedDistance.toStringAsFixed(1)}m not '
        'supported by a continuous trajectory; treated as GPS drift/outlier',
  );
}
