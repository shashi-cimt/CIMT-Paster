// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_recca_image_upload_db.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SUImageUploaddataAdapter extends TypeAdapter<SUImageUploaddata> {
  @override
  final int typeId = 5;

  @override
  SUImageUploaddata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SUImageUploaddata(
      printId: fields[0] as String,
      planCode: fields[1] as String,
      nearImagePath: fields[2] as String?,
      nearLatitude: fields[3] as String,
      nearLongitude: fields[4] as String,
      farImagePath: fields[5] as String?,
      farLatitude: fields[6] as String,
      farLongitude: fields[7] as String,
      villageCode: fields[8] as String,
      remark: fields[9] as String,
      executionDate: fields[10] as String,
      uploadDate: fields[11] as String,
      villageName: fields[12] as String,
      tensil: fields[13] as String,
      printNo: fields[14] as String,
      createdAt: fields[15] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SUImageUploaddata obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.printId)
      ..writeByte(1)
      ..write(obj.planCode)
      ..writeByte(2)
      ..write(obj.nearImagePath)
      ..writeByte(3)
      ..write(obj.nearLatitude)
      ..writeByte(4)
      ..write(obj.nearLongitude)
      ..writeByte(5)
      ..write(obj.farImagePath)
      ..writeByte(6)
      ..write(obj.farLatitude)
      ..writeByte(7)
      ..write(obj.farLongitude)
      ..writeByte(8)
      ..write(obj.villageCode)
      ..writeByte(9)
      ..write(obj.remark)
      ..writeByte(10)
      ..write(obj.executionDate)
      ..writeByte(11)
      ..write(obj.uploadDate)
      ..writeByte(12)
      ..write(obj.villageName)
      ..writeByte(13)
      ..write(obj.tensil)
      ..writeByte(14)
      ..write(obj.printNo)
      ..writeByte(15)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SUImageUploaddataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
