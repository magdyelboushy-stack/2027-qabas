import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../config/app_config.dart';

/// خدمة مركزية للتواصل مع Quran.Foundation API
class QuranFoundationApi {
  static const String _baseUrl = 'https://api.quran.com/api/v4';
  static const String _audioBaseUrl = 'https://verses.quran.com/';
  static const String _chapterAudioBaseUrl = 'https://download.quranicaudio.com/';

  // ═══════════════════════════════════════════
  // القراء
  // ═══════════════════════════════════════════

  /// جلب قائمة القراء المتاحين
  static Future<List<Map<String, dynamic>>> getReciters() async {
    List<Map<String, dynamic>> reciters = [];

    // جلب قراء المصحف ديناميكياً من الباك إند (لوحة التحكم) فقط
    try {
      final mihrabUrl = '${AppConfig.apiBaseUrl}/quran_reciters/read.php';
      final mihrabResponse = await http.get(Uri.parse(mihrabUrl));
      if (mihrabResponse.statusCode == 200) {
        final mihrabData = json.decode(mihrabResponse.body);
        final mihrabReciters = mihrabData['data'] as List?;
        if (mihrabReciters != null) {
          for (final r in mihrabReciters) {
            final reciterId = 'mihrab.${r['id']}';
            // نحول بيانات الـ API لنفس الشكل اللي بيستعمله التطبيق
            reciters.add({
              'id': reciterId,
              'reciter_name': r['name'],
              'style': r['style'],
              'audio_base_url': r['audio_base_url'],
            });
            // حفظ الرابط الأساسي في الكاش للاستخدام في getAyahAudioUrl
            if (r['audio_base_url'] != null) {
              _mihrabAudioBaseUrls[reciterId] = r['audio_base_url'];
            }
          }
        }
      }
    } catch (e) {
      print('⚠️ فشل جلب قراء المصحف من السيرفر: $e');
    }

    return reciters;
  }

  // ═══════════════════════════════════════════
  // صوت الآية
  // ═══════════════════════════════════════════

  // كاش لروابط صوت قراء المصحف (من لوحة التحكم)
  static final Map<String, String> _mihrabAudioBaseUrls = {};

  /// جلب رابط صوت آية معينة
  /// [reciterId] معرف القارئ
  /// [surahNumber] رقم السورة
  /// [ayahNumber] رقم الآية
  static Future<String> getAyahAudioUrl(String reciterId, int surahNumber, int ayahNumber) async {
    // قراء المصحف من لوحة تحكم محراب (mihrab.1, mihrab.2, ...)
    if (reciterId.startsWith('mihrab.')) {
      final baseUrl = _mihrabAudioBaseUrls[reciterId]?.trim();
      if (baseUrl != null && baseUrl.isNotEmpty) {
        final s = surahNumber.toString().padLeft(3, '0');
        final a = ayahNumber.toString().padLeft(3, '0');
        // نضمن إن الرابط ينتهي بـ /
        final cleanBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
        return '$cleanBase$s$a.mp3';
      }
      throw Exception('رابط صوت القارئ غير موجود');
    }
    // KSU uses ids like ksu.Husary_Mujawwad_64kbps
    if (reciterId.startsWith('ksu.')) {
      final ksuId = reciterId.substring(4);
      final s = surahNumber.toString().padLeft(3, '0');
      final a = ayahNumber.toString().padLeft(3, '0');
      return 'https://quran.ksu.edu.sa/ayat/mp3/$ksuId/$s$a.mp3';
    }
    // AlQuran.cloud uses string identifiers like ar.mahermuaiqly
    if (int.tryParse(reciterId) == null) {
      final absoluteAyah = _getAbsoluteAyahNumber(surahNumber, ayahNumber);
      return 'https://cdn.islamic.network/quran/audio/128/$reciterId/$absoluteAyah.mp3';
    }
    final verseKey = '$surahNumber:$ayahNumber';
    final response = await http.get(
      Uri.parse('$_baseUrl/recitations/$reciterId/by_ayah/$verseKey'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final audioFiles = data['audio_files'] as List;
      if (audioFiles.isNotEmpty) {
        final url = audioFiles[0]['url'] as String;
        if (url.startsWith('http')) return url;
        if (url.startsWith('//')) return 'https:$url';
        return '$_audioBaseUrl$url';
      }
    }
    throw Exception('فشل جلب صوت الآية');
  }

  // ═══════════════════════════════════════════
  // صوت السورة كاملة (مع timestamps)
  // ═══════════════════════════════════════════

  /// جلب صوت السورة كاملة مع timestamps لكل آية وكلمة
  static Future<Map<String, dynamic>> getChapterAudio(String reciterId, int chapterNumber, {bool segments = false}) async {
    final url = '$_baseUrl/chapter_recitations/$reciterId/$chapterNumber${segments ? '?segments=true' : ''}';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Map<String, dynamic>.from(data['audio_file']);
    }
    throw Exception('فشل جلب صوت السورة');
  }

