import 'package:quran/quran.dart' as quran;

/// Represents a segment of the daily ward (portion) within a single surah.
class WardSegment {
  final int surahNumber;
  final String surahNameAr;
  final String surahNameEn;
  final int fromAyah;
  final int toAyah;

  const WardSegment({
    required this.surahNumber,
    required this.surahNameAr,
    required this.surahNameEn,
    required this.fromAyah,
    required this.toAyah,
  });

  int get ayahCount => toAyah - fromAyah + 1;

  @override
  String toString() => '$surahNameAr ($fromAyah-$toAyah)';
}

/// Details of today's ward (reading portion).
class WardDetails {
  final int fromPage;
  final int toPage;
  final List<WardSegment> segments;

  const WardDetails({
    required this.fromPage,
    required this.toPage,
    required this.segments,
  });

  int get totalPages => toPage - fromPage + 1;

  /// Arabic summary: "سورة النساء (1-23) + سورة المائدة (1-5)"
  String get summaryAr {
    if (segments.isEmpty) return '';
    if (segments.length == 1) {
      final s = segments.first;
      return '${s.surahNameAr} (${_toArabicNum(s.fromAyah)}-${_toArabicNum(s.toAyah)})';
    }
    return segments.map((s) => '${s.surahNameAr} (${_toArabicNum(s.fromAyah)}-${_toArabicNum(s.toAyah)})').join(' + ');
  }

  /// English summary
  String get summaryEn {
    if (segments.isEmpty) return '';
    if (segments.length == 1) {
      final s = segments.first;
      return '${s.surahNameEn} (${s.fromAyah}-${s.toAyah})';
    }
    return segments.map((s) => '${s.surahNameEn} (${s.fromAyah}-${s.toAyah})').join(' + ');
  }

  /// Short notification text (Arabic)
  String get notificationTextAr {
    if (segments.isEmpty) return 'وردك اليوم';
    final first = segments.first;
    if (segments.length == 1) {
      return 'سورة ${first.surahNameAr}\nمن الآية ${_toArabicNum(first.fromAyah)} إلى الآية ${_toArabicNum(first.toAyah)}';
    }
    final last = segments.last;
    return 'من سورة ${first.surahNameAr} إلى سورة ${last.surahNameAr}';
  }

  /// Short notification text (English)
  String get notificationTextEn {
    if (segments.isEmpty) return 'Your daily portion';
    final first = segments.first;
    if (segments.length == 1) {
      return 'Surah ${first.surahNameEn}\nAyah ${first.fromAyah} to ${first.toAyah}';
    }
    final last = segments.last;
    return 'From Surah ${first.surahNameEn} to Surah ${last.surahNameEn}';
  }

  static String _toArabicNum(int n) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((d) => arabicDigits[int.parse(d)]).join();
  }
}

/// Calculator for determining daily reading portions.
class KhatmaWardCalculator {
  /// Get ward segments for a range of pages.
  /// Converts page numbers into surah names and ayah ranges.
  static WardDetails getWardForPages(int fromPage, int toPage) {
    fromPage = fromPage.clamp(1, 604);
    toPage = toPage.clamp(fromPage, 604);

    final segments = <WardSegment>[];

    for (int page = fromPage; page <= toPage; page++) {
      final pageData = quran.getPageData(page);
      // pageData is a list of maps: [{surah: X, start: Y, end: Z}, ...]
      for (final entry in pageData) {
        final surahNum = entry['surah'] as int;
        final startAyah = entry['start'] as int;
        final endAyah = entry['end'] as int;

        // Try to merge with the last segment if same surah
        if (segments.isNotEmpty && segments.last.surahNumber == surahNum) {
          final last = segments.last;
          // Extend the range
          segments[segments.length - 1] = WardSegment(
            surahNumber: surahNum,
            surahNameAr: last.surahNameAr,
            surahNameEn: last.surahNameEn,
            fromAyah: last.fromAyah,
            toAyah: endAyah > last.toAyah ? endAyah : last.toAyah,
          );
        } else {
          segments.add(WardSegment(
            surahNumber: surahNum,
            surahNameAr: quran.getSurahNameArabic(surahNum),
            surahNameEn: quran.getSurahNameEnglish(surahNum),
            fromAyah: startAyah,
            toAyah: endAyah,
          ));
        }
      }
    }

    return WardDetails(
      fromPage: fromPage,
      toPage: toPage,
      segments: segments,
    );
  }

  /// Get today's ward based on khatma current page and daily target.
  static WardDetails getTodayWard({
    required int currentPage,
    required int dailyTarget,
  }) {
    final fromPage = currentPage.clamp(1, 604);
    final toPage = (currentPage + dailyTarget - 1).clamp(1, 604);
    return getWardForPages(fromPage, toPage);
  }

  /// Get the current session's ward.
  static WardDetails getSessionWard({
    required int currentPage,
    required int sessionPages,
  }) {
    final fromPage = currentPage.clamp(1, 604);
    final toPage = (currentPage + sessionPages - 1).clamp(1, 604);
    return getWardForPages(fromPage, toPage);
  }

  /// Get the juz number for a page.
  static int getJuzForPage(int page) {
    return quran.getJuzNumber(
      _getSurahForPage(page),
      1,
    );
  }

  /// Get the surah number for a page.
  static int _getSurahForPage(int page) {
    for (int surah = 114; surah >= 1; surah--) {
      if (quran.getPageNumber(surah, 1) <= page) return surah;
    }
    return 1;
  }

  /// Get surah name (Arabic) for a page.
  static String getSurahNameArForPage(int page) {
    return quran.getSurahNameArabic(_getSurahForPage(page));
  }

  /// Get surah name (English) for a page.
  static String getSurahNameEnForPage(int page) {
    return quran.getSurahNameEnglish(_getSurahForPage(page));
  }

  /// Estimate reading time in minutes (~2.5 min/page average).
  static int estimateReadingMinutes(int pages) {
    return (pages * 2.5).round();
  }
}
