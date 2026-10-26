import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart'; // Added for SystemChrome
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'core/bootstrap/quran_bootstrap.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart'; // ✅ Import GetX
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mihrab/core/translations/app_translations.dart'; // ✅ Import translations
import 'package:mihrab/core/translations/app_locale_keys.dart'; // ✅ Import locale keys
import 'core/utils/desktop_utils.dart'; // ✅ Desktop platform detection

// استدعاء الخدمات
import 'core/theme/theme_provider.dart';
import 'core/services/download_manager.dart';
import 'features/prayers/logic/notification_manager.dart';
import 'features/quran/logic/global_audio_manager.dart'; // Import GlobalAudioManager
import 'core/services/background_service.dart'; // ✅ Import BackgroundService

import 'features/quran/data/services/surah_database_service.dart'; // ✅ Surah offline databases
import 'package:firebase_core/firebase_core.dart'; // ✅ Firebase Core
import 'core/services/fcm_service.dart'; // ✅ FCM Service
import 'core/services/ad_service.dart'; // ✅ AdMob
import 'package:connectivity_plus/connectivity_plus.dart';
import 'features/settings/ui/screens/downloads_screen.dart';

// استدعاء الشاشات
import 'features/auth/ui/screens/animated_splash_screen.dart' as import_splash;
import 'features/auth/ui/screens/auth_screen.dart' as import_auth;
import 'features/quran/logic/quran_settings_provider.dart';
import 'features/quran/logic/quran_audio_provider.dart';
import 'features/quran/logic/quran_download_provider.dart';
import 'features/quran/ui/widgets/mini_player_widget.dart';

// Global navigator key
import 'core/utils/keys.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // تم السماح بالتحميل من الإنترنت لتجنب تعطل التطبيق عند نقص أي وزن من أوزان الخطوط
    GoogleFonts.config.allowRuntimeFetching = true;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ));

    try {
      await dotenv.load(fileName: ".env.local");
    } catch (e) {
      try {
        await dotenv.load(fileName: ".env.production");
      } catch (e) {}
    }



    bootstrapQuranController();
    runApp(const MyAppWrapper());

    Future.delayed(const Duration(milliseconds: 300), () async {
      if (!DesktopUtils.isDesktop && !DesktopUtils.isWeb) {
        await _safeInit(() => Firebase.initializeApp());
        await _safeInit(() => DownloadManager.initializeDownloader());
        await _safeInit(() async {
          NotificationManager.navigatorKey = navigatorKey;
          await NotificationManager.initialize();
          await NotificationManager.setupListeners();
        });
        await _safeInit(() => JustAudioBackground.init(
              androidNotificationChannelId: 'com.magdy.mihrab.channel.audio_v2',
              androidNotificationChannelName: 'Audio playback',
              androidNotificationOngoing: false,
              notificationColor: const Color(0xFFD4AF37),
              androidNotificationIcon: 'mipmap/launcher_icon',
            ).then((_) {
              GlobalAudioManager().playerReady.value = true;
            }));
        await _safeInit(() => BackgroundService.init());
        await _safeInit(() => FCMService.initialize());
        await _safeInit(() => AdService.initialize());
      } else {
        GlobalAudioManager().playerReady.value = true;
      }
      await _safeInit(() => initQuranLibrary());
      await _safeInit(() => SurahDatabaseService.instance.initialize());
    });
  }, (error, stack) {
    debugPrint("❌ Global App Error: $error");
    debugPrintStack(stackTrace: stack);
  });
}

// Safe initialization wrapper
Future<void> _safeInit(Future<void> Function() init) async {
  try {
    await init();
  } catch (e) {
    debugPrint('Initialization error: $e');
  }
}

class MyAppWrapper extends StatelessWidget {
  const MyAppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => QuranSettingsProvider()),
        ChangeNotifierProvider(create: (_) => QuranAudioProvider()),
        ChangeNotifierProvider(create: (_) => QuranDownloadProvider()),
      ],
      child: const MyApp(),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  bool _offlineDialogShown = false;
  Locale? _savedLocale;
  void _showOfflineDialog() {
    if (_offlineDialogShown || navigatorKey.currentState == null) return;
    _offlineDialogShown = true;
    Get.dialog(
      AlertDialog(
        title: Text(AppLocaleKeys.noInternet.tr),
        content: Text(AppLocaleKeys.recitationOfflineMessage.tr),
        actions: [
          TextButton(
              onPressed: () {
                Get.back();
              },
              child: Text(AppLocaleKeys.ok.tr)),
          ElevatedButton(
              onPressed: () {
                Get.back();
                Get.to(() => const DownloadsScreen());
              },
              child: Text(AppLocaleKeys.goToDownloads.tr)),
        ],
      ),
      barrierDismissible: true,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSavedLocale();
    _connSub = _connectivity.onConnectivityChanged.listen((results) {
      final isOffline = results.contains(ConnectivityResult.none);
      if (isOffline) {
        _showOfflineDialog();
      }
      if (!isOffline) {
        _offlineDialogShown = false;
        if (Get.isDialogOpen ?? false) Get.back();
      }
    });
    _connectivity.checkConnectivity().then((results) {
      final offline = results.contains(ConnectivityResult.none);
      if (offline) {
        _showOfflineDialog();
      }
    });
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('app_language_code');
    if (!mounted || code == null || code.isEmpty) return;

    setState(() {
      _savedLocale =
          code == 'ar' ? const Locale('ar', 'EG') : const Locale('en', 'US');
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ));

      Future.delayed(const Duration(seconds: 4), () {
        NotificationManager.rescheduleAllNotificationsIfNeeded(
          minInterval: const Duration(minutes: 1),
        );
      });
    }
    if (state == AppLifecycleState.detached) {
      try {
        GlobalAudioManager().player.stop();
      } catch (e) {}
    }
  }

  @override
  Widget build(BuildContext context) {

    final themeProvider = Provider.of<ThemeProvider>(context);

    return GetMaterialApp(
      title: 'قبس | Qabas',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      routes: {
        '/auth': (context) => const import_auth.AuthScreen(),
        '/home': (context) => const import_splash.AnimatedSplashScreen(),
      },
      theme: themeProvider.getLightTheme(),
      darkTheme: themeProvider.getDarkTheme(),
      themeMode: themeProvider.themeMode,
      translations: AppTranslations(),
      locale: _savedLocale ??
          (Get.deviceLocale?.languageCode == 'ar'
              ? const Locale('ar', 'EG')
              : const Locale('en', 'US')),
      fallbackLocale: const Locale('ar', 'EG'),
      supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: Get.locale?.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: Stack(
            children: [
              child!,
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(top: false, child: MiniPlayerWidget()),
              ),
            ],
          ),
        );
      },
      home: const import_splash.AnimatedSplashScreen(),
    );
  }
}
