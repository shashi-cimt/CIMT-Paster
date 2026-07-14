import 'package:hive/hive.dart';
import '../Hive_Database/rework_db.dart';

class ReworkPlanRepository {
  Box<ReworkModel>? _box;

  Future<void> saveReworkPlans(List<ReworkModel> plans) async {
    if (plans.isEmpty) {
      return;
    }

    if (_box == null) {
      _box = await Hive.openBox<ReworkModel>('reworkBox');
    }

    await _box!.clear();

    for (int i = 0; i < plans.length; i++) {
      var plan = plans[i];
      String key = '${plan.planCode}_$i';
      await _box!.put(key, plan);
    }
  }

  //  Clear + Save (same like your SU)
  Future<void> clearAndSaveReworkPlans(List<ReworkModel> plans) async {
    if (_box == null) {
      _box = await Hive.openBox<ReworkModel>('reworkBox');
    }

    await _box!.clear();
    await _box!.compact();

    for (int i = 0; i < plans.length; i++) {
      try {
        var plan = plans[i];
        String key = '${plan.planCode}_$i';
        await _box!.put(key, plan);
      } catch (e) {
        print('Failed to save rework plan $i: $e');
      }
    }
  }

  Future<List<ReworkModel>> loadReworkPlans() async {
    if (_box == null) {
      _box = await Hive.openBox<ReworkModel>('reworkBox');
    }

    return _box!.values.toList();
  }
}