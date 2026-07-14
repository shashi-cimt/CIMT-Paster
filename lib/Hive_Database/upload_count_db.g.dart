// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_count_db.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UploadCountDataAdapter extends TypeAdapter<UploadCountData> {
  @override
  final int typeId = 11;

  @override
  UploadCountData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UploadCountData(
      uploadDate: fields[0] as String,
      count: fields[1] as int,
      timestamp: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, UploadCountData obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.uploadDate)
      ..writeByte(1)
      ..write(obj.count)
      ..writeByte(2)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UploadCountDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
