import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Available Tafsir editions
enum TafsirEdition {
  ibnKathir('ar.muyassar', 'Ibn Kathir'),
  jalalayn('ar.jalalayn', 'Al-Jalalayn'),
  saadi('ar.saadi', 'As-Saadi'),
  waseet('ar.waseet', 'Al-Waseet');

  final String id;
  final String arabicName;
  const TafsirEdition(this.id, this.arabicName);
}

class TafsirService {
  static final Map<String, String> _cache = {};

  /// Fetches tafsir for a specific ayah from quran.com API
  static Future<String> getTafsir(
    int surah,
    int verse, {
    TafsirEdition edition = TafsirEdition.ibnKathir,
  }) async {
    final cacheKey = '${edition.id}_${surah}_$verse';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    try {
      // Use quran.com API v4
      final url = Uri.parse(
        'https://api.quran.com/api/v4/tafsirs/${edition.id}/by_ayah/$surah:$verse'
      );
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tafsirData = data['tafsir'];
        if (tafsirData != null) {
          String text = tafsirData['text'] ?? '';
          // Strip HTML tags if present
          text = text.replaceAll(RegExp(r'<[^>]*>'), '');
          _cache[cacheKey] = text;
          return text;
        }
      }

      // Fallback: Try alternative API endpoint
      final altUrl = Uri.parse(
        'https://api.quran.com/api/v4/quran/tafsirs/${edition.id}?verse_key=$surah:$verse'
      );
      final altResponse = await http.get(altUrl, headers: {
        'Accept': 'application/json',
      });

      if (altResponse.statusCode == 200) {
        final data = jsonDecode(altResponse.body);
        final tafsirs = data['tafsirs'] as List?;
        if (tafsirs != null && tafsirs.isNotEmpty) {
          String text = tafsirs[0]['text'] ?? '';
          text = text.replaceAll(RegExp(r'<[^>]*>'), '');
          _cache[cacheKey] = text;
          return text;
        }
      }

      return 'No tafsir available for this ayah at the moment';
    } catch (e) {
      debugPrint('Tafsir fetch error: $e');
      return 'Error loading tafsir. Please check your internet connection.';
    }
  }

  /// Clears the cache
  static void clearCache() => _cache.clear();
}
