import 'package:hive/hive.dart';

import '../Hive_Database/post_recca_image_draft_db.dart';

class PostReccaImageDraftHiveRepository {
  static const String boxName = 'PostReccaImageDrafts';

  Box<PostReccaImageDraft>? _box;

  Future<Box<PostReccaImageDraft>> _openBox() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<PostReccaImageDraft>(boxName);
    }
    return _box!;
  }

  Future<void> saveDraft(PostReccaImageDraft draft) async {
    final box = await _openBox();
    draft.lastUpdated = DateTime.now();
    await box.put(draft.draftKey, draft);
  }

  Future<PostReccaImageDraft?> getDraft(String draftKey) async {
    final box = await _openBox();
    return box.get(draftKey);
  }

  Future<void> deleteDraft(String draftKey) async {
    final box = await _openBox();
    await box.delete(draftKey);
  }

  Future<List<PostReccaImageDraft>> getAllDrafts() async {
    final box = await _openBox();
    return box.values.toList();
  }
}
