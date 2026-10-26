import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// خدمة الوصول لقواعد بيانات مشروع سورة — Offline بالكامل
class SurahDatabaseService {
  SurahDatabaseService._();
  static final SurahDatabaseService instance = SurahDatabaseService._();

  // Cache for opened databases
  final Map<String, Database> _dbCache = {};
  bool _initialized = false;
  Future<void>? _initFuture;

  // Database file names
  static const String _quranDb = 'quran.sqlite';
  static const String _wordMeaningDb = 'word-meaning-word.sqlite';
  static const String _wordEerabDb = 'word-eerab-word.sqlite';
  static const String _wordTasreefDb = 'word-word-tasreef.sqlite';
  static const String _ayaTafsirSaadiDb = 'aya-tafsir-saadi.sqlite';
  static const String _ayaTafsirMoyassarDb = 'aya-w-moyassar.sqlite';
  static const String _ayaTafsirKatheerDb = 'aya-tafsir-katheer.sqlite';
  static const String _ayaTafsirTabaryDb = 'aya-tafsir-tabary.sqlite';
  static const String _ayaTafsirBaghawyDb = 'aya-tafsir-baghawy.sqlite';
  static const String _ayaTafsirMokhtasarDb = 'aya-tafsir-mokhtasar.sqlite';
  static const String _ayaEerabDb = 'aya-eerab-aya.sqlite';
  static const String _ayaEerabWordDb = 'aya-eerab-word-aya.sqlite';
  static const String _ayaNozoolDb = 'aya-ayat-nozool.sqlite';
  static const String _ayaTajweedDb = 'aya-tajweed-aya.sqlite';
  static const String _englishDb = 'english_saheeh.sqlite';

  /// All database names for initialization
  static const List<String> _allDbs = [
    _quranDb, _wordMeaningDb, _wordEerabDb, _wordTasreefDb,
    _ayaTafsirSaadiDb, _ayaTafsirMoyassarDb, _ayaTafsirKatheerDb,
    _ayaTafsirTabaryDb, _ayaTafsirBaghawyDb, _ayaTafsirMokhtasarDb,
    _ayaEerabDb, _ayaEerabWordDb, _ayaNozoolDb, _ayaTajweedDb, _englishDb,
  ];

  /// Initialize — copy databases from assets to app directory
  Future<void> initialize() async {
    if (_initialized) return;
    if (_initFuture != null) return _initFuture;

    _initFuture = _doInitialize();
    await _initFuture;
  }

  Future<void> _doInitialize() async {
    try {
      final dbDir = await _getDbDirectory();

      // Keep startup light: the core Quran database is needed for ID lookups.
      // Larger tafsir/grammar databases are copied only when first requested.
      await _copyDatabaseIfNeeded(_quranDb, dbDir);
      _initialized = true;
      debugPrint('✅ SurahDatabaseService initialized — core database ready');
    } finally {
      // Allow a later retry if initialization fails.
      _initFuture = null;
    }
  }

