import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui'; // للـ BackdropFilter
import 'setup_wizard_screen.dart';
import 'ui/widgets/onboarding_page_widget.dart';
import 'ui/widgets/onboarding_background.dart';
import 'ui/widgets/onboarding_controls.dart';
import 'package:get/get.dart';
import '../../core/translations/app_locale_keys.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  double _pageOffset = 0;

  // للتحكم في أنيميشن العناصر العائمة
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  // أنيميشن الدخول
  late AnimationController _entranceController;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, dynamic>> _pages = [
    {
      "title": AppLocaleKeys.quranFeatureTitle,
      "subtitle": AppLocaleKeys.quranFeatureSubtitle,
      "desc": AppLocaleKeys.quranFeatureDesc,
      "icon": Icons.menu_book_rounded,
      "color": Colors.cyanAccent,
      "bg_color": Color(0xFF006064),
    },
    {
      "title": AppLocaleKeys.prayerFeatureTitle,
      "subtitle": AppLocaleKeys.prayerFeatureSubtitle,
      "desc": AppLocaleKeys.prayerFeatureDesc,
      "icon": Icons.access_time_filled_rounded,
      "color": Colors.orangeAccent,
      "bg_color": Color(0xFFE65100),
    },
    {
      "title": AppLocaleKeys.adhkarFeatureTitle,
      "subtitle": AppLocaleKeys.adhkarFeatureSubtitle,
      "desc": AppLocaleKeys.adhkarFeatureDesc,
      "icon": Icons.wb_twilight_rounded,
      "color": Colors.purpleAccent,
      "bg_color": Color(0xFF4A148C),
    },
    {
      "title": AppLocaleKeys.recitationsFeatureTitle,
      "subtitle": AppLocaleKeys.recitationsFeatureSubtitle,
      "desc": AppLocaleKeys.recitationsFeatureDesc,
      "icon": Icons.headset_mic_rounded,
      "color": Colors.greenAccent,
      "bg_color": Color(0xFF1B5E20),
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _pageController.addListener(() {
      setState(() {
        _pageOffset = _pageController.page ?? 0;
      });
    });

    // أنيميشن الطفو (يجعل الأيقونة تتحرك للأعلى والأسفل ببطء)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: 0, end: 15).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // أنيميشن الدخول "تعبئة من الأسفل"
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutQuart,
    ));
    _entranceController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    if (mounted) {
      // ✅ التعديل هنا: التوجيه لصفحة الإعدادات بدلاً من AuthScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SetupWizardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isLastPage = _pageOffset > _pages.length - 1.5;

    return Scaffold(
      backgroundColor: const Color(0xFF071814),
      body: SlideTransition(
        position: _slideAnimation,
        child: Stack(
          children: [
            // 1. Enhanced dynamic background
            OnboardingBackground(
              pageOffset: _pageOffset,
              pageColors: _pages.map((p) => p['color'] as Color).toList(),
              isDark: true,
            ),

            // 2. Main content
            PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                final page = _pages[index];
                return OnboardingPageWidget(
                  title: page['title'].toString().tr,
                  subtitle: page['subtitle'].toString().tr,
                  description: page['desc'].toString().tr,
                  icon: page['icon'],
                  accentColor: page['color'],
                  backgroundColor: page['bg_color'],
                  pageOffset: _pageOffset,
                  floatAnimation: _floatAnimation,
                  pageIndex: index,
                  currentPageIndex: _pageOffset.round(),
                );
              },
            ),
            // --- أزرار التحكم السفلية ---
            OnboardingControls(
              totalPages: _pages.length,
              pageOffset: _pageOffset,
              isLastPage: isLastPage,
              onNextPressed: () {
                if (_pageOffset < _pages.length - 1) {
                  _pageController.nextPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut);
                } else {
                  _finishOnboarding();
                }
              },
              onSkipPressed: _finishOnboarding,
            ),
          ],
        ),
      ),
    );
  }
}
