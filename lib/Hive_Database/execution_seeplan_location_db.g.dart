// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'execution_seeplan_location_db.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocationItemAdapter extends TypeAdapter<LocationItem> {
  @override
  final int typeId = 10;

  @override
  LocationItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocationItem(
      locateId: fields[0] as String,
      latitude: fields[1] as String,
      longitude: fields[2] as String,
      id: fields[3] as int,
      isActive: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, LocationItem obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.locateId)
      ..writeByte(1)
      ..write(obj.latitude)
      ..writeByte(2)
      ..write(obj.longitude)
      ..writeByte(3)
      ..write(obj.id)
      ..writeByte(4)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
