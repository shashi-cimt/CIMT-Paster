import 'package:hive/hive.dart';

part 'post_recca_seePlan_db.g.dart';

@HiveType(typeId: 4)
class SUPlanModel {
  @HiveField(0)
  final int planServerId;

  @HiveField(1)
  final String planCode;

  @HiveField(2)
  final String villageCode;

  @HiveField(3)
  final String villageName;

  @HiveField(4)
  final String tehsil;

  @HiveField(5)
  final String stateName;

  @HiveField(6)
  final String districtName;

  @HiveField(7)
  final String projectName;

  @HiveField(8)
  final String projectId;

  @HiveField(9)
  final int noOfPrints;

  @HiveField(10)
  final int noOfBalance;

  @HiveField(11)
  final String range;

  @HiveField(12)
  final String remarks;

  @HiveField(13)
  final int artworkId;

  @HiveField(14)
  final String artworkName;

  @HiveField(15)
  final String height;

  @HiveField(16)
  final String width;

  @HiveField(17)
  final String sqft;

  @HiveField(18)
  final String artworkUrl;

  @HiveField(19)
  final int printId;

  @HiveField(20)
  final String printNo;

  @HiveField(21)
  final String address;

  @HiveField(22)
  final String latitude;

  @HiveField(23)
  final String longitude;

  @HiveField(24)
  final String surroundingView;

  @HiveField(25)
  final String frontView;

  SUPlanModel({
    required this.planServerId,
    required this.planCode,
    required this.villageCode,
    required this.villageName,
    required this.tehsil,
    required this.stateName,
    required this.districtName,
    required this.projectName,
    required this.projectId,
    required this.noOfPrints,
    required this.noOfBalance,
    required this.range,
    required this.remarks,
    required this.artworkId,
    required this.artworkName,
    required this.height,
    required this.width,
    required this.sqft,
    required this.artworkUrl,
    required this.printId,
    required this.printNo,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.surroundingView,
    required this.frontView,
  });

  // Method to map the PlanModel to/from a Map object
  factory SUPlanModel.fromJson(Map<String, dynamic> map) {
    return SUPlanModel(
      planServerId: map['planServerId'],
      planCode: map['planCode'],
      villageCode: map['villageCode'],
      villageName: map['villageName'],
      tehsil: map['tehsil'],
      stateName: map['stateName'],
      districtName: map['districtName'],
      projectName: map['projectName'],
      projectId: map['projectId'],
      noOfPrints: map['noOfPrints'],
      noOfBalance: map['noOfBalance'],
      range: map['range'],
      remarks: map['remarks'],
      artworkId: map['artworkId'],
      artworkName: map['artworkName'],
      height: map['height'],
      width: map['width'],
      sqft: map['sqft'],
      artworkUrl: map['artworkUrl'],
      printId: map['printId'],
      printNo: map['printNo'],
      address: map['address'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      surroundingView: map['surroundingView'],
      frontView: map['frontView'],
    );
  }
}
