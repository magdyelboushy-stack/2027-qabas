import 'package:flutter/foundation.dart';

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

  final Map<String, SurahDownloadStatus> _statuses = {};
  final Map<String, bool> _cancellationTokens = {};
  bool _isMushafDownloading = false;

  bool get isMushafDownloading => _isMushafDownloading;

  SurahDownloadStatus? getStatus(String reciterId, int surah) =>
      _statuses['${reciterId}_$surah'];

  static Future<String?> getLocalAyahPath(
          String reciterId, int surah, int ayah) async =>
      null;

  Future<void> checkSurahStatus(String reciterId, int surah) async {}

  Future<void> checkAllSurahs(String reciterId) async {}

  Future<void> downloadSurah(String reciterId, int surah) async {}

  Future<void> downloadFullMushaf(String reciterId) async {}

  void cancelDownload(String reciterId, int surah) {}

  void cancelFullMushaf(String reciterId) {
    _isMushafDownloading = false;
    notifyListeners();
  }

  Future<void> deleteSurah(String reciterId, int surah) async {}
}
