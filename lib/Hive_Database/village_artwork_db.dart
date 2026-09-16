import 'package:hive/hive.dart';

part 'village_artwork_db.g.dart';

@HiveType(typeId: 2) // Ensure this typeId is unique
class VillageArtwork {
  @HiveField(0)
  final String? projectId;

  @HiveField(1)
  final int? artworkId;

  @HiveField(2)
  final String? artworkName;

  @HiveField(3)
  final int? height;

  @HiveField(4)
  final int? width;

  @HiveField(5)
  final int? sqft;

  @HiveField(6)
  final String? artworkUrl;

  VillageArtwork({
    required this.projectId,
    required this.artworkId,
    required this.artworkName,
    required this.height,
    required this.width,
    required this.sqft,
    required this.artworkUrl,
  });

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  factory VillageArtwork.fromJson(Map<String, dynamic> json) {
    return VillageArtwork(
      projectId: json['projectId']?.toString(),
      artworkId: _parseInt(json['artworkId']),
      artworkName: json['artworkName']?.toString(),
      height: _parseInt(json['height']),
      width: _parseInt(json['width']),
      sqft: _parseInt(json['sqft']),
      artworkUrl: json['artworkUrl']?.toString(),
    );
  }
}
