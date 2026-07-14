import 'package:hive/hive.dart';

import '../Hive_Database/Map_pointer_locate_db.dart';


class CapturedLocateRepository {
  Box<CapturedLocate>? _box;

  Future<void> _openBox() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<CapturedLocate>('capturedLocates');
    }
  }

  // Mark a locateId as captured
  Future<void> markAsCaptured(String locateId, String planServerId) async {
    await _openBox();

    if (locateId.isEmpty || planServerId.isEmpty) {
      print("⚠️ Cannot mark as captured: locateId or planServerId is empty");
      return;
    }

    String key = '${planServerId}_$locateId';

    // Check if already marked
    if (_box!.containsKey(key)) {
      print("ℹ️ LocateId $locateId already marked as captured");
      return;
    }

    await _box!.put(key, CapturedLocate(
      locateId: locateId,
      planServerId: planServerId,
      capturedAt: DateTime.now(),
    ));

    print("✅ Marked locateId $locateId as captured for plan $planServerId");
  }

  // Check if a locateId has been captured
  Future<bool> isLocateCaptured(String locateId, String planServerId) async {
    await _openBox();

    if (locateId.isEmpty || planServerId.isEmpty) {
      return false;
    }

    String key = '${planServerId}_$locateId';
    return _box!.containsKey(key);
  }

  // Get all captured locateIds for a plan
  Future<List<String>> getCapturedLocateIds(String planServerId) async {
    await _openBox();

    List<String> capturedIds = [];
    for (var entry in _box!.values) {
      if (entry.planServerId == planServerId) {
        capturedIds.add(entry.locateId);
      }
    }
    return capturedIds;
  }

  // Get all captured locates (for debugging)
  Future<Map<String, CapturedLocate>> getAllCapturedLocates() async {
    await _openBox();

    Map<String, CapturedLocate> all = {};
    for (var entry in _box!.toMap().entries) {
      all[entry.key] = entry.value;
    }
    return all;
  }

  // Clear all captured locates (for testing)
  Future<void> clearAll() async {
    await _openBox();
    await _box!.clear();
    print("🗑️ Cleared all captured locates");
  }

  // Clear for specific plan (for testing)
  Future<void> clearForPlan(String planServerId) async {
    await _openBox();

    List<String> keysToDelete = [];
    for (var entry in _box!.toMap().entries) {
      if (entry.value.planServerId == planServerId) {
        keysToDelete.add(entry.key);
      }
    }

    for (var key in keysToDelete) {
      await _box!.delete(key);
    }

    print("🗑️ Cleared ${keysToDelete.length} captured locates for plan: $planServerId");
  }
}