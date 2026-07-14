import 'package:hive/hive.dart';

part 'offline_count_db.g.dart';

@HiveType(typeId: 6)
class OfflineCount {
  @HiveField(0)
  final String groupKey; // planCode_villageCode_villageName_tehsil

  @HiveField(1)
  int submittedCount; // How many have been submitted offline

  OfflineCount({
    required this.groupKey,
    required this.submittedCount,
  });
}