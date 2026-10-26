import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qcf_quran/qcf_quran.dart';
import '../widgets/custom_qcf_viewer.dart';
import '../widgets/ayah_details_sheet.dart';
import '../widgets/mini_audio_player.dart';
import '../widgets/mushaf_tutorial_overlay.dart';
import '../../data/services/surah_database_service.dart';
import 'mushaf_downloads_screen.dart';

import 'package:quran/quran.dart' as quran_utils;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../../../core/translations/app_locale_keys.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../logic/quran_settings_provider.dart';
import '../../logic/quran_audio_provider.dart';
import '../../data/khatma_model.dart';
import '../../logic/khatma_service.dart';
import 'khatma_progress_screen.dart';

// ── Bookmark model ──────────────────────────────────────────
class _Bookmark {
  final int surah;
  final int verse;
  final int page;
  final int colorIndex; // 0-3
  final DateTime createdAt;

  _Bookmark({
    required this.surah,
    required this.verse,
    required this.page,
    required this.colorIndex,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'surah': surah,
        'verse': verse,
        'page': page,
        'colorIndex': colorIndex,
        'createdAt': createdAt.toIso8601String(),
      };

  factory _Bookmark.fromJson(Map<String, dynamic> json) => _Bookmark(
        surah: json['surah'] as int,
        verse: json['verse'] as int,
        page: json['page'] as int,
        colorIndex: json['colorIndex'] as int,
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );
}

// ── Main Screen ─────────────────────────────────────────────
class QcfMushafScreen extends StatefulWidget {
  final int? initialPage;
  final String? khatmaId;
  const QcfMushafScreen({super.key, this.initialPage, this.khatmaId});

  @override
  State<QcfMushafScreen> createState() => _QcfMushafScreenState();
}

class _QcfMushafScreenState extends State<QcfMushafScreen> {
  int _currentPage = 1;
  int _initialPage = 1;
  bool _isLoading = true;
  bool _showBottomBar = true;
  bool _ayahSheetJustClosed = false;
  KhatmaModel? _activeKhatma;

  // Tutorial
  bool _showTutorial = false;

  // GlobalKeys for tutorial targeting
  final GlobalKey _topBarKey = GlobalKey();
  final GlobalKey _bottomNavKey = GlobalKey();
  final GlobalKey _searchBtnKey = GlobalKey();
  final GlobalKey _settingsBtnKey = GlobalKey();

  // Audio Auto-Scroll tracking
  int? _lastPlayingSurah;
  int? _lastPlayingAyah;

  // Search highlight
  int? _highlightSurah;
  int? _highlightVerse;

  // Bookmarks
  List<_Bookmark> _bookmarks = [];

  // Bookmark colors
  static const List<Color> _bmColors = [
    Color(0xFFE53935), // Red
    Color(0xFF1E88E5), // Blue
    Color(0xFF43A047), // Green
    Color(0xFFFFA726), // Orange
  ];
  static const List<String> _bmColorNamesAr = ['أحمر', 'أزرق', 'أخضر', 'برتقالي'];
  static const List<String> _bmColorNamesEn = ['Red', 'Blue', 'Green', 'Orange'];

  // Juz start pages
  static const List<int> _juzStartPages = [
    1,
    22,
    42,
    62,
    82,
    102,
    121,
    142,
    162,
    182,
    201,
    222,
    242,
    262,
    282,
    302,
    322,
    342,
    362,
    382,
    402,
    422,
    442,
    462,
    482,
    502,
    522,
    542,
    562,
    582,
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('qcf_mushaf_last_page') ?? 1;
    final bmJson = prefs.getStringList('qcf_bookmarks') ?? [];

    final bms = bmJson
        .map((s) {
          try {
            return _Bookmark.fromJson(jsonDecode(s));
          } catch (_) {
            return null;
          }
        })
        .whereType<_Bookmark>()
        .toList();

    // ✅ Wait for databases to initialize
    await SurahDatabaseService.instance.initialize();

    // Load active khatma if passed
    KhatmaModel? khatma;
    if (widget.khatmaId != null) {
      khatma = await KhatmaService.load();
      if (khatma?.id != widget.khatmaId) {
        khatma = null; // Mismatch
      }
    }

    if (mounted) {
      setState(() {
        // ✅ Fix: Set _initialPage to the target page so PageView starts correctly
        final targetPage = widget.initialPage ?? saved;
        _initialPage = targetPage;
        _currentPage = targetPage;
        _bookmarks = bms;
        _activeKhatma = khatma;
        _isLoading = false;
      });

      // Check if tutorial should be shown
      _checkTutorial();
    }
  }

