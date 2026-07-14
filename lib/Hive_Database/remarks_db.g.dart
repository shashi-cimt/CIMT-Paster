// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remarks_db.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RemarksAdapter extends TypeAdapter<Remarks> {
  @override
  final int typeId = 8;

  @override
  Remarks read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Remarks(
      id: fields[0] as int,
      remarks: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Remarks obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.remarks);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RemarksAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
