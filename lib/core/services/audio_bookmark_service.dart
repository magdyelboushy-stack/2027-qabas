import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AudioBookmarkService {
  static const String _bookmarkPrefix = 'audio_bookmarks_';
  static const String _lastPositionPrefix = 'audio_last_pos_';

  // --- Bookmarks ---

  static Future<void> addBookmark(String recitationId, String name, int positionMs) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_bookmarkPrefix$recitationId';
    List<String> bookmarks = prefs.getStringList(key) ?? [];
    
    final newBookmark = jsonEncode({
      'name': name,
      'position': positionMs,
      'date': DateTime.now().toIso8601String(),
    });
    
    bookmarks.add(newBookmark);
    await prefs.setStringList(key, bookmarks);
  }

  static Future<List<Map<String, dynamic>>> getBookmarks(String recitationId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_bookmarkPrefix$recitationId';
    List<String> bookmarks = prefs.getStringList(key) ?? [];
    
    return bookmarks.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
  }
  
  static Future<void> removeBookmark(String recitationId, int index) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_bookmarkPrefix$recitationId';
    List<String> bookmarks = prefs.getStringList(key) ?? [];
    
    if (index >= 0 && index < bookmarks.length) {
      bookmarks.removeAt(index);
      await prefs.setStringList(key, bookmarks);
    }
  }

  // --- Resume Position ---

  static Future<void> saveLastPosition(String recitationId, int positionMs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_lastPositionPrefix$recitationId', positionMs);
  }

  static Future<int?> getLastPosition(String recitationId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_lastPositionPrefix$recitationId');
  }
}
