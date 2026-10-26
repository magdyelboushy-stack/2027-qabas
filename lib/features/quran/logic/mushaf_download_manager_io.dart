import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:quran/quran.dart' as quran_utils;
import 'package:get/get.dart';
import '../data/services/quran_foundation_api.dart';

class SurahDownloadStatus {
  final int surah;
  final int totalAyahs;
  final int downloadedAyahs;
  final bool isDownloading;
  final bool isCompleted;
  final String? errorMessage;

  SurahDownloadStatus({
    required this.surah,
    required this.totalAyahs,
    required this.downloadedAyahs,
    required this.isDownloading,
    required this.isCompleted,
    this.errorMessage,
  });
  
  double get progress => totalAyahs == 0 ? 0 : downloadedAyahs / totalAyahs;
}

class MushafDownloadManager extends ChangeNotifier {
  static final MushafDownloadManager instance = MushafDownloadManager._();
  MushafDownloadManager._();

  // Maps reciterId_surahNumber to its status
  final Map<String, SurahDownloadStatus> _statuses = {};
  
  // Keep track of cancellation tokens if we need to stop
  final Map<String, bool> _cancellationTokens = {};

  bool _isMushafDownloading = false;
  bool get isMushafDownloading => _isMushafDownloading;

  SurahDownloadStatus? getStatus(String reciterId, int surah) {
    return _statuses['${reciterId}_$surah'];
  }

  static Future<String> get _basePath async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/mushaf_audio';
  }

  static Future<String?> getLocalAyahPath(String reciterId, int surah, int ayah) async {
    final base = await _basePath;
    final file = File('$base/$reciterId/$surah/$ayah.mp3');
    if (await file.exists() && await file.length() > 0) {
      return file.path;
    }
    return null;
  }

  Future<void> checkSurahStatus(String reciterId, int surah) async {
    final base = await _basePath;
    final totalAyahs = quran_utils.getVerseCount(surah);
    int downloadedCount = 0;
    
    final dir = Directory('$base/$reciterId/$surah');
    if (await dir.exists()) {
      for (int a = 1; a <= totalAyahs; a++) {
        final f = File('${dir.path}/$a.mp3');
        if (await f.exists() && await f.length() > 0) {
          downloadedCount++;
        }
      }
    }
    
    final key = '${reciterId}_$surah';
    _statuses[key] = SurahDownloadStatus(
      surah: surah,
      totalAyahs: totalAyahs,
      downloadedAyahs: downloadedCount,
      isDownloading: _statuses[key]?.isDownloading ?? false,
      isCompleted: downloadedCount == totalAyahs,
    );
    notifyListeners();
  }

  Future<void> checkAllSurahs(String reciterId) async {
    for (int s = 1; s <= 114; s++) {
      await checkSurahStatus(reciterId, s);
    }
  }

  Future<void> downloadSurah(String reciterId, int surah) async {
    final key = '${reciterId}_$surah';
    if (_statuses[key]?.isDownloading == true) return;
    
    _cancellationTokens[key] = false;
    
    final totalAyahs = quran_utils.getVerseCount(surah);
    
    _statuses[key] = SurahDownloadStatus(
      surah: surah,
      totalAyahs: totalAyahs,
      downloadedAyahs: _statuses[key]?.downloadedAyahs ?? 0,
      isDownloading: true,
      isCompleted: false,
    );
    notifyListeners();

    final base = await _basePath;
    final dir = Directory('$base/$reciterId/$surah');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    try {
      int downloaded = 0;
      for (int a = 1; a <= totalAyahs; a++) {
        if (_cancellationTokens[key] == true) {
          break; // cancelled
        }

        final file = File('${dir.path}/$a.mp3');
        if (await file.exists() && await file.length() > 0) {
          downloaded++;
          continue; // Already downloaded
        }

        try {
          final url = await QuranFoundationApi.getAyahAudioUrl(reciterId, surah, a);
          final response = await http.get(Uri.parse(url));
          if (response.statusCode == 200) {
            await file.writeAsBytes(response.bodyBytes);
            downloaded++;
            _statuses[key] = SurahDownloadStatus(
              surah: surah,
              totalAyahs: totalAyahs,
              downloadedAyahs: downloaded,
              isDownloading: true,
              isCompleted: false,
            );
            notifyListeners();
          } else {
             debugPrint("Error downloading $surah:$a - Status Code: ${response.statusCode}");
             throw Exception('Status Code: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint("Error downloading ayah $surah:$a - $e");
          final isAr = Get.locale?.languageCode == 'ar';
          String errMsg = isAr ? 'فشل التنزيل أو الرابط غير متوفر' : 'Download failed or URL unavailable';
          
          if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
            errMsg = isAr ? 'لا يوجد اتصال بالإنترنت' : 'No internet connection';
          }

          _statuses[key] = SurahDownloadStatus(
            surah: surah,
            totalAyahs: totalAyahs,
            downloadedAyahs: downloaded,
            isDownloading: false,
            isCompleted: false,
            errorMessage: errMsg,
          );
          notifyListeners();
          return; // Stop downloading this surah on error
        }
      }

      // If loop finishes normally without returning early
      if (_cancellationTokens[key] != true) {
        _statuses[key] = SurahDownloadStatus(
          surah: surah,
          totalAyahs: totalAyahs,
          downloadedAyahs: downloaded,
          isDownloading: false,
          isCompleted: downloaded == totalAyahs,
        );
        notifyListeners();
      }

    } catch (e) {
      debugPrint("Error downloading surah $surah: $e");
      final isAr = Get.locale?.languageCode == 'ar';
      _statuses[key] = SurahDownloadStatus(
        surah: surah,
        totalAyahs: totalAyahs,
        downloadedAyahs: _statuses[key]?.downloadedAyahs ?? 0,
        isDownloading: false,
        isCompleted: false,
        errorMessage: isAr ? 'حدث خطأ غير متوقع' : 'Unexpected error occurred',
      );
      notifyListeners();
    }
  }

  Future<void> downloadFullMushaf(String reciterId) async {
    if (_isMushafDownloading) return;
    _isMushafDownloading = true;
    _cancellationTokens['mushaf_$reciterId'] = false;
    notifyListeners();

    for (int s = 1; s <= 114; s++) {
      if (_cancellationTokens['mushaf_$reciterId'] == true) break;
      
      final st = _statuses['${reciterId}_$s'];
      if (st == null || !st.isCompleted) {
         await downloadSurah(reciterId, s);
      }
    }

    _isMushafDownloading = false;
    notifyListeners();
  }

  void cancelDownload(String reciterId, int surah) {
    _cancellationTokens['${reciterId}_$surah'] = true;
  }
  
  void cancelFullMushaf(String reciterId) {
    _cancellationTokens['mushaf_$reciterId'] = true;
    for (int s = 1; s <= 114; s++) {
      cancelDownload(reciterId, s);
    }
    _isMushafDownloading = false;
    notifyListeners();
  }
  
  Future<void> deleteSurah(String reciterId, int surah) async {
    cancelDownload(reciterId, surah);
    final base = await _basePath;
    final dir = Directory('$base/$reciterId/$surah');
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await checkSurahStatus(reciterId, surah);
  }
}
