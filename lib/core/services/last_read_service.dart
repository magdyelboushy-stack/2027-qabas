import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // Added for ValueNotifier

class LastReadService {
  static const String _keySurah = 'last_read_surah';
  static const String _keyAyah = 'last_read_ayah';

  static final ValueNotifier<Map<String, String>?> lastReadNotifier = ValueNotifier(null);

  /// Save the last read position (Surah name and Ayah number).
  static Future<void> saveLastRead(String surahName, String ayahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySurah, surahName);
    await prefs.setString(_keyAyah, ayahNumber);
    
    // Notify listeners
    lastReadNotifier.value = {'surah': surahName, 'ayah': ayahNumber};
  }

  /// Retrieve the last read position.
  /// Returns a Map with 'surah' and 'ayah' keys, or null if no data is saved.
  static Future<Map<String, String>?> getLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    final surah = prefs.getString(_keySurah);
    final ayah = prefs.getString(_keyAyah);

    if (surah != null && ayah != null) {
      // Ensure notifier is in sync on first load
      final data = {'surah': surah, 'ayah': ayah};
      if (lastReadNotifier.value == null) {
         lastReadNotifier.value = data;
      }
      return data;
    }
    return null; // No saved data
  }
}