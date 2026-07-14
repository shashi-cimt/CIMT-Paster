import 'package:hive/hive.dart';

part 'plan_offline_count_db.g.dart';

@HiveType(typeId: 7)
class PlanOfflineCount {
  @HiveField(0)
  final String groupKey; // planCode_villageCode_villageName_tehsil

  @HiveField(1)
  int submittedCount; // How many have been submitted offline

  PlanOfflineCount({
    required this.groupKey,
    required this.submittedCount,
  });
}