import 'package:flutter/material.dart';

class QuranCtrl {
  static final QuranCtrl instance = QuranCtrl._();
  QuranCtrl._();
}

class AyahModel {
  final int ayahUQNumber;
  final int ayahNumber;
  String text;
  final String ayaTextEmlaey;
  final String? codeV2;
  final int juz;
  final int page;
  final int? surahNumber;
  final int? lineStart;
  final int? lineEnd;
  final int? quarter;
  final int? hizb;
  final String? englishName;
  final String? arabicName;
  final bool? sajdaBool;
  final dynamic sajda;
  final Color? singleAyahTextColor;
  final bool? centered;
  final bool isDownloadedFonts;

  AyahModel({
    required this.ayahUQNumber,
    required this.ayahNumber,
    required this.text,
    required this.ayaTextEmlaey,
    this.codeV2,
    required this.juz,
    required this.page,
    this.surahNumber,
    this.lineStart,
    this.lineEnd,
    this.quarter,
    this.hizb,
    this.englishName,
    this.arabicName,
    this.sajdaBool,
    this.sajda,
    this.singleAyahTextColor,
    this.centered,
    required this.isDownloadedFonts,
  });
}

class QuranLibrary {
  Future<void> init() async {}

  List<String> getAllSurahs() => const [];

  List<AyahModel> search(String query) => const [];

  void jumpToSurah(int surahNumber) {}

  void jumpToPage(int pageNumber) {}
}

class QuranLibraryScreen extends StatelessWidget {
  final int? pageIndex;
  final AyahModel? initialAyah;
  final VoidCallback? onBack;

  const QuranLibraryScreen({
    super.key,
    this.pageIndex,
    this.initialAyah,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Quran reader is available in the mobile app.'),
      ),
    );
  }
}
