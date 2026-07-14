// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'completed_upload_db.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CompletedUploadAdapter extends TypeAdapter<CompletedUpload> {
  @override
  final int typeId = 10;

  @override
  CompletedUpload read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CompletedUpload(
      printId: fields[0] as String,
      uploadedAt: fields[1] as DateTime,
      planCode: fields[2] as String,
      villageCode: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CompletedUpload obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.printId)
      ..writeByte(1)
      ..write(obj.uploadedAt)
      ..writeByte(2)
      ..write(obj.planCode)
      ..writeByte(3)
      ..write(obj.villageCode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompletedUploadAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
