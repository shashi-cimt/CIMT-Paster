/// Centralized, tunable constants for GPS evidence collection and movement
/// classification. Keep every "magic number" involved in trusting/rejecting
/// a GPS sample here so field-test tuning never requires hunting through the
/// capture screens.
class LocationConfig {
  LocationConfig._();

  /// How much sample history to keep in the rolling buffer.
  static const int rollingWindowSeconds = 30;

  /// Hard cap on buffer length regardless of time window, in case the stream
  /// fires unusually fast (e.g. distanceFilter triggering in a moving vehicle).
  static const int maxBufferSize = 60;

  // ---- Accuracy tiers (meters) ----
  static const double goodAccuracyMeters = 10;
  static const double acceptableAccuracyMeters = 20;
  static const double poorAccuracyMeters = 35;

  // ---- Freshness tiers (ms) ----
  static const int freshAgeMs = 5000;
  static const int acceptableAgeMs = 12000;
  static const int staleAgeMs = 20000;

  /// A single-sample deviation from the surrounding cluster beyond this is a
  /// candidate outlier unless corroborated by nearby samples.
  static const double outlierJumpMeters = 20;

  /// Minimum consecutive corroborating samples required to call a distance
  /// shift a genuine, physically-supported trajectory rather than noise.
  static const int minTrajectorySamplesForMoved = 3;

  // ---- Business thresholds (unchanged from the pre-existing implementation) ----
  static const double image1PlanThresholdMeters = 40;
  static const double image1To37ThresholdMeters = 50;
  static const double submitThresholdMeters = 100;

  /// Minimum gap between two [GPS_SAMPLE] log lines, to keep the log file
  /// bounded even though the position stream can fire much faster.
  static const int gpsSampleLogMinIntervalMs = 1000;

  /// How long to batch pending log lines in memory before an async disk
  /// flush, to avoid a write on every single sample.
  static const int logFlushDelaySeconds = 3;
}