  Future<String> _getDbDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dbDir = Directory(p.join(appDir.path, 'surah_dbs'));
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }
    return dbDir.path;
  }

  Future<void> _copyDatabaseIfNeeded(String dbName, String dbDir) async {
    final dbPath = p.join(dbDir, dbName);
    if (!File(dbPath).existsSync()) {
      try {
        final data = await rootBundle.load('assets/dbs/$dbName');
        final bytes = data.buffer.asUint8List();
        await File(dbPath).writeAsBytes(bytes, flush: true);
        debugPrint('📦 Copied database: $dbName (${(bytes.length / 1024 / 1024).toStringAsFixed(1)} MB)');
      } catch (e) {
        debugPrint('⚠️ Could not copy database $dbName: $e');
      }
    }
  }

  Future<Database> _openDb(String dbName) async {
    if (_dbCache.containsKey(dbName)) return _dbCache[dbName]!;
    
    if (!_initialized) await initialize();
    
    final dbDir = await _getDbDirectory();
    final dbPath = p.join(dbDir, dbName);

    // Optional databases are copied on demand, not all during app startup.
    await _copyDatabaseIfNeeded(dbName, dbDir);

    if (!File(dbPath).existsSync()) {
      throw Exception('Database not found: $dbPath');
    }
    
    final db = await openDatabase(dbPath, readOnly: true);
    _dbCache[dbName] = db;
    return db;
  }

  /// Extract text content from a database row's content field
  /// Content can be TEXT or BLOB — handle both cases
  String? _extractContent(Map<String, dynamic> row) {
    final content = row['content'];
    if (content == null) return null;
    if (content is String) return content;
    if (content is Uint8List) {
      try {
        return utf8.decode(content);
      } catch (_) {
        return String.fromCharCodes(content);
      }
    }
    if (content is List<int>) {
      try {
        return utf8.decode(content);
      } catch (_) {
        return String.fromCharCodes(content);
      }
    }
    return content.toString();
  }

  // ══════════════════════════════════════════════
  //  كلمة — Word Level Data
  // ══════════════════════════════════════════════

  /// معنى الكلمة — returns the content text for the word
  Future<String?> getWordMeaning(int suraId, int ayaId, int wordId) async {
    return _getWordContent(_wordMeaningDb, suraId, ayaId, wordId);
  }

  /// إعراب الكلمة
  Future<String?> getWordEerab(int suraId, int ayaId, int wordId) async {
    return _getWordContent(_wordEerabDb, suraId, ayaId, wordId);
  }

  /// تصريف الكلمة
  Future<String?> getWordTasreef(int suraId, int ayaId, int wordId) async {
    return _getWordContent(_wordTasreefDb, suraId, ayaId, wordId);
  }

  /// Helper: Get word content from a database
  Future<String?> _getWordContent(String dbName, int suraId, int ayaId, int wordId) async {
    try {
      final absoluteAyaId = await _getAbsoluteAyaId(suraId, ayaId);
      final absoluteWordId = await _getAbsoluteWordId(suraId, ayaId, wordId);
      if (absoluteAyaId == null || absoluteWordId == null) return null;

      final db = await _openDb(dbName);
      final results = await db.query(
        'project_contents',
        where: 'sura_id = ? AND aya_id = ? AND word_id = ?',
        whereArgs: [suraId, absoluteAyaId, absoluteWordId],
        limit: 1,
      );
      if (results.isNotEmpty) {
        return _extractContent(results.first);
      }
    } catch (e) {
      debugPrint('❌ Error reading $dbName for word ($suraId:$ayaId:$wordId): $e');
    }
    return null;
  }

  /// الحصول على كلمات آية معينة مع معانيها
  Future<List<Map<String, dynamic>>> getAyaWordsWithMeanings(int suraId, int ayaId) async {
    try {
      final absoluteAyaId = await _getAbsoluteAyaId(suraId, ayaId);
      if (absoluteAyaId == null) return [];

      final db = await _openDb(_wordMeaningDb);
      final results = await db.query(
        'project_contents',
        where: 'sura_id = ? AND aya_id = ?',
        whereArgs: [suraId, absoluteAyaId],
        orderBy: 'word_id ASC',
      );
      return results.map((row) => {
        'word_id': row['word_id'],
        'title': row['title']?.toString() ?? '',
        'meaning': _extractContent(row) ?? '',
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting aya words: $e');
    }
    return [];
  }

  /// Helper to convert absolute aya ID to relative index
  Future<int?> _getRelativeAyaIndex(int absoluteAyaId) async {
    try {
      final db = await _openDb(_quranDb);
      final res = await db.query('ayas', columns: ['[index]'], where: 'id = ?', whereArgs: [absoluteAyaId], limit: 1);
      if (res.isNotEmpty) return res.first['index'] as int?;
    } catch (_) {}
    return null;
  }

  /// البحث عن كلمة في القرآن — أين وردت
  Future<List<Map<String, dynamic>>> searchWordInQuran(String word) async {
    try {
      final db = await _openDb(_wordMeaningDb);
      final normalized = _normalizeArabic(word);
      final results = await db.query(
        'project_contents',
        columns: ['sura_id', 'aya_id', 'word_id', 'title'],
        where: 'title_normalized LIKE ?',
        whereArgs: ['%$normalized%'],
        limit: 50,
      );
      
      final mappedResults = <Map<String, dynamic>>[];
      for (final row in results) {
        final absoluteAyaId = row['aya_id'] as int?;
        final relativeAyaIndex = absoluteAyaId != null ? await _getRelativeAyaIndex(absoluteAyaId) : null;
        mappedResults.add({
          'sura_id': row['sura_id'],
          'aya_index': relativeAyaIndex ?? absoluteAyaId,
          'word_id': row['word_id'],
          'word': row['title'],
        });
      }
      return mappedResults;
    } catch (e) {
      debugPrint('❌ Error searching word: $e');
    }
    return [];
  }

  // ══════════════════════════════════════════════
  //  آية — Ayah Level Data
  // ══════════════════════════════════════════════

  /// التفسير الميسر
  Future<String?> getTafsirMoyassar(int suraId, int ayaId) async {
    return _getAyaContent(_ayaTafsirMoyassarDb, suraId, ayaId);
  }

  /// تفسير السعدي
  Future<String?> getTafsirSaadi(int suraId, int ayaId) async {
    return _getAyaContent(_ayaTafsirSaadiDb, suraId, ayaId);
  }

  /// تفسير ابن كثير
  Future<String?> getTafsirKatheer(int suraId, int ayaId) async {
    return _getAyaContent(_ayaTafsirKatheerDb, suraId, ayaId);
  }

  /// تفسير الطبري
  Future<String?> getTafsirTabary(int suraId, int ayaId) async {
    return _getAyaContent(_ayaTafsirTabaryDb, suraId, ayaId);
  }

  /// تفسير البغوي
  Future<String?> getTafsirBaghawy(int suraId, int ayaId) async {
    return _getAyaContent(_ayaTafsirBaghawyDb, suraId, ayaId);
  }

  /// التفسير المختصر
  Future<String?> getTafsirMokhtasar(int suraId, int ayaId) async {
    return _getAyaContent(_ayaTafsirMokhtasarDb, suraId, ayaId);
  }

  /// تفسير بحسب الاسم
  Future<String?> getTafsirByName(String name, int suraId, int ayaId) async {
    switch (name) {
      case 'الميسر': return getTafsirMoyassar(suraId, ayaId);
      case 'السعدي': return getTafsirSaadi(suraId, ayaId);
      case 'ابن كثير': return getTafsirKatheer(suraId, ayaId);
      case 'الطبري': return getTafsirTabary(suraId, ayaId);
      case 'البغوي': return getTafsirBaghawy(suraId, ayaId);
      case 'المختصر': return getTafsirMokhtasar(suraId, ayaId);
      default: return getTafsirMoyassar(suraId, ayaId);
    }
  }

  /// إعراب الآية
  Future<String?> getAyaEerab(int suraId, int ayaId) async {
    return _getAyaContent(_ayaEerabDb, suraId, ayaId);
  }

  /// إعراب كلمات الآية
  Future<String?> getAyaWordEerab(int suraId, int ayaId) async {
    return _getAyaContent(_ayaEerabWordDb, suraId, ayaId);
  }

  /// أسباب النزول
  Future<String?> getAyaNozool(int suraId, int ayaId) async {
    return _getAyaContent(_ayaNozoolDb, suraId, ayaId);
  }

  /// أحكام التجويد
  Future<String?> getAyaTajweed(int suraId, int ayaId) async {
    return _getAyaContent(_ayaTajweedDb, suraId, ayaId);
  }

  /// الترجمة الإنجليزية
  Future<String?> getEnglishTranslation(int suraId, int ayaId) async {
    try {
      final db = await _openDb(_englishDb);
      final results = await db.query(
        'translations',
        columns: ['translation'],
        where: 'sura = ? AND aya = ?',
        whereArgs: [suraId, ayaId],
        limit: 1,
      );
      if (results.isNotEmpty) {
        return results.first['translation'] as String?;
      }
    } catch (e) {
      debugPrint('❌ Error getting English translation: $e');
    }
    return null;
  }

  /// Helper to convert relative aya number to absolute ID (1 to 6236)
  Future<int?> _getAbsoluteAyaId(int suraId, int ayaId) async {
    try {
      final db = await _openDb(_quranDb);
      final res = await db.query('ayas', columns: ['id'], where: 'sura_id = ? AND [index] = ?', whereArgs: [suraId, ayaId], limit: 1);
      if (res.isNotEmpty) return res.first['id'] as int?;
    } catch (_) {}
    return null;
  }

  /// Helper to convert relative word number to absolute ID
  Future<int?> _getAbsoluteWordId(int suraId, int ayaId, int wordIndex) async {
    try {
      final db = await _openDb(_quranDb);
      final res = await db.query('quran_words', columns: ['id'], where: 'sura_id = ? AND aya_index = ? AND [index] = ?', whereArgs: [suraId, ayaId, wordIndex], limit: 1);
      if (res.isNotEmpty) return res.first['id'] as int?;
    } catch (_) {}
    return null;
  }

  /// Helper: Get ayah content from a database
  Future<String?> _getAyaContent(String dbName, int suraId, int ayaId) async {
    try {
      final absoluteAyaId = await _getAbsoluteAyaId(suraId, ayaId);
      if (absoluteAyaId == null) return null;

      final db = await _openDb(dbName);
      final results = await db.query(
        'project_contents',
        where: 'sura_id = ? AND aya_id = ?',
        whereArgs: [suraId, absoluteAyaId],
        limit: 1,
      );
      if (results.isNotEmpty) {
        return _extractContent(results.first);
      }
    } catch (e) {
      debugPrint('❌ Error reading $dbName for aya ($suraId:$ayaId): $e');
    }
    return null;
  }

  /// Arabic text normalization
  static String _normalizeArabic(String text) {
    return text
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ٱ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
        .trim();
  }

  /// Close all databases
  Future<void> dispose() async {
    for (final db in _dbCache.values) {
      await db.close();
    }
    _dbCache.clear();
    _initialized = false;
  }
}
