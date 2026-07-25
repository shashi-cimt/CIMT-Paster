import 'package:hive/hive.dart';

import '../Hive_Database/execution_image_draft_db.dart';

class ExecutionImageDraftHiveRepository {
  static const String boxName = 'ExecutionImageDrafts';

  Box<ExecutionImageDraft>? _box;

  Future<Box<ExecutionImageDraft>> _openBox() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<ExecutionImageDraft>(boxName);
    }
    return _box!;
  }

  Future<void> saveDraft(ExecutionImageDraft draft) async {
    final box = await _openBox();
    draft.lastUpdated = DateTime.now();
    await box.put(draft.draftKey, draft);
  }

  Future<ExecutionImageDraft?> getDraft(String draftKey) async {
    final box = await _openBox();
    return box.get(draftKey);
  }

  Future<void> deleteDraft(String draftKey) async {
    final box = await _openBox();
    await box.delete(draftKey);
  }

  Future<List<ExecutionImageDraft>> getAllDrafts() async {
    final box = await _openBox();
    return box.values.toList();
  }
}
