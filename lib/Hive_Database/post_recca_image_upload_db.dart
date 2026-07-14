import 'dart:io';

import 'package:hive/hive.dart';

part 'post_recca_image_upload_db.g.dart'; // For generating Hive adapter

@HiveType(typeId: 5)
class SUImageUploaddata {
  @HiveField(0)
  String printId;

  @HiveField(1)
  String planCode;

  @HiveField(2)
  String? nearImagePath; // Store file path as String

  @HiveField(3)
  String nearLatitude;

  @HiveField(4)
  String nearLongitude;

  @HiveField(5)
  String? farImagePath; // Store file path as String

  @HiveField(6)
  String farLatitude;

  @HiveField(7)
  String farLongitude;

  @HiveField(8)
  String villageCode;

  @HiveField(9)
  String remark;

  @HiveField(10)
  String executionDate;

  @HiveField(11)
  String uploadDate;

  @HiveField(12)
  String villageName;

  @HiveField(13)
  String tensil;

  @HiveField(14)
  String printNo;

  @HiveField(15)  // NEW FIELD
  DateTime? createdAt;

  SUImageUploaddata({
    required this.printId,
    required this.planCode,
    this.nearImagePath,
    required this.nearLatitude,
    required this.nearLongitude,
    this.farImagePath,
    required this.farLatitude,
    required this.farLongitude,
    required this.villageCode,
    required this.remark,
    required this.executionDate,
    required this.uploadDate,
    required this.villageName,
    required this.tensil,
    required this.printNo,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      "printId": printId,
      "planCode": planCode,
      "nearImagePath": nearImagePath,
      "nearLatitude": nearLatitude,
      "nearLongitude": nearLongitude,
      "farImagePath": farImagePath,
      "farLatitude": farLatitude,
      "farLongitude": farLongitude,
      "villageCode": villageCode,
      "remark": remark,
      "executionDate": executionDate,
      "uploadDate": uploadDate,
      "villageName": villageName,
      "tensil": tensil,
      "printNo": printNo,
      "createdAt": createdAt!.toIso8601String(),
    };
  }
  factory SUImageUploaddata.fromJson(Map<String, dynamic> json) {
    return SUImageUploaddata(
      printId: json['printId'],
      planCode: json['planCode'],
      nearImagePath: json['nearImagePath'],
      nearLatitude: json['nearLatitude'],
      nearLongitude: json['nearLongitude'],
      farImagePath: json['farImagePath'],
      farLatitude: json['farLatitude'],
      farLongitude: json['farLongitude'],
      villageCode: json['villageCode'],
      remark: json['remark'],
      executionDate: json['executionDate'],
      uploadDate: json['uploadDate'],
      villageName: json['villageName'],
      tensil: json['tensil'],
      printNo: json['printNo'],
      createdAt: json['createdAt']
    );
  }
}

