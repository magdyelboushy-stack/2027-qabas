import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:get/get.dart';
import 'dart:convert'; // ✅ For jsonDecode
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:provider/provider.dart';
// Quran library import
import '../../../../core/quran/quran_compat.dart';
import 'package:quran/quran.dart'
    as quran_utils; // ✅ Added utility for calculations
import 'package:shared_preferences/shared_preferences.dart'; // ✅ Import SharedPreferences
import 'dart:ui'; // ✅ Required for ImageFilter
import 'package:url_launcher/url_launcher.dart'; // ✅ Required for launching URLs

import '../../../../core/services/last_read_service.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/location_service.dart'; // ✅
import '../../../../core/services/background_service.dart'; // ✅
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/development_dialog.dart';
import '../../../../core/translations/app_locale_keys.dart';
import '../../../auth/data/auth_service.dart';
import '../../../quran/data/models/shaykh.dart';
import '../../../quran/data/models/recitation.dart';
import '../../../quran/data/models/mushaf_category.dart'; // ✅ Import MushafCategory
import '../../../../core/theme/theme_provider.dart';

import '../widgets/qabas_home_header.dart';
import '../widgets/qabas_features_grid.dart';
import '../widgets/premium_adhkar_section.dart';
import '../widgets/state_radios_banner.dart';
import '../widgets/smart_contextual_cards.dart';

import '../widgets/last_read_card.dart';
import '../widgets/main_drawer.dart';

import '../../../quran/ui/screens/shaykhs_screen.dart';
import '../../../prayers/ui/screens/qibla_screen.dart';
import '../../../quran/ui/screens/quran_view_screen.dart';
import '../../../quran/ui/screens/mushaf_selection_screen.dart'; // ✅ Import MushafSelectionScreen
import '../../../adhkar/ui/screens/adhkar_categories_screen.dart';
import '../../../adhkar/ui/screens/adhkar_details_screen.dart';
import '../../../adhkar/ui/screens/sebha_screen.dart';
import '../../../adhkar/data/adhkar_service.dart';
import '../../../prayers/logic/notification_manager.dart';
import '../../../prayers/logic/prayer_times_controller.dart';

import '../../../quran/ui/screens/favorites_screen.dart';
import '../../../quran/ui/screens/mushaf_screen.dart';
import '../../../quran/ui/screens/media_player_screen.dart';
import '../../../quran/ui/screens/state_radios_screen.dart';
import '../../../quran/ui/screens/qcf_mushaf_screen.dart'; // ✅ Import QcfMushafScreen
import '../../../settings/ui/screens/settings_screen.dart'; // ✅ Import SettingsScreen
import '../../../settings/ui/screens/unified_prayer_settings_screen.dart'; // ✅ Import Unified Settings
import '../../../notifications/ui/screens/notification_list_screen.dart'; // ✅ Import NotificationListScreen
import '../../../../core/utils/desktop_utils.dart'; // ✅ Import

// ✅ Ramadan imports
import '../../../ramadan/logic/ramadan_service.dart';
import '../../../ramadan/ui/widgets/ramadan_hero_card.dart';
import '../../../../core/services/ad_service.dart'; // ✅ AdMob
import 'names_of_allah_screen.dart'; // ✅ Names of Allah

class DashboardTab extends StatefulWidget {
  final GlobalKey keyMenu;
  final GlobalKey keyPrayerCard;
  final GlobalKey keyAdhkarRow;
  final GlobalKey keyQibla;
  final GlobalKey keyHawamdia;
  final GlobalKey keyLastRead;
  final GlobalKey keySettingsGrid;
  final VoidCallback? onShowTutorial; // ✅ New

  const DashboardTab({
    super.key,
    required this.keyMenu,
    required this.keyPrayerCard,
    required this.keyAdhkarRow,
    required this.keyQibla,
    required this.keyHawamdia,
    required this.keyLastRead,
    required this.keySettingsGrid,
    this.onShowTutorial,
  });

  @override
  State<DashboardTab> createState() => DashboardTabState();
}

