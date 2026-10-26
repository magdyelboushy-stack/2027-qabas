import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:isolate';
import '../../features/quran/data/models/recitation.dart';
import '../../features/quran/data/models/shaykh.dart';
import '../../core/utils/desktop_utils.dart';

class DownloadUpdate {
  final String taskId;
  final DownloadTaskStatus status;
  final int progress;
  final String? url;

  DownloadUpdate(this.taskId, this.status, this.progress, {this.url});
}

class DownloadManager {
  static const String _storageKey = 'saved_downloads_v1';
  static final ReceivePort _port = ReceivePort();
  static final StreamController<DownloadUpdate> _updatesController = StreamController<DownloadUpdate>.broadcast();
  static Stream<DownloadUpdate> get updates => _updatesController.stream;
  static bool _isInitialized = false;
  static final Map<String, String> _taskIdToUrl = {}; // ✅ Cache for mapping

  // 1. تهيئة المكتبة
  static Future<void> initializeDownloader() async {
    if (DesktopUtils.isDesktop) return; // Skip on Desktop
    if (_isInitialized) return;
    
    try {
      // ✅ Register port FIRST and wait a bit
      IsolateNameServer.removePortNameMapping('downloader_send_port');
      bool success = IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
      debugPrint("📡 [DownloadManager] Port registration: $success");
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      _port.listen((dynamic data) async {
        try {
          String id = data[0];
          int statusInt = data[1];
          int progress = data[2];
          
          // ✅ Try to find URL if not in cache
          String? url = _taskIdToUrl[id];
          if (url == null) {
              final task = await FlutterDownloader.loadTasksWithRawQuery(query: "SELECT * FROM task WHERE task_id = '$id'");
              if (task != null && task.isNotEmpty) {
                  url = task.first.url;
                  _taskIdToUrl[id] = url;
              }
          }

          debugPrint("📬 Main Isolate: Task $id, Status $statusInt, Progress $progress%, URL: $url");
          
          DownloadTaskStatus status;
          if (statusInt >= 0 && statusInt < DownloadTaskStatus.values.length) {
            status = DownloadTaskStatus.values[statusInt];
          } else {
            status = DownloadTaskStatus.undefined;
          }

          _updatesController.add(DownloadUpdate(id, status, progress, url: url));
        } catch (e) {
          debugPrint("❌ Error in download port listener: $e");
        }
      });

      await FlutterDownloader.initialize(debug: true, ignoreSsl: true);
      await FlutterDownloader.registerCallback(downloadCallback);
      _isInitialized = true;
    } catch (e) {
      debugPrint('⚠️ Download Manager init failed: $e');
    }
  }

  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
    if (send != null) {
      send.send([id, status, progress]);
    }
    // We can't use debugPrint easily here on some devices, but we can try
  }

  // Get local path for downloads (app-specific directory - no permission needed)
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // 2. بدء التحميل (وحفظ البيانات) - Return taskId instead of path
  static Future<String?> startDownload(Recitation recitation, Shaykh shaykh) async {
    if (DesktopUtils.isDesktop) {
      debugPrint("Downloads not fully supported on Desktop yet.");
      return null;
    }
    try {
      final path = await _localPath;
      final fileName = getFileName(recitation);
      final savePath = '$path/$fileName';

      // إذا الملف موجود، لا نحمل مرة أخرى ونحدث البيانات
      if (await File(savePath).exists()) {
        await _saveMetadata(recitation, shaykh, savePath);
        return savePath;
      }

      String url = recitation.audioUrl;
      // if (url.startsWith('http://')) url = url.replaceFirst('http://', 'https://');

      final taskId = await FlutterDownloader.enqueue(
        url: url,
        savedDir: path,
        fileName: fileName,
        showNotification: true,
        openFileFromNotification: false,
        saveInPublicStorage: false, // ✅ Use app-specific storage (no permission needed)
      );

      debugPrint("✅ [DownloadManager] Enqueued task: $taskId for URL: $url");

      if (taskId != null) {
        _taskIdToUrl[taskId] = recitation.audioUrl;
        // Notify UI immediately that download has started
        _updatesController.add(DownloadUpdate(taskId, DownloadTaskStatus.enqueued, 0, url: recitation.audioUrl));
        
        // حفظ بيانات التلاوة في السجل
        await _saveMetadata(recitation, shaykh, savePath);
        return taskId;
      }
      return null;
    } catch (e) {
      debugPrint("❌ Error starting download: $e");
      return null;
    }
  }

  // 3. حفظ البيانات (Metadata)
  static Future<void> _saveMetadata(Recitation r, Shaykh s, String localPath) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedList = prefs.getStringList(_storageKey) ?? [];

    // إزالة التكرار
    savedList.removeWhere((item) {
      try {
        final map = json.decode(item);
        return map['id'].toString() == r.id.toString();
      } catch (e) { return false; }
    });

    Map<String, dynamic> itemData = {
      'id': r.id,
      'title': r.title,
      'reciterName': s.name,
      'shaykhId': s.id,
      'imageUrl': s.imageUrl,
      'filePath': localPath,
      'date': DateTime.now().toIso8601String(),
    };

    savedList.add(json.encode(itemData));
    await prefs.setStringList(_storageKey, savedList);
  }

  // 4. جلب كل التحميلات (للعرض في الشاشة)
  static Future<List<Map<String, dynamic>>> getAllDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedList = prefs.getStringList(_storageKey) ?? [];
    List<Map<String, dynamic>> validDownloads = [];
    List<String> updatedList = [];

    for (String itemStr in savedList) {
      try {
        Map<String, dynamic> item = json.decode(itemStr);
        if (await File(item['filePath']).exists()) {
          validDownloads.add(item);
          updatedList.add(itemStr);
        }
      } catch (e) {
        // تجاهل البيانات التالفة
      }
    }

    // تحديث القائمة (حذف الملفات التي مسحت يدوياً)
    if (validDownloads.length != savedList.length) {
      await prefs.setStringList(_storageKey, updatedList);
    }

    return validDownloads.reversed.toList(); // الأحدث أولاً
  }

  // 5. حذف تحميل
  static Future<void> deleteDownload(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      final prefs = await SharedPreferences.getInstance();
      List<String> savedList = prefs.getStringList(_storageKey) ?? [];
      savedList.removeWhere((item) => item.contains(filePath));
      await prefs.setStringList(_storageKey, savedList);

    } catch (e) {
      debugPrint("Error deleting file: $e");
    }
  }

  // ✅✅ 6. مسح الكل (طريقة قوية لإيقاف الإشعارات)
  static Future<void> cancelAllDownloads() async {
    if (DesktopUtils.isDesktop) return;
    await FlutterDownloader.cancelAll();
  }

  static Future<void> pauseDownload(String taskId) async {
    await FlutterDownloader.pause(taskId: taskId);
  }

  static Future<void> resumeDownload(String taskId) async {
    await FlutterDownloader.resume(taskId: taskId);
  }

  static Future<void> cancelDownload(String taskId) async {
    await FlutterDownloader.cancel(taskId: taskId);
    await FlutterDownloader.remove(taskId: taskId, shouldDeleteContent: true);
  }

  static Future<DownloadTask?> getTaskByUrl(String url) async {
    if (DesktopUtils.isDesktop) return null;
    final tasks = await FlutterDownloader.loadTasks();
    if (tasks == null) return null;
    try {
      return tasks.firstWhere((t) => t.url == url);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearAllDownloads() async {
    try {
      final dir = Directory(await _localPath);
      if (await dir.exists()) await dir.delete(recursive: true);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint("Error clearing all: $e");
    }
  }

  static String getFileName(Recitation recitation) {
    final cleanTitle = recitation.title.replaceAll(RegExp(r'[^\w\u0600-\u06FF]'), '_');
    return '${recitation.id}_$cleanTitle.mp3';
  }

  // ✅✅ 7. دوال الفحص (تم تعديلها لتكون أكثر دقة)
  static Future<bool> isDownloaded(Recitation recitation, Shaykh shaykh) async {
    // If recitation audioUrl is already a valid local file path
    if (recitation.audioUrl.isNotEmpty && await File(recitation.audioUrl).exists()) {
      return (await File(recitation.audioUrl).length()) > 0;
    }

    final path = await _localPath;
    final fileName = getFileName(recitation);
    final file = File('$path/$fileName');
    
    if (!await file.exists()) {
      // Check saved downloads metadata fallback
      final prefs = await SharedPreferences.getInstance();
      final savedList = prefs.getStringList(_storageKey) ?? [];
      for (final itemStr in savedList) {
        try {
          final map = json.decode(itemStr);
          if (map['id'].toString() == recitation.id.toString()) {
            final fPath = map['filePath'];
            if (fPath != null && await File(fPath).exists()) {
              return (await File(fPath).length()) > 0;
            }
          }
        } catch (_) {}
      }
      return false;
    }

    // ✅ التحقق من حالة المهمة في المكتبة لضمان عدم وجود تحميل جاري
    if (DesktopUtils.isDesktop) return (await file.length()) > 0;
    
    try {
      final task = await getTaskByUrl(recitation.audioUrl);
      if (task != null) {
        if (task.status == DownloadTaskStatus.running || 
            task.status == DownloadTaskStatus.enqueued || 
            task.status == DownloadTaskStatus.paused) {
          return false;
        }
        return task.status == DownloadTaskStatus.complete;
      }
    } catch (e) {
      debugPrint("Error checking task status: $e");
    }

    // fallback: if file exists and no task info found, assume it's done if size > 0
    return (await file.length()) > 0;
  }

  static Future<String?> getLocalFilePath(Recitation recitation, Shaykh shaykh) async {
    // If recitation audioUrl is already a valid local file path
    if (recitation.audioUrl.isNotEmpty && await File(recitation.audioUrl).exists()) {
      return recitation.audioUrl;
    }

    final path = await _localPath;
    final fileName = getFileName(recitation);
    final file = File('$path/$fileName');
    if (await file.exists()) {
      return file.path;
    }

    // Check saved downloads metadata fallback
    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getStringList(_storageKey) ?? [];
    for (final itemStr in savedList) {
      try {
        final map = json.decode(itemStr);
        if (map['id'].toString() == recitation.id.toString()) {
          final fPath = map['filePath'];
          if (fPath != null && await File(fPath).exists()) {
            return fPath;
          }
        }
      } catch (_) {}
    }

    return null;
  }

  // ✅ Force trigger an update for a specific URL
  static Future<void> refreshStatusForUrl(String url) async {
    final task = await getTaskByUrl(url);
    if (task != null) {
      _updatesController.add(DownloadUpdate(task.taskId, task.status, task.progress));
    }
  }
}
