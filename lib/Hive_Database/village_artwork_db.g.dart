// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'village_artwork_db.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VillageArtworkAdapter extends TypeAdapter<VillageArtwork> {
  @override
  final int typeId = 2;

  @override
  VillageArtwork read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VillageArtwork(
      projectId: fields[0] as String?,
      artworkId: fields[1] as int?,
      artworkName: fields[2] as String?,
      height: fields[3] as int?,
      width: fields[4] as int?,
      sqft: fields[5] as int?,
      artworkUrl: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, VillageArtwork obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.projectId)
      ..writeByte(1)
      ..write(obj.artworkId)
      ..writeByte(2)
      ..write(obj.artworkName)
      ..writeByte(3)
      ..write(obj.height)
      ..writeByte(4)
      ..write(obj.width)
      ..writeByte(5)
      ..write(obj.sqft)
      ..writeByte(6)
      ..write(obj.artworkUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VillageArtworkAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
