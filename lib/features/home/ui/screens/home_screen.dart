import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme_provider.dart';

import '../../../adhkar/ui/screens/adhkar_categories_screen.dart';
import '../../../quran/ui/screens/mushaf_screen.dart';
import '../../../quran/ui/screens/qcf_mushaf_screen.dart';
import '../../../prayers/ui/screens/prayer_times_screen.dart';
import '../../../adhkar/ui/screens/sebha_screen.dart';
import '../../../quran/ui/screens/shaykhs_screen.dart'; // ✅ Added for audio reciters
import '../../../settings/ui/screens/settings_screen.dart'; // ✅ Added for settings

import '../widgets/custom_bottom_nav_bar.dart';
import 'dashboard_tab.dart';

// 🌟🌟🌟 الإضافات الضرورية 🌟🌟🌟
// ⚠️ تأكد من صحة هذا المسار لملف ApiService
import '../../../../core/services/api_service.dart';
// ⚠️ تأكد من صحة هذا المسار لملف AdPopupDialog
import '../widgets/ad_popup_dialog.dart';
import '../../../../core/utils/desktop_utils.dart';
import '../../../../features/prayers/logic/notification_manager.dart'; // ✅ Import NotificationManager

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      autoPlay: false,
      scrollDuration: const Duration(milliseconds: 400),
      onFinish: () {
        // Optional: show a thank you message
      },
      builder: (context) => const _HomeScreenContent(),
    );
  }
}

class _HomeScreenContent extends StatefulWidget {
  const _HomeScreenContent();

  @override
  State<_HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<_HomeScreenContent> {
  int _selectedIndex = 0;

  final GlobalKey _keyNavQuran = GlobalKey();
  final GlobalKey _keyNavPrayer = GlobalKey();
  final GlobalKey _keyNavAdhkar = GlobalKey();
  final GlobalKey _keyNavSebha = GlobalKey();
  final GlobalKey _keyMenu = GlobalKey();
  final GlobalKey _keyPrayerCard = GlobalKey();
  final GlobalKey _keyAdhkarRow = GlobalKey();
  final GlobalKey _keyQibla = GlobalKey();
  final GlobalKey _keyHawamdia = GlobalKey();
  final GlobalKey _keyLastRead = GlobalKey();
  final GlobalKey _keySettingsGrid = GlobalKey();

  // ✅ Added GlobalKey to refresh Dashboard
  final GlobalKey<DashboardTabState> _dashboardKey =
      GlobalKey<DashboardTabState>();

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // ✅ Notification rescheduling moved to main.dart to prevent duplicate calls

    _pages = [
      DashboardTab(
        key: _dashboardKey,
        keyMenu: _keyMenu,
        keyPrayerCard: _keyPrayerCard,
        keyAdhkarRow: _keyAdhkarRow,
        keyQibla: _keyQibla,
        keyHawamdia: _keyHawamdia,
        keyLastRead: _keyLastRead,
        keySettingsGrid: _keySettingsGrid,
        onShowTutorial: _startAppTutorial,
      ),
      MushafScreen(onBack: () => setState(() => _selectedIndex = 0)),
      const PrayerTimesScreen(),
      const ShaykhsScreen(), // 3: Audio/Reciters
      const SettingsScreen(), // 4: Settings
    ];

    // Pre-cache main background image for zero-jank appearance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('assets/background.png'), context);
    });

    _checkShowcaseAndAdPopup();
  }

  void _startAppTutorial() {
    if (!mounted) return;
    ShowCaseWidget.of(context).startShowCase([
      _keyMenu,
      _keyPrayerCard,
      _keyAdhkarRow,
      _keyHawamdia,
      _keyLastRead,
      _keyQibla,
      _keySettingsGrid,
      _keyNavPrayer,
      _keyNavAdhkar,
      _keyNavSebha
    ]);
  }

  void _checkShowcaseAndAdPopup() async {
    final prefs = await SharedPreferences.getInstance();

    bool showcaseSeen = prefs.getBool('showcase_seen_v2') ?? false;
    if (!showcaseSeen && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startAppTutorial();
        prefs.setBool('showcase_seen_v2', true);
      });
    }

    // 2. منطق الإعلان المنبثق (مرة واحدة يومياً)
    try {
      final String today =
          DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
      final String? lastAdDate = prefs.getString('ad_popup_last_date');

      if (lastAdDate != today && mounted) {
        // 🚀 جلب الرابط الكامل للإعلان
        final String? adLink = await ApiService.getAdImageUrl();

        // نتحقق من وجود رابط حقيقي
        if (mounted && adLink != null && adLink.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog(
              context: context,
              builder: (context) => AdPopupDialog(imageUrl: adLink),
              barrierDismissible: true,
            );
            prefs.setString('ad_popup_last_date', today); // تسجيل تاريخ اليوم
          });
        }
      }
    } catch (e) {
      // Ignore errors
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark;

    return Scaffold(
      // 🌟 التعديل الحاسم الأول: تمديد الجسم ليحتل مساحة الشريط السفلي
      extendBody: true,

      // ✅ التأكد من أن الخلفية شفافة
      backgroundColor: Colors.transparent,

      body: Stack(
        children: [
          // 1. Background (Optimized with RepaintBoundary)
          RepaintBoundary(
            child: Container(
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF071814) : const Color(0xFFF5F5F5),
                image: isDark
                    ? const DecorationImage(
                        image: AssetImage('assets/background.png'),
                        fit: BoxFit.cover,
                        opacity: 0.2,
                        // Memory and performance optimization
                        filterQuality: FilterQuality.low,
                      )
                    : null,
              ),
            ),
          ),

          // 2. المحتوى (IndexedStack) - Wrapped in RepaintBoundary to isolate page animations
          Positioned.fill(
            child: RepaintBoundary(
              child: IndexedStack(
                index: _selectedIndex,
                children: _pages,
              ),
            ),
          ),

          // 3. الشريط السفلي العائم (موضوع يدوياً في Stack)
          // ✅ إخفاء الشريط عند فتح المصحف (index 1) - (Disabled for now as index 1 is blocked)
          if (_selectedIndex != 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(maxWidth: DesktopUtils.maxContentWidth),
                  child: RepaintBoundary(
                    child: CustomBottomNavBar(
                      selectedIndex: _selectedIndex,
                      onItemTapped: (index) {
                        if (index == 1) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const QcfMushafScreen()),
                          ).then(
                              (_) => _dashboardKey.currentState?.refreshData());
                        } else {
                          setState(() => _selectedIndex = index);
                        }
                      },
                      keyAdhkar: _keyNavAdhkar,
                      keySebha: _keyNavSebha,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
