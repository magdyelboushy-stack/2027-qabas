import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mihrab/features/auth/data/auth_service.dart';
import 'package:mihrab/config/api_endpoints.dart';

/// Core service for Ramadan features.
/// Handles date calculations, daily content rotation, and worship tracking.
class RamadanService {
  // ─── Ramadan 1447 AH Dates ───
  // Adjust these if the actual moon sighting differs
  static final DateTime ramadanStart = DateTime(2026, 2, 18); // 1 رمضان 1447 هـ
  static final DateTime ramadanEnd =
      DateTime(2026, 3, 19); // 30 رمضان (18 فبراير + 29 يوم)
  static const int ramadanDays = 30;

  // يتحكم فيه الأدمن من خلال إعدادات السيرفر
  static bool _featureOpened = false;

  static const String _prefKeyFeatureOpened = 'ramadan_feature_opened_offline';

  /// Initialize service (load saved status)
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _featureOpened = prefs.getBool(_prefKeyFeatureOpened) ?? false;
  }

  static Future<void> setFeatureOpened(bool opened) async {
    _featureOpened = opened;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyFeatureOpened, opened);
  }

  static bool isFeatureOpened() => _featureOpened;

  // ─── Date Calculations ───

  /// Is today before Ramadan?
  static bool isBeforeRamadan() {
    final now = DateTime.now();
    return now.isBefore(ramadanStart);
  }

  /// Is today during Ramadan?
  static bool isDuringRamadan() {
    final now = DateTime.now();
    return !now.isBefore(ramadanStart) &&
        now.isBefore(ramadanEnd.add(const Duration(days: 1)));
  }

  /// Is it the Last Ten Days (day 21–30)?
  static bool isLastTenDays() {
    final day = currentRamadanDay();
    return day >= 21 && day <= 30;
  }

  /// Days remaining until Ramadan starts.
  static int daysUntilRamadan() {
    final now = DateTime.now();
    if (!now.isBefore(ramadanStart)) return 0;
    return ramadanStart
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
  }

  /// Current Ramadan day number (1–30). Returns 0 if not Ramadan.
  static int currentRamadanDay() {
    final now = DateTime.now();
    if (now.isBefore(ramadanStart)) return 0;
    if (now.isAfter(ramadanEnd)) return 0;
    return DateTime(now.year, now.month, now.day)
            .difference(DateTime(
                ramadanStart.year, ramadanStart.month, ramadanStart.day))
            .inDays +
        1;
  }

  /// Should show Ramadan UI? (Before or during)
  static bool shouldShowRamadanUI() {
    // return true; // ✅ مؤقتاً: مفتوح للمعاينة — هنقفله بعدين
    final now = DateTime.now();
    // Show countdown 30 days before + during Ramadan
    final showFrom = ramadanStart.subtract(const Duration(days: 30));
    return now.isAfter(showFrom) &&
        now.isBefore(ramadanEnd.add(const Duration(days: 1)));
  }

  // ─── Daily Content ───

  /// Get today's content (Ayah, Dhikr, Dua).
  static RamadanDailyContent getTodayContent() {
    int dayIndex;
    if (isDuringRamadan()) {
      dayIndex = currentRamadanDay() - 1;
    } else {
      // Before Ramadan: cycle through content based on day of year
      dayIndex = DateTime.now()
              .difference(DateTime(DateTime.now().year, 1, 1))
              .inDays %
          ramadanDays;
    }
    return RamadanDailyContent(
      ayah: _dailyAyahs[dayIndex % _dailyAyahs.length],
      ayahReference: _dailyAyahRefs[dayIndex % _dailyAyahRefs.length],
      dhikr: _dailyAdhkar[dayIndex % _dailyAdhkar.length],
      dua: _dailyDuas[dayIndex % _dailyDuas.length],
    );
  }

  /// Get random content seeded by today's date (consistent within a day, changes daily).
  static RamadanDailyContent getRandomContent() {
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    final rng = Random(seed);
    return RamadanDailyContent(
      ayah: _dailyAyahs[rng.nextInt(_dailyAyahs.length)],
      ayahReference: _dailyAyahRefs[rng.nextInt(_dailyAyahRefs.length)],
      dhikr: _dailyAdhkar[rng.nextInt(_dailyAdhkar.length)],
      dua: _dailyDuas[rng.nextInt(_dailyDuas.length)],
    );
  }

  /// Get content for a specific Ramadan day (1-30).
  static RamadanDailyContent getContentForDay(int day) {
    final d = day.clamp(1, 30);
    final idx = d - 1;
    return RamadanDailyContent(
      ayah: _dailyAyahs[idx % _dailyAyahs.length],
      ayahReference: _dailyAyahRefs[idx % _dailyAyahRefs.length],
      dhikr: _dailyAdhkar[idx % _dailyAdhkar.length],
      dua: _dailyDuas[idx % _dailyDuas.length],
    );
  }

  /// Get a calm quote for the Hero Card.
  static String getTodayQuote() {
    int dayIndex;
    if (isDuringRamadan()) {
      dayIndex = currentRamadanDay() - 1;
    } else {
      dayIndex = DateTime.now()
              .difference(DateTime(DateTime.now().year, 1, 1))
              .inDays %
          _heroQuotes.length;
    }
    return _heroQuotes[dayIndex % _heroQuotes.length];
  }

  // ─── Worship Tracking ───

  static String _worshipKey(int day) => 'ramadan_worship_day_$day';

  /// Get today's worship status.
  static Future<Map<String, bool>> getTodayWorship() async {
    final prefs = await SharedPreferences.getInstance();
    final day = isDuringRamadan() ? currentRamadanDay() : 0;
    if (day == 0) {
      return {
        'quran': false,
        'qiyam': false,
        'taraweeh': false,
        'dhikr': false
      };
    }
    final key = _worshipKey(day);
    return {
      'quran': prefs.getBool('${key}_quran') ?? false,
      'qiyam': prefs.getBool('${key}_qiyam') ?? false,
      'taraweeh': prefs.getBool('${key}_taraweeh') ?? false,
      'dhikr': prefs.getBool('${key}_dhikr') ?? false,
    };
  }

  /// Toggle a worship item for today.
  static Future<void> toggleWorship(String item, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final day = currentRamadanDay();
    if (day == 0) return;
    await prefs.setBool('${_worshipKey(day)}_$item', value);
  }

  // ─── Last Ten Days Tracking ───

  static String _lastTenKey(int day) => 'ramadan_last10_day_$day';

  static Future<Map<String, bool>> getLastTenWorship() async {
    final prefs = await SharedPreferences.getInstance();
    final day = currentRamadanDay();
    if (day < 21) return {'qiyam_layl': false, 'witr': false, 'dua': false};
    final key = _lastTenKey(day);
    return {
      'qiyam_layl': prefs.getBool('${key}_qiyam_layl') ?? false,
      'witr': prefs.getBool('${key}_witr') ?? false,
      'dua': prefs.getBool('${key}_dua') ?? false,
    };
  }

  static Future<void> toggleLastTenWorship(String item, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final day = currentRamadanDay();
    if (day < 21) return;
    await prefs.setBool('${_lastTenKey(day)}_$item', value);
  }

  // ─── Comprehensive Hub Tracking (16 items) ───

  static const List<WorshipItem> allWorshipItems = [
    // الصلاة (8 items)
    WorshipItem(
        key: 'fajr', title: 'صلاة الفجر', emoji: '🌅', category: 'الصلاة'),
    WorshipItem(
        key: 'dhuhr', title: 'صلاة الظهر', emoji: '☀️', category: 'الصلاة'),
    WorshipItem(
        key: 'asr', title: 'صلاة العصر', emoji: '🌤️', category: 'الصلاة'),
    WorshipItem(
        key: 'maghrib', title: 'صلاة المغرب', emoji: '🌇', category: 'الصلاة'),
    WorshipItem(
        key: 'isha', title: 'صلاة العشاء', emoji: '🌙', category: 'الصلاة'),
    WorshipItem(
        key: 'taraweeh', title: 'التراويح', emoji: '🕌', category: 'الصلاة'),
    WorshipItem(
        key: 'qiyam', title: 'قيام الليل', emoji: '🌃', category: 'الصلاة'),
    WorshipItem(key: 'witr', title: 'الوتر', emoji: '🤲', category: 'الصلاة'),
    // القرآن والذكر (4 items)
    WorshipItem(
        key: 'quran_read',
        title: 'قراءة القرآن',
        emoji: '📖',
        category: 'القرآن والذكر'),
    WorshipItem(
        key: 'morning_adhkar',
        title: 'أذكار الصباح',
        emoji: '🌞',
        category: 'القرآن والذكر'),
    WorshipItem(
        key: 'evening_adhkar',
        title: 'أذكار المساء',
        emoji: '🌜',
        category: 'القرآن والذكر'),
    WorshipItem(
        key: 'istighfar',
        title: 'الاستغفار',
        emoji: '💫',
        category: 'القرآن والذكر'),
    // الإحسان (4 items)
    WorshipItem(
        key: 'sadaqah', title: 'صدقة', emoji: '💝', category: 'الإحسان'),
    WorshipItem(
        key: 'iftar_saem',
        title: 'إفطار صائم',
        emoji: '🍽️',
        category: 'الإحسان'),
    WorshipItem(
        key: 'silat_rahm',
        title: 'صلة الرحم',
        emoji: '🤝',
        category: 'الإحسان'),
    WorshipItem(
        key: 'hub_dua', title: 'الدعاء', emoji: '🕊️', category: 'الإحسان'),
  ];

  static List<String> get worshipCategories =>
      allWorshipItems.map((e) => e.category).toSet().toList();

  static List<WorshipItem> itemsForCategory(String cat) =>
      allWorshipItems.where((e) => e.category == cat).toList();

  static String _hubKey(int day, String itemKey) => 'rmdn_hub_d${day}_$itemKey';

  /// Get all hub worship statuses for a specific day.
  static Future<Map<String, bool>> getHubDay(int day) async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final item in allWorshipItems)
        item.key: prefs.getBool(_hubKey(day, item.key)) ?? false,
    };
  }

  /// Toggle a hub worship item for a specific day.
  static Future<void> toggleHubItem(int day, String itemKey, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hubKey(day, itemKey), value);
  }

  /// Completion ratio for a specific day (0.0 – 1.0).
  static Future<double> dayCompletion(int day) async {
    final data = await getHubDay(day);
    final done = data.values.where((v) => v).length;
    return done / allWorshipItems.length;
  }

  /// Month-level stats.
  static Future<Map<String, dynamic>> getMonthStats() async {
    final prefs = await SharedPreferences.getInstance();
    int totalDone = 0;
    int totalPossible = 0;
    int streak = 0;
    bool streakBroken = false;

    final today = currentRamadanDay().clamp(1, 30);
    for (int d = today; d >= 1; d--) {
      int dayDone = 0;
      for (final item in allWorshipItems) {
        if (prefs.getBool(_hubKey(d, item.key)) ?? false) dayDone++;
      }
      totalDone += dayDone;
      totalPossible += allWorshipItems.length;
      if (!streakBroken && dayDone == allWorshipItems.length) {
        streak++;
      } else {
        streakBroken = true;
      }
    }

    return {
      'totalDone': totalDone,
      'totalPossible': totalPossible,
      'streak': streak,
      'daysTracked': today,
    };
  }

  // ─── XP / Level / Achievement System ───

  static const Map<String, int> _xpValues = {
    'fajr': 10,
    'dhuhr': 10,
    'asr': 10,
    'maghrib': 10,
    'isha': 10,
    'taraweeh': 15,
    'qiyam': 20,
    'witr': 10,
    'quran_read': 15,
    'morning_adhkar': 5,
    'evening_adhkar': 5,
    'istighfar': 5,
    'sadaqah': 10,
    'iftar_saem': 15,
    'silat_rahm': 10,
    'hub_dua': 5,
    'fasting': 50,
  };

  static const int _fullDayBonus = 50;

  static const List<Map<String, dynamic>> levels = [
    {'name': 'مبتدئ', 'emoji': '🌱', 'minXP': 0},
    {'name': 'مبادر', 'emoji': '🌿', 'minXP': 100},
    {'name': 'مجتهد', 'emoji': '🌳', 'minXP': 350},
    {'name': 'مواظب', 'emoji': '⭐', 'minXP': 750},
    {'name': 'مثابر', 'emoji': '🌙', 'minXP': 1500},
    {'name': 'متميز', 'emoji': '💎', 'minXP': 2500},
    {'name': 'سابق', 'emoji': '👑', 'minXP': 4000},
  ];

  static String _fastingKey(int day) => 'ramadan_fasting_day_$day';

  /// Check if fasted on a specific day
  static Future<bool> isFasted(int day) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_fastingKey(day)) ?? false;
  }

  /// Toggle fasting status for a specific day
  static Future<void> toggleFasting(int day, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_fastingKey(day), value);
  }

  /// Calculate total XP from all tracked days.
  static Future<int> calculateTotalXP() async {
    final prefs = await SharedPreferences.getInstance();
    int totalXP = 0;
    final today = currentRamadanDay().clamp(1, 30);

    for (int d = 1; d <= today; d++) {
      int dayDone = 0;
      for (final item in allWorshipItems) {
        if (prefs.getBool(_hubKey(d, item.key)) ?? false) {
          totalXP += _xpValues[item.key] ?? 5;
          dayDone++;
        }
      }

      // Fasting XP
      if (prefs.getBool(_fastingKey(d)) ?? false) {
        totalXP += _xpValues['fasting'] ?? 50;
      }

      // Full day bonus
      if (dayDone == allWorshipItems.length) totalXP += _fullDayBonus;
    }
    return totalXP;
  }

  /// Get current level info based on XP.
  static Map<String, dynamic> getLevelForXP(int xp) {
    Map<String, dynamic> current = levels[0];
    for (final lvl in levels) {
      if (xp >= (lvl['minXP'] as int)) current = lvl;
    }
    return current;
  }

  /// Get level index (0-6).
  static int getLevelIndex(int xp) {
    int idx = 0;
    for (int i = 0; i < levels.length; i++) {
      if (xp >= (levels[i]['minXP'] as int)) idx = i;
    }
    return idx;
  }

  /// Progress to next level (0.0 – 1.0).
  static double progressToNextLevel(int xp) {
    final idx = getLevelIndex(xp);
    if (idx >= levels.length - 1) return 1.0;
    final currentMin = levels[idx]['minXP'] as int;
    final nextMin = levels[idx + 1]['minXP'] as int;
    return (xp - currentMin) / (nextMin - currentMin);
  }

  /// Calculate achievements earned.
  static Future<List<Map<String, dynamic>>> getAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final today = currentRamadanDay().clamp(1, 30);
    final achievements = <Map<String, dynamic>>[];

    // Streak tracking
    int streak = 0;
    bool streakBroken = false;
    // Per-category tracking
    int prayerPerfectDays = 0;
    int quranDays = 0;
    int sadaqahCount = 0;
    int qiyamCount = 0;
    int fullDays = 0;

    for (int d = today; d >= 1; d--) {
      int dayDone = 0;
      bool allPrayers = true;
      for (final item in allWorshipItems) {
        final done = prefs.getBool(_hubKey(d, item.key)) ?? false;
        if (done) dayDone++;
        // Check per-category
        if (item.category == 'الصلاة' &&
            item.key != 'taraweeh' &&
            item.key != 'qiyam' &&
            item.key != 'witr' &&
            !done) {
          allPrayers = false;
        }
      }
      if (dayDone == allWorshipItems.length) fullDays++;
      if (!streakBroken && dayDone == allWorshipItems.length) {
        streak++;
      } else {
        streakBroken = true;
      }
      if (allPrayers) prayerPerfectDays++;
      if (prefs.getBool(_hubKey(d, 'quran_read')) ?? false) quranDays++;
      if (prefs.getBool(_hubKey(d, 'sadaqah')) ?? false) sadaqahCount++;
      if (prefs.getBool(_hubKey(d, 'qiyam')) ?? false) qiyamCount++;
    }

    // Define achievements
    if (streak >= 3)
      achievements.add({
        'emoji': '🔥',
        'title': 'سلسلة ٣ أيام',
        'desc': '٣ أيام كاملة متتالية'
      });
    if (streak >= 7)
      achievements.add({
        'emoji': '🔥',
        'title': 'سلسلة ٧ أيام',
        'desc': '٧ أيام بدون انقطاع!'
      });
    if (streak >= 15)
      achievements.add({
        'emoji': '💪',
        'title': 'نصف رمضان!',
        'desc': '١٥ يوم كامل متتالي!'
      });
    if (prayerPerfectDays >= 3)
      achievements.add(
          {'emoji': '🕌', 'title': 'حارس الصلوات', 'desc': 'كل الفروض ٣ أيام'});
    if (prayerPerfectDays >= 10)
      achievements.add({
        'emoji': '🕋',
        'title': 'ركيزة الصلاة',
        'desc': 'كل الفروض ١٠ أيام!'
      });
    if (quranDays >= 7)
      achievements.add(
          {'emoji': '📖', 'title': 'قارئ القرآن', 'desc': 'قراءة قرآن ٧ أيام'});
    if (quranDays >= 20)
      achievements.add({
        'emoji': '📚',
        'title': 'خاتم القرآن',
        'desc': 'قراءة قرآن ٢٠ يوم!'
      });
    if (sadaqahCount >= 5)
      achievements.add({'emoji': '💝', 'title': 'كريم', 'desc': 'صدقة ٥ مرات'});
    if (sadaqahCount >= 15)
      achievements
          .add({'emoji': '🤲', 'title': 'جواد', 'desc': 'صدقة ١٥ مرة!'});
    if (qiyamCount >= 5)
      achievements
          .add({'emoji': '🌃', 'title': 'قائم الليل', 'desc': 'قيام ٥ ليالي'});
    if (qiyamCount >= 15)
      achievements
          .add({'emoji': '✨', 'title': 'عابد الليل', 'desc': 'قيام ١٥ ليلة!'});
    if (fullDays >= 10)
      achievements
          .add({'emoji': '🏆', 'title': 'بطل رمضان', 'desc': '١٠ أيام كاملة!'});
    if (fullDays >= 25)
      achievements.add(
          {'emoji': '👑', 'title': 'أسطورة رمضان', 'desc': '٢٥ يوم كامل!'});

    return achievements;
  }

  // ─── Sync & Leaderboard ───

  /// Syncs local progress to the backend if logged in.
  static Future<void> syncProgress() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null || user['id'] == null) {
        debugPrint("Sync skipped: No user.");
        return;
      }

      final userId = user['id'];
      final totalXP = await calculateTotalXP();
      final levelIdx = getLevelIndex(totalXP);

      // Collect all relevant worship data from prefs
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys().where((k) =>
          k.startsWith('rmdn_hub_') || k.startsWith('ramadan_fasting_day_'));
      final Map<String, dynamic> worshipData = {};
      for (var k in allKeys) {
        worshipData[k] = prefs.getBool(k);
      }

      final url = Uri.parse(ApiEndpoints.ramadanSync);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'total_xp': totalXP,
          'level': levelIdx,
          'worship_data': worshipData,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('Sync failed: ${response.statusCode} ${response.body}');
      } else {
        debugPrint('✅ Progress Synced');
      }
    } catch (e) {
      debugPrint('Sync Error: $e');
    }
  }

  /// Fetches the global leaderboard.
  static Future<List<Map<String, dynamic>>> getLeaderboard() async {
    try {
      final url = Uri.parse(ApiEndpoints.ramadanLeaderboard);
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Leaderboard Error: $e');
    }
    return [];
  }

  // ─── Content Data ───

  static const List<String> _heroQuotes = [
    'شَهْرُ رَمَضَانَ الَّذِي أُنزِلَ فِيهِ الْقُرْآنُ',
    'وَقُولُوا لِلنَّاسِ حُسْنًا',
    'إِنَّ اللَّهَ مَعَ الصَّابِرِينَ',
    'وَمِنَ اللَّيْلِ فَتَهَجَّدْ بِهِ نَافِلَةً لَّكَ',
    'وَقُلِّيلٌ مِّنَ اللَّيْلِ مَا يَهْجَعُونَ',
    'ادْعُونِي أَسْتَجِبْ لَكُمْ',
    'وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ',
    'وَاسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ',
    'رَبِّ اشْرَحْ لِي صَدْرِي',
    'فَاذْكُرُونِي أَذْكُرْكُمْ',
    'وَلَسَوْفَ يُعْطِيكَ رَبُّكَ فَتَرْضَىٰ',
    'إِنَّ مَعَ الْعُسْرِ يُسْرًا',
    'وَتَوَكَّلْ عَلَى الْحَيِّ الَّذِي لَا يَمُوتُ',
    'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً',
    'وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ',
    'إِنَّا أَنزَلْنَاهُ فِي لَيْلَةِ الْقَدْرِ',
    'لَيْلَةُ الْقَدْرِ خَيْرٌ مِّنْ أَلْفِ شَهْرٍ',
    'سَلَامٌ هِيَ حَتَّىٰ مَطْلَعِ الْفَجْرِ',
    'وَرَتِّلِ الْقُرْآنَ تَرْتِيلًا',
    'يَا أَيُّهَا الَّذِينَ آمَنُوا كُتِبَ عَلَيْكُمُ الصِّيَامُ',
    'لَعَلَّكُمْ تَتَّقُونَ',
    'وَأَن تَصُومُوا خَيْرٌ لَّكُمْ',
    'هُوَ اللَّهُ الَّذِي لَا إِلَٰهَ إِلَّا هُوَ',
    'قُلْ هُوَ اللَّهُ أَحَدٌ',
    'وَاللَّيْلِ إِذَا يَغْشَىٰ',
    'وَالْفَجْرِ وَلَيَالٍ عَشْرٍ',
    'إِنَّ اللَّهَ وَمَلَائِكَتَهُ يُصَلُّونَ عَلَى النَّبِيِّ',
    'اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ',
    'رَبِّ زِدْنِي عِلْمًا',
    'حَسْبِيَ اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ',
  ];

  static const List<String> _dailyAyahs = [
    'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ ۝ الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
    'ذَٰلِكَ الْكِتَابُ لَا رَيْبَ ۛ فِيهِ ۛ هُدًى لِّلْمُتَّقِينَ',
    'وَإِلَٰهُكُمْ إِلَٰهٌ وَاحِدٌ ۖ لَّا إِلَٰهَ إِلَّا هُوَ الرَّحْمَٰنُ الرَّحِيمُ',
    'شَهِدَ اللَّهُ أَنَّهُ لَا إِلَٰهَ إِلَّا هُوَ وَالْمَلَائِكَةُ وَأُولُو الْعِلْمِ',
    'رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِن لَّدُنكَ رَحْمَةً',
    'كُلُّ نَفْسٍ ذَائِقَةُ الْمَوْتِ ۗ وَإِنَّمَا تُوَفَّوْنَ أُجُورَكُمْ يَوْمَ الْقِيَامَةِ',
    'يَا أَيُّهَا الَّذِينَ آمَنُوا اصْبِرُوا وَصَابِرُوا وَرَابِطُوا وَاتَّقُوا اللَّهَ',
    'وَمَن يَعْمَلْ مِنَ الصَّالِحَاتِ وَهُوَ مُؤْمِنٌ فَلَا يَخَافُ ظُلْمًا وَلَا هَضْمًا',
    'وَاعْبُدْ رَبَّكَ حَتَّىٰ يَأْتِيَكَ الْيَقِينُ',
    'إِنَّ رَبَّكَ يَبْسُطُ الرِّزْقَ لِمَن يَشَاءُ وَيَقْدِرُ',
    'وَلَا تَمْشِ فِي الْأَرْضِ مَرَحًا ۖ إِنَّكَ لَن تَخْرِقَ الْأَرْضَ',
    'وَقُل رَّبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا',
    'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا ۝ إِنَّ مَعَ الْعُسْرِ يُسْرًا',
    'وَاصْبِرْ لِحُكْمِ رَبِّكَ فَإِنَّكَ بِأَعْيُنِنَا',
    'وَمَا تَوْفِيقِي إِلَّا بِاللَّهِ ۚ عَلَيْهِ تَوَكَّلْتُ وَإِلَيْهِ أُنِيبُ',
    'قَالَ رَبِّ اشْرَحْ لِي صَدْرِي ۝ وَيَسِّرْ لِي أَمْرِي',
    'وَنُنَزِّلُ مِنَ الْقُرْآنِ مَا هُوَ شِفَاءٌ وَرَحْمَةٌ لِّلْمُؤْمِنِينَ',
    'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
    'وَقَالَ رَبُّكُمُ ادْعُونِي أَسْتَجِبْ لَكُمْ',
    'يَا أَيُّهَا الَّذِينَ آمَنُوا اسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ',
    'إِنَّ اللَّهَ لَا يُضِيعُ أَجْرَ الْمُحْسِنِينَ',
    'وَاللَّهُ يُحِبُّ الصَّابِرِينَ',
    'وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا ۝ وَيَرْزُقْهُ مِنْ حَيْثُ لَا يَحْتَسِبُ',
    'رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ',
    'سُبْحَانَ الَّذِي أَسْرَىٰ بِعَبْدِهِ لَيْلًا',
    'وَلَقَدْ يَسَّرْنَا الْقُرْآنَ لِلذِّكْرِ فَهَلْ مِن مُّدَّكِرٍ',
    'إِنَّا فَتَحْنَا لَكَ فَتْحًا مُّبِينًا',
    'وَمَا أَرْسَلْنَاكَ إِلَّا رَحْمَةً لِّلْعَالَمِينَ',
    'وَعَسَىٰ أَن تَكْرَهُوا شَيْئًا وَهُوَ خَيْرٌ لَّكُمْ',
    'وَبَشِّرِ الصَّابِرِينَ',
  ];

  static const List<String> _dailyAyahRefs = [
    'الفاتحة ١-٢',
    'البقرة ٢',
    'البقرة ١٦٣',
    'آل عمران ١٨',
    'آل عمران ٨',
    'آل عمران ١٨٥',
    'آل عمران ٢٠٠',
    'طه ١١٢',
    'الحجر ٩٩',
    'الإسراء ٣٠',
    'الإسراء ٣٧',
    'الإسراء ٢٤',
    'الشرح ٥-٦',
    'الطور ٤٨',
    'هود ٨٨',
    'طه ٢٥-٢٦',
    'الإسراء ٨٢',
    'الرعد ٢٨',
    'غافر ٦٠',
    'البقرة ١٥٣',
    'التوبة ١٢٠',
    'آل عمران ١٤٦',
    'الطلاق ٢-٣',
    'الفرقان ٧٤',
    'الإسراء ١',
    'القمر ١٧',
    'الفتح ١',
    'الأنبياء ١٠٧',
    'البقرة ٢١٦',
    'البقرة ١٥٥',
  ];

  static const List<String> _dailyAdhkar = [
    'سبحان الله وبحمده، سبحان الله العظيم',
    'لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير',
    'سبحان الله، والحمد لله، ولا إله إلا الله، والله أكبر',
    'لا حول ولا قوة إلا بالله العلي العظيم',
    'أستغفر الله العظيم الذي لا إله إلا هو الحي القيوم وأتوب إليه',
    'اللهم صل وسلم على نبينا محمد',
    'سبحان الله وبحمده عدد خلقه ورضا نفسه وزنة عرشه ومداد كلماته',
    'حسبي الله لا إله إلا هو عليه توكلت وهو رب العرش العظيم',
    'اللهم إني أعوذ بك من الهم والحزن',
    'يا حي يا قيوم برحمتك أستغيث',
    'اللهم أنت ربي لا إله إلا أنت خلقتني وأنا عبدك',
    'رضيت بالله رباً وبالإسلام ديناً وبمحمد نبياً ورسولاً',
    'اللهم إني أسألك العفو والعافية في الدنيا والآخرة',
    'بسم الله الذي لا يضر مع اسمه شيء في الأرض ولا في السماء',
    'اللهم بك أصبحنا وبك أمسينا وبك نحيا وبك نموت',
    'اللهم عافني في بدني، اللهم عافني في سمعي، اللهم عافني في بصري',
    'اللهم إني أعوذ بك من الكفر والفقر وعذاب القبر',
    'اللهم اغفر لي وارحمني واهدني وعافني وارزقني',
    'أعوذ بكلمات الله التامات من شر ما خلق',
    'اللهم إني أسألك الهدى والتقى والعفاف والغنى',
    'سبحانك اللهم وبحمدك أشهد أن لا إله إلا أنت أستغفرك وأتوب إليك',
    'اللهم أعني على ذكرك وشكرك وحسن عبادتك',
    'لا إله إلا أنت سبحانك إني كنت من الظالمين',
    'ربنا تقبل منا إنك أنت السميع العليم',
    'اللهم تقبل صيامنا وقيامنا',
    'اللهم بلغنا ليلة القدر',
    'اللهم إنك عفو كريم تحب العفو فاعف عنا',
    'اللهم اجعلنا من عتقاء هذا الشهر الكريم',
    'ربِّ اجعلني مقيم الصلاة ومن ذريتي',
    'اللهم أحسن خاتمتنا في الأمور كلها',
  ];

  static const List<String> _dailyDuas = [
    'اللهم إني أسألك الجنة وما قرّب إليها من قول أو عمل',
    'ربِّ اغفر لي ولوالديّ وللمؤمنين يوم يقوم الحساب',
    'اللهم إنك عفو تحب العفو فاعف عني',
    'اللهم أصلح لي ديني الذي هو عصمة أمري',
    'ربنا آتنا في الدنيا حسنة وفي الآخرة حسنة وقنا عذاب النار',
    'اللهم اهدني وسددني',
    'اللهم إني أعوذ بك من زوال نعمتك وتحول عافيتك',
    'اللهم أعوذ بك من جهد البلاء ودرك الشقاء وسوء القضاء',
    'ربِّ أوزعني أن أشكر نعمتك التي أنعمت عليّ',
    'اللهم إني أسألك علماً نافعاً ورزقاً طيباً وعملاً متقبلاً',
    'اللهم باعد بيني وبين خطاياي كما باعدت بين المشرق والمغرب',
    'اللهم يا مقلب القلوب ثبت قلبي على دينك',
    'اللهم ارزقنا حُسن الخاتمة',
    'اللهم اجعل القرآن ربيع قلبي ونور صدري',
    'اللهم ارحم والدَيّ كما ربياني صغيراً',
    'ربنا هب لنا من أزواجنا وذرياتنا قرة أعين',
    'اللهم اغفر لي ذنبي كله دقّه وجلّه وأوله وآخره',
    'اللهم إني أسألك من الخير كله عاجله وآجله',
    'اللهم إني أعوذ بك من الشر كله عاجله وآجله',
    'اللهم إني أسألك الثبات في الأمر والعزيمة على الرشد',
    'اللهم أحيني ما دامت الحياة خيراً لي',
    'اللهم لك الحمد حمداً كثيراً طيباً مباركاً فيه',
    'ربنا اصرف عنا عذاب جهنم إن عذابها كان غراماً',
    'اللهم اجعلنا ممن يستمعون القول فيتبعون أحسنه',
    'اللهم تقبل منا صيامنا وقيامنا وركوعنا وسجودنا',
    'اللهم بلغنا رمضان وأعنا فيه على الصيام والقيام',
    'اللهم أعتق رقابنا من النار',
    'اللهم تقبل توبتنا واغسل حوبتنا',
    'اللهم إنا نسألك رضاك والجنة ونعوذ بك من سخطك والنار',
    'اللهم اختم لنا شهر رمضان برضوانك والعتق من نيرانك',
  ];

  /// Iftar dua to show near Maghrib.
  static const String iftarDua =
      'اللهم لك صمت وعلى رزقك أفطرت، ذهب الظمأ وابتلت العروق وثبت الأجر إن شاء الله';
}

/// Daily content model.
class RamadanDailyContent {
  final String ayah;
  final String ayahReference;
  final String dhikr;
  final String dua;

  const RamadanDailyContent({
    required this.ayah,
    required this.ayahReference,
    required this.dhikr,
    required this.dua,
  });
}

/// A single worship item for the Ramadan Hub.
class WorshipItem {
  final String key;
  final String title;
  final String emoji;
  final String category;

  const WorshipItem({
    required this.key,
    required this.title,
    required this.emoji,
    required this.category,
  });
}
