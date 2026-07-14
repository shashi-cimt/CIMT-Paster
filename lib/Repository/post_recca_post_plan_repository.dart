import 'package:hive/hive.dart';

import '../Hive_Database/post_recca_seePlan_db.dart';

class PostReccaPlanHiveRepository {
  Box<SUPlanModel>? _SUbox;

  Future<void> saveSUPlans(List<SUPlanModel> plans) async {
    if (plans.isEmpty) {
      // print('The plans list is empty. No data to save.');
      return;
    }

    if (_SUbox == null) {
      _SUbox = await Hive.openBox<SUPlanModel>('SUplans');
      // print('Box opened: $_SUbox');
    }

    await _SUbox!.clear();
    // print('Box cleared.');

    // Use index-based keys to avoid overwrites from duplicate planCodes
    for (int i = 0; i < plans.length; i++) {
      var plan = plans[i];
      String key = '${plan.planCode}_$i';
      await _SUbox!.put(key, plan);
    }

    // print('Saved ${plans.length} plans to the box.');
    // print('Box now contains ${_SUbox!.length} items');
  }

  // Add this new method for clearing and saving with debugging
  // This is the new clear and save method
  Future<void> clearAndSaveSUPlans(List<SUPlanModel> plans) async {
    if (_SUbox == null) {
      _SUbox = await Hive.openBox<SUPlanModel>('SUplans');
    }

    // Force clear the box and compact it
    await _SUbox!.clear();
    await _SUbox!.compact();

    // print('=== DEBUGGING SAVE PROCESS ===');
    // print('Total plans to save: ${plans.length}');

    // Simply save all plans without checking for duplicates
    for (int i = 0; i < plans.length; i++) {
      try {
        var plan = plans[i];
        String key = '${plan.planCode}_$i'; // Use planCode combined with index for uniqueness
        await _SUbox!.put(key, plan);
        // print('Saved plan $i: ${plan.planCode} -> ${plan.villageName}');
      } catch (e) {
        // print('Failed to save plan $i: $e');
      }
    }

    // print('Successfully saved ${plans.length} plans');
    // print('Box now contains: ${_SUbox!.length} items');
    // print('=== END DEBUGGING ===');
  }


  Future<List<SUPlanModel>> loadSUPlans() async {
    if (_SUbox == null) {
      _SUbox = await Hive.openBox<SUPlanModel>('SUplans');
    }
    return _SUbox!.values.toList();
  }
}