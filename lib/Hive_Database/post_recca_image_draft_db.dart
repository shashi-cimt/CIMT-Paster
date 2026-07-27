import 'package:hive/hive.dart';

part 'post_recca_image_draft_db.g.dart';

// Persists in-progress (not-yet-submitted) post-recca (SU) image captures so
// that closing the upload screen before hitting Submit does not lose already
// captured images. One record per print item. This screen only ever
// captures 2 photos (near/far), unlike the 7-slot execution/rework screens,
// so it gets its own small shape instead of carrying 5 unused fields.
@HiveType(typeId: 17)
class PostReccaImageDraft {
  @HiveField(0)
  String draftKey;

  @HiveField(1)
  String? printId;

  @HiveField(2)
  String? planCode;

  @HiveField(3)
  String? villageCode;

  @HiveField(4)
  String? nearImagePath;
  @HiveField(5)
  double? nearLatitude;
  @HiveField(6)
  double? nearLongitude;

  @HiveField(7)
  String? farImagePath;
  @HiveField(8)
  double? farLatitude;
  @HiveField(9)
  double? farLongitude;

  @HiveField(10)
  DateTime? lastUpdated;

  PostReccaImageDraft({
    required this.draftKey,
    this.printId,
    this.planCode,
    this.villageCode,
    this.nearImagePath,
    this.nearLatitude,
    this.nearLongitude,
    this.farImagePath,
    this.farLatitude,
    this.farLongitude,
    this.lastUpdated,
  });

  // Index order matches the 2 capture slots used on this screen: 0=near 1=far
  List<String?> get imagePathsBySlot => [nearImagePath, farImagePath];

  List<double?> get latitudesBySlot => [nearLatitude, farLatitude];

  List<double?> get longitudesBySlot => [nearLongitude, farLongitude];

  void setSlot(int index, String? path, double? lat, double? long) {
    switch (index) {
      case 0:
        nearImagePath = path;
        nearLatitude = lat;
        nearLongitude = long;
        break;
      case 1:
        farImagePath = path;
        farLatitude = lat;
        farLongitude = long;
        break;
    }
  }

  bool get hasAnyImage => imagePathsBySlot.any((path) => path != null);
}
