import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'adhkar_model.dart';

Future<bool> isAdhkarAudioDownloaded(DhikrItem item) async {
  final file = await localAdhkarAudioFile(item);
  return file.existsSync();
}

Future<File> localAdhkarAudioFile(DhikrItem item) async {
  final baseDir = await getApplicationDocumentsDirectory();
  final dir = Directory('${baseDir.path}/adhkar_audio');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  final fileName = safeAdhkarAudioFileName(item, item.audio);
  return File('${dir.path}/$fileName');
}

String safeAdhkarAudioFileName(DhikrItem item, String audioPath) {
  final cleaned = audioPath.trim().replaceAll('\\', '/');
  final sourceName =
      cleaned.isEmpty ? 'adhkar_${item.id}.mp3' : cleaned.split('/').last;
  final sanitized =
      sourceName.replaceAll(RegExp(r'[^\w\.\-\u0600-\u06FF]'), '_');
  return '${item.id}_$sanitized';
}

Future<String?> localAdhkarAudioPathIfExists(DhikrItem item) async {
  final file = await localAdhkarAudioFile(item);
  if (await file.exists()) return file.path;
  return null;
}

Future<void> saveAdhkarAudio(DhikrItem item, List<int> bytes) async {
  final file = await localAdhkarAudioFile(item);
  await file.writeAsBytes(bytes, flush: true);
}

Future<void> deleteAdhkarAudio(DhikrItem item) async {
  final file = await localAdhkarAudioFile(item);
  if (await file.exists()) {
    await file.delete();
  }
}
