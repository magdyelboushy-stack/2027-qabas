import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mihrab/core/translations/app_locale_keys.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:quran_library/quran.dart';
import 'package:quran/quran.dart' as quran_utils;

// تأكد من أن مسارات الاستيراد هذه صحيحة حسب هيكل مشروعك
import '../../../../core/theme/theme_provider.dart';
import '../widgets/ayah_options_sheet.dart';
import '../widgets/download_manager_sheet.dart';

class MushafScreen extends StatefulWidget {
  final int initialPage;
  final AyahModel? initialAyah;
  final VoidCallback? onBack; // ✅ Callback to go back

  const MushafScreen({
    super.key,
    this.initialPage = 1,
    this.initialAyah,
    this.onBack,
  });

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  int _currentPage = 1; // ✅ Track current page

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // ✅ FORCE PRE-SET CONTROLLER INITIAL PAGE
    // This ensures PageView builds with the correct page immediately,
    // avoiding race conditions with onPageChanged(0).
    try {
      if (Get.isRegistered<QuranCtrl>()) {
        Get.find<QuranCtrl>().jumpToPage(widget.initialPage - 1);
      }
    } catch (e) {
      debugPrint("Error pre-setting page controller: $e");
    }

    // ✅ If page is default (1), try to load last read page
    if (widget.initialPage == 1) {
      _loadLastReadPage();
    }
  }

  Future<void> _loadLastReadPage() async {
    // Small delay to ensure GetX is ready if coming straight from splash
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      if (Get.isRegistered<QuranCtrl>()) {
        final quranCtrl = Get.find<QuranCtrl>();
        // quranCtrl.lastPage is 1-based
        if (quranCtrl.lastPage > 1) {
          setState(() {
            _currentPage = quranCtrl.lastPage;
          });
          debugPrint("Resuming from page: $_currentPage");
        }
      }
    } catch (e) {
      debugPrint("Error loading last read from controller: $e");
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  bool _isFullScreen = true; // ✅ Default to true (Hidden controls) as requested

  @override
  Widget build(BuildContext context) {
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final Color paperColor =
        isDark ? const Color(0xff1E1E1E) : const Color(0xFFFFFBE0);
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color highlightColor =
        isDark ? Colors.cyanAccent : const Color(0xFF8B6F47);
    final Color iconColor = isDark ? Colors.white70 : const Color(0xFF8B6F47);

    return Scaffold(
      backgroundColor: paperColor,
      // ✅ Hide default AppBar
      body: Stack(
        children: [
          // 1. Main Content (Quran Library) - Always Full Screen
          QuranLibraryScreen(
            pageIndex: _currentPage - 1,
            isDark: isDark,
            backgroundColor: Colors.transparent,
            textColor: textColor,
            ayahIconColor: highlightColor,
            ayahSelectedBackgroundColor: highlightColor.withOpacity(0.3),
            ayahSelectedFontColor: textColor,
            isFontsLocal: true,
            fontsName: 'UthmanTN',

            useDefaultAppBar: false,
            withPageView: true,
            showAyahBookmarkedIcon: false,

            // ✅ Sync State: When library toggles (tapped), we toggle here too
            onPagePress: () {
              setState(() {
                _isFullScreen = !_isFullScreen;
              });
            },

            onPageChanged: (page) {
              if (_currentPage != page + 1) {
                setState(() {
                  _currentPage = page + 1;
                });
              }
            },
            // ✅ Long press on ayah → Show options (Audio, Repeat, Tafsir)
            onAyahLongPress: (details, ayah) {
              AyahOptionsSheet.show(
                context,
                surahNumber: ayah.surahNumber ?? 1,
                ayahNumber: ayah.ayahNumber ?? 1,
                surahName: (ayah.arabicName ?? 'سورة')
                    .replaceAll(RegExp(r'[0-9]'), '')
                    .trim(),
                ayahText: ayah.text,
                isDark: isDark,
              );
            },
            // ✅ Custom menu item → Also opens options sheet
            anotherMenuChild: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.headphones, size: 16, color: highlightColor),
                const SizedBox(width: 4),
                Text(
                  'تشغيل / تفسير',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            anotherMenuChildOnTap: (ayah) {
              AyahOptionsSheet.show(
                context,
                surahNumber: ayah.surahNumber ?? 1,
                ayahNumber: ayah.ayahNumber ?? 1,
                surahName: (ayah.arabicName ?? 'سورة')
                    .replaceAll(RegExp(r'[0-9]'), '')
                    .trim(),
                ayahText: ayah.text,
                isDark: isDark,
              );
            },
          ),

          // 2. Custom Overlay AppBar (Top Controls)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            // ✅ Controls logic:
            // If _isFullScreen is TRUE (User wants reading mode) -> Top is -100 (Hidden)
            // If _isFullScreen is FALSE (User tapped to see menu) -> Top is 0 (Visible)
            top: _isFullScreen ? -100 : 0,
            left: 0,
            right: 0,
            child: SafeArea(
              // Keep SafeArea for status bar padding
              bottom: false,
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  // ✅ Gradient to make text readable but not blocky
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      (isDark ? Colors.black : Colors.white).withOpacity(0.95),
                      (isDark ? Colors.black : Colors.white).withOpacity(0.8),
                      (isDark ? Colors.black : Colors.white).withOpacity(0.0),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
                child: Row(
                  children: [
                    // Back Button
                    widget.onBack != null
                        ? IconButton(
                            icon: Icon(Icons.home_rounded, color: iconColor),
                            onPressed: widget.onBack,
                          )
                        : IconButton(
                            icon: Icon(Icons.arrow_back, color: iconColor),
                            onPressed: () => Navigator.pop(context),
                          ),

                    const Spacer(),

                    const Spacer(),

                    // ✅ Current Surah Name (Moved here from internal header)
                    if (!_isFullScreen)
                      Builder(builder: (context) {
                        // Get real-time surah name
                        try {
                          if (Get.isRegistered<QuranCtrl>()) {
                            final ctrl = Get.find<QuranCtrl>();
                            final surah =
                                ctrl.getCurrentSurahByPage(_currentPage);
                            String name = surah.arabicName ?? 'سورة';
                            name = name.replaceAll(RegExp(r'[0-9]'), '').trim();
                            return Text(
                              name,
                              style: TextStyle(
                                  fontSize: 18,
                                  color: iconColor,
                                  fontWeight: FontWeight.bold),
                            );
                          }
                        } catch (e) {
                          return const SizedBox.shrink();
                        }
                        return const SizedBox.shrink();
                      }),

                    const Spacer(),

                    // Search
                    IconButton(
                      icon: Icon(Icons.search, color: iconColor),
                      onPressed: () => _showSearchDialog(context, isDark),
                    ),

                    // Download Manager
                    IconButton(
                      icon: Icon(Icons.download_for_offline_outlined,
                          color: iconColor),
                      onPressed: () =>
                          DownloadManagerSheet.show(context, isDark: isDark),
                    ),

                    // Surahs List
                    IconButton(
                      icon: Icon(Icons.menu_book_rounded, color: iconColor),
                      onPressed: () => _showSurahsList(context, isDark),
                    ),

                    // Bookmarks
                    IconButton(
                      icon: Icon(Icons.bookmark_border, color: iconColor),
                      onPressed: () => _showBookmarksList(context, isDark),
                    ),

                    // Settings
                    IconButton(
                      icon: Icon(Icons.settings_outlined, color: iconColor),
                      onPressed: () => _showSettingsDialog(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show Settings Dialog
  void _showSettingsDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final quranCtrl = Get.find<QuranCtrl>();

    showModalBottomSheet(
      context: context,
      backgroundColor: themeProvider.themeMode == ThemeMode.dark
          ? const Color(0xff1E1E1E)
          : const Color(0xFFFFFBE0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "إعدادات القراءة",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.themeMode == ThemeMode.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                const Divider(),
                const SizedBox(height: 10),

                // Theme Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "الوضع الليلي",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.themeMode == ThemeMode.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    Switch(
                      value: themeProvider.themeMode == ThemeMode.dark,
                      activeColor: const Color(0xFF8B6F47),
                      onChanged: (value) {
                        themeProvider.toggleTheme();
                        setModalState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Font Size Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "حجم الخط",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.themeMode == ThemeMode.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    Text(
                      "${(quranCtrl.state.scaleFactor.value * 100).toInt()}%",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Obx(() => Slider(
                      value: quranCtrl.state.scaleFactor.value,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      activeColor: const Color(0xFF8B6F47),
                      label:
                          "${(quranCtrl.state.scaleFactor.value * 100).toInt()}%",
                      onChanged: (value) {
                        quranCtrl.state.scaleFactor.value = value;
                        quranCtrl.update(); // Trigger rebuild in library
                      },
                    )),

                const SizedBox(height: 10),
                const Divider(),

                // Font Download Option
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    "تحميل الخطوط",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.themeMode == ThemeMode.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (ctx) => Dialog(
                        backgroundColor:
                            themeProvider.themeMode == ThemeMode.dark
                                ? const Color(0xff1E1E1E)
                                : Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        child: QuranLibrary().getFontsDownloadWidget(
                          ctx,
                          isDark: themeProvider.themeMode == ThemeMode.dark,
                          isFontsLocal:
                              quranCtrl.state.isDownloadedV2Fonts.value,
                          // Note: We might need to fetch isFontsLocal status if important, but widget often handles it.
                          // Checking quran_library_screen usage: isFontsLocal: widget.isFontsLocal
                          // Here we don't have widget.isFontsLocal easily.
                          // However, getFontsDownloadWidget allows isFontsLocal to be nullable/default.
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        });
      },
    );
  }

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
    604
  ];

  // Static list of Surah Names (Clean Arabic for Cairo Font)
  final List<String> _surahNames = [
    "الفاتحة",
    "البقرة",
    "آل عمران",
    "النساء",
    "المائدة",
    "الأنعام",
    "الأعراف",
    "الأنفال",
    "التوبة",
    "يونس",
    "هود",
    "يوسف",
    "الرعد",
    "إبراهيم",
    "الحجر",
    "النحل",
    "الإسراء",
    "الكهف",
    "مريم",
    "طه",
    "الأنبياء",
    "الحج",
    "المؤمنون",
    "النور",
    "الفرقان",
    "الشعراء",
    "النمل",
    "القصص",
    "العنكبوت",
    "الروم",
    "لقمان",
    "السجدة",
    "الأحزاب",
    "سبأ",
    "فاطر",
    "يس",
    "الصافات",
    "ص",
    "الزمر",
    "غافر",
    "فصلت",
    "الشورى",
    "الزخرف",
    "الدخان",
    "الجاثية",
    "الأحقاف",
    "محمد",
    "الفتح",
    "الحجرات",
    "ق",
    "الذاريات",
    "الطور",
    "النجم",
    "القمر",
    "الرحمن",
    "الواقعة",
    "الحديد",
    "المجادلة",
    "الحشر",
    "الممتحنة",
    "الصف",
    "الجمعة",
    "المنافقون",
    "التغابن",
    "الطلاق",
    "التحريم",
    "الملك",
    "القلم",
    "الحاقة",
    "المعارج",
    "نوح",
    "الجن",
    "المزمل",
    "المدثر",
    "القيامة",
    "الإنسان",
    "المرسلات",
    "النبأ",
    "النازعات",
    "عبس",
    "التكوير",
    "الانفطار",
    "المطففين",
    "الانشقاق",
    "البروج",
    "الطارق",
    "الأعلى",
    "الغاشية",
    "الفجر",
    "البلد",
    "الشمس",
    "الليل",
    "الضحى",
    "الشرح",
    "التين",
    "العلق",
    "القدر",
    "البينة",
    "الزلزلة",
    "العاديات",
    "القارعة",
    "التكاثر",
    "العصر",
    "الهمزة",
    "الفيل",
    "قريش",
    "الماعون",
    "الكوثر",
    "الكافرون",
    "النصر",
    "المسد",
    "الإخلاص",
    "الفلق",
    "الناس"
  ];

  // Show Surahs list dialog
  void _showSurahsList(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          isDark ? const Color(0xff1E1E1E) : const Color(0xFFFFFBE0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                "السور",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: _surahNames.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF8B6F47),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                      title: Text(
                        _surahNames[index],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        try {
                          // ✅ STRICT STATIC NAVIGATION
                          // We rely on the state update to trigger the jump in QuranLibraryScreen
                          // This prevents "double jumping" or scrolling wars

                          int targetPage = 1;
                          if (index < _surahStartPages.length) {
                            targetPage = _surahStartPages[index];
                          }

                          // Update local state is enough - the QuranLibraryScreen will detect the change
                          setState(() {
                            _currentPage = targetPage;
                          });

                          // Perform the jump (0-based) explicitly for speed
                          Get.find<QuranCtrl>().jumpToPage(targetPage - 1);
                        } catch (e) {
                          debugPrint("Error jumping to surah: $e");
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Show Bookmarks list dialog
  void _showBookmarksList(BuildContext context, bool isDark) {
    final bookmarksCtrl = BookmarksCtrl.instance;
    final allBookmarks =
        bookmarksCtrl.bookmarks.values.expand((list) => list).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor:
          isDark ? const Color(0xff1E1E1E) : const Color(0xFFFFFBE0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "العلامات المحفوظة",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    "${allBookmarks.length}",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: allBookmarks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bookmark_border,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "لا توجد علامات محفوظة",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "اضغط على رقم أي آية لحفظها",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: allBookmarks.length,
                        itemBuilder: (context, index) {
                          final bookmark = allBookmarks[index];
                          final bookmarkColor = Color(bookmark.colorCode);

                          return Dismissible(
                            key: Key(bookmark.id.toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 20),
                              color: Colors.red,
                              child:
                                  const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (direction) {
                              bookmarksCtrl.removeBookmark(bookmark.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم حذف العلامة',
                                      style: TextStyle()),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: ListTile(
                              leading: Container(
                                width: 4,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: bookmarkColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              title: Text(
                                "${bookmark.name} - آية ${bookmark.ayahNumber}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                "الصفحة ${bookmark.page}",
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                onPressed: () {
                                  bookmarksCtrl.removeBookmark(bookmark.id);
                                  Navigator.pop(context);
                                  _showBookmarksList(context, isDark);
                                },
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                try {
                                  // Update local state immediately
                                  setState(() {
                                    _currentPage = bookmark.page;
                                  });
                                  // Jump using controller (0-based)
                                  Get.find<QuranCtrl>()
                                      .jumpToPage(bookmark.page - 1);
                                } catch (e) {
                                  debugPrint("Error: $e");
                                  QuranLibrary().jumpToPage(bookmark.page);
                                }
                              },
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
  }

  // Search Dialog
  void _showSearchDialog(BuildContext context, bool isDark) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _QuranSearchScreen(
          isDark: isDark,
          onResultTap: (int pageNumber) {
            setState(() {
              _currentPage = pageNumber;
            });
            final quranCtrl = Get.find<QuranCtrl>();
            quranCtrl.jumpToPage(pageNumber - 1);
          },
        ),
      ),
    );
  }
}

// Full Search Results Screen
class _QuranSearchScreen extends StatefulWidget {
  final bool isDark;
  final Function(int) onResultTap;

  const _QuranSearchScreen({
    required this.isDark,
    required this.onResultTap,
  });

  @override
  State<_QuranSearchScreen> createState() => _QuranSearchScreenState();
}

class _QuranSearchScreenState extends State<_QuranSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<AyahModel> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _performSearch(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    // Debounce: wait 500ms after user stops typing
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      setState(() {
        _isSearching = true;
      });

      // Perform search asynchronously
      final normalizedQuery = _normalizeArabic(query.trim().toLowerCase());
      debugPrint(
          '🔍 Searching for: "$query" -> normalized: "$normalizedQuery"');
      final results = <AyahModel>[];
      const maxResults = 100; // Limit results for performance
      bool loggedSample = false;

      // Search through all 604 pages (0-indexed: 0-603)
      for (int page = 0; page < 604 && results.length < maxResults; page++) {
        try {
          final pageAyahs =
              QuranLibrary().getPageAyahsByPageNumber(pageNumber: page);
          for (var ayah in pageAyahs) {
            if (results.length >= maxResults) break;

            // Check if ayah text matches
            final normalizedText = _normalizeArabic(ayah.text.toLowerCase());

            // Log first ayah as sample
            if (!loggedSample && page == 0) {
              debugPrint(
                  '📄 Sample ayah text: "${ayah.text.substring(0, min(30, ayah.text.length))}"');
              debugPrint(
                  '📄 Normalized: "${normalizedText.substring(0, min(30, normalizedText.length))}"');
              loggedSample = true;
            }

            if (normalizedText.contains(normalizedQuery)) {
              results.add(ayah);
              if (results.length == 1) {
                debugPrint(
                    '✅ First match found on page $page: ${ayah.text.substring(0, 50)}...');
              }
              continue;
            }

            // Check if surah name matches
            final surahName = ayah.arabicName ?? '';
            final normalizedSurahName =
                _normalizeArabic(surahName.toLowerCase());
            if (normalizedSurahName.contains(normalizedQuery)) {
              results.add(ayah);
            }
          }
        } catch (e) {
          debugPrint('❌ Error on page $page: $e');
        }

        // Yield to UI every 50 pages to prevent freeze
        if (page % 50 == 0) {
          await Future.delayed(Duration.zero);
        }
      }

      debugPrint('🔍 Search complete. Found ${results.length} results');

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  // Get unique surah matches
  List<Map<String, dynamic>> _getSurahMatches() {
    if (_searchController.text.trim().isEmpty) return [];

    final normalizedQuery =
        _normalizeArabic(_searchController.text.trim().toLowerCase());
    final surahs = <Map<String, dynamic>>[];

    // Get all surah names and search through them
    final allSurahs = QuranLibrary().getAllSurahs();

    for (int i = 0; i < allSurahs.length; i++) {
      final surahName = allSurahs[i];
      final normalizedSurahName = _normalizeArabic(surahName.toLowerCase());

      if (normalizedSurahName.contains(normalizedQuery)) {
        final surahNumber = i + 1; // Surah numbers are 1-indexed
        final firstPage = quran_utils.getPageNumber(surahNumber, 1);

        // Clean surah name: remove 'سورة' prefix and numbers
        String cleanName = surahName
            .replaceAll(RegExp(r'سورة\s*'), '')
            .replaceAll(RegExp(r'[0-9]'), '')
            .trim();

        surahs.add({
          'name': cleanName,
          'number': surahNumber,
          'page': firstPage,
        });
      }
    }

    return surahs;
  }

  // Get ayah matches (all ayahs that match the query in their text)
  List<AyahModel> _getAyahMatches() {
    if (_searchController.text.trim().isEmpty) return [];

    final normalizedQuery =
        _normalizeArabic(_searchController.text.trim().toLowerCase());

    return _searchResults.where((ayah) {
      final normalizedAyahText = _normalizeArabic(ayah.text.toLowerCase());
      return normalizedAyahText.contains(normalizedQuery);
    }).toList();
  }

  // Normalize Arabic text by removing diacritics and normalizing letter variations
  String _normalizeArabic(String text) {
    // Remove diacritics and Quranic marks
    // \u064B-\u065F: Tashkeel (Fathatan, Dammatan, etc.)
    // \u0670: Superscript Alef
    // \u06D6-\u06DC: Quranic Pause Marks
    // \u06DF-\u06E8: Quranic Marks
    // \u06EA-\u06ED: Quranic Marks
    String normalized = text.replaceAll(
        RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED]'),
        '');

    // Normalize Alef variations (أ إ آ ا ٱ) to ا
    // Added \u0671 (Alef Wasla)
    normalized = normalized.replaceAll(RegExp(r'[أإآٱ]'), 'ا');

    // Normalize Hamza variations (ؤ ئ ء) to و ي (or remove)
    normalized = normalized.replaceAll('ؤ', 'و');
    normalized = normalized.replaceAll('ئ', 'ي');
    normalized = normalized.replaceAll('ء', '');

    // Normalize Taa Marbuta ة to Haa ه (so both ة and ه match)
    normalized = normalized.replaceAll('ة', 'ه');

    return normalized;
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        widget.isDark ? const Color(0xff1E1E1E) : const Color(0xFFFFFBE0);
    final textColor = widget.isDark ? Colors.white : Colors.black87;
    final iconColor = widget.isDark ? Colors.white70 : const Color(0xFF8B6F47);
    final cardColor =
        widget.isDark ? Colors.white.withOpacity(0.05) : Colors.white;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: iconColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'البحث في القرآن',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: AppLocaleKeys.searchSurahOrAyah.tr,
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: iconColor),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: _performSearch,
              ),
            ),

            // Results
            Expanded(
              child: _isSearching
                  ? Center(
                      child: CircularProgressIndicator(
                        color: widget.isDark
                            ? Colors.cyanAccent
                            : const Color(0xFF8B6F47),
                      ),
                    )
                  : _searchResults.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchController.text.isEmpty
                                    ? 'ابدأ البحث عن آية أو سورة'
                                    : 'لم يتم العثور على نتائج',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            // Surah Names Section
                            if (_getSurahMatches().isNotEmpty) ...[
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'السور',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              ..._getSurahMatches().map((surahInfo) {
                                return Card(
                                  color: cardColor,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      widget.onResultTap(
                                          surahInfo['page'] as int);
                                      Navigator.pop(context);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: widget.isDark
                                                  ? Colors.cyanAccent
                                                      .withOpacity(0.2)
                                                  : const Color(0xFF8B6F47)
                                                      .withOpacity(0.2),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${surahInfo['number']}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: widget.isDark
                                                      ? Colors.cyanAccent
                                                      : const Color(0xFF8B6F47),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              surahInfo['name'] as String,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: textColor,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 16),
                            ],

                            // Ayah Results Section
                            if (_getAyahMatches().isNotEmpty) ...[
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'الآيات',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              ..._getAyahMatches().map((ayah) {
                                // Use original surah name, just remove numbers
                                final surahName = (ayah.arabicName ?? 'سورة')
                                    .replaceAll(RegExp(r'\d+'), '')
                                    .trim();

                                return Card(
                                  color: cardColor,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      widget.onResultTap(ayah.page);
                                      Navigator.pop(context);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: widget.isDark
                                                      ? Colors.cyanAccent
                                                          .withOpacity(0.2)
                                                      : const Color(0xFF8B6F47)
                                                          .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  surahName,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: widget.isDark
                                                        ? Colors.cyanAccent
                                                        : const Color(
                                                            0xFF8B6F47),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'آية ${ayah.ayahNumber}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                'صفحة ${ayah.page}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            ayah.text,
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: textColor,
                                              height: 1.8,
                                            ),
                                            textAlign: TextAlign.justify,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
