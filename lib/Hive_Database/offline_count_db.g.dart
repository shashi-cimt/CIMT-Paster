// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_count_db.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OfflineCountAdapter extends TypeAdapter<OfflineCount> {
  @override
  final int typeId = 6;

  @override
  OfflineCount read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineCount(
      groupKey: fields[0] as String,
      submittedCount: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineCount obj) {
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
      other is OfflineCountAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
