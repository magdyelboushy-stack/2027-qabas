import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/auth_service.dart';
import '../../../home/ui/screens/home_screen.dart';
import 'package:mihrab/features/intro/welcome_screen.dart';
import 'package:mihrab/features/auth/ui/screens/auth_screen.dart';
import 'package:mihrab/features/intro/setup_wizard_screen.dart';
import 'package:mihrab/features/maintenance/ui/screens/maintenance_screen.dart'; 
import 'package:mihrab/features/maintenance/ui/screens/update_screen.dart';
import 'package:mihrab/core/services/api_service.dart';
import 'package:mihrab/features/ramadan/logic/ramadan_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:get/get.dart';
import '../../../../core/translations/app_locale_keys.dart';

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  bool _navigated = false;

  late Future<Map<String, String>> _appSettingsFuture;
  
  @override
  void initState() {
    super.initState();
    _initAnimations();

    RamadanService.init();

    _appSettingsFuture = ApiService.getAppSettings().then((settings) {
      if (settings.containsKey('ramadan_feature_open')) {
        final opened = settings['ramadan_feature_open'] == '1';
        RamadanService.setFeatureOpened(opened);
      }
      return settings;
    });

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkUserAndNavigate(); 
      }
    });
    
    Timer(const Duration(seconds: 2), () async {
      if (!mounted || _navigated) return;
      final prefs = await SharedPreferences.getInstance();
      final bool seenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
      final bool completedSetup = prefs.getBool('is_setup_completed') ?? false;
      
      if (!seenOnboarding) {
        _navigated = true;
        Get.offAll(() => const WelcomeScreen());
        return;
      }
      if (!completedSetup) {
        _navigated = true;
        Get.offAll(() => const SetupWizardScreen());
        return;
      }
      final user = await AuthService.getCurrentUser();
      final isGuest = await AuthService.isGuest();
      _navigated = true;
      if (user != null || isGuest) {
        Get.offAll(() => const HomeScreen());
      } else {
        Get.offAll(() => const AuthScreen());
      }
    });
  }

  void _initAnimations() {
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  Future<void> _checkUserAndNavigate() async {
    if (_navigated) return;
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    Map<String, String> settings = {};

    try {
      settings = await _appSettingsFuture.timeout(
        const Duration(seconds: 1), 
        onTimeout: () => <String, String>{},
      );
      
      if (settings.isNotEmpty && (settings['maintenance_mode'] == '1' || settings['maintenance_mode'] == 'true')) {
        if (!mounted || _navigated) return;
        _navigated = true;
        Get.offAll(() => const MaintenanceScreen());
        return;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;
      final String? latestVersion = settings.isNotEmpty ? settings['latest_version'] : null;
      final bool forceUpdate = settings.isNotEmpty && (settings['force_update'] == '1' || settings['force_update'] == 'true');
      final String storeUrl = settings.isNotEmpty
          ? (settings['store_url'] ?? 'https://play.google.com/store/apps/details?id=com.magdy.mihrab')
          : 'https://play.google.com/store/apps/details?id=com.magdy.mihrab';

      if (latestVersion != null && _isUpdateAvailable(currentVersion, latestVersion)) {
        if (forceUpdate) {
            if (!mounted || _navigated) return;
            _navigated = true;
            Get.offAll(() => UpdateScreen(isForceUpdate: true, storeUrl: storeUrl));
            return;
        }
      }
    } catch (e) {}

    if (!mounted) return;

    bool seenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    bool completedSetup = prefs.getBool('is_setup_completed') ?? false;

    if (!seenOnboarding) {
      _navigated = true;
      Get.offAll(() => const WelcomeScreen());
      return;
    }

    if (!completedSetup) {
      _navigated = true;
      Get.offAll(() => const SetupWizardScreen());
      return;
    }

    final user = await AuthService.getCurrentUser();
    final isGuest = await AuthService.isGuest();

    if (user != null || isGuest) {
      _navigated = true;
      Get.offAll(() => const HomeScreen());
    } else {
      _navigated = true;
      Get.offAll(() => const AuthScreen());
    }
  }

  bool _isUpdateAvailable(String current, String latest) {
    try {
       List<int> c = current.split('+')[0].split('.').map(int.parse).toList();
       List<int> l = latest.split('+')[0].split('.').map(int.parse).toList();
       for (int i = 0; i < l.length && i < c.length; i++) {
         if (l[i] > c[i]) return true;
         if (l[i] < c[i]) return false;
       }
       return l.length > c.length;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // خلفية خضراء داكنة تناسب هوية التطبيق (نفس لون الأيقونة تقريباً)
        color: const Color(0xFF1E4233), 
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _opacityAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 152,
                    height: 152,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.cover, // لجعل الصورة تملأ المربع بالكامل بدون حواف بيضاء
                      errorBuilder: (c, e, s) => const Icon(Icons.mosque, size: 100, color: Color(0xFFD4AF37)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              FadeTransition(
                opacity: _opacityAnimation,
                child: Text(
                  AppLocaleKeys.qabasAppName.tr,
                  style: TextStyle(
                    fontSize: 42,
                    fontFamily: 'Amiri', // أو أي خط عربي جميل عندك
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD4AF37), // لون ذهبي
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              FadeTransition(
                opacity: _opacityAnimation,
                child: Text(
                  'Qabas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

