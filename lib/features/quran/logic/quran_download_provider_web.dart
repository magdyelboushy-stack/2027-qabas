import 'package:flutter/material.dart';

class SurahDownloadStatus {
  final int surahNumber;
  final double progress;
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

class QuranDownloadProvider extends ChangeNotifier {
  final Map<int, SurahDownloadStatus> _downloadStatuses = {};
  bool _isDownloadingAll = false;
  int _totalDownloaded = 0;

  Map<int, SurahDownloadStatus> get downloadStatuses => _downloadStatuses;
  bool get isDownloadingAll => _isDownloadingAll;
  int get totalDownloaded => _totalDownloaded;

  Future<bool> isSurahDownloaded(String reciterId, int surahNumber) async =>
      false;

  Future<String?> getLocalPath(String reciterId, int surahNumber) async =>
      null;

  Future<void> downloadSurah(String reciterId, int surahNumber) async {}

  Future<void> downloadAll(String reciterId) async {}

  void cancelDownloadAll() {
    _isDownloadingAll = false;
    notifyListeners();
  }

  Future<void> deleteReciterAudio(String reciterId) async {
    _downloadStatuses.clear();
    notifyListeners();
  }

  Future<String> getDownloadedSize(String reciterId) async => '0 MB';
}
