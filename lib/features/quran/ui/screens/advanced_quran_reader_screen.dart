import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:quran_library/quran.dart';
import '../../../../core/theme/theme_provider.dart';
// import '../../../../core/services/global_audio_manager.dart'; // ❌ Disabled - Not implemented yet
// import '../widgets/integrated_audio_player.dart'; // ❌ Disabled - Needs GlobalAudioManager
import '../widgets/quran_info_bar.dart';
import 'package:get/get.dart';
import '../../../../core/translations/app_locale_keys.dart';

/// Advanced Quran Reader Screen - شاشة قارئ القرآن المتقدمة
/// تطابق التصميم في الصورة المرجعية
class AdvancedQuranReaderScreen extends StatefulWidget {
  final int initialPage;
  final AyahModel? initialAyah;

  const AdvancedQuranReaderScreen({
    super.key,
    this.initialPage = 1,
    this.initialAyah,
  });

  @override
  State<AdvancedQuranReaderScreen> createState() =>
      _AdvancedQuranReaderScreenState();
}

class _AdvancedQuranReaderScreenState extends State<AdvancedQuranReaderScreen> {
  int _currentPage = 1;
  bool _isFullScreen = false; // ✅ Full screen state

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // ✅ Don't call jumpToPage here - let QuranLibraryScreen handle it via pageIndex
    // The pageIndex parameter will be passed to QuranLibraryScreen in build()
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }

  // Show bookmarks drawer
  void _showBookmarksDrawer() {
    // TODO: Implement actual bookmarks from quran_library
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Provider.of<ThemeProvider>(context, listen: false).themeMode ==
                  ThemeMode.dark
              ? const Color(0xff1E1E1E)
              : const Color(0xFFFFFBE0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        Get.locale?.languageCode == 'ar' ? AppLocaleKeys.savedBookmarks.tr : "My Bookmarks",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              Provider.of<ThemeProvider>(context).themeMode ==
                                      ThemeMode.dark
                                  ? Colors.white
                                  : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Center(
                    child: Text(
                      Get.locale?.languageCode == 'ar' ? AppLocaleKeys.noBookmarksYet.tr : "No saved bookmarks yet",
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Show Surahs/Juz menu (الدارات)
  void _showDaratMenu() {
    final allSurahs = QuranLibrary().getAllSurahs(); // ✅ Get real surah names

    showModalBottomSheet(
      context: context,
      backgroundColor:
          Provider.of<ThemeProvider>(context, listen: false).themeMode ==
                  ThemeMode.dark
              ? const Color(0xff1E1E1E)
              : const Color(0xFFFFFBE0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TabBar(
                          labelColor: Color(0xFF8B6F47),
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Color(0xFF8B6F47),
                          labelStyle: TextStyle(fontWeight: FontWeight.bold),
                          tabs: [
                            Tab(text: AppLocaleKeys.surahsTab.tr),
                            Tab(text: AppLocaleKeys.juzsTab.tr),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // ✅ Surahs list with REAL names
                        ListView.builder(
                          controller: scrollController,
                          itemCount: allSurahs.length,
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
                                allSurahs[index], // ✅ Real surah name
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                // ✅ Navigate to surah using QuranLibrary
                                try {
                                  QuranLibrary().jumpToSurah(index + 1);
                                  setState(() {
                                    // Update current page (approximate)
                                    _currentPage =
                                        (index + 1) * 5; // Rough estimate
                                  });
                                } catch (e) {
                                  debugPrint("Error jumping to surah: $e");
                                }
                              },
                            );
                          },
                        ),
                        // ✅ Juz list
                        ListView.builder(
                          controller: scrollController,
                          itemCount: 30,
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
                                "الجزء ${index + 1}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                // ✅ Navigate to juz
                                try {
                                  final juzPage =
                                      (index * 20) + 1; // Each juz ≈ 20 pages
                                  QuranLibrary().jumpToPage(juzPage);
                                  setState(() {
                                    _currentPage = juzPage;
                                  });
                                } catch (e) {
                                  debugPrint("Error jumping to juz: $e");
                                }
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final Color paperColor =
        isDark ? const Color(0xff1E1E1E) : const Color(0xFFFFFBE0);
    final Color iconColor = isDark ? Colors.white70 : const Color(0xFF8B6F47);

    return Scaffold(
      backgroundColor: paperColor,

      // ✅ AppBar - Only show when NOT in fullscreen
      appBar: _isFullScreen
          ? null
          : AppBar(
              backgroundColor: paperColor,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: iconColor),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                // Settings icon - Long press on page shows settings
                IconButton(
                  icon: Icon(Icons.settings_outlined, color: iconColor),
                  tooltip: Get.locale?.languageCode == 'ar' ? AppLocaleKeys.settingsTab.tr : "Settings",
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            Get.locale?.languageCode == 'ar' 
                              ? AppLocaleKeys.longPressForSettings.tr 
                              : 'Long press on the page to open settings',
                            style: TextStyle()),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),

                // Bookmark icon
                IconButton(
                  icon: Icon(Icons.bookmark_border, color: iconColor),
                  tooltip: Get.locale?.languageCode == 'ar' ? AppLocaleKeys.bookmarksTab.tr : "Bookmarks",
                  onPressed: _showBookmarksDrawer,
                ),

                // Search icon
                IconButton(
                  icon: Icon(Icons.search, color: iconColor),
                  tooltip: AppLocaleKeys.searchBtn.tr,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocaleKeys.searchFeatureComingSoon.tr, style: TextStyle()),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),

                // Book/Menu icon - Opens Surahs/Juz menu
                IconButton(
                  icon: Icon(Icons.menu_book_rounded, color: iconColor),
                  tooltip: AppLocaleKeys.surahsAndJuzsTitle.tr,
                  onPressed: _showDaratMenu,
                ),

                // Fullscreen toggle icon
                IconButton(
                  icon: Icon(
                      _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                      color: iconColor),
                  tooltip:
                      _isFullScreen ? AppLocaleKeys.exitFullScreen.tr : AppLocaleKeys.fullScreen.tr,
                  onPressed: _toggleFullScreen,
                ),
              ],
            ),

      // Main body
      body: Column(
        children: [
          // Quran content
          Expanded(
            child: QuranLibraryScreen(
              pageIndex: _currentPage - 1, // ✅ Pass current page index
              isDark: isDark,
              backgroundColor: Colors.transparent,
              textColor: isDark ? Colors.white : Colors.black,
              ayahIconColor: isDark ? Colors.cyan : const Color(0xFF8B6F47),
              ayahSelectedBackgroundColor:
                  const Color(0xFF8B6F47).withOpacity(0.3),
              ayahSelectedFontColor: isDark ? Colors.white : Colors.black,
              useDefaultAppBar: false,
              withPageView: true,
              showAyahBookmarkedIcon: false,
              isFontsLocal: true,
              fontsName: 'UthmanTN',
              onPagePress:
                  _toggleFullScreen, // ✅ Pass fullscreen toggle to library
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page + 1;
                });
              },
            ),
          ),

          // ✅ Info Bar - Only show when NOT in fullscreen
          if (!_isFullScreen)
            QuranInfoBar(
              currentPage: _currentPage,
              isDark: isDark,
              onDaratPressed: _showDaratMenu,
            ),

          // ❌ Integrated Audio Player - Disabled until GlobalAudioManager is implemented
          // IntegratedAudioPlayer(isDark: isDark),
        ],
      ),
    );
  }
}
