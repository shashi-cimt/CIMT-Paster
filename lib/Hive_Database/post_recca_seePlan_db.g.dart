// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_recca_seePlan_db.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SUPlanModelAdapter extends TypeAdapter<SUPlanModel> {
  @override
  final int typeId = 4;

  @override
  SUPlanModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SUPlanModel(
      planServerId: fields[0] as int,
      planCode: fields[1] as String,
      villageCode: fields[2] as String,
      villageName: fields[3] as String,
      tehsil: fields[4] as String,
      stateName: fields[5] as String,
      districtName: fields[6] as String,
      projectName: fields[7] as String,
      projectId: fields[8] as String,
      noOfPrints: fields[9] as int,
      noOfBalance: fields[10] as int,
      range: fields[11] as String,
      remarks: fields[12] as String,
      artworkId: fields[13] as int,
      artworkName: fields[14] as String,
      height: fields[15] as String,
      width: fields[16] as String,
      sqft: fields[17] as String,
      artworkUrl: fields[18] as String,
      printId: fields[19] as int,
      printNo: fields[20] as String,
      address: fields[21] as String,
      latitude: fields[22] as String,
      longitude: fields[23] as String,
      surroundingView: fields[24] as String,
      frontView: fields[25] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SUPlanModel obj) {
    writer
      ..writeByte(26)
      ..writeByte(0)
      ..write(obj.planServerId)
      ..writeByte(1)
      ..write(obj.planCode)
      ..writeByte(2)
      ..write(obj.villageCode)
      ..writeByte(3)
      ..write(obj.villageName)
      ..writeByte(4)
      ..write(obj.tehsil)
      ..writeByte(5)
      ..write(obj.stateName)
      ..writeByte(6)
      ..write(obj.districtName)
      ..writeByte(7)
      ..write(obj.projectName)
      ..writeByte(8)
      ..write(obj.projectId)
      ..writeByte(9)
      ..write(obj.noOfPrints)
      ..writeByte(10)
      ..write(obj.noOfBalance)
      ..writeByte(11)
      ..write(obj.range)
      ..writeByte(12)
      ..write(obj.remarks)
      ..writeByte(13)
      ..write(obj.artworkId)
      ..writeByte(14)
      ..write(obj.artworkName)
      ..writeByte(15)
      ..write(obj.height)
      ..writeByte(16)
      ..write(obj.width)
      ..writeByte(17)
      ..write(obj.sqft)
      ..writeByte(18)
      ..write(obj.artworkUrl)
      ..writeByte(19)
      ..write(obj.printId)
      ..writeByte(20)
      ..write(obj.printNo)
      ..writeByte(21)
      ..write(obj.address)
      ..writeByte(22)
      ..write(obj.latitude)
      ..writeByte(23)
      ..write(obj.longitude)
      ..writeByte(24)
      ..write(obj.surroundingView)
      ..writeByte(25)
      ..write(obj.frontView);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SUPlanModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