  static int _getAbsoluteAyahNumber(int surahNumber, int ayahNumber) {
    const List<int> surahAyahCounts = [
      7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128,
      111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73,
      54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60,
      49, 62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12, 12, 30, 52, 52,
      44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42, 29, 19, 36, 25, 22, 17, 19,
      26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3,
      6, 3, 5, 4, 5, 6
    ];
    int count = 0;
    for (int i = 0; i < surahNumber - 1; i++) {
      count += surahAyahCounts[i];
    }
    return count + ayahNumber;
  }

  // ═══════════════════════════════════════════
  // الكلمات (Word-by-Word)
  // ═══════════════════════════════════════════

  /// جلب كلمات آية مع الصوت والمعنى
  static Future<Map<String, dynamic>> getVerseWords(int surahNumber, int ayahNumber) async {
    final verseKey = '$surahNumber:$ayahNumber';
    final response = await http.get(
      Uri.parse('$_baseUrl/verses/by_key/$verseKey?language=ar&words=true&word_fields=text_uthmani,text_indopak&fields=text_uthmani'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Map<String, dynamic>.from(data['verse']);
    }
    throw Exception('فشل جلب كلمات الآية');
  }

  /// بناء رابط صوت الكلمة
  static String getWordAudioUrl(String relativeUrl) {
    if (relativeUrl.startsWith('http')) return relativeUrl;
    return '$_audioBaseUrl$relativeUrl';
  }

  // ═══════════════════════════════════════════
  // التفسير
  // ═══════════════════════════════════════════

  /// جلب قائمة التفاسير المتاحة
  static Future<List<Map<String, dynamic>>> getTafsirs() async {
    final response = await http.get(Uri.parse('$_baseUrl/resources/tafsirs'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['tafsirs']);
    }
    throw Exception('فشل جلب قائمة التفاسير');
  }

  /// جلب تفسير آية معينة
  /// [tafsirId] معرف التفسير (مثلاً 16 للميسر)
  static Future<Map<String, dynamic>> getTafsirForAyah(int tafsirId, int surahNumber, int ayahNumber) async {
    final verseKey = '$surahNumber:$ayahNumber';
    final response = await http.get(
      Uri.parse('$_baseUrl/tafsirs/$tafsirId/by_ayah/$verseKey'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Map<String, dynamic>.from(data['tafsir'] ?? data);
    }
    throw Exception('فشل جلب التفسير');
  }

  // ═══════════════════════════════════════════
  // النص القرآني
  // ═══════════════════════════════════════════

  /// جلب آيات سورة بالرسم العثماني
  static Future<List<Map<String, dynamic>>> getVersesByChapter(int chapterNumber) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/quran/verses/uthmani?chapter_number=$chapterNumber'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['verses']);
    }
    throw Exception('فشل جلب الآيات');
  }

  /// جلب معلومات السورة
  static Future<Map<String, dynamic>> getChapterInfo(int chapterNumber) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/chapters/$chapterNumber?language=ar'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Map<String, dynamic>.from(data['chapter']);
    }
    throw Exception('فشل جلب معلومات السورة');
  }

  // ═══════════════════════════════════════════
  // البحث
  // ═══════════════════════════════════════════

  /// البحث في القرآن
  static Future<Map<String, dynamic>> search(String query, {int page = 1, int size = 20}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/search?q=${Uri.encodeComponent(query)}&size=$size&page=$page&language=ar'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('فشل البحث');
  }

  // ═══════════════════════════════════════════
  // الترجمات
  // ═══════════════════════════════════════════

  /// جلب قائمة الترجمات المتاحة
  static Future<List<Map<String, dynamic>>> getTranslations() async {
    final response = await http.get(Uri.parse('$_baseUrl/resources/translations'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['translations']);
    }
    throw Exception('فشل جلب الترجمات');
  }
}
