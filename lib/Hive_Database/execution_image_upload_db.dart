import 'package:hive/hive.dart';

part 'execution_image_upload_db.g.dart'; // For generating Hive adapter

@HiveType(typeId: 3)
class ImageUploaddata {
  @HiveField(0)
  String? ServerPlanId; // Village Name

  @HiveField(1)
  String? PlanCode; // Brand

  @HiveField(2)
  String? PrintNo; // Size (e.g., width x height)

  @HiveField(3)
  String? VillageCode; // Print number

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

  @HiveField(30)  // NEW FIELD
  DateTime? createdAt;

  @HiveField(31)  // NEW FIELD - printId from server response
  String? printId;

  @HiveField(32)  // NEW FIELD - Network status flag
  String? networkFlagString;

  @HiveField(33)
  String? uploadType;

  @HiveField(34) // Use the next available number
  String? locateId;

  ImageUploaddata({
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
    this.uploadType,
    this.networkFlagString,
    this.locateId// NEW PARAMETER
  });
  // Convert an ImageUploaddata object to JSON
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
      'createdAt': createdAt!.toIso8601String(),
      'printId': printId,
      'uploadType':uploadType,
      'networkFlag': networkFlagString,
      'locateId': locateId,  // NEW FIELD IN JSON
    };
  }

  // Convert JSON to an ImageUploaddata object
  factory ImageUploaddata.fromJson(Map<String, dynamic> json) {
    return ImageUploaddata(
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
      uploadType:json['uploadType'],
      networkFlagString: json['networkFlagString'],  // NEW FIELD FROM JSON
      locateId: json['locateId'],  // NEW FIELD FROM JSON
    );
  }
}
