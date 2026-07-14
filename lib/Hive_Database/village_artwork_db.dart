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

  factory VillageArtwork.fromJson(Map<String, dynamic> json) {
    return VillageArtwork(
      projectId: json['projectId']?.toString(),
      artworkId: json['artworkId'] as int?,
      artworkName: json['artworkName']?.toString(),
      height: json['height'] as int?,
      width: json['width'] as int?,
      sqft: json['sqft'] as int?,
      artworkUrl: json['artworkUrl']?.toString(),
    );
  }
}
