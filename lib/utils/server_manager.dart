import 'base.dart';

/// Tracks and advances the active server for each URL family (main API vs
/// See-Plan API). Failover is sticky: once switched to a backup domain,
/// requests keep using it until that backup also becomes unreachable.
class ServerManager {
  static int _baseIndex = 0;
  static int _seePlanIndex = 0;

  /// Advances APIURLs.baseURL to the candidate after [failedUrl] (the base
  /// that just failed to connect). Returns true and updates APIURLs.baseURL
  /// if a further candidate was available; false if [failedUrl] was already
  /// the last candidate.
  static bool failoverBaseUrl(String failedUrl) {
    final matchedIndex = APIURLs.baseUrls.indexOf(failedUrl);
    final from = matchedIndex == -1 ? _baseIndex : matchedIndex;

    if (from >= APIURLs.baseUrls.length - 1) {
      return false;
    }

    _baseIndex = from + 1;
    APIURLs.baseURL = APIURLs.baseUrls[_baseIndex];
    return true;
  }

  /// Same as [failoverBaseUrl] but for APIURLs.URL (See-Plan portal).
  static bool failoverSeePlanUrl(String failedUrl) {
    final matchedIndex = APIURLs.seePlanUrls.indexOf(failedUrl);
    final from = matchedIndex == -1 ? _seePlanIndex : matchedIndex;

    if (from >= APIURLs.seePlanUrls.length - 1) {
      return false;
    }

    _seePlanIndex = from + 1;
    APIURLs.URL = APIURLs.seePlanUrls[_seePlanIndex];
    return true;
  }

  /// Resets both URL families back to their primary domain.
  static void resetAll() {
    _baseIndex = 0;
    _seePlanIndex = 0;
    APIURLs.baseURL = APIURLs.baseUrls[0];
    APIURLs.URL = APIURLs.seePlanUrls[0];
  }
}
