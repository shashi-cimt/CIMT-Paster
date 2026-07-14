// completed_upload_db.dart
import 'package:hive/hive.dart';

part 'completed_upload_db.g.dart';

@HiveType(typeId: 10) // Use unique typeId
class CompletedUpload {
  @HiveField(0)
  String printId;

  @HiveField(1)
  DateTime uploadedAt;

  @HiveField(2)
  String planCode;

  @HiveField(3)
  String villageCode;

  CompletedUpload({
    required this.printId,
    required this.uploadedAt,
    required this.planCode,
    required this.villageCode,
  });

  factory CompletedUpload.fromJson(Map<String, dynamic> map) {
    return CompletedUpload(
      printId: map['printId'] as String? ?? "",
      uploadedAt: map['uploadedAt'] ?? "",
      planCode: map['planCode'] as String? ?? "",
      villageCode: map['villageCode'] as String? ?? "",

    );
  }
}