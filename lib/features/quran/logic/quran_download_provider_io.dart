import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../data/services/quran_foundation_api.dart';

/// حالة تحميل السورة
class SurahDownloadStatus {
  final int surahNumber;
  final double progress; // 0.0 - 1.0
  final bool isCompleted;
  final bool isDownloading;
  final String? filePath;
  final String? error;

  const SurahDownloadStatus({
    required this.surahNumber,
    this.progress = 0.0,
    this.isCompleted = false,
    this.isDownloading = false,
    this.filePath,
    this.error,
  });

  SurahDownloadStatus copyWith({
    double? progress,
    bool? isCompleted,
    bool? isDownloading,
    String? filePath,
    String? error,
  }) {
    return SurahDownloadStatus(
      surahNumber: surahNumber,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      isDownloading: isDownloading ?? this.isDownloading,
      filePath: filePath ?? this.filePath,
      error: error,
    );
  }
}

/// Provider لتحميل صوتيات المصحف
class QuranDownloadProvider extends ChangeNotifier {
  final Map<int, SurahDownloadStatus> _downloadStatuses = {};
  bool _isDownloadingAll = false;
  int _totalDownloaded = 0;

  Map<int, SurahDownloadStatus> get downloadStatuses => _downloadStatuses;
  bool get isDownloadingAll => _isDownloadingAll;
  int get totalDownloaded => _totalDownloaded;

  /// المسار الأساسي لحفظ الملفات
  Future<String> _getBasePath(String reciterId) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/quran_audio/$reciterId';
    final directory = Directory(path);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return path;
  }

  /// التحقق إذا كانت السورة محملة
  Future<bool> isSurahDownloaded(String reciterId, int surahNumber) async {
    final basePath = await _getBasePath(reciterId);
    final file = File('$basePath/$surahNumber.mp3');
    return file.exists();
  }

  /// جلب مسار الملف المحلي
  Future<String?> getLocalPath(String reciterId, int surahNumber) async {
    final basePath = await _getBasePath(reciterId);
    final file = File('$basePath/$surahNumber.mp3');
    if (await file.exists()) {
      return file.path;
    }
    return null;
  }

  /// تحميل سورة واحدة
  Future<void> downloadSurah(String reciterId, int surahNumber) async {
    _downloadStatuses[surahNumber] = SurahDownloadStatus(
      surahNumber: surahNumber,
      isDownloading: true,
    );
    notifyListeners();

    try {
      // جلب رابط الصوت من الـ API
      final audioData = await QuranFoundationApi.getChapterAudio(reciterId, surahNumber);
      final audioUrl = audioData['audio_url'] as String;

      // تحميل الملف
      final response = await http.get(Uri.parse(audioUrl));

      if (response.statusCode == 200) {
        final basePath = await _getBasePath(reciterId);
        final file = File('$basePath/$surahNumber.mp3');
        await file.writeAsBytes(response.bodyBytes);

        _downloadStatuses[surahNumber] = SurahDownloadStatus(
          surahNumber: surahNumber,
          progress: 1.0,
          isCompleted: true,
          filePath: file.path,
        );
      } else {
        throw Exception('فشل التحميل: ${response.statusCode}');
      }
    } catch (e) {
      _downloadStatuses[surahNumber] = SurahDownloadStatus(
        surahNumber: surahNumber,
        error: e.toString(),
      );
      debugPrint('❌ خطأ في تحميل سورة $surahNumber: $e');
    }
    notifyListeners();
  }

  /// تحميل المصحف كامل
  Future<void> downloadAll(String reciterId) async {
    _isDownloadingAll = true;
    _totalDownloaded = 0;
    notifyListeners();

    for (int i = 1; i <= 114; i++) {
      if (!_isDownloadingAll) break; // التوقف إذا طلب المستخدم

      final isDownloaded = await isSurahDownloaded(reciterId, i);
      if (!isDownloaded) {
        await downloadSurah(reciterId, i);
      }
      _totalDownloaded = i;
      notifyListeners();
    }

    _isDownloadingAll = false;
    notifyListeners();
  }

  /// إلغاء تحميل الكل
  void cancelDownloadAll() {
    _isDownloadingAll = false;
    notifyListeners();
  }

  /// حذف صوتيات قارئ
  Future<void> deleteReciterAudio(String reciterId) async {
    final basePath = await _getBasePath(reciterId);
    final dir = Directory(basePath);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    _downloadStatuses.clear();
    notifyListeners();
  }

  /// حساب حجم الملفات المحملة
  Future<String> getDownloadedSize(String reciterId) async {
    final basePath = await _getBasePath(reciterId);
    final dir = Directory(basePath);
    if (!await dir.exists()) return '0 MB';

    int totalBytes = 0;
    await for (var entity in dir.list()) {
      if (entity is File) {
        totalBytes += await entity.length();
      }
    }

    if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
