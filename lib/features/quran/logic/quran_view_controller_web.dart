import 'dart:async';

import '../data/models/mushaf_category.dart';
import '../data/models/recitation.dart';
import '../data/models/shaykh.dart';
import '../data/recitation_service.dart';

class DownloadEstimate {
  final int toDownload;
  final double size;
  final String unit;
  final bool isApproximate;

  const DownloadEstimate({
    required this.toDownload,
    required this.size,
    required this.unit,
    required this.isApproximate,
  });

  String get formattedSize => '${size.toStringAsFixed(2)} $unit';
}

class QuranViewController {
  List<Recitation> recitations = [];
  List<Recitation> filteredRecitations = [];
  bool isLoading = true;
  String error = '';
  bool isBatchDownloading = false;
  int downloadedCount = 0;
  int totalToDownload = 0;

  Timer? _statusTimer;

  Future<void> fetchRecitations({
    required Shaykh shaykh,
    required String? mushafId,
  }) async {
    isLoading = true;
    error = '';
    try {
      final shaykhRecitations = await RecitationService.getRecitationsForShaykh(
        shaykh.id,
        mushafId: mushafId,
      );
      shaykhRecitations.sort((a, b) {
        try {
          return int.parse(a.id).compareTo(int.parse(b.id));
        } catch (_) {
          return 0;
        }
      });
      recitations = shaykhRecitations;
      filteredRecitations = List<Recitation>.from(shaykhRecitations);
    } catch (_) {
      error = 'تعذر تحميل التلاوات';
    } finally {
      isLoading = false;
    }
  }

  void applySearch(String query) {
    final normalizedQuery = _normalizeForSearch(query);
    if (normalizedQuery.isEmpty) {
      filteredRecitations = List<Recitation>.from(recitations);
      return;
    }
    filteredRecitations = recitations.where((recitation) {
      final searchable = _normalizeForSearch(
        '${recitation.title} ${recitation.reciterName} ${recitation.mushafName ?? ''} ${recitation.id}',
      );
      return searchable.contains(normalizedQuery);
    }).toList();
  }

  String _normalizeForSearch(String value) {
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

  Shaykh? buildMushafSelectionShaykh({
    required Shaykh shaykh,
    required String? mushafId,
  }) {
    if (mushafId != null) return null;
    final uniqueMushafIds =
        recitations.map((r) => r.mushafId).whereType<String>().toSet().toList();
    if (uniqueMushafIds.length <= 1) return null;

    final mushafDetails = <String, String>{};
    for (final recitation in recitations) {
      if (recitation.mushafId != null &&
          recitation.mushafName != null &&
          recitation.mushafName!.isNotEmpty) {
        mushafDetails[recitation.mushafId!] = recitation.mushafName!;
      }
    }

    final detectedMushafs = uniqueMushafIds.map((id) {
      final mushafName = mushafDetails[id] ?? 'Mushaf / Riwaya $id';
      double totalSizeGB = 0;
      double totalSizeMB = 0;
      try {
        final originalMushaf = shaykh.availableMushafs.firstWhere(
          (mushaf) => mushaf.id == id,
        );
        totalSizeGB = originalMushaf.totalSizeGB;
        totalSizeMB = originalMushaf.totalSizeMB;
      } catch (_) {}

      return MushafCategory(
        id: id,
        name: mushafName,
        totalSizeGB: totalSizeGB,
        totalSizeMB: totalSizeMB,
      );
    }).toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    return Shaykh(
      id: shaykh.id,
      name: shaykh.name,
      bio: shaykh.bio,
      imageUrl: shaykh.imageUrl,
      category: shaykh.category,
      availableMushafs: detectedMushafs,
    );
  }

  String getCurrentMushafName({
    required Shaykh shaykh,
    required String? mushafId,
    required String? mushafName,
  }) {
    if (mushafName != null) return mushafName;
    if (mushafId == null) {
      if (recitations.isNotEmpty && recitations.first.mushafId != null) {
        final firstRecitation = recitations.first;
        final mushaf = shaykh.availableMushafs.firstWhere(
          (m) => m.id == firstRecitation.mushafId,
          orElse: () => MushafCategory(
            id: firstRecitation.mushafId!,
            name: firstRecitation.mushafName != null &&
                    firstRecitation.mushafName!.isNotEmpty
                ? firstRecitation.mushafName!
                : 'Available Recitation',
          ),
        );
        return mushaf.name;
      }
      return 'جميع التلاوات';
    }

    final mushaf = shaykh.availableMushafs.firstWhere(
      (m) => m.id == mushafId,
      orElse: () => MushafCategory(id: mushafId, name: 'مصحف غير معروف'),
    );
    return mushaf.name;
  }

  void startStatusCheck(void Function() onChanged) {}

  Future<void> cancelBatchDownload() async {
    isBatchDownloading = false;
  }

  Future<bool> hasInternetConnection() async => true;

  Future<DownloadEstimate> buildDownloadEstimate({
    required Shaykh shaykh,
    required String? mushafId,
  }) async {
    return const DownloadEstimate(
      toDownload: 0,
      size: 0,
      unit: 'MB',
      isApproximate: true,
    );
  }

  Future<void> downloadAllRecitations({
    required Shaykh shaykh,
    required void Function() onChanged,
  }) async {}

  void dispose() {
    _statusTimer?.cancel();
  }
}
