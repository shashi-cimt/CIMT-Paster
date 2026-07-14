import 'package:hive/hive.dart';

part 'Rework_image_upload_db.g.dart';

@HiveType(typeId: 14)
class ReworkImageUploadData {
  @HiveField(0)
  String? ServerPlanId;

  @HiveField(1)
  String? PlanCode;

  @HiveField(2)
  String? PrintNo;

  @HiveField(3)
  String? VillageCode;

  @HiveField(4)
  String? Address;

  @HiveField(5)
  String? ExecutionDate;

  @HiveField(6)
  String? UploadDate;

  @HiveField(7)
  String? CleanImage;

  @HiveField(8)
  String? CleanLatitude;

  @HiveField(9)
  String? CleanLongitude;

  @HiveField(10)
  String? WBImage;

  @HiveField(11)
  String? WBLatitude;

  @HiveField(12)
  String? WBLongitude;

  @HiveField(13)
  String? SprayImage;

  @HiveField(14)
  String? SprayLatitude;

  @HiveField(15)
  String? SprayLongitude;

  @HiveField(16)
  String? NearImage;

  @HiveField(17)
  String? NearLatitude;

  @HiveField(18)
  String? NearLongitude;

  @HiveField(19)
  String? FarImage;

  @HiveField(20)
  String? FarLatitude;

  @HiveField(21)
  String? FarLongitude;

  @HiveField(22)
  String? NewImage6;

  @HiveField(23)
  String? New6Latitude;

  @HiveField(24)
  String? New6Longitude;

  @HiveField(25)
  String? NewImage7;

  @HiveField(26)
  String? New7Latitude;

  @HiveField(27)
  String? New7Longitude;

  @HiveField(28)
  String? VillageName;

  @HiveField(29)
  String? Tensil;

  @HiveField(30)
  DateTime? createdAt;

  @HiveField(31)
  String? printId;

  @HiveField(32)
  String? networkFlagString;

  ReworkImageUploadData({
    required this.ServerPlanId,
    required this.PlanCode,
    required this.PrintNo,
    required this.VillageCode,
    required this.Address,
    required this.ExecutionDate,
    required this.UploadDate,
    required this.CleanImage,
    required this.CleanLatitude,
    required this.CleanLongitude,
    required this.WBImage,
    required this.WBLatitude,
    required this.WBLongitude,
    required this.SprayImage,
    required this.SprayLatitude,
    required this.SprayLongitude,
    required this.NearImage,
    required this.NearLatitude,
    required this.NearLongitude,
    required this.FarImage,
    required this.FarLatitude,
    required this.FarLongitude,
    required this.NewImage6,
    required this.New6Latitude,
    required this.New6Longitude,
    required this.NewImage7,
    required this.New7Latitude,
    required this.New7Longitude,
    required this.VillageName,
    required this.Tensil,
    required this.createdAt,
    this.printId,
    this.networkFlagString,
  });

  Map<String, dynamic> toJson() {
    return {
      'ServerPlanId': ServerPlanId,
      'PlanCode': PlanCode,
      'PrintNo': PrintNo,
      'VillageCode': VillageCode,
      'Address': Address,
      'ExecutionDate': ExecutionDate,
      'UploadDate': UploadDate,
      'CleanImage': CleanImage,
      'CleanLatitude': CleanLatitude,
      'CleanLongitude': CleanLongitude,
      'WBImage': WBImage,
      'WBLatitude': WBLatitude,
      'WBLongitude': WBLongitude,
      'SprayImage': SprayImage,
      'SprayLatitude': SprayLatitude,
      'SprayLongitude': SprayLongitude,
      'NearImage': NearImage,
      'NearLatitude': NearLatitude,
      'NearLongitude': NearLongitude,
      'FarImage': FarImage,
      'FarLatitude': FarLatitude,
      'FarLongitude': FarLongitude,
      'NewImage6': NewImage6,
      'New6Latitude': New6Latitude,
      'New6Longitude': New6Longitude,
      'NewImage7': NewImage7,
      'New7Latitude': New7Latitude,
      'New7Longitude': New7Longitude,
      'VillageName': VillageName,
      'Tensil': Tensil,
      'createdAt': createdAt?.toIso8601String(),
      'printId': printId,
      'networkFlag': networkFlagString,
    };
  }

  factory ReworkImageUploadData.fromJson(Map<String, dynamic> json) {
    return ReworkImageUploadData(
      ServerPlanId: json['ServerPlanId'],
      PlanCode: json['PlanCode'],
      PrintNo: json['PrintNo'],
      VillageCode: json['VillageCode'],
      Address: json['Address'],
      ExecutionDate: json['ExecutionDate'],
      UploadDate: json['UploadDate'],
      CleanImage: json['CleanImage'],
      CleanLatitude: json['CleanLatitude'],
      CleanLongitude: json['CleanLongitude'],
      WBImage: json['WBImage'],
      WBLatitude: json['WBLatitude'],
      WBLongitude: json['WBLongitude'],
      SprayImage: json['SprayImage'],
      SprayLatitude: json['SprayLatitude'],
      SprayLongitude: json['SprayLongitude'],
      NearImage: json['NearImage'],
      NearLatitude: json['NearLatitude'],
      NearLongitude: json['NearLongitude'],
      FarImage: json['FarImage'],
      FarLatitude: json['FarLatitude'],
      FarLongitude: json['FarLongitude'],
      NewImage6: json['NewImage6'],
      New6Latitude: json['New6Latitude'],
      New6Longitude: json['New6Longitude'],
      NewImage7: json['NewImage7'],
      New7Latitude: json['New7Latitude'],
      New7Longitude: json['New7Longitude'],
      VillageName: json['VillageName'],
      Tensil: json['Tensil'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      printId: json['printId'],
      networkFlagString: json['networkFlag'],
    );
  }
}