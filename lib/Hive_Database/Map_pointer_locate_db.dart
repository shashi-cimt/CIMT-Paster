// Hive_Database/captured_locate_db.dart
import 'package:hive/hive.dart';

part 'Map_pointer_locate_db.g.dart';

@HiveType(typeId: 13) // Make sure this typeId is unique
class CapturedLocate {
@HiveField(0)
String locateId;

@HiveField(1)
String planServerId;

@HiveField(2)
DateTime capturedAt;

CapturedLocate({
required this.locateId,
required this.planServerId,
required this.capturedAt,
});
}