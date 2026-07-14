import 'package:hive/hive.dart';

import 'execution_seeplan_location_db.dart';

part 'execution_seeplan_db.g.dart';

@HiveType(typeId: 0)
class PlanItem {
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
  final String latitude;

  @HiveField(8)
  final String longitude;

  @HiveField(9)
  final String projectName;

  @HiveField(10)
  final String projectId;

  @HiveField(11)
  final int noOfPrints;

  @HiveField(12)
  final int noOfBalance;

  @HiveField(13)
  final String range;

  @HiveField(14)
  final int artworkId;

  @HiveField(15)
  final String artworkName;

  @HiveField(16)
  final String height;

  @HiveField(17)
  final String width;

  @HiveField(18)
  final String sqft;

  @HiveField(19)
  final String artworkUrl;

  @HiveField(20)
  final List<LocationItem> locations;

  PlanItem({
    required this.planServerId,
    required this.planCode,
    required this.villageCode,
    required this.villageName,
    required this.tehsil,
    required this.stateName,
    required this.districtName,
    required this.latitude,
    required this.longitude,
    required this.projectName,
    required this.projectId,
    required this.noOfPrints,
    required this.noOfBalance,
    required this.range,
    required this.artworkId,
    required this.artworkName,
    required this.height,
    required this.width,
    required this.sqft,
    required this.artworkUrl,
    required this.locations,
  });
  factory PlanItem.fromJson(Map<String, dynamic> map) {
    return PlanItem(
      planServerId: map['planServerId'] as int? ?? 0,
      planCode: map['planCode'] as String? ?? "",
      villageCode: map['villageCode'] as String? ?? "",
      villageName: map['villageName'] as String? ?? "",
      tehsil: map['tehsil'] as String? ?? "",
      stateName: map['stateName'] as String? ?? "",
      districtName: map['districtName'] as String? ?? "",
      latitude: map['latitude'] as String? ?? "",
      longitude: map['longitude'] as String? ?? "",
      projectName: map['projectName'] as String? ?? "",
      projectId: map['projectId'] as String? ?? "",
      noOfPrints: map['noOfPrints'] as int? ?? 0,
      noOfBalance: map['noOfBalance'] as int? ?? 0,
      range: map['range'] as String? ?? "",
      artworkId: map['artworkId'] as int? ?? 0,
      artworkName: map['artworkName'] as String? ?? "",
      height: map['height'] as String? ?? "",
      width: map['width'] as String? ?? "",
      sqft: map['sqft'] as String? ?? "",
      artworkUrl: map['artworkUrl'] as String? ?? "",
      locations: (map['locations'] as List<dynamic>?)
          ?.map((e) => LocationItem.fromJson(e))
          .toList() ??
          [],
    );
  }
}
