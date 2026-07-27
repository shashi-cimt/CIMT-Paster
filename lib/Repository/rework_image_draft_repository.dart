import 'package:hive/hive.dart';

import '../Hive_Database/rework_image_draft_db.dart';

class ReworkImageDraftHiveRepository {
  static const String boxName = 'ReworkImageDrafts';

  Box<ReworkImageDraft>? _box;

  Future<Box<ReworkImageDraft>> _openBox() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<ReworkImageDraft>(boxName);
    }
    return _box!;
  }

  Future<void> saveDraft(ReworkImageDraft draft) async {
    final box = await _openBox();
    draft.lastUpdated = DateTime.now();
    await box.put(draft.draftKey, draft);
  }

  Future<ReworkImageDraft?> getDraft(String draftKey) async {
    final box = await _openBox();
    return box.get(draftKey);
  }

  Future<void> deleteDraft(String draftKey) async {
    final box = await _openBox();
    await box.delete(draftKey);
  }

  Future<List<ReworkImageDraft>> getAllDrafts() async {
    final box = await _openBox();
    return box.values.toList();
  }
}
