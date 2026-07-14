// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Map_pointer_locate_db.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CapturedLocateAdapter extends TypeAdapter<CapturedLocate> {
  @override
  final int typeId = 13;

  @override
  CapturedLocate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CapturedLocate(
      locateId: fields[0] as String,
      planServerId: fields[1] as String,
      capturedAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CapturedLocate obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.locateId)
      ..writeByte(1)
      ..write(obj.planServerId)
      ..writeByte(2)
      ..write(obj.capturedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CapturedLocateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
