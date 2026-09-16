import 'package:hive/hive.dart';

import '../Hive_Database/execution_image_upload_db.dart';

class ExecutionImageUploadHiveRepository {
  Box<ImageUploaddata>? _metadataBox;

  Future<void> _openBox() async {
    if (_metadataBox == null || !_metadataBox!.isOpen) {
      _metadataBox = await Hive.openBox<ImageUploaddata>('ImageUploadMetadata');
    }
  }

  // Create a unique key combining ServerPlanId and PrintNo
  String _createUniqueKey(ImageUploaddata metadata) {
    return "${metadata.ServerPlanId}_${metadata.PrintNo}";
  }

  Future<void> saveMetadata(ImageUploaddata metadata) async {
    if (_metadataBox == null) {
      _metadataBox = await Hive.openBox<ImageUploaddata>('ImageUploadMetadata');
    }

    // Create unique key using ServerPlanId + PrintNo
    String uniqueKey = _createUniqueKey(metadata);

    // Check if metadata already exists for this specific combination
    var existingMetadata = _metadataBox!.get(uniqueKey);

    if (existingMetadata != null) {
      // If metadata exists, update the existing entry
      existingMetadata.CleanImage = metadata.CleanImage;
      existingMetadata.WBImage = metadata.WBImage;
      existingMetadata.SprayImage = metadata.SprayImage;
      existingMetadata.NearImage = metadata.NearImage;
      existingMetadata.FarImage = metadata.FarImage;
      existingMetadata.NewImage6 = metadata.NewImage6;
      existingMetadata.NewImage7 = metadata.NewImage7;
      existingMetadata.CleanLatitude = metadata.CleanLatitude;
      existingMetadata.CleanLongitude = metadata.CleanLongitude;
      existingMetadata.WBLatitude = metadata.WBLatitude;
      existingMetadata.WBLongitude = metadata.WBLongitude;
      existingMetadata.SprayLatitude = metadata.SprayLatitude;
      existingMetadata.SprayLongitude = metadata.SprayLongitude;
      existingMetadata.NearLatitude = metadata.NearLatitude;
      existingMetadata.NearLongitude = metadata.NearLongitude;
      existingMetadata.FarLatitude = metadata.FarLatitude;
      existingMetadata.FarLongitude = metadata.FarLongitude;
      existingMetadata.New6Latitude = metadata.New6Latitude;
      existingMetadata.New6Longitude = metadata.New6Longitude;
      existingMetadata.New7Latitude = metadata.New7Latitude;
      existingMetadata.New7Longitude = metadata.New7Longitude;
      existingMetadata.ServerPlanId = metadata.ServerPlanId;
      existingMetadata.PlanCode = metadata.PlanCode;
      existingMetadata.PrintNo = metadata.PrintNo;
      existingMetadata.VillageCode = metadata.VillageCode;
      existingMetadata.Address = metadata.Address;
      existingMetadata.ExecutionDate = metadata.ExecutionDate;
      existingMetadata.UploadDate = metadata.UploadDate;

      // Save the updated metadata back to Hive with the unique key
      await _metadataBox!.put(uniqueKey, existingMetadata);
    } else {
      // If metadata does not exist, save as a new entry with unique key
      await _metadataBox!.put(uniqueKey, metadata);
    }
  }

  // Load metadata for all entries
  Future<List<ImageUploaddata>> loadMetadata() async {
    if (_metadataBox == null) {
      _metadataBox = await Hive.openBox<ImageUploaddata>('ImageUploadMetadata');
    }

    return _metadataBox!.values.toList();
  }

  Future<List<ImageUploaddata>> getAllMetadata() async {
    await _openBox();
    return _metadataBox!.values.toList();
  }

  // Updated delete method to use the unique key
  // Future<void> deleteMetadata(String serverPlanId, String printNo) async {
  //   if (_metadataBox == null) {
  //     _metadataBox = await Hive.openBox<ImageUploaddata>('ImageUploadMetadata');
  //   }
  //
  //   String uniqueKey = "${serverPlanId}_${printNo}";
  //   await _metadataBox!.delete(uniqueKey);
  // }

  // Updated method to get metadata by both ServerPlanId and PrintNo
  Future<void> deleteMetadata(String serverPlanId, String printNo) async {
    await _openBox();

    String uniqueKey =
        "${serverPlanId.trim()}_${printNo.trim().toUpperCase()}";

    print(" DELETE KEY => $uniqueKey");
    print(" ALL KEYS => ${_metadataBox!.keys.toList()}");

    await _metadataBox!.delete(uniqueKey);
  }

  Future<ImageUploaddata?> loadMetadataByPlanAndPrint(String serverPlanId, String printNo) async {
    if (_metadataBox == null) {
      _metadataBox = await Hive.openBox<ImageUploaddata>('ImageUploadMetadata');
    }

    String uniqueKey = "${serverPlanId}_${printNo}";
    return _metadataBox!.get(uniqueKey);
  }

  // Keep the old method for backward compatibility but update the logic
  Future<ImageUploaddata?> loadMetadataByPrintNumber(String printNumber) async {
    if (_metadataBox == null) {
      _metadataBox = await Hive.openBox<ImageUploaddata>('ImageUploadMetadata');
    }

    // Search through all values to find by print number
    // This is less efficient but maintains compatibility
    for (var metadata in _metadataBox!.values) {
      if (metadata.PrintNo == printNumber) {
        return metadata;
      }
    }
    return null;
  }

  // Helper method to get all metadata for a specific plan
  Future<List<ImageUploaddata>> getMetadataByPlan(String serverPlanId) async {
    await _openBox();

    return _metadataBox!.values
        .where((metadata) => metadata.ServerPlanId == serverPlanId)
        .toList();
  }

  // Helper method to get all metadata for a specific village and plan
  Future<List<ImageUploaddata>> getMetadataByVillageAndPlan(String villageCode, String planCode) async {
    await _openBox();

    return _metadataBox!.values
        .where((metadata) =>
    metadata.VillageCode == villageCode &&
        metadata.PlanCode == planCode)
        .toList();
  }

  // Increments and persists the retry count for a pending item, matched by
  // its own ServerPlanId/PrintNo fields (not the Hive key, whose format has
  // been inconsistent across call sites). Returns the new count, or null if
  // the item is no longer in the pending queue.
  Future<int?> incrementRetryCount(String serverPlanId, String printNo) async {
    await _openBox();

    for (final entry in _metadataBox!.toMap().entries) {
      final item = entry.value;
      if (item.ServerPlanId == serverPlanId && item.PrintNo == printNo) {
        item.retryCount = item.retryCount + 1;
        await _metadataBox!.put(entry.key, item);
        return item.retryCount;
      }
    }

    return null;
  }
}