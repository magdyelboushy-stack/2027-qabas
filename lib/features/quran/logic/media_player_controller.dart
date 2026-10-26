import '../../../core/utils/platform.dart';

import '../data/models/recitation.dart';

class MediaPlayerController {
  static String normalizeImageUrl(String url) {
    if (isAndroid && url.contains('localhost')) {
      return url
          .replaceFirst('localhost', 'mihrab-app.alwaysdata.net')
          .replaceFirst('http://', 'https://');
    }
    return url;
  }

  static Recitation resolveCurrentRecitation({
    required List<Recitation> allRecitations,
    required Recitation fallback,
    required String? currentRecitationId,
  }) {
    return allRecitations.firstWhere(
      (recitation) => recitation.id == (currentRecitationId ?? fallback.id),
      orElse: () => fallback,
    );
  }

  static Uri? safeParseAudioUri(String url) {
    var processedUrl = url.trim();
    if (processedUrl.contains('archive.org') &&
        processedUrl.contains('/0/items/')) {
      try {
        final regex = RegExp(r'https?:\/\/[^\/]+\/0\/items\/([^\/]+)\/(.+)');
        final match = regex.firstMatch(processedUrl);
        if (match != null) {
          final item = match.group(1);
          final file = match.group(2);
          processedUrl = 'https://archive.org/download/$item/$file';
        }
      } catch (_) {}
    }

    try {
      if (processedUrl.contains('.php') && !processedUrl.endsWith('.mp3')) {
        processedUrl += (processedUrl.contains('?') ? '&' : '?') + 'ext=.mp3';
      }
      return Uri.parse(processedUrl);
    } catch (_) {
      try {
        return Uri.parse(Uri.encodeFull(processedUrl));
      } catch (_) {
        return null;
      }
    }
  }

  static String printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    final twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
    }
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  static String normalizeForSearch(String value) {
    var normalized = value.trim().toLowerCase();
    const diacriticsPattern = r'[\u064B-\u065F\u0670\u06D6-\u06ED]';
    normalized = normalized.replaceAll(RegExp(diacriticsPattern), '');
    normalized = normalized
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي');
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (var i = 0; i < arabicDigits.length; i++) {
      normalized = normalized.replaceAll(arabicDigits[i], '$i');
    }
    return normalized;
  }
}
