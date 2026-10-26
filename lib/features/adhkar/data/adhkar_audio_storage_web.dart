import 'adhkar_model.dart';

Future<bool> isAdhkarAudioDownloaded(DhikrItem item) async => false;

Future<void> saveAdhkarAudio(DhikrItem item, List<int> bytes) async {}

Future<void> deleteAdhkarAudio(DhikrItem item) async {}

Future<String?> localAdhkarAudioPathIfExists(DhikrItem item) async => null;

String safeAdhkarAudioFileName(DhikrItem item, String audioPath) {
  final cleaned = audioPath.trim().replaceAll('\\', '/');
  final sourceName =
      cleaned.isEmpty ? 'adhkar_${item.id}.mp3' : cleaned.split('/').last;
  final sanitized =
      sourceName.replaceAll(RegExp(r'[^\w\.\-\u0600-\u06FF]'), '_');
  return '${item.id}_$sanitized';
}
