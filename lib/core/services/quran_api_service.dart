import 'dart:convert';
import 'package:flutter/services.dart';

class QuranApiService {
  static List<dynamic>? _cachedQuranData;

  // Load database
  static Future<void> _loadDatabase() async {
    if (_cachedQuranData != null) return;

    try {
      final String response = await rootBundle.loadString('assets/json/databases.json');
      var decodedData = json.decode(response);

      // Handle different structures
      if (decodedData is List) {
        _cachedQuranData = decodedData;
      } else if (decodedData is Map) {
        // محاولة إيجاد القائمة داخل المفاتيح المشهورة
        if (decodedData.containsKey('quran')) {
          _cachedQuranData = decodedData['quran'];
        } else if (decodedData.containsKey('surahs')) _cachedQuranData = decodedData['surahs'];
        else if (decodedData.containsKey('data')) _cachedQuranData = decodedData['data'];
      }
    } catch (e) {
      print("❌ Error loading databases: $e");
      throw Exception("Failed to load Mushaf file");
    }
  }

  // Helper function to extract name (Arabic/English)
  static String _getName(dynamic nameData, String langKey) {
    if (nameData is Map) {
      return nameData[langKey] ?? nameData['ar'] ?? nameData['en'] ?? "";
    }
    return nameData.toString();
  }

  // 1. Get list for index (the error was here and has been fixed)
  static Future<List<dynamic>> getSurahList() async {
    await _loadDatabase();

    return _cachedQuranData!.map((surah) {
      return {
        "number": surah['number'] ?? int.tryParse(surah['index'].toString()) ?? 0,
        "name": _getName(surah['name'], 'ar'),
        "englishName": _getName(surah['name'], 'en'),

        "revelationType": surah['revelation_place'] is Map
            ? (surah['revelation_place']['ar'] ?? 'Meccan')
            : (surah['place'] ?? 'Meccan'),

        // ✅ Fix here: search for verses_count first then count
        "numberOfAyahs": surah['verses_count'] ?? surah['count'] ?? 0,
      };
    }).toList();
  }

  // 2. Get surah details
  static Future<Map<String, dynamic>> getSurah(int surahNumber) async {
    await _loadDatabase();

    try {
      final surahJson = _cachedQuranData!.firstWhere(
            (s) => (s['number'] ?? int.tryParse(s['index'].toString())) == surahNumber,
        orElse: () => throw Exception("Surah not found"),
      );

      List<Map<String, dynamic>> ayahsList = [];

      // Handle verses
      if (surahJson['verses'] is List) {
        List<dynamic> verses = surahJson['verses'];
        ayahsList = verses.map((v) {
          return {
            "numberInSurah": v['number'],
            "text": _getName(v['text'], 'ar'),
          };
        }).toList();
      } else if (surahJson['verse'] is Map) {
        Map<String, dynamic> versesMap = surahJson['verse'];
        // ✅ Fix here also to ensure reading the correct number
        int count = surahJson['verses_count'] ?? surahJson['count'] ?? 0;
        if (count == 0 && surahJson['count'] is String) {
          count = int.tryParse(surahJson['count']) ?? 0;
        }

        for (int i = 1; i <= count; i++) {
          String key = "verse_$i";
          if (versesMap.containsKey(key)) {
            ayahsList.add({
              "numberInSurah": i,
              "text": _getName(versesMap[key], 'ar'),
            });
          }
        }
      }

      return {
        "number": surahJson['number'] ?? int.parse(surahJson['index'].toString()),
        "name": _getName(surahJson['name'], 'ar'),
        "englishName": _getName(surahJson['name'], 'en'),
        "revelationType": surahJson['revelation_place'] is Map
            ? surahJson['revelation_place']['ar']
            : (surahJson['place'] ?? 'Meccan'),
        "numberOfAyahs": ayahsList.length, // Rely on actual list length for accuracy
        "ayahs": ayahsList,
      };

    } catch (e) {
      print("❌ Error parsing surah details: $e");
      return {};
    }
  }

  // Search function (very important it remains)
  static Future<List<dynamic>> searchQuran(String query) async {
    await _loadDatabase();
    if (query.isEmpty) return await getSurahList();

    // ... (باقي كود البحث كما هو في النسخة السابقة، تأكد من وجوده)
    // سأعيد كتابته مختصراً هنا للتأكيد
    String normalizedQuery = _normalize(query);
    List<dynamic> results = [];

    for (var surah in _cachedQuranData!) {
      bool isMatch = false;
      String matchReason = "";
      int? matchedAyahNumber;
      String? matchedAyahText;

      String surahNameAr = _normalize(_getName(surah['name'], 'ar'));

      if (surahNameAr.contains(normalizedQuery)) {
        isMatch = true;
        matchReason = "Surah";
      } else {
        List<dynamic> verses = [];
        if (surah['verses'] is List) {
          verses = surah['verses'];
        } else if (surah['verse'] is Map) verses = (surah['verse'] as Map).values.toList();

        for (int i = 0; i < verses.length; i++) {
          var verse = verses[i];
          String verseText = "";
          if (verse is Map) {
            verseText = _getName(verse['text'], 'ar');
          } else if (verse is String) verseText = verse;

          if (_normalize(verseText).contains(normalizedQuery)) {
            isMatch = true;
            matchReason = "Ayah";
            matchedAyahNumber = i + 1;
            matchedAyahText = verseText;
            break;
          }
        }
      }

      if (isMatch) {
        results.add({
          "number": surah['number'] ?? int.tryParse(surah['index'].toString()) ?? 0,
          "name": _getName(surah['name'], 'ar'),
          "englishName": _getName(surah['name'], 'en'),
          "revelationType": surah['revelation_place'] is Map ? (surah['revelation_place']['ar'] ?? "") : (surah['place'] ?? ""),
          "numberOfAyahs": surah['verses_count'] ?? surah['count'] ?? 0, // ✅ تصحيح هنا أيضاً
          "matchReason": matchReason,
          "matchedAyah": matchedAyahNumber,
          "matchedText": matchedAyahText,
        });
      }
    }
    return results;
  }

  static String _normalize(String text) {
    String normalized = text.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
    normalized = normalized.replaceAll(RegExp(r'[أإآٱ]'), 'ا');
    normalized = normalized.replaceAll('ى', 'ي');
    normalized = normalized.replaceAll('ة', 'ه');
    normalized = normalized.replaceAll('ؤ', 'و');
    normalized = normalized.replaceAll('ئ', 'ي');
    return normalized.toLowerCase().trim();
  }
}