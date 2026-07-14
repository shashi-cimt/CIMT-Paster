import 'package:hive/hive.dart';

import '../Hive_Database/remarks_db.dart';

class RemarksHiveRepository {
  Box<Remarks>? _remarksBox;

  Future<void> saveRemakrs(List<Remarks> remarksData) async {
    if (remarksData.isEmpty) {
      // print('The artwork list is empty. No data to save.');
      return;
    }

    if (_remarksBox == null) {
      _remarksBox = await Hive.openBox<Remarks>('remarksList');
    }

    await _remarksBox!.clear();  // Clear previous data
    // print('Remarks Box cleared.');

    for (int i = 0; i < remarksData.length; i++) {
      var remarksIndex = remarksData[i];
      String key = '${remarksIndex.remarks}_$i';  // Using `villageCode` and index as key
      await _remarksBox!.put(key, remarksIndex);
    }

    // print('Saved ${remarksData.length} artworks to the box.');
  }

  // Method to load the artwork details from Hive
  Future<List<Remarks>> loadRemarks() async {
    if (_remarksBox == null) {
      _remarksBox = await Hive.openBox<Remarks>('remarksList');
    }
    return _remarksBox!.values.toList();
  }
}