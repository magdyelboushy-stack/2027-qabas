import 'dart:async';

import '../../features/quran/data/models/recitation.dart';
import '../../features/quran/data/models/shaykh.dart';

class DownloadUpdate {
  final String taskId;
  final int status;
  final int progress;
  final String? url;

  DownloadUpdate(this.taskId, this.status, this.progress, {this.url});
}

class DownloadManager {
  static Stream<DownloadUpdate> get updates => const Stream.empty();

  static Future<void> initializeDownloader() async {}

  static Future<String?> startDownload(
      Recitation recitation, Shaykh shaykh) async {
    return null;
  }

  static Future<List<Map<String, dynamic>>> getAllDownloads() async => [];

  static Future<void> deleteDownload(String filePath) async {}

  static Future<void> cancelAllDownloads() async {}

  static Future<void> pauseDownload(String taskId) async {}

  static Future<void> resumeDownload(String taskId) async {}

  static Future<void> cancelDownload(String taskId) async {}

  static Future<dynamic> getTaskByUrl(String url) async => null;

  static Future<void> clearAllDownloads() async {}

  static String getFileName(Recitation recitation) => '';

  static Future<bool> isDownloaded(
          Recitation recitation, Shaykh shaykh) async =>
      false;

  static Future<String?> getLocalFilePath(
          Recitation recitation, Shaykh shaykh) async =>
      null;

  static Future<void> refreshStatusForUrl(String url) async {}
}
