import 'package:hive/hive.dart';

part 'upload_count_db.g.dart';

@HiveType(typeId: 11) // Use a unique typeId
class UploadCountData extends HiveObject {
  @HiveField(0)
  String uploadDate; // Format: yyyy-MM-dd

  @HiveField(1)
  int count;

  @HiveField(2)
  DateTime timestamp;

  UploadCountData({
    required this.uploadDate,
    required this.count,
    required this.timestamp,
  });
}