class DashboardTabState extends State<DashboardTab>
    with WidgetsBindingObserver {
  late Future<Map<String, dynamic>?> _userDataFuture;
  String _lastSurah = '';
  String _lastAyah = '';
  // ✅ Bookmark variables
  String _lastBookmarkSurah = '';
  String _lastBookmarkAyah = '';
  String _lastBookmarkText = '';
  int _lastBookmarkPage = 0;
  int _lastBookmarkSurahNo = 0;
  int _lastBookmarkVerseNo = 0;
  List<Shaykh> _hawamdiaShaykhs = [];
  List<Shaykh> _allShaykhs = []; // ✅ Store all shaykhs for the new card
  bool _isLoadingShaykhs = true;
  int _unreadNotificationsCount = 0; // ✅ Badge count for notifications
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController =
      ScrollController(); // ✅ Added Controller

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initializeDateFormatting('ar', null);
    refreshData();
    _loadNotificationCount();
    _loadLastBookmark(); // ✅ Load last bookmark

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      _checkAndShowAd();
      _initLocationAndService();
    });
  }

  // ✅ دالة تهيئة الموقع والخدمة
  Future<void> _initLocationAndService() async {
    // حاول جلب الموقع المحفوظ أولاً
    var loc = await LocationService.getSavedLocation();

    // إذا لم يوجد، اطلب التحديث
    loc ??= await LocationService.getAndSaveLocation();

    // تشغيل الخدمة فقط إذا كان الإعداد مفعلاً
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // ✅ Essential to sync with background isolate
    bool shouldStart = prefs.getBool('persistent_notification_enabled') ?? true;

    if (shouldStart) {
      await BackgroundService.startService();
    } else {
      await BackgroundService
          .stopService(); // Ensure it's stopped if setting is off
    }
  }

  // Manual location update function
  Future<void> _manualLocationUpdate() async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocaleKeys.updatingLocation.tr, style: TextStyle())));
    final loc = await LocationService.getAndSaveLocation();
    if (loc != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocaleKeys.locationUpdatedSuccess.tr, style: TextStyle())));
      // إعادة تشغيل الخدمة لتأخذ الإحداثيات الجديدة
      await BackgroundService.stopService();
      await BackgroundService.startService();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocaleKeys.failedToDetermineLocation.tr, style: TextStyle())));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose(); // ✅ Dispose it
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initLocationAndService();
      _loadLastRead();
      _loadLastBookmark(); // ✅ Refresh bookmark
      _checkAndShowAd();
      _loadHawamdiaShaykhs(
          forceRefresh: false); // ✅ Don't force refresh on every resume
      setState(() {});
    }
  }

  // ✅ Made Public for external refresh
  void refreshData() {
    setState(() {
      _userDataFuture = AuthService.getCurrentUser();
    });
    _loadLastRead();
    _loadLastBookmark();
    _loadHawamdiaShaykhs(forceRefresh: true);
  }

  Future<void> _loadHawamdiaShaykhs({bool forceRefresh = false}) async {
    // ✅ Skip if data is already loaded and not forcing refresh
    if (_allShaykhs.isNotEmpty && !forceRefresh) return;

    try {
      final allShaykhsList = await ApiService.getShaykhs(refresh: forceRefresh);

      // 🟢 تطبيق نفس التعديل اليدوي الموجود في ShaykhsScreen (إضافة سعد حمودة)
      final customShaykh = Shaykh(
        id: 'saad_hamouda_manual',
        name: 'سعد حمودة',
        bio: 'دروس دينية ومواعظ',
        imageUrl:
            'https://mihrab-app.alwaysdata.net/uploads/images/default_reciter.png',
        category: 'hawamdia',
        availableMushafs: [
          MushafCategory(id: '33', name: 'تفسير'),
          MushafCategory(
              id: '101', name: 'خواطر إيمانية (سلسلة)', isSeries: true),
        ],
      );

      final int existingIndex =
          allShaykhsList.indexWhere((s) => s.name.contains('سعد حمودة'));
      if (existingIndex != -1) {
        final existing = allShaykhsList[existingIndex];
        final hasTafsir =
            existing.availableMushafs.any((m) => m.name.contains('تفسير'));
        if (!hasTafsir) {
          final updatedMushafs =
              List<MushafCategory>.from(existing.availableMushafs)
                ..add(MushafCategory(id: '33', name: 'تفسير'));

          allShaykhsList[existingIndex] = Shaykh(
            id: existing.id,
            name: existing.name,
            bio: existing.bio,
            imageUrl: existing.imageUrl,
            category: existing.category,
            availableMushafs: updatedMushafs,
          );
        }
      } else {
        allShaykhsList.add(customShaykh);
      }

      if (mounted) {
        setState(() {
          _allShaykhs = allShaykhsList;

          var list = allShaykhsList
              .where((s) =>
                  s.category.toString().trim().toLowerCase() == 'hawamdia')
              .toList();
          list.sort((a, b) {
            if (a.name.contains("محمد حسني")) return -1;
            if (b.name.contains("محمد حسني")) return 1;
            if (a.name.contains("محمد جمعة")) return -1;
            if (b.name.contains("محمد جمعة")) return 1;
            if (a.name.contains("سعد حمودة")) return -1;
            if (b.name.contains("سعد حمودة")) return 1;
            if (a.name.contains("حمدي أبو الدهب")) return -1;
            if (b.name.contains("حمدي أبو الدهب")) return 1;
            if (a.name.contains("محمود عبد السلام")) return -1;
            if (b.name.contains("محمود عبد السلام")) return 1;
            return 0;
          });
          _hawamdiaShaykhs = list;
          _isLoadingShaykhs = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingShaykhs = false);
    }
  }

  Future<void> _loadLastRead() async {
    final data = await LastReadService.getLastRead();
    if (mounted) {
      setState(() {
        if (data != null) {
          _lastSurah = data['surah']!;
          _lastAyah = data['ayah']!;
        } else {
          _lastSurah = '';
          _lastAyah = '';
        }
      });
    }
  }

  // ✅ Load Last Bookmark for Home Screen
  Future<void> _loadLastBookmark() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> bookmarks = prefs.getStringList('qcf_bookmarks') ?? [];

      if (bookmarks.isNotEmpty) {
        // Decode all
        List<Map<String, dynamic>> decoded = [];
        for (var b in bookmarks) {
          decoded.add(jsonDecode(b));
        }

        // Sort by createdAt desc (newest first)
        decoded.sort((a, b) {
          DateTime da = DateTime.tryParse(a['createdAt']) ?? DateTime(2000);
          DateTime db = DateTime.tryParse(b['createdAt']) ?? DateTime(2000);
          return db.compareTo(da);
        });

        final latest = decoded.first;
        final surahId = latest['surah'] as int;
        final verseId = latest['verse'] as int;
        final pageId = latest['page'] as int;

        // Get Text
        // Using quran package for text
        String text =
            quran_utils.getVerse(surahId, verseId, verseEndSymbol: true);

        if (mounted) {
          setState(() {
            _lastBookmarkSurah = quran_utils.getSurahNameArabic(surahId);
            _lastBookmarkAyah = verseId.toString();
            _lastBookmarkPage = pageId;
            _lastBookmarkText = text;
            _lastBookmarkSurahNo = surahId;
            _lastBookmarkVerseNo = verseId;
          });
        }
      }
    } catch (e) {
      debugPrint("❌ Error loading bookmark: $e");
    }
  }

  void _openBookmark() {
    if (_lastBookmarkPage == 0) return;
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => QcfMushafScreen(initialPage: _lastBookmarkPage)));
  }

  void _continueReading() async {
    showDialog(
      context: context,
      builder: (ctx) => const DevelopmentDialog(),
    );
    return; // Stop execution

    if (_lastSurah.isEmpty) return;

    // إظهار لودينج
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
            child: CircularProgressIndicator(color: Colors.cyanAccent)));

    try {
      // 1. Get Surah list to find index
      final allSurahs = QuranLibrary().getAllSurahs();

      // Clean saved name (remove diacritics and "surah" prefix)
      String cleanLastSurah =
          _normalize(_lastSurah).replaceAll(AppLocaleKeys.surahWord.tr, "").trim();

      // Find Surah number (index + 1)
      int surahNumber = 1; // Default: Al-Fatiha

      for (int i = 0; i < allSurahs.length; i++) {
        // Normalize list item as well
        String listSurah =
            _normalize(allSurahs[i]).replaceAll(AppLocaleKeys.surahWord.tr, "").trim();
        if (listSurah == cleanLastSurah) {
          surahNumber = i + 1;
          break;
        }
      }

      int ayahNum = int.tryParse(_lastAyah) ?? 1;
      int pageNumber = quran_utils.getPageNumber(surahNumber, ayahNum);

      debugPrint(
          "Continue Reading: $_lastSurah ($_lastAyah) -> Surah: $surahNumber, Page: $pageNumber");

      // 2. Create Ayah object (with required data)
      final targetAyah = AyahModel(
        ayahUQNumber: 0, // Dummy
        ayahNumber: ayahNum,
        codeV2: "", // Dummy
        text: "", // Dummy
        surahNumber: surahNumber,
        ayaTextEmlaey: "",
        isDownloadedFonts: false,
        juz: quran_utils.getJuzNumber(surahNumber, ayahNum),
        page: pageNumber,
      );

      if (mounted) {
        Navigator.pop(context); // إغلاق اللودينج

        // 3. Navigate
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MushafScreen(
              initialPage: pageNumber,
              initialAyah: targetAyah,
            ),
          ),
        ).then((_) => _loadLastRead());
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  String _normalize(String text) {
    return text.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '').trim();
  }

  // ... (باقي الدوال كما هي: _openAdhkar, _checkAndShowAd...)
  void _openAdhkar(String type) async {
    // ✅ Lock Evening Adhkar until Asr
    if (type == AppLocaleKeys.eveningAdhkarDash.tr) {
      final times =
          await PrayerTimesController().getStoredOrDefaultPrayerTimes();
      final now = DateTime.now();
      if (now.isBefore(times.asr)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocaleKeys.eveningAdhkarLocked.tr,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: Colors.orange.shade800,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        return;
      }
    }

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
            child: CircularProgressIndicator(color: Colors.cyanAccent)));
    try {
      final allAdhkar = await AdhkarService.getAdhkar();
      final target = allAdhkar.firstWhere(
          (a) => a.category.trim() == type.trim(),
          orElse: () => throw Exception("Not found"));
      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (ctx) => AdhkarDetailsScreen(category: target)));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocaleKeys.adhkarNotFoundDash.tr, style: TextStyle())));
      }
    }
  }

  void _openQuranRadioPlayer() {
    const radioUrl = 'https://n0a.radiojar.com/8s5u5tpdtwzuv';

    final radioShaykh = Shaykh(
      id: 'quran_radio',
      name: AppLocaleKeys.quranRadioBroad.tr,
      bio: AppLocaleKeys.liveStreamInApp.tr,
      imageUrl:
          'https://mihrab-app.alwaysdata.net/uploads/images/default_reciter.png',
      category: 'radio',
    );

    final radioRecitation = Recitation(
      id: 'quran_radio_live',
      title: AppLocaleKeys.quranRadioBroad.tr,
      audioUrl: radioUrl,
      reciterName: AppLocaleKeys.quranRadioBroad.tr,
      mushafName: AppLocaleKeys.liveStreamShort.tr,
      audioSource: 'radio',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MediaPlayerScreen(
          shaykh: radioShaykh,
          currentRecitation: radioRecitation,
          allRecitations: [radioRecitation],
        ),
      ),
    );
  }

  void _openStateRadiosScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StateRadiosScreen()),
    );
  }

  Future<void> _checkAndShowAd() async {
    debugPrint("🔍 Checking for Ad...");
    final prefs = await SharedPreferences.getInstance();
    // Using a simpler key for testing/session
    final bool alreadyShown = prefs.getBool('ad_shown_session_today') ?? false;

    // For testing and better user verification, let's reset it if it's a new run?
    // Or just let it show if it was already shown in a previous session but we want to show it now
    if (alreadyShown) {
      debugPrint("ℹ️ Ad already shown today according to prefs.");
      // For now, let's keep it commented out so the user can DEFINITELY see it during this testing phase
      // return;
    }

    final adUrl = await ApiService.getAdImageUrl();
    debugPrint("📥 Ad Image URL: $adUrl");

    if (adUrl == null || adUrl.isEmpty || !mounted) {
      debugPrint("⚠️ Ad URL is empty or null, or widget unmounted.");
      return;
    }

    await prefs.setBool('ad_shown_session_today', true);

    if (!mounted) return;
    debugPrint("🚀 Showing Ad Dialog...");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ad Image with Rounded Corners
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10))
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: CachedNetworkImage(
                    imageUrl: adUrl,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Close Button
                  _buildAdButton(
                    icon: Icons.close,
                    label: AppLocaleKeys.closeAction.tr,
                    color: Colors.white24,
                    onTap: () => Navigator.pop(ctx),
                  ),
                  // Facebook Button
                  _buildAdButton(
                    icon: FontAwesomeIcons.facebook,
                    label: AppLocaleKeys.contactUsAction.tr,
                    color: const Color(0xFF1877F2),
                    onTap: () async {
                      const fbUrl =
                          'https://www.facebook.com/Qabas.App.Official/';
                      if (await canLaunchUrl(Uri.parse(fbUrl))) {
                        await launchUrl(Uri.parse(fbUrl),
                            mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                  // Download Button
                  _buildAdButton(
                    icon: FontAwesomeIcons.googlePlay,
                    label: AppLocaleKeys.updateLinkText.tr,
                    color: const Color(0xFF34A853),
                    onTap: () async {
                      const playStoreUrl =
                          'https://play.google.com/store/apps/details?id=com.magdy.mihrab'; // ✅ Fixed ID
                      if (await canLaunchUrl(Uri.parse(playStoreUrl))) {
                        await launchUrl(Uri.parse(playStoreUrl),
                            mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdButton(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final accentColor = isDark ? Colors.cyanAccent : const Color(0xFF00695C);
    final iconColor = isDark ? Colors.white : Colors.black87;

    final DateTime now = DateTime.now();
    final String gregorianDate =
        DateFormat(AppLocaleKeys.dateFormatterStr.tr, 'ar').format(now);
    HijriCalendar.setLocal('ar');
    final HijriCalendar hijriDate = HijriCalendar.fromDate(now);
    final String hijriString =
        AppLocaleKeys.hijriDateFormatted.trParams({'day': hijriDate.hDay.toString(), 'month': hijriDate.longMonthName.toString(), 'year': hijriDate.hYear.toString()});

    return RepaintBoundary(
        child: Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A1F1B) : const Color(0xFFF5F7FA),
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        drawer:
            MainDrawer(onShowTutorial: widget.onShowTutorial), // ✅ Passed here

        body: SafeArea(
          top: false,
          child: DesktopUtils.createResponsiveContainer(
            child: FutureBuilder<Map<String, dynamic>?>(
              future: _userDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: CircularProgressIndicator(color: accentColor));
                }
                final userData = snapshot.data;
                final String firstName = userData?['name'] ?? 'زائر';

                final isEnglish = Get.locale?.languageCode == 'en';

                return Directionality(
                  textDirection:
                      isEnglish ? ui.TextDirection.ltr : ui.TextDirection.rtl,
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: CustomScrollView(
                      controller: _scrollController, // ✅ Linked Controller
                      physics: const ClampingScrollPhysics(),
                      slivers: [
                        // 1. New Curved Header with Prayer Times
                        SliverToBoxAdapter(
                          child: QabasHomeHeader(
                            hijriString: hijriString,
                            unreadNotificationsCount: _unreadNotificationsCount,
                            onBellTapped: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const NotificationListScreen()),
                              );
                              _markNotificationsAsRead();
                            },
                            onMenuTapped: () =>
                                _scaffoldKey.currentState?.openDrawer(),
                            onHijriTapped: () =>
                                _showHijriCalendarSheet(context, hijriDate),
                            onCenterButtonTapped: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const UnifiedPrayerSettingsScreen(),
                                ),
                              );
                            },
                          ),
                        ),

                        // Dynamic Contextual Cards (Forbidden times, After Prayer Adhkar, etc)
                        const SliverToBoxAdapter(
                          child: SmartContextualCards(),
                        ),

                        SliverToBoxAdapter(
                          child: _EntranceAnimation(
                            delay: const Duration(milliseconds: 80),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
                              child: _buildHawamdiaSection(
                                isDark: isDark,
                                textColor: textColor,
                                accentColor: accentColor,
                                isEnglish: isEnglish,
                              ),
                            ),
                          ),
                        ),

                        SliverToBoxAdapter(
                          child: _EntranceAnimation(
                            delay: const Duration(milliseconds: 70),
                            child: StateRadiosBanner(
                              onTap: _openStateRadiosScreen,
                            ),
                          ),
                        ),

                        // 2. Features Grid
                        SliverToBoxAdapter(
                          child: _EntranceAnimation(
                            delay: const Duration(milliseconds: 100),
                            child: QabasFeaturesGrid(
                              onQuranTapped: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const QcfMushafScreen())),
                              onMasbahaTapped: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const SebhaScreen())),
                              onQiblaTapped: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const QiblaScreen())),
                              onCommunityTapped: () => showDialog(
                                  context: context,
                                  builder: (ctx) => const DevelopmentDialog()),
                              onHisnTapped: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const AdhkarCategoriesScreen())),
                            ),
                          ),
                        ),

                        if (RamadanService.shouldShowRamadanUI()) ...[
                          const SliverToBoxAdapter(
                            child: _EntranceAnimation(
                              delay: Duration.zero,
                              child: RamadanHeroCard(),
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 6)),
                        ],

                        // ✅ AdMob Banner Ad
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: AdService.bannerAdWidget(),
                          ),
                        ),

                        SliverToBoxAdapter(
                          child: _EntranceAnimation(
                            delay: Duration.zero,
                            child: PremiumAdhkarSection(
                              onMorningTapped: () =>
                                  _openAdhkar(AppLocaleKeys.morningAdhkarDash.tr),
                              onEveningTapped: () =>
                                  _openAdhkar(AppLocaleKeys.eveningAdhkarDash.tr),
                              onNewFeatureTapped: _openStateRadiosScreen,
                              showNewFeatureBanner: false,
                            ),
                          ),
                        ),

                        const SliverToBoxAdapter(child: SizedBox(height: 6)),

                        // 🕌 أصوات من الحوامدية (مشايخ الحوامدية)

                        // مساحة فارغة في الأسفل لترك مسافة لشريط التنقل السفلي الذي هو الآن جزء من Scaffold
                        const SliverToBoxAdapter(child: SizedBox(height: 80)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ));
  }

  // ✅ Load notification count from API
  Future<void> _loadNotificationCount() async {
    try {
      final notifications = await ApiService.getNotifications();
      final prefs = await SharedPreferences.getInstance();
      final lastReadTime = prefs.getString('last_notification_read_time') ?? '';

      // Count notifications newer than last read time
      int count = 0;

      for (var notif in notifications) {
        final createdAt = notif['created_at'] ?? '';
        if (lastReadTime.isEmpty || createdAt.compareTo(lastReadTime) > 0) {
          count++;
        }
      }

      if (mounted) {
        setState(() {
          _unreadNotificationsCount = count;
        });
      }
    } catch (e) {
      // Silent fail - badge just won't show if API fails
    }
  }

  // ✅ Mark notifications as read when user opens the screen
  Future<void> _markNotificationsAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'last_notification_read_time', DateTime.now().toIso8601String());

      if (mounted) {
        setState(() {
          _unreadNotificationsCount = 0;
        });
      }
    } catch (e) {
      // Silent fail
    }
  }

  // ... (باقي الويدجتات كما هي)
  Widget _buildAdhkarHalf(String title, IconData icon, Color color,
      VoidCallback onTap, Color textColor) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(title,
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildHawamdiaSection({
    required bool isDark,
    required Color textColor,
    required Color accentColor,
    required bool isEnglish,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF112824) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFF071513) : const Color(0xFF0A5448))
                .withValues(alpha: isDark ? 0.22 : 0.10),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            isEnglish ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Row(
            textDirection:
                isEnglish ? ui.TextDirection.ltr : ui.TextDirection.rtl,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: isEnglish
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppLocaleKeys.voicesFromHawamdia.tr,
                      style: const TextStyle(
                        color: Color(0xFF0F6A5C),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocaleKeys.hawamdiaSubtitle.tr,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFA7C1BA)
                            : const Color(0xFF6F8E87),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const ShaykhsScreen(initialCategory: 'hawamdia'),
                  ),
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF173A34)
                        : const Color(0xFFEAF5F1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    AppLocaleKeys.viewAll.tr,
                    style: const TextStyle(
                      color: Color(0xFF0F6A5C),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_isLoadingShaykhs)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF0F6A5C))),
            )
          else
            SizedBox(
              height: 236,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _hawamdiaShaykhs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _buildHawamdiaPortraitCard(
                    shaykh: _hawamdiaShaykhs[index],
                    isEnglish: isEnglish,
                    isDark: isDark,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _openShaykh(Shaykh shaykh) {
    final bool hasSeries = shaykh.availableMushafs.any((m) => m.isSeries);
    final bool hasMultiple = shaykh.availableMushafs.length > 1;

    if (hasMultiple || hasSeries) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MushafSelectionScreen(shaykh: shaykh),
        ),
      );
    } else if (shaykh.availableMushafs.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuranViewScreen(
            shaykh: shaykh,
            mushafId: shaykh.availableMushafs.first.id,
            mushafName: shaykh.availableMushafs.first.name,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuranViewScreen(shaykh: shaykh),
        ),
      );
    }
  }

  Widget _buildHawamdiaPortraitCard({
    required Shaykh shaykh,
    required bool isEnglish,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => _openShaykh(shaykh),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 176,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF173430) : const Color(0xFFF7FBF9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color:
                  isDark ? const Color(0xFF274A44) : const Color(0xFFE0EEEA)),
        ),
        child: Column(
          crossAxisAlignment:
              isEnglish ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: Container(
                width: 176,
                height: 148,
                color:
                    isDark ? const Color(0xFF173A34) : const Color(0xFFEAF5F1),
                child: CachedNetworkImage(
                  imageUrl: shaykh.imageUrl,
                  imageBuilder: (context, imageProvider) => Image(
                    image: imageProvider,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                  placeholder: (context, url) => const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF0F6A5C),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.person,
                    color: Color(0xFF0F6A5C),
                    size: 28,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: isEnglish
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.end,
                  children: [
                    Text(
                      shaykh.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: isEnglish ? TextAlign.left : TextAlign.right,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF173B35),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Cairo',
                        height: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      textDirection: isEnglish
                          ? ui.TextDirection.ltr
                          : ui.TextDirection.rtl,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F6A5C),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isEnglish
                                ? Icons.arrow_forward_rounded
                                : Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppLocaleKeys.openProfile.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign:
                                isEnglish ? TextAlign.left : TextAlign.right,
                            style: const TextStyle(
                              color: Color(0xFF6F8E87),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShaykhCard(
      BuildContext context, Shaykh shaykh, bool isDark, Color textColor) {
    return GestureDetector(
      onTap: () {
        final bool hasSeries = shaykh.availableMushafs.any((m) => m.isSeries);
        final bool hasMultiple = shaykh.availableMushafs.length > 1;

        if (hasMultiple || hasSeries) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => MushafSelectionScreen(shaykh: shaykh)));
        } else if (shaykh.availableMushafs.isNotEmpty) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => QuranViewScreen(
                        shaykh: shaykh,
                        mushafId: shaykh.availableMushafs.first.id,
                        mushafName: shaykh.availableMushafs.first.name,
                      )));
        } else {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => QuranViewScreen(shaykh: shaykh)));
        }
      },
      child: Container(
        width: 165,
        height: 230,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              // 1. Background Image
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: shaykh.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: Colors.grey[800]),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),

              // 2. Glass Effect at Top (Subtle gradient without blur)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 60,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Bottom Gradient for Text Readability
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 90,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.5),
                        Colors.black.withOpacity(0.85),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. Shaykh Name and Badge (Bottom Right)
              Positioned(
                bottom: 12,
                right: 10,
                left: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      shaykh.name,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        height: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black87,
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          AppLocaleKeys.famousVoices.tr,
                          style: TextStyle(
                            color: const Color(0xFFFFD700).withOpacity(0.95),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.verified,
                          color: Color(0xFFFFD700),
                          size: 11,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniButton(String title, IconData icon, Color color,
      Color textColor, VoidCallback onTap) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      borderRadius: BorderRadius.circular(15),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        FittedBox(
            child: Text(title,
                style: TextStyle(
                  color: textColor.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                )))
      ]),
    );
  }

  // ✅ New Stacked Shaykhs Card
  Widget _buildShaykhsStackedCard(
      bool isDark, Color textColor, Color accentColor) {
    // Pick top 3 images (if available)
    final topShaykhs = _allShaykhs.take(3).toList();
    final count = _allShaykhs.length;

    return GlassCard(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const ShaykhsScreen(initialCategory: 'all'))),
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            // Icon & Title
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(FontAwesomeIcons.microphoneLines,
                  color: accentColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppLocaleKeys.islamicWorldReciters.tr,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(AppLocaleKeys.listenToSweetVoices.tr,
                      style: TextStyle(
                        color: textColor.withOpacity(0.6),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),

            // Stacked Avatars
            if (topShaykhs.isNotEmpty)
              SizedBox(
                width: 100, // Enough for overlap
                height: 40,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    for (int i = 0; i < topShaykhs.length; i++)
                      Positioned(
                        right: i * 22.0, // Overlap effect
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: isDark
                                    ? const Color(0xFF1E1E1E)
                                    : Colors.white,
                                width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundImage: CachedNetworkImageProvider(
                                topShaykhs[i].imageUrl),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // Count Badge (+N)
            if (count > 3)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "+${count - 3}",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showHijriCalendarSheet(
      BuildContext context, HijriCalendar currentHijri) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E2C) : Colors.white;
    final gold = isDark ? const Color(0xFFFFD700) : const Color(0xFFBF8000);
    final textPrimary = isDark ? Colors.white : Colors.black87;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 20),
            Text(
              '${currentHijri.longMonthName} ${currentHijri.hYear}',
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary),
            ),
            const SizedBox(height: 20),
            // Calendar Grid Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                AppLocaleKeys.daySat.tr,
                AppLocaleKeys.daySun.tr,
                AppLocaleKeys.dayMon.tr,
                AppLocaleKeys.dayTue.tr,
                AppLocaleKeys.dayWed.tr,
                AppLocaleKeys.dayThu.tr,
                AppLocaleKeys.dayFri.tr
              ]
                  .map((e) => Text(e,
                      style: TextStyle(
                          fontFamily: 'Cairo', fontSize: 12, color: gold)))
                  .toList(),
            ),
            const Divider(),
            Expanded(
              child: FutureBuilder<List<HijriCalendar>>(
                future:
                    _generateMonthGrid(currentHijri.hYear, currentHijri.hMonth),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return Center(
                        child: CircularProgressIndicator(color: gold));
                  final days = snapshot.data!;
                  if (days.isEmpty) return const SizedBox();

                  // Calculate padding: Sat (6) -> 0, Sun(7) -> 1, Mon(1) -> 2
                  final firstDayWk = days.first.wkDay ?? 6;
                  final padding = (firstDayWk + 1) % 7;

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7),
                    itemCount: days.length + padding,
                    itemBuilder: (context, index) {
                      if (index >= padding) {
                        final d = days[index - padding];
                        final isToday = d.hDay == currentHijri.hDay;
                        return Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isToday ? gold : null,
                            borderRadius: BorderRadius.circular(8),
                            border: isToday
                                ? null
                                : Border.all(
                                    color: Colors.grey.withOpacity(0.2)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${d.hDay}',
                            style: TextStyle(
                                fontFamily: 'Cairo',
                                color: isToday
                                    ? (isDark ? Colors.black : Colors.white)
                                    : textPrimary),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            // Holidays Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocaleKeys.upcomingOccasionsDash.tr,
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          color: gold)),
                  const SizedBox(height: 10),
                  _buildHolidayRow(AppLocaleKeys.eidAlFitrName.tr, AppLocaleKeys.shawwal1.tr, textPrimary),
                  _buildHolidayRow(AppLocaleKeys.arafatDay.tr, AppLocaleKeys.dhuAlHijjah9.tr, textPrimary),
                  _buildHolidayRow(AppLocaleKeys.eidAlAdhaName.tr, AppLocaleKeys.dhuAlHijjah10.tr, textPrimary),
                  _buildHolidayRow(AppLocaleKeys.hijriNewYearName.tr, AppLocaleKeys.muharram1.tr, textPrimary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHolidayRow(String name, String date, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name,
              style: TextStyle(
                  fontFamily: 'Cairo', fontSize: 14, color: textColor)),
          Text(date,
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: textColor.withOpacity(0.7))),
        ],
      ),
    );
  }

  Future<List<HijriCalendar>> _generateMonthGrid(int year, int month) async {
    // Generate days for the month
    // Hijri package logic
    List<HijriCalendar> days = [];
    final length = HijriCalendar().getDaysInMonth(year, month);
    for (int i = 1; i <= length; i++) {
      final h = HijriCalendar()
        ..hYear = year
        ..hMonth = month
        ..hDay = i;
      // We need to calculate wkDay to align grid
      // h.wkDay is calculated automatically when setting y/m/d? No, usually fromGregorian.
      // We might need to map it to Gregorian to get weekday perfectly if library doesn't auto-calc on set.
      // HijriCalendar doesn't support direct day setting to calc weekday easily without conversion.
      // Let's rely on simple list for now or try conversion if needed.
      // Actually, let's just use it as a list of numbers.
      days.add(h);
    }
    return days;
  }
}

// 🪄 Reusable Entrance Animation for Silky Smooth UI
class _EntranceAnimation extends StatelessWidget {
  final Widget child;
  final Duration delay;

  const _EntranceAnimation({
    required this.child,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
