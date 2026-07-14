// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resend_db.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ApiResponseDataAdapter extends TypeAdapter<ApiResponseData> {
  @override
  final int typeId = 9;

  @override
  ApiResponseData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ApiResponseData(
      planId: fields[0] as String,
      originalData: fields[1] as ImageUploaddata,
      isSuccess: fields[2] as bool,
      responseMessage: fields[3] as String,
      responseTime: fields[4] as DateTime,
      statusCode: fields[5] as int,
      retryCount: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ApiResponseData obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.planId)
      ..writeByte(1)
      ..write(obj.originalData)
      ..writeByte(2)
      ..write(obj.isSuccess)
      ..writeByte(3)
      ..write(obj.responseMessage)
      ..writeByte(4)
      ..write(obj.responseTime)
      ..writeByte(5)
      ..write(obj.statusCode)
      ..writeByte(6)
      ..write(obj.retryCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiResponseDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