  Future<void> _saveLastPage(int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('qcf_mushaf_last_page', page);

    // Track khatma progress
    if (_activeKhatma != null) {
      final wasCompleted = _activeKhatma!.todayRemaining == 0;
      final updated = await KhatmaService.onPageRead(_activeKhatma!, page);
      if (mounted && updated != null) {
        setState(() {
          _activeKhatma = updated;
        });

        if (!wasCompleted && updated.todayRemaining == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocaleKeys.khatmaCompleted.tr,
                style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _bookmarks.map((b) => jsonEncode(b.toJson())).toList();
    await prefs.setStringList('qcf_bookmarks', jsonList);
  }

  String _getBookmarkColorName(int colorIndex) {
    switch (colorIndex) {
      case 0:
        return AppLocaleKeys.bookmarkColorNameRed.tr;
      case 1:
        return AppLocaleKeys.bookmarkColorNameBlue.tr;
      case 2:
        return AppLocaleKeys.bookmarkColorNameGreen.tr;
      case 3:
        return AppLocaleKeys.bookmarkColorNameOrange.tr;
      default:
        return '';
    }
  }

  String _getQuarterLabel(int quarterIndex) {
    switch (quarterIndex) {
      case 0:
        return AppLocaleKeys.quarterFirst.tr;
      case 1:
        return AppLocaleKeys.quarterSecond.tr;
      case 2:
        return AppLocaleKeys.quarterThird.tr;
      case 3:
        return AppLocaleKeys.quarterFourth.tr;
      default:
        return '';
    }
  }

  String _getQuarterOfPartLabel(int quarterIndex, int partNumber) {
    final quarterLabel = _getQuarterLabel(quarterIndex);
    final partLabel = AppLocaleKeys.partNameWithNumber.trParams({'number': partNumber.toString()});
    if (Get.locale?.languageCode == 'ar') {
      return '$quarterLabel من $partLabel';
    } else {
      return '$quarterLabel of $partLabel';
    }
  }

  Future<void> _checkTutorial() async {
    final shouldShow = await MushafTutorialOverlay.shouldShow();
    if (shouldShow && mounted) {
      // Delay to allow UI rendering
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _showTutorial = true;
          });
        }
      });
    }
  }

  Rect _getRect(GlobalKey key) {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final size = renderBox.size;
      final offset = renderBox.localToGlobal(Offset.zero);
      return Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);
    }
    return Rect.zero;
  }

  void _goToPage(int page) {
    setState(() {
      _initialPage = page;
      _currentPage = page;
      _isLoading = true;
    });
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) setState(() => _isLoading = false);
    });
    _saveLastPage(page);
  }

  void _goToPageWithHighlight(int page, int surah, int verse) {
    setState(() {
      _highlightSurah = surah;
      _highlightVerse = verse;
    });
    _goToPage(page);
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted)
        setState(() {
          _highlightSurah = null;
          _highlightVerse = null;
        });
    });
  }

  void _toggleUI() {
    setState(() => _showBottomBar = !_showBottomBar);
    if (_showBottomBar) {
      _ayahSheetJustClosed = false;
    }
    if (_showBottomBar) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    }
  }

  void _ensureUIVisible() {
    if (_showBottomBar) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      return;
    }
    setState(() => _showBottomBar = true);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  // ── Add Bookmark (called on verse long-press) ──
  void _onVerseLongPress(int surah, int verse) {
    final isDark =
        Provider.of<ThemeProvider>(context, listen: false).themeMode ==
            ThemeMode.dark;
    final page = getPageNumber(surah, verse);
    final surahName = getSurahNameArabic(surah);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0E241E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                AppLocaleKeys.addBookmark.tr,
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 6),
              Text(
                '$surahName — ${AppLocaleKeys.ayahNumberLabel.trParams({'number': verse.toString()})}  •  ${AppLocaleKeys.pageLabel.trParams({'page': page.toString()})}',
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: isDark ? Colors.white54 : Colors.black45),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocaleKeys.chooseBookmarkColor.tr,
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: isDark ? Colors.white60 : Colors.black54),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (i) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _addBookmark(surah, verse, page, i);
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _bmColors[i].withOpacity(0.15),
                            border: Border.all(color: _bmColors[i], width: 2.5),
                          ),
                          child: Icon(Icons.bookmark_rounded,
                              color: _bmColors[i], size: 28),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _getBookmarkColorName(i),
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              color: isDark ? Colors.white60 : Colors.black54),
                        ),
                      ],
                    ),
                  );
                }),
              ),
              SizedBox(height: MediaQuery.of(ctx).padding.bottom + 12),
            ],
          ),
        );
      },
    );
  }

  void _addBookmark(int surah, int verse, int page, int colorIndex) {
    // Check for duplicate with same color only (allow multiple colors per verse)
    final exists = _bookmarks.any((b) =>
        b.surah == surah && b.verse == verse && b.colorIndex == colorIndex);
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocaleKeys.bookmarkAlreadyExists.tr,
              style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: _bmColors[colorIndex],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    setState(() {
      _bookmarks.insert(
          0,
          _Bookmark(
            surah: surah,
            verse: verse,
            page: page,
            colorIndex: colorIndex,
          ));
    });
    _saveBookmarks();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocaleKeys.bookmarkSavedMessage.trParams({
            'surah': Get.locale?.languageCode == 'ar'
              ? getSurahNameArabic(surah)
              : getSurahNameEnglish(surah),
            'ayah': verse.toString(),
          }),
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: _bmColors[colorIndex],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _removeBookmark(int index) {
    setState(() => _bookmarks.removeAt(index));
    _saveBookmarks();
  }

  // ─────────────────────────────────────────────────────
  //  SURAH INDEX (Tabbed)
  // ─────────────────────────────────────────────────────
  // ── Arabic text normalization for search ──
  static String _normalizeArabic(String text) {
    return text
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ٱ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '') // Remove tashkeel
        .trim();
  }

  void _showSurahIndex() {
    final isDark =
        Provider.of<ThemeProvider>(context, listen: false).themeMode ==
            ThemeMode.dark;
    final accent = isDark ? const Color(0xFF2A8B68) : const Color(0xFF00695C);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, __) {
            return DefaultTabController(
              length: 5,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0E241E) : Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 6),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text(
                      AppLocaleKeys.indexTitle.tr,
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: accent),
                    ),
                    const SizedBox(height: 4),
                    TabBar(
                      labelColor: accent,
                      unselectedLabelColor:
                          isDark ? Colors.white38 : Colors.black38,
                      indicatorColor: accent,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                      unselectedLabelStyle:
                          const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                      tabs: [
                        Tab(text: AppLocaleKeys.tabSurah.tr),
                        Tab(text: AppLocaleKeys.tabJuz.tr),
                        Tab(text: AppLocaleKeys.tabHizb.tr),
                        Tab(text: AppLocaleKeys.tabQuarter.tr),
                        Tab(text: AppLocaleKeys.tabPage.tr),
                      ],
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildSearchableSurahList(isDark, accent, ctx),
                          _buildJuzList(isDark, accent, ctx),
                          _buildExactHizbList(isDark, accent, ctx),
                          _buildQuarterList(isDark, accent, ctx),
                          _buildPagePicker(isDark, accent, ctx),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchableSurahList(
      bool isDark, Color accent, BuildContext ctx) {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return _SurahSearchList(
          isDark: isDark,
          accent: accent,
          onSurahTap: (page) {
            Navigator.pop(ctx);
            _goToPage(page);
          },
        );
      },
    );
  }

  Widget _buildJuzList(bool isDark, Color accent, BuildContext ctx) {
    return ListView.builder(
      itemCount: 30,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemBuilder: (_, index) {
        final j = index + 1;
        final startPage = _juzStartPages[index];
        return ListTile(
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.1),
              border: Border.all(color: accent.withOpacity(0.3)),
            ),
            alignment: Alignment.center,
            child: Text('$j',
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: accent)),
          ),
          title: Text(AppLocaleKeys.juzLabel.trParams({'juz': j.toString()}),
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87)),
          subtitle: Text(AppLocaleKeys.hizbLabel.trParams({'hizb': '${j * 2 - 1} و ${j * 2}'}),
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.black38)),
          trailing: Text(AppLocaleKeys.pageLabel.trParams({'page': startPage.toString()}),
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black38)),
          onTap: () {
            Navigator.pop(ctx);
            _goToPage(startPage);
          },
        );
      },
    );
  }

  Widget _buildPagePicker(bool isDark, Color accent, BuildContext ctx) {
    final controller = TextEditingController();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Icon(Icons.menu_book_rounded,
              size: 56, color: accent.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(AppLocaleKeys.goToPage.tr,
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: accent),
            decoration: InputDecoration(
              hintText: '1 - 604',
              hintStyle: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  color: isDark ? Colors.white24 : Colors.black26),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.04),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            onSubmitted: (val) {
              final p = int.tryParse(val);
              if (p != null && p >= 1 && p <= 604) {
                Navigator.pop(ctx);
                _goToPage(p);
              }
            },
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                final p = int.tryParse(controller.text);
                if (p != null && p >= 1 && p <= 604) {
                  Navigator.pop(ctx);
                  _goToPage(p);
                }
              },
              child: Text(AppLocaleKeys.navigateButton.tr,
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
          Text('${AppLocaleKeys.currentPage.tr}: $_currentPage',
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  color: isDark ? Colors.white38 : Colors.black38)),
        ],
      ),
    );
  }

  Widget _buildExactHizbList(bool isDark, Color accent, BuildContext ctx) {
    return ListView.builder(
      itemCount: 60,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemBuilder: (_, index) {
        final hizbNum = index + 1;
        final juzNum = (index ~/ 2) + 1;
        final juzStart = _juzStartPages[juzNum - 1];
        final nextJuzStart = juzNum < 30 ? _juzStartPages[juzNum] : 605;
        final juzPages = nextJuzStart - juzStart;
        final isFirstHalf = index % 2 == 0;
        final hizbStart = juzStart + (isFirstHalf ? 0 : juzPages ~/ 2);

        return ListTile(
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.1),
              border: Border.all(color: accent.withOpacity(0.3)),
            ),
            alignment: Alignment.center,
            child: Text('$hizbNum',
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: accent)),
          ),
          title: Text(AppLocaleKeys.partNameWithNumber.trParams({'number': hizbNum.toString()}),
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87)),
          subtitle: Text(AppLocaleKeys.juzNameWithNumber.trParams({'number': juzNum.toString()}),
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.black38)),
          trailing: Text('ص $hizbStart',
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black38)),
          onTap: () {
            Navigator.pop(ctx);
            _goToPage(hizbStart);
          },
        );
      },
    );
  }

  Widget _buildQuarterList(bool isDark, Color accent, BuildContext ctx) {
    return ListView.builder(
      itemCount: 240,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemBuilder: (_, index) {
        final quarterNum = index + 1;
        final hizbNum = (index ~/ 4) + 1;
        final juzNum = (hizbNum - 1) ~/ 2 + 1;
        final juzStart = _juzStartPages[juzNum - 1];
        final nextJuzStart = juzNum < 30 ? _juzStartPages[juzNum] : 605;
        final juzPages = nextJuzStart - juzStart;
        final hizbIndexInJuz = (hizbNum - 1) % 2;
        final hizbStart = juzStart + (hizbIndexInJuz == 0 ? 0 : juzPages ~/ 2);
        final halfPages = juzPages ~/ 2;
        
        final quarterIndexInHizb = index % 4;
        final qPage = hizbStart + (halfPages * quarterIndexInHizb ~/ 4);

        return ListTile(
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.08),
              border: Border.all(color: accent.withOpacity(0.2)),
            ),
            alignment: Alignment.center,
            child: Text('${quarterIndexInHizb + 1}',
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: accent)),
          ),
          title: Text(_getQuarterOfPartLabel(quarterIndexInHizb, hizbNum),
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87)),
          subtitle: Text(AppLocaleKeys.juzNameWithNumber.trParams({'number': juzNum.toString()}),
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.black38)),
          trailing: Text('ص $qPage',
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black38)),
          onTap: () {
            Navigator.pop(ctx);
            _goToPage(qPage);
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────
  //  SEARCH
  // ─────────────────────────────────────────────────────
  void _showSearch() {
    final isDark =
        Provider.of<ThemeProvider>(context, listen: false).themeMode ==
            ThemeMode.dark;
    final accent = isDark ? const Color(0xFF2A8B68) : const Color(0xFF00695C);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _SearchSheet(
          isDark: isDark,
          accent: accent,
          onGoToPage: (page, surah, verse) {
            Navigator.pop(ctx);
            _goToPageWithHighlight(page, surah, verse);
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────
  //  BOOKMARKS (full history)
  // ─────────────────────────────────────────────────────
  void _showBookmarks() {
    final isDark =
        Provider.of<ThemeProvider>(context, listen: false).themeMode ==
            ThemeMode.dark;
    final accent = isDark ? const Color(0xFF2A8B68) : const Color(0xFF00695C);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.3,
              maxChildSize: 0.95,
              builder: (_, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0E241E) : Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 6),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bookmarks_rounded,
                              color: accent, size: 22),
                          const SizedBox(width: 8),
                          Text(AppLocaleKeys.bookmarksTitle.tr,
                              style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: accent)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${AppLocaleKeys.savedBookmarksCount.trParams({'count': _bookmarks.length.toString()})}  •  ${AppLocaleKeys.longPressToAddBookmark.tr}',
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: isDark ? Colors.white38 : Colors.black38),
                      ),
                      const Divider(height: 12),
                      if (_bookmarks.isEmpty)
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bookmark_border_rounded,
                                    size: 60,
                                    color: isDark
                                        ? Colors.white12
                                        : Colors.black12),
                                const SizedBox(height: 12),
                                Text(AppLocaleKeys.noSavedBookmarks.tr,
                                    style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 15,
                                        color: isDark
                                            ? Colors.white24
                                            : Colors.black26)),
                                const SizedBox(height: 6),
                                Text(AppLocaleKeys.longPressToAddBookmark.tr,
                                    style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white10
                                            : Colors.black12)),
                              ],
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: _bookmarks.length,
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 12),
                            itemBuilder: (_, i) {
                              final bm = _bookmarks[i];
                              final color = _bmColors[bm.colorIndex];
                              final surahName = getSurahNameArabic(bm.surah);

                              return Dismissible(
                                key: ValueKey(
                                    '${bm.surah}_${bm.verse}_${bm.createdAt}'),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(left: 20),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade400,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.delete_rounded,
                                      color: Colors.white),
                                ),
                                onDismissed: (_) {
                                  _removeBookmark(i);
                                  setSheetState(() {});
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: color.withOpacity(0.25),
                                        width: 1.5),
                                    color:
                                        color.withOpacity(isDark ? 0.06 : 0.04),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 2),
                                    leading: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: color.withOpacity(0.15),
                                      ),
                                      child: Icon(Icons.bookmark_rounded,
                                          color: color, size: 22),
                                    ),
                                    title: Text('${AppLocaleKeys.surahNameLabel.trParams({'name': surahName})} — ${AppLocaleKeys.ayahNumberLabel.trParams({'number': bm.verse.toString()})}',
                                        style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87)),
                                    subtitle: Text(
                                        '${AppLocaleKeys.pageLabel.trParams({'page': bm.page.toString()})}  •  ${AppLocaleKeys.juzLabel.trParams({'juz': _getJuzForPage(bm.page).toString()})}',
                                        style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 12,
                                            color: isDark
                                                ? Colors.white38
                                                : Colors.black45)),
                                    trailing: Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 16,
                                        color: isDark
                                            ? Colors.white24
                                            : Colors.black26),
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      _goToPageWithHighlight(
                                          bm.page, bm.surah, bm.verse);
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────
  //  SETTINGS
  // ─────────────────────────────────────────────────────
  void _showSettings() {
    final isDark =
        Provider.of<ThemeProvider>(context, listen: false).themeMode ==
            ThemeMode.dark;
    final accent = isDark ? const Color(0xFF2A8B68) : const Color(0xFF00695C);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer<QuranSettingsProvider>(
          builder: (context, qSettings, child) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0E241E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(AppLocaleKeys.mushafSettings.tr,
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: accent)),
                  ),
                  const SizedBox(height: 24),
                  
                  // ── لون خلفية المصحف ──
                  Text(
                    AppLocaleKeys.backgroundColor.tr,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: MushafThemePreset.values.length,
                      itemBuilder: (context, index) {
                        final preset = MushafThemePreset.values[index];
                        final themeColors = mushafThemeMap[preset]!;
                        final isSelected = qSettings.mushafTheme == preset;

                        return GestureDetector(
                          onTap: () {
                            qSettings.setMushafTheme(preset);
                          },
                          child: Container(
                            width: 65,
                            margin: const EdgeInsets.only(left: 12),
                            child: Column(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: themeColors.background,
                                    border: Border.all(
                                      color: isSelected 
                                          ? accent 
                                          : (isDark ? Colors.white24 : Colors.black12),
                                      width: isSelected ? 3 : 1,
                                    ),
                                    boxShadow: isSelected ? [
                                      BoxShadow(
                                        color: accent.withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      )
                                    ] : null,
                                  ),
                                  child: isSelected
                                      ? Icon(
                                          Icons.check_rounded,
                                          color: themeColors.isDarkBackground
                                              ? Colors.white
                                              : Colors.black87,
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  themeColors.nameKey.tr,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected 
                                        ? accent 
                                        : (isDark ? Colors.white54 : Colors.black54),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: accent),
                    title: Text(AppLocaleKeys.darkModeApp.tr,
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87)),
                    trailing: Switch(
                      value: isDark,
                      activeColor: accent,
                      onChanged: (_) {
                        themeProvider.toggleTheme();
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                  
                  SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
                ],
              ),
            );
          }
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark =
        Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark;
    final accent = isDark ? const Color(0xFF2A8B68) : const Color(0xFF00695C);

    if (_isLoading) {
      return Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF071814) : const Color(0xFFFFFBE0),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: accent),
              const SizedBox(height: 24),
              Text(
                AppLocaleKeys.initializingDatabases.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Cairo',
                    color: accent,
                    fontSize: 16,
                    height: 1.5),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
      );
    }

    // Highlight color for search
    final searchHighlight = isDark
        ? const Color(0xFF2A8B68).withOpacity(0.18)
        : const Color(0xFF00695C).withOpacity(0.15);

    final audio = Provider.of<QuranAudioProvider>(context);

    // Audio tracking for auto-scroll
    if (audio.hasActiveSession && audio.currentSurah != null && audio.currentAyah != null) {
      if (_lastPlayingSurah != audio.currentSurah || _lastPlayingAyah != audio.currentAyah) {
        _lastPlayingSurah = audio.currentSurah;
        _lastPlayingAyah = audio.currentAyah;
        
        final targetPage = getPageNumber(_lastPlayingSurah!, _lastPlayingAyah!);
        if (targetPage != _currentPage) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _goToPage(targetPage);
          });
        }
      }
    }

    // Verse background callback (search highlight + playing highlight + bookmark colors)
    Color? verseBackground(int surah, int verse) {
      // Search highlight takes priority
      if (_highlightSurah == surah && _highlightVerse == verse) {
        return searchHighlight;
      }
      
      // Playing/Active Ayah highlight — نظهر التظليل حتى أثناء الإيقاف المؤقت
      if (audio.hasActiveSession && audio.currentSurah == surah && audio.currentAyah == verse) {
        final qSettings = Provider.of<QuranSettingsProvider>(context, listen: false);
        final mColors = qSettings.mushafColors;
        // ألوان متناسقة تناسب الخلفية (شفافة قليلاً حتى لا تغطي الرسم)
        if (audio.isPlaying) {
          // لون أقوى أثناء التشغيل
          return mColors.isDarkBackground 
              ? const Color(0xFF81C784).withOpacity(0.25) // أخضر فاتح للوضع الداكن
              : const Color(0xFF2E7D32).withOpacity(0.15); // أخضر داكن للوضع الفاتح
        } else {
          // لون أخف أثناء الإيقاف المؤقت
          return mColors.isDarkBackground 
              ? const Color(0xFF81C784).withOpacity(0.12)
              : const Color(0xFF2E7D32).withOpacity(0.08);
        }
      }
      
      // Check bookmarks
      for (final bm in _bookmarks) {
        if (bm.surah == surah && bm.verse == verse) {
          return _bmColors[bm.colorIndex].withOpacity(isDark ? 0.14 : 0.12);
        }
      }
      return null;
    }

    const mushafPaper = Color(0xFFF7F0DA);
    const mushafInk = Color(0xFF23201A);
    const mushafOlive = Color(0xFF7B8A4A);

    // ── ألوان المصحف من الإعدادات ──
    final qSettings = Provider.of<QuranSettingsProvider>(context);
    final mColors = qSettings.mushafColors;

    final qcfTheme = QcfThemeData(
      verseTextColor: mColors.textColor,
      verseNumberColor: mColors.verseNumberColor,
      basmalaColor: mColors.textColor,
      headerTextColor: mColors.headerColor,
      pageBackgroundColor: mColors.background,
      verseHeight: 2.55,
      horizontalPadding: 2.0,
      verticalPadding: 2.0,
      verseBackgroundColor: verseBackground,
    );

    final surahForPage = _getSurahForPage(_currentPage);
    final surahName = getSurahNameArabic(surahForPage);
    final juzForPage = _getJuzForPage(_currentPage);
    final juzPageInfo = _getJuzPageInfo(_currentPage);
    final verseInfo = _getPageVerseInfo(_currentPage, surahForPage);
    final bool isThemeDark = mColors.isDarkBackground;

    return Scaffold(
      backgroundColor: qcfTheme.pageBackgroundColor,
      body: Stack(
        children: [
          // ---- المصحف ----
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                bottom: audio.hasActiveSession 
                    ? (_showBottomBar ? 150.0 : 80.0) 
                    : (_showBottomBar ? 80.0 : 0.0),
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _toggleUI,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double screenWidth = MediaQuery.of(context).size.width;
                    double scaleFactor = screenWidth / 412.0;
                    double dynamicSp = (1.06 * scaleFactor).clamp(0.8, 1.2);

                    return CustomPageviewQuran(
                      initialPageNumber: _initialPage,
                      theme: qcfTheme,
                      sp: dynamicSp,
                      onPageChanged: (page) {
                        setState(() {
                          _currentPage = page;
                          _highlightSurah = null;
                          _highlightVerse = null;
                        });
                        _saveLastPage(page);
                      },
                      onLongPress: _onVerseLongPress,
                      onTap: (surah, verse) async {
                        if (_ayahSheetJustClosed && _showBottomBar) {
                          setState(() => _ayahSheetJustClosed = false);
                          _toggleUI();
                          return;
                        }

                        _ensureUIVisible();
                        final isDk =
                            Provider.of<ThemeProvider>(context, listen: false)
                                    .themeMode ==
                                ThemeMode.dark;
                        final sName = quran_utils.getSurahNameArabic(surah);
                        final verseText = quran_utils.getVerse(surah, verse);
                        final pg = getPageNumber(surah, verse);
                        final existingColors = _bookmarks
                            .where((b) => b.surah == surah && b.verse == verse)
                            .map((b) => b.colorIndex)
                            .toSet();
                        await AyahDetailsSheet.show(
                          context,
                          surahNumber: surah,
                          ayahNumber: verse,
                          surahName: sName,
                          ayahText: verseText,
                          isDark: isDk,
                          existingBookmarkColors: existingColors,
                          onBookmark: (colorIndex) {
                            _addBookmark(surah, verse, pg, colorIndex);
                          },
                        );
                        if (mounted) {
                          setState(() => _ayahSheetJustClosed = true);
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ),

          // ════════════════════════════════════════════
          //  TOP BAR — شريط معلومات المصحف
          // ════════════════════════════════════════════
          AnimatedPositioned(
            key: _topBarKey,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top:
                _showBottomBar ? 0 : -(MediaQuery.of(context).padding.top + 60),
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 6,
                bottom: 6,
                left: 12,
                right: 12,
              ),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF0E241E) : mColors.infoBarBg)
                    .withOpacity(0.97),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(isThemeDark ? 0.2 : 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2)),
                ],
                border: Border(
                  bottom: BorderSide(
                    color: (isDark ? accent : mColors.headerColor).withOpacity(0.15),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // ── بحث (يسار) ──
                  GestureDetector(
                    key: _searchBtnKey,
                    onTap: _showSearch,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isDark ? accent : mColors.headerColor).withOpacity(0.08),
                      ),
                      child: Icon(Icons.search_rounded,
                          color: isDark ? accent : mColors.headerColor, size: 20),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // ── تنزيلات (مصحف) ──
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MushafDownloadsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isDark ? accent : mColors.headerColor).withOpacity(0.08),
                      ),
                      child: Icon(Icons.download_rounded,
                          color: isDark ? accent : mColors.headerColor, size: 20),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // ── إعدادات ──
                  GestureDetector(
                    key: _settingsBtnKey,
                    onTap: _showSettings,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isDark ? accent : mColors.headerColor).withOpacity(0.08),
                      ),
                      child: Icon(Icons.settings_rounded,
                          color: isDark ? accent : mColors.headerColor, size: 19),
                    ),
                  ),

                  const Spacer(),

                  // ── أيقونة المصحف (يمين) ──
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (isDark ? accent : mColors.headerColor).withOpacity(0.08),
                    ),
                    child: Icon(Icons.menu_book_rounded,
                        color: isDark ? accent : mColors.headerColor, size: 19),
                  ),
                ],
              ),
            ),
          ),

          // ════════════════════════════════════════════
          //  BOTTOM NAVBAR — المصحف + الفهرس + الختمة + العلامات
          // ════════════════════════════════════════════
          AnimatedPositioned(
            key: _bottomNavKey,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: _showBottomBar ? 0 : -120,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 6,
                top: 8,
              ),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF0E241E) : Colors.white)
                    .withOpacity(0.96),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, -3)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _modernNavItem(
                    icon: Icons.auto_stories_rounded,
                    label: AppLocaleKeys.navMushaf.tr,
                    isDark: isDark,
                    accent: accent,
                    isActive: true,
                    onTap: () {},
                  ),
                  _modernNavItem(
                    icon: Icons.list_alt_rounded,
                    label: AppLocaleKeys.navIndex.tr,
                    isDark: isDark,
                    accent: accent,
                    onTap: _showSurahIndex,
                  ),
                  _modernNavItem(
                    icon: Icons.check_circle_outline_rounded,
                    label: AppLocaleKeys.navKhatma.tr,
                    isDark: isDark,
                    accent: accent,
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const KhatmaProgressScreen(),
                          ));
                    },
                  ),
                  _modernNavItem(
                    icon: Icons.bookmark_rounded,
                    label: AppLocaleKeys.navBookmarks.tr,
                    isDark: isDark,
                    accent: accent,
                    badge:
                        _bookmarks.isNotEmpty ? '${_bookmarks.length}' : null,
                    onTap: _showBookmarks,
                  ),
                ],
              ),
            ),
          ),

          // ════════════════════════════════════════════
          //  MINI AUDIO PLAYER — مشغل صوتي مصغر
          // ════════════════════════════════════════════
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: _showBottomBar ? (MediaQuery.of(context).padding.bottom + 70) : 8,
            left: 0,
            right: 0,
            child: const MiniAudioPlayer(),
          ),

          // ════════════════════════════════════════════
          //  TUTORIAL OVERLAY
          // ════════════════════════════════════════════
          if (_showTutorial)
            Positioned.fill(
              child: MushafTutorialOverlay(
                isDark: isThemeDark,
                onComplete: () {
                  setState(() => _showTutorial = false);
                },
                quranPageRect: Rect.fromLTWH(
                  0,
                  MediaQuery.of(context).padding.top + 60,
                  MediaQuery.of(context).size.width,
                  MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      60 -
                      120,
                ),
                topBarRect: _getRect(_topBarKey),
                bottomNavRect: _getRect(_bottomNavKey),
                searchBtnRect: _getRect(_searchBtnKey),
                settingsBtnRect: _getRect(_settingsBtnKey),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────────────
  Widget _circleBtn(IconData icon, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.06),
        ),
        child:
            Icon(icon, color: isDark ? Colors.white : Colors.black87, size: 20),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool isDark, Color accent,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isDark ? Colors.white70 : Colors.black54, size: 24),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    color: isDark ? Colors.white60 : Colors.black54)),
          ],
        ),
      ),
    );
  }

  /// Modern bottom nav item with optional badge and active state
  Widget _modernNavItem({
    required IconData icon,
    required String label,
    required bool isDark,
    required Color accent,
    required VoidCallback onTap,
    bool isActive = false,
    String? badge,
  }) {
    final color =
        isActive ? accent : (isDark ? Colors.white54 : Colors.black45);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: isActive
                        ? accent.withOpacity(0.12)
                        : Colors.transparent,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                if (badge != null)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(badge,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.black : Colors.white,
                          )),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: color,
                )),
          ],
        ),
      ),
    );
  }

  int _getSurahForPage(int page) {
    try {
      for (int surah = 114; surah >= 1; surah--) {
        if (getPageNumber(surah, 1) <= page) return surah;
      }
    } catch (_) {}
    return 1;
  }

  int _getJuzForPage(int page) {
    for (int i = _juzStartPages.length - 1; i >= 0; i--) {
      if (page >= _juzStartPages[i]) return i + 1;
    }
    return 1;
  }

  /// حساب رقم الصفحة داخل الجزء وإجمالي صفحات الجزء
  (int pageInJuz, int totalJuzPages) _getJuzPageInfo(int page) {
    final juz = _getJuzForPage(page);
    final juzStart = _juzStartPages[juz - 1];
    final juzEnd = juz < 30 ? _juzStartPages[juz] - 1 : 604;
    final totalPages = juzEnd - juzStart + 1;
    final pageInJuz = page - juzStart + 1;
    return (pageInJuz, totalPages);
  }

  /// حساب أول آية في الصفحة الحالية وعدد آيات السورة
  (int firstVerse, int totalVerses) _getPageVerseInfo(int page, int surah) {
    // Find first verse on this page
    int firstVerse = 1;
    final totalVerses = quran_utils.getVerseCount(surah);
    for (int v = 1; v <= totalVerses; v++) {
      if (getPageNumber(surah, v) == page) {
        firstVerse = v;
        break;
      }
    }
    return (firstVerse, totalVerses);
  }

  String _toArabicNum(dynamic num) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return num.toString().split('').map((d) {
      final i = int.tryParse(d);
      return i != null ? digits[i] : d;
    }).join();
  }

  Widget _mushafInfoChip(String text, MushafThemeColors mColors) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: mColors.infoBarText,
      ),
    );
  }

  Widget _infoSeparator(MushafThemeColors mColors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: 1,
        height: 12,
        color: mColors.infoBarText.withOpacity(0.3),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  LIVE TIME WIDGET
// ─────────────────────────────────────────────────────
class _LiveTimeWidget extends StatefulWidget {
  final bool isDark;
  final Color accent;
  const _LiveTimeWidget({required this.isDark, required this.accent});

  @override
  State<_LiveTimeWidget> createState() => _LiveTimeWidgetState();
}

class _LiveTimeWidgetState extends State<_LiveTimeWidget> {
  late String _time;
  late final Stream<void> _ticker;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _ticker =
        Stream.periodic(const Duration(seconds: 30), (_) => _updateTime());
    _ticker.listen((_) {});
  }

  void _updateTime() {
    final now = DateTime.now();
    final h = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final m = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? 'م' : 'ص';
    if (mounted) {
      setState(() => _time = '$h:$m $ampm');
    } else {
      _time = '$h:$m $ampm';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.access_time_rounded,
            size: 15, color: widget.accent.withOpacity(0.6)),
        const SizedBox(width: 4),
        Text(_time,
            style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: widget.isDark ? Colors.white70 : Colors.black54)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────
//  SEARCH SHEET
// ─────────────────────────────────────────────────────
class _SearchSheet extends StatefulWidget {
  final bool isDark;
  final Color accent;
  final void Function(int page, int surah, int verse) onGoToPage;

  const _SearchSheet(
      {required this.isDark, required this.accent, required this.onGoToPage});

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final TextEditingController _controller = TextEditingController();
  Map<String, dynamic>? _results;

  void _doSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() => _results = null);
      return;
    }
    final normalized = _normalizeArabic(query.trim());
    // Don't search if normalized query is too short
    if (normalized.length < 2) {
      setState(() => _results = null);
      return;
    }
    // Run search asynchronously to avoid UI jank
    Future.microtask(() {
      final res = _customSearch(normalized);
      if (mounted) setState(() => _results = res);
    });
  }

  Map<String, dynamic> _customSearch(String normalizedQuery) {
    List<Map<String, dynamic>> results = [];
    int count = 0;

    for (int s = 1; s <= 114; s++) {
      final verseCount = quran_utils.getVerseCount(s);
      for (int v = 1; v <= verseCount; v++) {
        final verseText = quran_utils.getVerse(s, v, verseEndSymbol: false);
        final normalizedVerse = _normalizeArabic(verseText);

        if (normalizedVerse.contains(normalizedQuery)) {
          results.add({'suraNumber': s, 'verseNumber': v});
          count++;
        }
        if (count >= 500) break;
      }
      if (count >= 500) break;
    }
    return {'occurences': count, 'result': results};
  }

  String _normalizeArabic(String text) {
    return text
        // Remove tashkeel (Arabic diacritics)
        .replaceAll(RegExp('[\u064B-\u065F\u0670\u06D6-\u06ED]'), '')
        // Unify hamza variants to plain alef
        .replaceAll('\u0623', '\u0627') // أ → ا
        .replaceAll('\u0625', '\u0627') // إ → ا
        .replaceAll('\u0622', '\u0627') // آ → ا
        .replaceAll('\u0671', '\u0627') // ٱ → ا
        // Unify ya/alef maksura
        .replaceAll('\u0649', '\u064A') // ى → ي
        // Unify ta marbuta
        .replaceAll('\u0629', '\u0647') // ة → ه
        // Unify hamza carriers
        .replaceAll('\u0624', '\u0648') // ؤ → و
        .replaceAll('\u0626', '\u064A') // ئ → ي
        // Remove tatweel and isolated hamza
        .replaceAll('\u0640', '') // ـ tatweel
        .replaceAll('\u0621', '') // ء hamza
        .trim();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF0E241E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: widget.isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(AppLocaleKeys.searchInQuran.tr,
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: widget.accent)),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: TextField(
                  controller: _controller,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      color: widget.isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: AppLocaleKeys.searchQuranHint.tr,
                    hintTextDirection: TextDirection.rtl,
                    hintStyle: TextStyle(
                        fontFamily: 'Cairo',
                        color: widget.isDark ? Colors.white30 : Colors.black26),
                    prefixIcon: Icon(Icons.search, color: widget.accent),
                    filled: true,
                    fillColor: widget.isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.04),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: _doSearch,
                  onChanged: (v) {
                    if (v.length >= 2) _doSearch(v);
                  },
                ),
              ),
              if (_results != null) ...[
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(children: [
                    Text(AppLocaleKeys.searchResultsCount.trParams({'count': (_results!['occurences'] ?? 0).toString()}),
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            color: widget.isDark
                                ? Colors.white54
                                : Colors.black45)),
                  ]),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: (_results!['result'] as List?)?.length ?? 0,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemBuilder: (_, i) {
                      final item = (_results!['result'] as List)[i];
                      final surah = item['suraNumber'] ?? 1;
                      final verse = item['verseNumber'] ?? 1;
                      final page = getPageNumber(surah, verse);
                      final surahName = getSurahNameArabic(surah);
                      return InkWell(
                        onTap: () => widget.onGoToPage(page, surah, verse),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: widget.isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: widget.isDark
                                    ? Colors.white12
                                    : Colors.black12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: widget.accent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('${AppLocaleKeys.surahNameLabel.trParams({'name': surahName})} : $verse',
                                        style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: widget.accent)),
                                  ),
                                  const Spacer(),
                                  Text(AppLocaleKeys.pageLabel.trParams({'page': page.toString()}),
                                      style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 11,
                                          color: widget.isDark
                                              ? Colors.white38
                                              : Colors.black38)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                quran_utils.getVerse(surah, verse,
                                    verseEndSymbol: false),
                                textAlign: TextAlign.justify,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontFamily: 'UthmanTN',
                                  fontSize: 18,
                                  color: widget.isDark
                                      ? Colors.white.withOpacity(0.9)
                                      : Colors.black87,
                                  height:
                                      2.2, // Increased line height to prevent overlapping
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ] else
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_rounded,
                            size: 60,
                            color: widget.isDark
                                ? Colors.white12
                                : Colors.black12),
                        const SizedBox(height: 12),
                        Text(AppLocaleKeys.searchQuranSub.tr,
                            style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                color: widget.isDark
                                    ? Colors.white24
                                    : Colors.black26)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────
