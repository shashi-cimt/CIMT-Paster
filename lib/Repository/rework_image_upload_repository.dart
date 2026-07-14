import 'package:hive/hive.dart';

import '../Hive_Database/post_recca_image_upload_db.dart';

class ReworkImageUploadHiveRepository {
  Box<SUImageUploaddata>? _SUmetadataBox;

  Future<void> _openBox() async {
    if (_SUmetadataBox == null || !_SUmetadataBox!.isOpen) {
      _SUmetadataBox = await Hive.openBox<SUImageUploaddata>('SUImageUploadMetadata');
    }
  }

  // Enhanced method to get uploaded print IDs with better filtering
  Future<List<String>> getUploadedPrintIds() async {
    await _openBox();

    return _SUmetadataBox!.values
        .map((metadata) => metadata.printId.toString())
        .where((id) => id.isNotEmpty && id != 'null')
        .toList();
  }

  // Method to check if specific printId exists in uploaded metadata
  Future<bool> isPrintIdUploaded(String printId) async {
    await _openBox();

    return _SUmetadataBox!.values.any((metadata) =>
    metadata.printId.toString() == printId);
  }

  // Method to get uploaded metadata by specific criteria
  Future<List<SUImageUploaddata>> getUploadedMetadataBy({
    String? planCode,
    String? villageCode,
    String? printId,
  }) async {
    await _openBox();

    return _SUmetadataBox!.values.where((metadata) {
      bool matches = true;

      if (planCode != null) {
        matches = matches && metadata.planCode == planCode;
      }

      if (villageCode != null) {
        matches = matches && metadata.villageCode == villageCode;
      }

      if (printId != null) {
        matches = matches && metadata.printId.toString() == printId;
      }

      return matches;
    }).toList();
  }

  // Method to get statistics about uploaded data
  Future<Map<String, dynamic>> getUploadStatistics() async {
    await _openBox();

    final allMetadata = _SUmetadataBox!.values.toList();

    return {
      'totalUploaded': allMetadata.length,
      'uniquePrintIds': allMetadata.map((m) => m.printId).toSet().length,
      'uniquePlanCodes': allMetadata.map((m) => m.planCode).toSet().length,
      'uniqueVillageCodes': allMetadata.map((m) => m.villageCode).toSet().length,
    };
  }

  Future<void> saveSUImageMetadata(SUImageUploaddata metadata) async {
    if (_SUmetadataBox == null) {
      _SUmetadataBox = await Hive.openBox<SUImageUploaddata>('SUImageUploadMetadata');
    }
    // print("metadata.printNo::::000");
    // print(metadata.printNo);
    // print("metadata.printNo::::");

    // Check if metadata already exists for the printId
    var existingMetadata = _SUmetadataBox!.get(metadata.printId);


    if (existingMetadata != null) {
      // If metadata exists, update the existing entry
      existingMetadata.nearImagePath = metadata.nearImagePath;  // Update file path
      existingMetadata.farImagePath = metadata.farImagePath;  // Update file path
      existingMetadata.nearLatitude = metadata.nearLatitude;
      existingMetadata.nearLongitude = metadata.nearLongitude;
      existingMetadata.farLatitude = metadata.farLatitude;
      existingMetadata.farLongitude = metadata.farLongitude;
      existingMetadata.remark = metadata.remark;
      existingMetadata.executionDate = metadata.executionDate;
      existingMetadata.uploadDate = metadata.uploadDate;
      existingMetadata.printNo = metadata.printNo;

      // Save the updated metadata back to Hive
      await _SUmetadataBox!.put(metadata.printId, existingMetadata);
      // print('Updated metadata for printId: ${metadata.printId}');
    } else {
      // If metadata does not exist, save as a new entry
      await _SUmetadataBox!.put(metadata.printId, metadata);
      // print('Saved new metadata for printId: ${metadata.printId}');
    }
  }

  Future<List<SUImageUploaddata>> loadSUMetadata() async {
    if (_SUmetadataBox == null) {
      _SUmetadataBox = await Hive.openBox<SUImageUploaddata>('SUImageUploadMetadata');
    }

    return _SUmetadataBox!.values.toList();
  }

  Future<List<SUImageUploaddata>> getAllMetadata() async {
    await _openBox();
    return _SUmetadataBox!.values.toList();
  }

  Future<void> deleteMetadataFromHive(String printId) async {
    if (_SUmetadataBox == null) {
      _SUmetadataBox = await Hive.openBox<SUImageUploaddata>('SUImageUploadMetadata');
    }

    await _SUmetadataBox!.delete(printId);
    // print('Deleted metadata for printId: $printId from Hive');
  }
}