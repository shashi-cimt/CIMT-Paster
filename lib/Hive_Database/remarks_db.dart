import 'package:hive/hive.dart';

part 'remarks_db.g.dart';

@HiveType(typeId: 8)
class Remarks {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String remarks;

  Remarks({
    required this.id,
    required this.remarks,
  });

  factory Remarks.fromJson(Map<String, dynamic> map) {
    return Remarks(
      id: map['id'] as int? ?? 0,
      remarks: map['remarks'] as String? ?? "",

    );
  }
}