//  SURAH SEARCH LIST (with Arabic normalization)
// ─────────────────────────────────────────────────────
class _SurahSearchList extends StatefulWidget {
  final bool isDark;
  final Color accent;
  final void Function(int page) onSurahTap;

  const _SurahSearchList({
    required this.isDark,
    required this.accent,
    required this.onSurahTap,
  });

  @override
  State<_SurahSearchList> createState() => _SurahSearchListState();
}

class _SurahSearchListState extends State<_SurahSearchList> {
  final TextEditingController _searchController = TextEditingController();
  List<int> _filteredSurahs = List.generate(114, (i) => i + 1);

  static String _normalizeArabic(String text) {
    return text
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ٱ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll('ء', '') // Remove isolated Hamza
        .replaceAll(RegExp(r'[^\u0621-\u064A\s0-9]'), '')
        .trim();
  }

  void _onSearchChanged(String query) {
    final normalized = _normalizeArabic(query);
    if (normalized.isEmpty) {
      setState(() => _filteredSurahs = List.generate(114, (i) => i + 1));
      return;
    }
    setState(() {
      _filteredSurahs = List.generate(114, (i) => i + 1).where((s) {
        final name = _normalizeArabic(getSurahNameArabic(s));
        return name.contains(normalized);
      }).toList();
    });
  }

