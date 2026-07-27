// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_recca_image_draft_db.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PostReccaImageDraftAdapter extends TypeAdapter<PostReccaImageDraft> {
  @override
  final int typeId = 17;

  @override
  PostReccaImageDraft read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PostReccaImageDraft(
      draftKey: fields[0] as String,
      printId: fields[1] as String?,
      planCode: fields[2] as String?,
      villageCode: fields[3] as String?,
      nearImagePath: fields[4] as String?,
      nearLatitude: fields[5] as double?,
      nearLongitude: fields[6] as double?,
      farImagePath: fields[7] as String?,
      farLatitude: fields[8] as double?,
      farLongitude: fields[9] as double?,
      lastUpdated: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PostReccaImageDraft obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.draftKey)
      ..writeByte(1)
      ..write(obj.printId)
      ..writeByte(2)
      ..write(obj.planCode)
      ..writeByte(3)
      ..write(obj.villageCode)
      ..writeByte(4)
      ..write(obj.nearImagePath)
      ..writeByte(5)
      ..write(obj.nearLatitude)
      ..writeByte(6)
      ..write(obj.nearLongitude)
      ..writeByte(7)
      ..write(obj.farImagePath)
      ..writeByte(8)
      ..write(obj.farLatitude)
      ..writeByte(9)
      ..write(obj.farLongitude)
      ..writeByte(10)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostReccaImageDraftAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
