import 'package:shared_preferences/shared_preferences.dart';
/// post recce
class CompletedUploadRepository {
  static const String _key = 'su_completed_uploads';

  Future<void> markAsCompleted(String printId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> completed = prefs.getStringList(_key) ?? [];

    if (!completed.contains(printId)) {
      completed.add(printId);
      await prefs.setStringList(_key, completed);
      // print('Marked as completed: $printId');
    }
  }

  Future<List<String>> getCompletedPrintIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    // print('Cleared all completed uploads');
  }

  Future<bool> isCompleted(String printId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> completed = prefs.getStringList(_key) ?? [];
    return completed.contains(printId);
  }
}