  String _getFirstVersePreview(int surah) {
    try {
      final verse = quran_utils.getVerse(surah, 1);
      if (verse.length > 70) return '${verse.substring(0, 70)}...';
      return verse;
    } catch (_) {
      return '';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Search Field ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              color: widget.isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: AppLocaleKeys.searchSurahHint.tr,
              hintTextDirection: TextDirection.rtl,
              hintStyle: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: widget.isDark ? Colors.white30 : Colors.black26,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: widget.isDark ? Colors.white30 : Colors.black26,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear,
                          size: 18,
                          color:
                              widget.isDark ? Colors.white30 : Colors.black26),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: widget.isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ),

        // ── Results ──
        Expanded(
          child: _filteredSurahs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off_rounded,
                          size: 48,
                          color:
                              widget.isDark ? Colors.white12 : Colors.black12),
                      const SizedBox(height: 8),
                      Text(AppLocaleKeys.noSearchResults.tr,
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              color: widget.isDark
                                  ? Colors.white24
                                  : Colors.black26)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredSurahs.length,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemBuilder: (_, index) {
                    final s = _filteredSurahs[index];
                    final name = getSurahNameArabic(s);
                    final page = getPageNumber(s, 1);
                    final count = getVerseCount(s);
                    final placeRaw = getPlaceOfRevelation(s).toLowerCase();
                    final place = placeRaw.contains('makkah') || placeRaw.contains('مكية') 
                        ? AppLocaleKeys.makkah.tr 
                        : AppLocaleKeys.madinah.tr;
                    final versePreview = _getFirstVersePreview(s);

                    return ListTile(
                      dense: true,
                      leading: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: widget.accent.withOpacity(0.4)),
                        ),
                        alignment: Alignment.center,
                        child: Text('$s',
                            style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: widget.accent)),
                      ),
                      title: Text(name,
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: widget.isDark
                                  ? Colors.white
                                  : Colors.black87)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$place  •  ${AppLocaleKeys.ayahsCount.trParams({'count': count.toString()})}',
                              style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 11,
                                  color: widget.isDark
                                      ? Colors.white38
                                      : Colors.black38)),
                          if (versePreview.isNotEmpty)
                            Text(
                              versePreview,
                              textDirection: TextDirection.rtl,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'UthmanTN',
                                fontSize: 13,
                                height: 1.8,
                                color: widget.isDark
                                    ? Colors.white.withOpacity(0.3)
                                    : Colors.black.withOpacity(0.3),
                              ),
                            ),
                        ],
                      ),
                      trailing: Text(AppLocaleKeys.pageLabel.trParams({'page': page.toString()}),
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: widget.isDark
                                  ? Colors.white38
                                  : Colors.black38)),
                      onTap: () => widget.onSurahTap(page),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
