import 'package:hive/hive.dart';

part 'execution_seeplan_location_db.g.dart';

@HiveType(typeId: 10) // Use an unused typeId
class LocationItem {

  @HiveField(0)
  final String locateId;

  @HiveField(1)
  final String latitude;

  @HiveField(2)
  final String longitude;

  @HiveField(3)
  final int id;

  @HiveField(4)
  final bool isActive;

  LocationItem({
    required this.locateId,
    required this.latitude,
    required this.longitude,
    required this.id,
    required this.isActive,
  });

  factory LocationItem.fromJson(Map<String, dynamic> json) {
    return LocationItem(
      locateId: json["locate_id"]?.toString() ?? "",
      latitude: json["latitude"]?.toString() ?? "",
      longitude: json["longitude"]?.toString() ?? "",
      id: json["Id"] ?? 0,
      isActive: json["IsActive"] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "locate_id": locateId,
      "latitude": latitude,
      "longitude": longitude,
      "Id": id,
      "IsActive": isActive,
    };
  }
}