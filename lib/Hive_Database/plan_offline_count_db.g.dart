// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_offline_count_db.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlanOfflineCountAdapter extends TypeAdapter<PlanOfflineCount> {
  @override
  final int typeId = 7;

  @override
  PlanOfflineCount read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlanOfflineCount(
      groupKey: fields[0] as String,
      submittedCount: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PlanOfflineCount obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.groupKey)
      ..writeByte(1)
      ..write(obj.submittedCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanOfflineCountAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
