import 'package:hive/hive.dart';

import '../Hive_Database/offline_count_db.dart';
import '../Hive_Database/plan_offline_count_db.dart';

class PlanCountChangeHiveRepository {
  Box<PlanOfflineCount>? _offlineCountBox;
  Box<PlanOfflineCount>? _artworkOfflineCountBox;

  // This should be called when user submits a plan locally (offline)
  Future<void> incrementOfflineCount(String planCode, String villageCode, String villageName, String tehsil) async {
    if (_offlineCountBox == null) {
      _offlineCountBox = await Hive.openBox<PlanOfflineCount>('planofflineCount');
    }

    String groupKey = '${planCode}_${villageCode}_${villageName}_${tehsil}';
    PlanOfflineCount? existingCount = _offlineCountBox!.get(groupKey);

    if (existingCount != null) {
      existingCount.submittedCount += 1;
      await _offlineCountBox!.put(groupKey, existingCount);
    } else {
      PlanOfflineCount newCount = PlanOfflineCount(groupKey: groupKey, submittedCount: 1);
      await _offlineCountBox!.put(groupKey, newCount);
    }


  }

  // This should be called when the upload is successfully synced to server
  Future<void> decrementOfflineCount(String planCode, String villageCode, String villageName, String tehsil) async {
    if (_offlineCountBox == null) {
      _offlineCountBox = await Hive.openBox<PlanOfflineCount>('planofflineCount');
    }

    String groupKey = '${planCode}_${villageCode}_${villageName}_${tehsil}';
    PlanOfflineCount? existingCount = _offlineCountBox!.get(groupKey);

    if (existingCount != null && existingCount.submittedCount > 0) {
      existingCount.submittedCount -= 1;

      if (existingCount.submittedCount == 0) {
        await _offlineCountBox!.delete(groupKey);
        } else {
        await _offlineCountBox!.put(groupKey, existingCount);
      }
    } else {
      print(' No offline count to decrement for group: $groupKey');
    }
  }

  Future<int> getOfflineCountForGroup(String planCode, String villageCode, String villageName, String tehsil) async {
    if (_offlineCountBox == null) {
      _offlineCountBox = await Hive.openBox<PlanOfflineCount>('planofflineCount');
    }

    String groupKey = '${planCode}_${villageCode}_${villageName}_${tehsil}';
    PlanOfflineCount? count = _offlineCountBox!.get(groupKey);

    int offlineCount = count?.submittedCount ?? 0;
    return offlineCount;
  }

  // Add method to get all offline counts for debugging
  Future<Map<String, int>> getAllOfflineCounts() async {
    if (_offlineCountBox == null) {
      _offlineCountBox = await Hive.openBox<PlanOfflineCount>('planofflineCount');
    }

    Map<String, int> allCounts = {};
    for (var key in _offlineCountBox!.keys) {
      PlanOfflineCount? count = _offlineCountBox!.get(key);
      if (count != null) {
        allCounts[key] = count.submittedCount;
      }
    }
    return allCounts;
  }

  Future<void> clearAllOfflineCounts() async {
    if (_offlineCountBox == null) {
      _offlineCountBox = await Hive.openBox<PlanOfflineCount>('planofflineCount');
    }

    await _offlineCountBox!.clear();
    if (_artworkOfflineCountBox == null) {
      _artworkOfflineCountBox = await Hive.openBox<PlanOfflineCount>('artworkOfflineCount');
    }
    await _artworkOfflineCountBox!.clear();
  }

  Future<void> clearArtworkOfflineCount(
      String planServerId,
      String planCode,
      String villageCode,
      int artworkId
      ) async {
    if (_artworkOfflineCountBox == null) {
      _artworkOfflineCountBox = await Hive.openBox<PlanOfflineCount>('artworkOfflineCount');
    }

    String artworkKey = '${planServerId}_${planCode}_${villageCode}_${artworkId}';
    await _artworkOfflineCountBox!.delete(artworkKey);
  }

  Future<void> incrementArtworkOfflineCount(
      String planServerId,
      String planCode,
      String villageCode,
      int artworkId
      ) async {
    if (_artworkOfflineCountBox == null) {
      _artworkOfflineCountBox = await Hive.openBox<PlanOfflineCount>('artworkOfflineCount');
    }

    String artworkKey = '${planServerId}_${planCode}_${villageCode}_${artworkId}';
    PlanOfflineCount? existingCount = _artworkOfflineCountBox!.get(artworkKey);

    if (existingCount != null) {
      existingCount.submittedCount += 1;
      await _artworkOfflineCountBox!.put(artworkKey, existingCount);
    } else {
      PlanOfflineCount newCount = PlanOfflineCount(groupKey: artworkKey, submittedCount: 1);
      await _artworkOfflineCountBox!.put(artworkKey, newCount);
    }
  }

  // Decrement offline count for a specific artwork (called after successful upload)
  Future<void> decrementArtworkOfflineCount(
      String planServerId,
      String planCode,
      String villageCode,
      int artworkId
      ) async {
    if (_artworkOfflineCountBox == null) {
      _artworkOfflineCountBox = await Hive.openBox<PlanOfflineCount>('artworkOfflineCount');
    }

    String artworkKey = '${planServerId}_${planCode}_${villageCode}_${artworkId}';
    PlanOfflineCount? existingCount = _artworkOfflineCountBox!.get(artworkKey);

    if (existingCount != null && existingCount.submittedCount > 0) {
      existingCount.submittedCount -= 1;

      if (existingCount.submittedCount == 0) {
        await _artworkOfflineCountBox!.delete(artworkKey);
      } else {
        await _artworkOfflineCountBox!.put(artworkKey, existingCount);
      }
    }
  }

  // Get offline count for a specific artwork
  Future<int> getArtworkOfflineCount(
      String planServerId,
      String planCode,
      String villageCode,
      int artworkId
      ) async {
    if (_artworkOfflineCountBox == null) {
      _artworkOfflineCountBox = await Hive.openBox<PlanOfflineCount>('artworkOfflineCount');
    }

    String artworkKey = '${planServerId}_${planCode}_${villageCode}_${artworkId}';
    PlanOfflineCount? count = _artworkOfflineCountBox!.get(artworkKey);

    return count?.submittedCount ?? 0;
  }

  // Get all artwork offline counts for debugging
  Future<Map<String, int>> getAllArtworkOfflineCounts() async {
    if (_artworkOfflineCountBox == null) {
      _artworkOfflineCountBox = await Hive.openBox<PlanOfflineCount>('artworkOfflineCount');
    }

    Map<String, int> allCounts = {};
    for (var key in _artworkOfflineCountBox!.keys) {
      PlanOfflineCount? count = _artworkOfflineCountBox!.get(key);
      if (count != null) {
        allCounts[key] = count.submittedCount;
      }
    }

    return allCounts;
  }
}