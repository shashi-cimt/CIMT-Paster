// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'execution_image_draft_db.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExecutionImageDraftAdapter extends TypeAdapter<ExecutionImageDraft> {
  @override
  final int typeId = 15;

  @override
  ExecutionImageDraft read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExecutionImageDraft(
      draftKey: fields[0] as String,
      ServerPlanId: fields[1] as String?,
      PlanCode: fields[2] as String?,
      VillageCode: fields[3] as String?,
      locateId: fields[4] as String?,
      printNumber1: fields[5] as String?,
      printNumber2: fields[6] as String?,
      CleanImage: fields[7] as String?,
      CleanLatitude: fields[8] as double?,
      CleanLongitude: fields[9] as double?,
      WBImage: fields[10] as String?,
      WBLatitude: fields[11] as double?,
      WBLongitude: fields[12] as double?,
      SprayImage: fields[13] as String?,
      SprayLatitude: fields[14] as double?,
      SprayLongitude: fields[15] as double?,
      NearImage: fields[16] as String?,
      NearLatitude: fields[17] as double?,
      NearLongitude: fields[18] as double?,
      FarImage: fields[19] as String?,
      FarLatitude: fields[20] as double?,
      FarLongitude: fields[21] as double?,
      NewImage6: fields[22] as String?,
      New6Latitude: fields[23] as double?,
      New6Longitude: fields[24] as double?,
      NewImage7: fields[25] as String?,
      New7Latitude: fields[26] as double?,
      New7Longitude: fields[27] as double?,
      lastUpdated: fields[28] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ExecutionImageDraft obj) {
    writer
      ..writeByte(29)
      ..writeByte(0)
      ..write(obj.draftKey)
      ..writeByte(1)
      ..write(obj.ServerPlanId)
      ..writeByte(2)
      ..write(obj.PlanCode)
      ..writeByte(3)
      ..write(obj.VillageCode)
      ..writeByte(4)
      ..write(obj.locateId)
      ..writeByte(5)
      ..write(obj.printNumber1)
      ..writeByte(6)
      ..write(obj.printNumber2)
      ..writeByte(7)
      ..write(obj.CleanImage)
      ..writeByte(8)
      ..write(obj.CleanLatitude)
      ..writeByte(9)
      ..write(obj.CleanLongitude)
      ..writeByte(10)
      ..write(obj.WBImage)
      ..writeByte(11)
      ..write(obj.WBLatitude)
      ..writeByte(12)
      ..write(obj.WBLongitude)
      ..writeByte(13)
      ..write(obj.SprayImage)
      ..writeByte(14)
      ..write(obj.SprayLatitude)
      ..writeByte(15)
      ..write(obj.SprayLongitude)
      ..writeByte(16)
      ..write(obj.NearImage)
      ..writeByte(17)
      ..write(obj.NearLatitude)
      ..writeByte(18)
      ..write(obj.NearLongitude)
      ..writeByte(19)
      ..write(obj.FarImage)
      ..writeByte(20)
      ..write(obj.FarLatitude)
      ..writeByte(21)
      ..write(obj.FarLongitude)
      ..writeByte(22)
      ..write(obj.NewImage6)
      ..writeByte(23)
      ..write(obj.New6Latitude)
      ..writeByte(24)
      ..write(obj.New6Longitude)
      ..writeByte(25)
      ..write(obj.NewImage7)
      ..writeByte(26)
      ..write(obj.New7Latitude)
      ..writeByte(27)
      ..write(obj.New7Longitude)
      ..writeByte(28)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExecutionImageDraftAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
