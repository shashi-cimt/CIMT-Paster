import 'package:hive/hive.dart';

part 'rework_image_draft_db.g.dart';

// Persists in-progress (not-yet-submitted) rework image captures so that
// closing the rework upload screen before hitting Submit does not lose
// already captured images. One record per rework print item.
@HiveType(typeId: 16)
class ReworkImageDraft {
  @HiveField(0)
  String draftKey;

  @HiveField(1)
  String? ServerPlanId;

  @HiveField(2)
  String? PlanCode;

  @HiveField(3)
  String? VillageCode;

  @HiveField(4)
  String? printId;

  @HiveField(5)
  String? printNumber1;

  @HiveField(6)
  String? printNumber2;

  @HiveField(7)
  String? CleanImage;
  @HiveField(8)
  double? CleanLatitude;
  @HiveField(9)
  double? CleanLongitude;

  @HiveField(10)
  String? WBImage;
  @HiveField(11)
  double? WBLatitude;
  @HiveField(12)
  double? WBLongitude;

  @HiveField(13)
  String? SprayImage;
  @HiveField(14)
  double? SprayLatitude;
  @HiveField(15)
  double? SprayLongitude;

  @HiveField(16)
  String? NearImage;
  @HiveField(17)
  double? NearLatitude;
  @HiveField(18)
  double? NearLongitude;

  @HiveField(19)
  String? FarImage;
  @HiveField(20)
  double? FarLatitude;
  @HiveField(21)
  double? FarLongitude;

  @HiveField(22)
  String? NewImage6;
  @HiveField(23)
  double? New6Latitude;
  @HiveField(24)
  double? New6Longitude;

  @HiveField(25)
  String? NewImage7;
  @HiveField(26)
  double? New7Latitude;
  @HiveField(27)
  double? New7Longitude;

  @HiveField(28)
  DateTime? lastUpdated;

  ReworkImageDraft({
    required this.draftKey,
    this.ServerPlanId,
    this.PlanCode,
    this.VillageCode,
    this.printId,
    this.printNumber1,
    this.printNumber2,
    this.CleanImage,
    this.CleanLatitude,
    this.CleanLongitude,
    this.WBImage,
    this.WBLatitude,
    this.WBLongitude,
    this.SprayImage,
    this.SprayLatitude,
    this.SprayLongitude,
    this.NearImage,
    this.NearLatitude,
    this.NearLongitude,
    this.FarImage,
    this.FarLatitude,
    this.FarLongitude,
    this.NewImage6,
    this.New6Latitude,
    this.New6Longitude,
    this.NewImage7,
    this.New7Latitude,
    this.New7Longitude,
    this.lastUpdated,
  });

  // Index order matches the 7 capture slots used on the rework upload
  // screen: 0=Clean 1=WB 2=Spray 3=Near 4=Far 5=New6 6=New7
  List<String?> get imagePathsBySlot =>
      [CleanImage, WBImage, SprayImage, NearImage, FarImage, NewImage6, NewImage7];

  List<double?> get latitudesBySlot => [
        CleanLatitude,
        WBLatitude,
        SprayLatitude,
        NearLatitude,
        FarLatitude,
        New6Latitude,
        New7Latitude,
      ];

  List<double?> get longitudesBySlot => [
        CleanLongitude,
        WBLongitude,
        SprayLongitude,
        NearLongitude,
        FarLongitude,
        New6Longitude,
        New7Longitude,
      ];

  void setSlot(int index, String? path, double? lat, double? long) {
    switch (index) {
      case 0:
        CleanImage = path;
        CleanLatitude = lat;
        CleanLongitude = long;
        break;
      case 1:
        WBImage = path;
        WBLatitude = lat;
        WBLongitude = long;
        break;
      case 2:
        SprayImage = path;
        SprayLatitude = lat;
        SprayLongitude = long;
        break;
      case 3:
        NearImage = path;
        NearLatitude = lat;
        NearLongitude = long;
        break;
      case 4:
        FarImage = path;
        FarLatitude = lat;
        FarLongitude = long;
        break;
      case 5:
        NewImage6 = path;
        New6Latitude = lat;
        New6Longitude = long;
        break;
      case 6:
        NewImage7 = path;
        New7Latitude = lat;
        New7Longitude = long;
        break;
    }
  }

  bool get hasAnyImage => imagePathsBySlot.any((path) => path != null);
}
