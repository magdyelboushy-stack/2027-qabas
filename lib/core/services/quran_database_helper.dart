import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import '../../features/quran/data/models/ayah_bounds.dart';

class QuranDatabaseHelper {
  static Database? _db;
  static const String _dbName = "quran.db";

  static Future<Database> get db async {
    if (kIsWeb) throw UnsupportedError('Database not supported on web');
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    final exists = await databaseExists(path);

    if (!exists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
        ByteData data = await rootBundle.load("assets/databases/$_dbName");
        List<int> bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes, flush: true);
      } catch (e) {
        print("Error copying db: $e");
      }
    }
    return await openDatabase(path, readOnly: true);
  }

  // ✅ الاستعلام الصحيح لربط الجداول
  static Future<List<AyahBounds>> getPageBounds(int pageNumber) async {
    if (kIsWeb) return []; // Web not supported for database

    final database = await db;

    final List<Map<String, dynamic>> result = await database.rawQuery('''
      SELECT 
        ga.sura_number, 
        ga.ayah_number, 
        b.min_x, b.max_x, b.min_y, b.max_y
      FROM glyph g
      JOIN glyph_ayah ga ON g.glyph_id = ga.glyph_id
      JOIN glyph_ayah_bbox b ON ga.glyph_ayah_id = b.glyph_ayah_id
      WHERE g.page_number = ?
    ''', [pageNumber]);

    return result.map((map) => AyahBounds.fromMap(map)).toList();
  }
}
