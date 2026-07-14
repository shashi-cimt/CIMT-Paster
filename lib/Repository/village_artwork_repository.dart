import 'package:hive/hive.dart';

import '../Hive_Database/village_artwork_db.dart';

class VillageArtworkHiveRepository {
  Box<VillageArtwork>? _villageArtworkBox;

  Future<void> saveVillageArtwork(List<VillageArtwork> artworks) async {
    if (artworks.isEmpty) {
      return;
    }

    if (_villageArtworkBox == null) {
      _villageArtworkBox = await Hive.openBox<VillageArtwork>('villageArtwork');
    }

    // DON'T clear the box - we want to accumulate artworks
    // await _villageArtworkBox!.clear();  // Remove this line


    for (var artwork in artworks) {
      // Use artworkId as the key to avoid duplicates
      String key = '${artwork.artworkId}';
      await _villageArtworkBox!.put(key, artwork);
      }


  }

// Also add a method to clear artworks when you want to start fresh:
  Future<void> clearAllVillageArtworks() async {
    if (_villageArtworkBox == null) {
      _villageArtworkBox = await Hive.openBox<VillageArtwork>('villageArtwork');
    }

    await _villageArtworkBox!.clear();

  }

  // Method to load the artwork details from Hive
  Future<List<VillageArtwork>> loadVillageArtwork() async {
    if (_villageArtworkBox == null) {
      _villageArtworkBox = await Hive.openBox<VillageArtwork>('villageArtwork');
    }
    return _villageArtworkBox!.values.toList();
  }
}