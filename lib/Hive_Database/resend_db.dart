import 'package:hive/hive.dart';
import 'execution_image_upload_db.dart';

part 'resend_db.g.dart';

@HiveType(typeId: 9)
class ApiResponseData {
  @HiveField(0)
  String planId;

  @HiveField(1)
  ImageUploaddata originalData;

  @HiveField(2)
  bool isSuccess;

  @HiveField(3)
  String responseMessage;

  @HiveField(4)
  DateTime responseTime;

  @HiveField(5)
  int statusCode;

  @HiveField(6)
  int retryCount;

  ApiResponseData({
    required this.planId,
    required this.originalData,
    required this.isSuccess,
    required this.responseMessage,
    required this.responseTime,
    required this.statusCode,
    this.retryCount = 0,
  });
}