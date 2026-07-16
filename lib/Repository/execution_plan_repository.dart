import 'package:hive/hive.dart';

import '../Hive_Database/execution_seeplan_db.dart';

class ExecutionHiveRepository {
  Box<PlanItem>? _box;

  Future<void> savePlans(List<PlanItem> plans) async {
    if (plans.isEmpty) {
      // print('The plans list is empty. No data to save.');
      return;
    }

    // Filter out plans with zero balance before saving
    List<PlanItem> plansWithBalance = plans.where((plan) =>
    (plan.noOfBalance ?? 0) > 0
    ).toList();

    // print('Original plans count: ${plans.length}');
    // print('Plans with balance > 0: ${plansWithBalance.length}');
    // print('Filtered out ${plans.length - plansWithBalance.length} plans with zero balance');

    if (plansWithBalance.isEmpty) {
      // print('No plans with balance > 0 to save.');
      return;
    }

    if (_box == null) {
      _box = await Hive.openBox<PlanItem>('plans');
      // print('Box opened: $_box');
    }

    await _box!.clear();
    // print('Box cleared.');

    // Use index-based keys to avoid overwrites from duplicate planCodes
    for (int i = 0; i < plansWithBalance.length; i++) {
      var plan = plansWithBalance[i];
      String key = '${plan.planCode}_$i';
      await _box!.put(key, plan);
    }

    // print('Saved ${plansWithBalance.length} plans to the box.');
    // print('Box now contains ${_box!.length} items');
  }

  // Add this new method for clearing and saving with debugging
  Future<void> clearAndSavePlans(List<PlanItem> plans) async {
    if (_box == null) {
      _box = await Hive.openBox<PlanItem>('plans');
    }

    // Always clear the box first
    await _box!.clear();
    await _box!.compact();

    // print('=== DEBUGGING SAVE PROCESS ===');
    // print('Total plans received: ${plans.length}');

    // If no plans received, just leave the box empty
    if (plans.isEmpty) {
      // print('No plans to save - box cleared and left empty');
      // print('=== END DEBUGGING ===');
      return;
    }

    // Filter out plans with zero balance before saving
    List<PlanItem> plansWithBalance = plans.where((plan) =>
    (plan.noOfBalance ?? 0) > 0
    ).toList();

    // print('Plans with balance > 0: ${plansWithBalance.length}');
    // print('Filtered out ${plans.length - plansWithBalance.length} plans with zero balance');

    if (plansWithBalance.isEmpty) {
      // print('No plans with balance > 0 to save - box left empty');
      // print('=== END DEBUGGING ===');
      return;
    }

    // Save plans with index-based keys to avoid overwrites
    int savedCount = 0;
    for (int i = 0; i < plansWithBalance.length; i++) {
      try {
        var plan = plansWithBalance[i];
        String key = '${plan.planCode}_$i';
        await _box!.put(key, plan);
        savedCount++;
        // print('Saved plan $i: ${plan.planCode} -> ${plan.villageName} (Balance: ${plan.noOfBalance})');
      } catch (e) {
        print('Failed to save plan $i: $e');
      }
    }

    // print('Successfully saved: $savedCount plans');
    // print('Box now contains: ${_box!.length} items');
    // print('=== END DEBUGGING ===');
  }


  Future<void> clearAndSavePlansWithBalanceFilter(List<PlanItem> plans) async {
    if (_box == null) {
      _box = await Hive.openBox<PlanItem>('plans');
    }

    // Always clear the box first
    await _box!.clear();
    await _box!.compact();

    // print('=== DEBUGGING SAVE PROCESS WITH BALANCE FILTER ===');
    // print('Total plans received: ${plans.length}');

    // If no plans received, just leave the box empty
    if (plans.isEmpty) {
      // print('No plans to save - box cleared and left empty');
      // print('=== END DEBUGGING ===');
      return;
    }

    // Filter out plans with zero or negative balance before saving
    List<PlanItem> plansWithPositiveBalance = plans.where((plan) {
      int balance = plan.noOfBalance ?? 0;
      bool hasPositiveBalance = balance > 0;

      if (!hasPositiveBalance) {
        // print(' Filtering out plan ${plan.planCode} - balance: $balance');
      }

      return hasPositiveBalance;
    }).toList();

    // print('Plans with positive balance: ${plansWithPositiveBalance.length}');
    // print('Filtered out ${plans.length - plansWithPositiveBalance.length} plans with zero/negative balance');

    if (plansWithPositiveBalance.isEmpty) {
      // print('No plans with positive balance to save - box left empty');
      // print('=== END DEBUGGING ===');
      return;
    }

    // Save plans with index-based keys to avoid overwrites
    int savedCount = 0;
    for (int i = 0; i < plansWithPositiveBalance.length; i++) {
      try {
        var plan = plansWithPositiveBalance[i];
        String key = '${plan.planCode}_$i';
        await _box!.put(key, plan);
        savedCount++;
        // print(' Saved plan $i: ${plan.planCode} -> ${plan.villageName} (Balance: ${plan.noOfBalance})');
      } catch (e) {
        print(' Failed to save plan $i: $e');
      }
    }

    // print('Successfully saved: $savedCount plans');
    // print('Box now contains: ${_box!.length} items');
    // print('=== END DEBUGGING ===');
  }

  Future<List<PlanItem>> loadPlans() async {
    if (_box == null) {
      _box = await Hive.openBox<PlanItem>('plans');
    }

    List<PlanItem> allPlans = _box!.values.toList();

    // Additional safety check: filter out any zero-balance plans that might exist
    List<PlanItem> plansWithBalance = allPlans.where((plan) =>
    (plan.noOfBalance ?? 0) > 0
    ).toList();

    // print('Loaded ${allPlans.length} plans from Hive');
    // print('Plans with balance > 0: ${plansWithBalance.length}');

    return plansWithBalance;
  }

  // Optional: Add a method to get count of filtered plans
  Future<Map<String, int>> getPlansCounts() async {
    if (_box == null) {
      _box = await Hive.openBox<PlanItem>('plans');
    }

    List<PlanItem> allPlans = _box!.values.toList();
    int totalPlans = allPlans.length;
    int plansWithBalance = allPlans.where((plan) => (plan.noOfBalance ?? 0) > 0).length;
    int plansWithZeroBalance = totalPlans - plansWithBalance;

    return {
      'total': totalPlans,
      'withBalance': plansWithBalance,
      'zeroBalance': plansWithZeroBalance,
    };
  }

  // Optional: Add a method to clean existing data (remove zero-balance plans)
  Future<void> cleanZeroBalancePlans() async {
    if (_box == null) {
      _box = await Hive.openBox<PlanItem>('plans');
    }

    List<PlanItem> allPlans = _box!.values.toList();
    List<PlanItem> plansWithBalance = allPlans.where((plan) =>
    (plan.noOfBalance ?? 0) > 0
    ).toList();

    if (allPlans.length != plansWithBalance.length) {
      // print('Cleaning ${allPlans.length - plansWithBalance.length} zero-balance plans');

      await _box!.clear();

      // Re-save only plans with balance
      for (int i = 0; i < plansWithBalance.length; i++) {
        var plan = plansWithBalance[i];
        String key = '${plan.planCode}_$i';
        await _box!.put(key, plan);
      }

      // print('Cleanup complete. Box now contains ${_box!.length} items');
    } else {
      print('No zero-balance plans found. No cleanup needed.');
    }
  }
}