// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Rework_image_upload_db.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReworkImageUploadDataAdapter extends TypeAdapter<ReworkImageUploadData> {
  @override
  final int typeId = 14;

  @override
  ReworkImageUploadData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReworkImageUploadData(
      ServerPlanId: fields[0] as String?,
      PlanCode: fields[1] as String?,
      PrintNo: fields[2] as String?,
      VillageCode: fields[3] as String?,
      Address: fields[4] as String?,
      ExecutionDate: fields[5] as String?,
      UploadDate: fields[6] as String?,
      CleanImage: fields[7] as String?,
      CleanLatitude: fields[8] as String?,
      CleanLongitude: fields[9] as String?,
      WBImage: fields[10] as String?,
      WBLatitude: fields[11] as String?,
      WBLongitude: fields[12] as String?,
      SprayImage: fields[13] as String?,
      SprayLatitude: fields[14] as String?,
      SprayLongitude: fields[15] as String?,
      NearImage: fields[16] as String?,
      NearLatitude: fields[17] as String?,
      NearLongitude: fields[18] as String?,
      FarImage: fields[19] as String?,
      FarLatitude: fields[20] as String?,
      FarLongitude: fields[21] as String?,
      NewImage6: fields[22] as String?,
      New6Latitude: fields[23] as String?,
      New6Longitude: fields[24] as String?,
      NewImage7: fields[25] as String?,
      New7Latitude: fields[26] as String?,
      New7Longitude: fields[27] as String?,
      VillageName: fields[28] as String?,
      Tensil: fields[29] as String?,
      createdAt: fields[30] as DateTime?,
      printId: fields[31] as String?,
      networkFlagString: fields[32] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ReworkImageUploadData obj) {
    writer
      ..writeByte(33)
      ..writeByte(0)
      ..write(obj.ServerPlanId)
      ..writeByte(1)
      ..write(obj.PlanCode)
      ..writeByte(2)
      ..write(obj.PrintNo)
      ..writeByte(3)
      ..write(obj.VillageCode)
      ..writeByte(4)
      ..write(obj.Address)
      ..writeByte(5)
      ..write(obj.ExecutionDate)
      ..writeByte(6)
      ..write(obj.UploadDate)
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
      ..write(obj.VillageName)
      ..writeByte(29)
      ..write(obj.Tensil)
      ..writeByte(30)
      ..write(obj.createdAt)
      ..writeByte(31)
      ..write(obj.printId)
      ..writeByte(32)
      ..write(obj.networkFlagString);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReworkImageUploadDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
