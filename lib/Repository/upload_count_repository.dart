import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../Hive_Database/upload_count_db.dart';

class UploadCountRepository {
  Box<UploadCountData>? _uploadCountBox;

  Future<void> _openBox() async {
    if (_uploadCountBox == null || !_uploadCountBox!.isOpen) {
      _uploadCountBox = await Hive.openBox<UploadCountData>('uploadCountBox');
    }
  }

  // Increment upload count when image is successfully uploaded
  Future<void> incrementUploadCount(String uploadDate) async {
    await _openBox();

    String key = uploadDate; // Simplified key

    UploadCountData? existing = _uploadCountBox!.get(key);

    if (existing != null) {
      existing.count += 1;
      existing.timestamp = DateTime.now();
      await existing.save();
    } else {
      await _uploadCountBox!.put(key, UploadCountData(
        uploadDate: uploadDate,
        count: 1,
        timestamp: DateTime.now(),
      ));
    }
  }

  // Get upload count for a specific date range
  Future<int> getUploadCount(String startDate, String endDate) async {
    await _openBox();

    int totalCount = 0;

    try {
      // Parse dates at the start of the day
      DateTime start = DateFormat('yyyy-MM-dd').parse(startDate);
      DateTime end = DateFormat('yyyy-MM-dd').parse(endDate);

      // Normalize to start of day for accurate comparison
      start = DateTime(start.year, start.month, start.day);
      end = DateTime(end.year, end.month, end.day, 23, 59, 59);



      // Iterate through all entries
      for (var entry in _uploadCountBox!.values) {
        try {
          DateTime entryDate = DateFormat('yyyy-MM-dd').parse(entry.uploadDate);
          // Normalize entry date to start of day
          entryDate = DateTime(entryDate.year, entryDate.month, entryDate.day);

          // Check if entry date is within range (inclusive)
          if (!entryDate.isBefore(start) && !entryDate.isAfter(end)) {
            totalCount += entry.count;

          }
        } catch (parseError) {
          print("Error parsing entry date: ${entry.uploadDate} - $parseError");
        }
      }


    } catch (e) {
      print("Error in getUploadCount: $e");
    }

    return totalCount;
  }

  // Get today's upload count
  Future<int> getTodayUploadCount() async {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return await getUploadCount(today, today);
  }

  // Get all upload data (for debugging)
  Future<Map<String, int>> getAllUploadCounts() async {
    await _openBox();

    Map<String, int> allCounts = {};
    for (var entry in _uploadCountBox!.values) {
      allCounts[entry.uploadDate] = entry.count;
    }

    return allCounts;
  }

  // Clear upload counts (use this when reload/sync happens)
  Future<void> clearUploadCounts() async {
    await _openBox();
    await _uploadCountBox!.clear();

  }

  // Clear old upload counts (older than specified days)
  Future<void> clearOldUploadCounts(int daysToKeep) async {
    await _openBox();

    DateTime cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

    List<String> keysToDelete = [];

    for (var entry in _uploadCountBox!.toMap().entries) {
      if (entry.value.timestamp.isBefore(cutoffDate)) {
        keysToDelete.add(entry.key.toString());
      }
    }

    for (var key in keysToDelete) {
      await _uploadCountBox!.delete(key);
    }
  }
}