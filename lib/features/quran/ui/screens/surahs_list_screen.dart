import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:quran_library/quran.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../../core/translations/app_locale_keys.dart';
import '../../../../core/utils/surah_data.dart';
import '../../../home/ui/widgets/main_drawer.dart';
import 'mushaf_screen.dart';

class SurahsListScreen extends StatefulWidget {
  const SurahsListScreen({super.key});

  @override
  State<SurahsListScreen> createState() => _SurahsListScreenState();
}

class _SurahsListScreenState extends State<SurahsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<SurahData> _filteredSurahs = [];
  List<AyahModel> _searchResults = [];
  bool _isSearchingContent = false;

  final List<int> _surahStartPages = [
    1,
    2,
    50,
    77,
    106,
    128,
    151,
    177,
    187,
    208,
    221,
    235,
    249,
    255,
    262,
    267,
    282,
    293,
    305,
    312,
    322,
    332,
    342,
    350,
    359,
    367,
    377,
    385,
    396,
    404,
    411,
    415,
    418,
    428,
    434,
    440,
    446,
    453,
    458,
    467,
    477,
    483,
    489,
    496,
    499,
    502,
    507,
    511,
    515,
    518,
    520,
    523,
    526,
    528,
    531,
    534,
    537,
    542,
    545,
    549,
    551,
    553,
    554,
    556,
    558,
    560,
    562,
    564,
    566,
    568,
    570,
    572,
    574,
    575,
    577,
    578,
    580,
    582,
    583,
    585,
    586,
    587,
    587,
    589,
    590,
    591,
    591,
    592,
    593,
    594,
    595,
    595,
    596,
    596,
    597,
    597,
    598,
    598,
    599,
    599,
    600,
    600,
    601,
    601,
    601,
    602,
    602,
    602,
    603,
    603,
    603,
    604,
    604,
    604,
  ];

  @override
  void initState() {
    super.initState();
    _filteredSurahs = SurahData.allSurahs;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() {
      if (query.isEmpty) {
        _isSearchingContent = false;
        _filteredSurahs = SurahData.allSurahs;
        _searchResults = [];
      } else {
        _filteredSurahs = SurahData.allSurahs.where((s) {
          return s.arabicName.contains(query) ||
              s.englishName.toLowerCase().contains(query.toLowerCase()) ||
              s.id.toString() == query;
        }).toList();

        _searchResults = QuranLibrary().search(query);
        _isSearchingContent =
            _searchResults.isNotEmpty || _filteredSurahs.isEmpty;
      }
    });
  }

  void _navigateToMushaf(int pageNumber, {AyahModel? targetAyah}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => MushafScreen(
          initialPage: pageNumber,
          initialAyah: targetAyah,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark ? Colors.white : Colors.black87;
    final accentColor = isDark ? Colors.cyanAccent : const Color(0xFF00695C);

    return Directionality(
      textDirection: Get.locale?.languageCode == 'ar'
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? Colors.transparent : const Color(0xFFF5F5F5),
        drawer: const MainDrawer(),
        appBar: AppBar(
          title: Text(
            AppLocaleKeys.quranTitle.tr,
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu, color: iconColor),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: _buildSearchBar(isDark, textColor, iconColor),
              ),
              Expanded(
                child: _isSearchingContent
                    ? _buildAyahSearchResults(isDark, textColor, accentColor)
                    : _buildSurahListView(isDark, textColor, accentColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurahListView(
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    if (_filteredSurahs.isEmpty && !_isSearchingContent) {
      return Center(
        child: Text(
          AppLocaleKeys.noSurahsFound.tr,
          style: TextStyle(color: textColor),
        ),
      );
    }

    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final cardColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final borderColor =
        isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade300;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      physics: const BouncingScrollPhysics(),
      itemCount: _filteredSurahs.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final surah = _filteredSurahs[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: borderColor),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: ListTile(
                onTap: () {
                  int targetPage = 1;
                  if (surah.id <= _surahStartPages.length) {
                    targetPage = _surahStartPages[surah.id - 1];
                  }
                  _navigateToMushaf(targetPage);
                },
                leading: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor.withOpacity(0.5)),
                    color: accentColor.withOpacity(0.1),
                  ),
                  child: Text(
                    '${surah.id}',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  surah.arabicName,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${surah.revelationType} • ${surah.ayahCount} ${AppLocaleKeys.ayahNumber.tr}',
                  style: TextStyle(color: subTextColor, fontSize: 12),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: subTextColor.withOpacity(0.5),
                  size: 16,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAyahSearchResults(
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          AppLocaleKeys.noSearchResults.tr,
          style: TextStyle(color: textColor),
        ),
      );
    }

    final cardColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final borderColor =
        isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade300;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      physics: const BouncingScrollPhysics(),
      itemCount: _searchResults.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final ayah = _searchResults[index];

        String surahName =
            '${AppLocaleKeys.surahNumber.tr} ${ayah.surahNumber}';
        if (ayah.surahNumber != null &&
            ayah.surahNumber! > 0 &&
            ayah.surahNumber! <= SurahData.allSurahs.length) {
          surahName = SurahData.allSurahs[ayah.surahNumber! - 1].arabicName;
        }

        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: borderColor),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: ListTile(
            onTap: () => _navigateToMushaf(ayah.page, targetAyah: ayah),
            title: Text(
              ayah.text,
              style: TextStyle(color: textColor, fontSize: 18),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 5.0),
              child: Row(
                children: [
                  Icon(Icons.menu_book, size: 14, color: accentColor),
                  const SizedBox(width: 5),
                  Text(
                    '$surahName - ${AppLocaleKeys.ayahNumber.tr} ${ayah.ayahNumber}',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${AppLocaleKeys.pageShort.tr} ${ayah.page}',
                    style: TextStyle(
                      color: textColor.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(bool isDark, Color textColor, Color iconColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color:
                  isDark ? Colors.white.withOpacity(0.2) : Colors.grey.shade300,
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: TextField(
            controller: _searchController,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: AppLocaleKeys.searchSurahOrAyah.tr,
              hintStyle: TextStyle(
                color: textColor.withOpacity(0.5),
                fontSize: 14,
              ),
              prefixIcon: Icon(Icons.search, color: iconColor),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.close,
                        color: textColor.withOpacity(0.5),
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
        ),
      ),
    );
  }
}
