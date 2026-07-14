// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'execution_seeplan_db.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlanItemAdapter extends TypeAdapter<PlanItem> {
  @override
  final int typeId = 0;

  @override
  PlanItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlanItem(
      planServerId: fields[0] as int,
      planCode: fields[1] as String,
      villageCode: fields[2] as String,
      villageName: fields[3] as String,
      tehsil: fields[4] as String,
      stateName: fields[5] as String,
      districtName: fields[6] as String,
      latitude: fields[7] as String,
      longitude: fields[8] as String,
      projectName: fields[9] as String,
      projectId: fields[10] as String,
      noOfPrints: fields[11] as int,
      noOfBalance: fields[12] as int,
      range: fields[13] as String,
      artworkId: fields[14] as int,
      artworkName: fields[15] as String,
      height: fields[16] as String,
      width: fields[17] as String,
      sqft: fields[18] as String,
      artworkUrl: fields[19] as String,
      locations: (fields[20] as List).cast<LocationItem>(),
    );
  }

  @override
  void write(BinaryWriter writer, PlanItem obj) {
    writer
      ..writeByte(21)
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
      ..write(obj.latitude)
      ..writeByte(8)
      ..write(obj.longitude)
      ..writeByte(9)
      ..write(obj.projectName)
      ..writeByte(10)
      ..write(obj.projectId)
      ..writeByte(11)
      ..write(obj.noOfPrints)
      ..writeByte(12)
      ..write(obj.noOfBalance)
      ..writeByte(13)
      ..write(obj.range)
      ..writeByte(14)
      ..write(obj.artworkId)
      ..writeByte(15)
      ..write(obj.artworkName)
      ..writeByte(16)
      ..write(obj.height)
      ..writeByte(17)
      ..write(obj.width)
      ..writeByte(18)
      ..write(obj.sqft)
      ..writeByte(19)
      ..write(obj.artworkUrl)
      ..writeByte(20)
      ..write(obj.locations);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
