import 'package:hive/hive.dart';

import '../Hive_Database/offline_count_db.dart';

class CountChangeHiveRepository {
  Box<OfflineCount>? _offlineCountBox;

  Future<void> incrementOfflineCount(String planCode, String villageCode, String villageName, String tehsil) async {
    if (_offlineCountBox == null) {
      _offlineCountBox = await Hive.openBox<OfflineCount>('offlineCount');
    }

    String groupKey = '${planCode}_${villageCode}_${villageName}_${tehsil}';

    // Get existing count or create new
    OfflineCount? existingCount = _offlineCountBox!.get(groupKey);

    if (existingCount != null) {
      existingCount.submittedCount += 1;
      await _offlineCountBox!.put(groupKey, existingCount);
    } else {
      OfflineCount newCount = OfflineCount(groupKey: groupKey, submittedCount: 1);
      await _offlineCountBox!.put(groupKey, newCount);
    }

    // print('Incremented offline count for group: $groupKey');
  }

  Future<int> getOfflineCountForGroup(String planCode, String villageCode, String villageName, String tehsil) async {
    if (_offlineCountBox == null) {
      _offlineCountBox = await Hive.openBox<OfflineCount>('offlineCount');
    }

    String groupKey = '${planCode}_${villageCode}_${villageName}_${tehsil}';
    OfflineCount? count = _offlineCountBox!.get(groupKey);

    return count?.submittedCount ?? 0;
  }

  Future<void> decrementOfflineCount(String planCode, String villageCode, String villageName, String tehsil) async {
    if (_offlineCountBox == null) {
      _offlineCountBox = await Hive.openBox<OfflineCount>('offlineCount');
    }

    String groupKey = '${planCode}_${villageCode}_${villageName}_${tehsil}';
    OfflineCount? existingCount = _offlineCountBox!.get(groupKey);

    if (existingCount != null && existingCount.submittedCount > 0) {
      existingCount.submittedCount -= 1;

      if (existingCount.submittedCount == 0) {
        await _offlineCountBox!.delete(groupKey);
      } else {
        await _offlineCountBox!.put(groupKey, existingCount);
      }

      // print('Decremented offline count for group: $groupKey');
    }
  }

  Future<Map<String, int>> getAllOfflineCountsMap() async {
    if (_offlineCountBox == null) {
      _offlineCountBox = await Hive.openBox<OfflineCount>('offlineCount');
    }
    final Map<String, int> counts = {};
    for (var key in _offlineCountBox!.keys) {
      final item = _offlineCountBox!.get(key);
      if (item != null) {
        counts[key.toString()] = item.submittedCount;
      }
    }
    return counts;
  }

  Future<void> clearAllOfflineCounts() async {
    if (_offlineCountBox == null) {
      _offlineCountBox = await Hive.openBox<OfflineCount>('offlineCount');
    }

    await _offlineCountBox!.clear();
    // print('Cleared all offline counts');
  }
}