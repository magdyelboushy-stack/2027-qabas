import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import '../../logic/ramadan_service.dart';
import '../../../prayers/logic/prayer_times_controller.dart';
import 'package:mihrab/features/auth/data/auth_service.dart';
import 'ramadan_journey_screen.dart';
import 'leaderboard_screen.dart';
import 'fawanees_screen.dart';
import 'fasting_tracker_screen.dart';
import '../../../../core/services/ad_service.dart';

/// Ramadan Hub Screen — The comprehensive Ramadan tracking experience.
/// 16 worship items • 3 categories • 30-day calendar • Stats • Daily content.
/// Supports Light & Dark themes.
class RamadanHubScreen extends StatefulWidget {
  const RamadanHubScreen({super.key});

  @override
  State<RamadanHubScreen> createState() => _RamadanHubScreenState();
}

class _RamadanHubScreenState extends State<RamadanHubScreen>
    with TickerProviderStateMixin {
  Map<String, bool> _worship = {};
  Map<String, dynamic> _stats = {};
  List<double> _calendarData = [];
  bool _isLoading = true;
  bool _isAuthenticated = false;
  late AnimationController _progressController;
  PrayerTimes? _prayerTimes;

  /// Keys of prayers that are time-gated.
  static const _gatedKeys = {
    'fajr',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
    'taraweeh',
    'qiyam',
    'witr'
  };

  int get _day => RamadanService.currentRamadanDay(); // 0 = before Ramadan
  bool get _isDuringRamadan => RamadanService.isDuringRamadan();

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _load();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    // Check Auth
    final user = await AuthService.getCurrentUser();
    _isAuthenticated = user != null;

    if (_isAuthenticated) {
      // Sync if online
      RamadanService.syncProgress();
    }

    final effectiveDay = _day.clamp(1, 30); // For data loading only
    final worship = _isDuringRamadan
        ? await RamadanService.getHubDay(effectiveDay)
        : <String, bool>{};
    final stats = await RamadanService.getMonthStats();
    // Load prayer times
    try {
      _prayerTimes =
          await PrayerTimesController().getStoredOrDefaultPrayerTimes();
    } catch (_) {}
    // Load calendar completions
    final cal = <double>[];
    for (int d = 1; d <= 30; d++) {
      if (_isDuringRamadan && d <= effectiveDay) {
        cal.add(await RamadanService.dayCompletion(d));
      } else {
        cal.add(-1); // Future day or before Ramadan
      }
    }
    if (mounted) {
      setState(() {
        _worship = worship;
        _stats = stats;
        _calendarData = cal;
        _isLoading = false;
      });
      _progressController.forward();
    }
  }

  /// Get the unlock time for a prayer key.
  DateTime? _getUnlockTime(String key) {
    if (_prayerTimes == null) return null;
    switch (key) {
      case 'fajr':
        return _prayerTimes!.fajr;
      case 'dhuhr':
        return _prayerTimes!.dhuhr;
      case 'asr':
        return _prayerTimes!.asr;
      case 'maghrib':
        return _prayerTimes!.maghrib;
      case 'isha':
        return _prayerTimes!.isha;
      // Taraweeh, Qiyam, and Witr depend on Isha
      case 'taraweeh':
      case 'qiyam':
      case 'witr':
        return _prayerTimes!.isha;
      default:
        return null;
    }
  }

  /// Whether a prayer key is currently unlocked.
  bool _isPrayerUnlocked(String key) {
    if (!_gatedKeys.contains(key))
      return true; // Non-time-gated items always unlocked
    final unlockTime = _getUnlockTime(key);
    if (unlockTime == null) return true; // If no prayer times, allow anyway
    return DateTime.now().isAfter(unlockTime);
  }

  static const Map<String, String> _prayerArabicNames = {
    'fajr': 'الفجر',
    'dhuhr': 'الظهر',
    'asr': 'العصر',
    'maghrib': 'المغرب',
    'isha': 'العشاء',
    'taraweeh': 'العشاء (للتراويح)',
    'qiyam': 'العشاء (للقيام)',
    'witr': 'العشاء (للوتر)',
  };

  Future<void> _toggle(String key) async {
    // ⛔ لا يمكن التتبع قبل رمضان
    if (!_isDuringRamadan) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🌙 التتبع يبدأ مع أول يوم من رمضان إن شاء الله',
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
            ),
            backgroundColor: Colors.blueGrey.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    // Gate prayers by time
    if (_gatedKeys.contains(key) && !_isPrayerUnlocked(key)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🔒 لسه أذان ${_prayerArabicNames[key] ?? "الصلاة"} ما أذّنش',
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
            ),
            backgroundColor: Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    final effectiveDay = _day.clamp(1, 30);
    final newVal = !(_worship[key] ?? false);
    setState(() => _worship[key] = newVal);
    await RamadanService.toggleHubItem(effectiveDay, key, newVal);
    // Refresh stats
    final stats = await RamadanService.getMonthStats();
    final comp = await RamadanService.dayCompletion(effectiveDay);
    if (mounted) {
      setState(() {
        _stats = stats;
        _calendarData[effectiveDay - 1] = comp;
      });
    }
  }

  int get _todayDone => _worship.values.where((v) => v).length;
  int get _todayTotal => RamadanService.allWorshipItems.length;
  double get _todayRatio => _todayTotal > 0 ? _todayDone / _todayTotal : 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme colors
    final scaffoldBg =
        isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF8F5F0);
    final headerGrad = isDark
        ? [const Color(0xFF0D1B2A), const Color(0xFF1B3A2D)]
        : [const Color(0xFF1B5E20), const Color(0xFF2E7D32)];
    final gold = isDark ? const Color(0xFFFFD700) : const Color(0xFFBF8000);
    final cardBg = isDark ? const Color(0xFF141E30) : Colors.white;
    final cardBorder = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.05);
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white70 : Colors.black54;
    final sectionLabelColor = isDark ? gold : const Color(0xFF1B5E20);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        body: Center(child: CircularProgressIndicator(color: gold)),
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Gradient Header ──
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: headerGrad[0],
                leading: IconButton(
                  icon:
                      const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: headerGrad,
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 30),
                          // Moon + Title
                          const Text('🌙', style: TextStyle(fontSize: 36)),
                          const SizedBox(height: 8),
                          Text(
                            _isDuringRamadan ? 'رمضان كريم' : 'قريبًا.. رمضان',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: gold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Day counter or countdown badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              _isDuringRamadan
                                  ? 'اليوم $_day من ٣٠'
                                  : 'باقي ${RamadanService.daysUntilRamadan()} يوم على رمضان',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Fawanees Journey Banner ──
              SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FawaneesScreen()),
                    );
                    _load(); // Refresh stats/XP after potential changes
                  },
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF141E30), const Color(0xFF243B55)]
                            : [
                                const Color(0xFFFFD700),
                                const Color(0xFFFFA000)
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? Colors.black : Colors.orange)
                              .withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child:
                              const Text('🏮', style: TextStyle(fontSize: 28)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'رحلة الفوانيس',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'عش أجواء رمضان في رحلة يومية مبهرة ✨',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                  color:
                                      isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: isDark ? Colors.white54 : Colors.black45,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Fasting Tracker Button (New) ──
              SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FastingTrackerScreen()),
                    );
                    _load(); // Refresh stats/XP after potential changes
                  },
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: isDark ? const Color(0xFF2C3E50) : Colors.white,
                      border: Border.all(color: cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          color:
                              isDark ? Colors.lightBlueAccent : Colors.blueGrey,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'سجل الصيام ومتابعة الأيام الفائتة',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: textSecondary,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Today's Progress Ring ──
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.black : Colors.grey)
                            .withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Stats text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إنجاز اليوم',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_todayDone من $_todayTotal عبادة',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if ((_stats['streak'] ?? 0) > 0)
                              Row(
                                children: [
                                  Text(
                                    '${_stats['streak']} يوم متتالي',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: gold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text('🔥',
                                      style: TextStyle(fontSize: 16)),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Progress Ring
                      AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, child) {
                          return SizedBox(
                            width: 80,
                            height: 80,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: CircularProgressIndicator(
                                    value:
                                        _todayRatio * _progressController.value,
                                    strokeWidth: 8,
                                    backgroundColor: isDark
                                        ? Colors.white.withOpacity(0.08)
                                        : Colors.grey.withOpacity(0.12),
                                    valueColor: AlwaysStoppedAnimation(gold),
                                    strokeCap: StrokeCap.round,
                                  ),
                                ),
                                Text(
                                  '${(_todayRatio * 100 * _progressController.value).toInt()}%',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: gold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // ── Categories ──
              for (final cat in RamadanService.worshipCategories) ...[
                // Category header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          cat,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: sectionLabelColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _categoryEmoji(cat),
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
                // Category grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final items = RamadanService.itemsForCategory(cat);
                        if (i >= items.length) return null;
                        final item = items[i];
                        final done = _worship[item.key] ?? false;
                        return _buildTile(item, done, isDark, gold, cardBg,
                            cardBorder, textPrimary);
                      },
                      childCount: RamadanService.itemsForCategory(cat).length,
                    ),
                  ),
                ),
              ],

              // ── Ramadan Journey CTA ──
              SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RamadanJourneyScreen()),
                    );
                    _load(); // Refresh data upon return
                  },
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 18, 16, 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1A1040), const Color(0xFF0D1B2A)]
                            : [
                                const Color(0xFF4A148C),
                                const Color(0xFF6A1B9A)
                              ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: gold.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'رحلة رمضان 🏆',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: gold,
                              ),
                            ),
                            Text(
                              'مستواك وإنجازاتك في رمضان',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Manually mirror for RTL since Icon doesn't support matchTextDirection
                        Transform.scale(
                          scaleX:
                              Directionality.of(context) == TextDirection.rtl
                                  ? -1
                                  : 1,
                          child: Icon(Icons.arrow_forward_ios,
                              size: 16, color: Colors.white.withOpacity(0.4)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Leaderboard CTA (New) ──
              SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LeaderboardScreen()),
                    );
                    _load(); // Refresh data upon return
                  },
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF2C3E50), const Color(0xFF4CA1AF)]
                            : [
                                const Color(0xFF134E5E),
                                const Color(0xFF71B280)
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark
                                  ? const Color(0xFF4CA1AF)
                                  : const Color(0xFF71B280))
                              .withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'لوحة الأبطال 🥇',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'نافس المتسابقين وتصدر القائمة',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Transform.scale(
                          scaleX:
                              Directionality.of(context) == TextDirection.rtl
                                  ? -1
                                  : 1,
                          child: Icon(Icons.arrow_forward_ios,
                              size: 16, color: Colors.white.withOpacity(0.8)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Daily Content ──
              SliverToBoxAdapter(
                child: _buildDailyContent(isDark, gold, cardBg, cardBorder,
                    textPrimary, textSecondary),
              ),

              // ── 30-Day Calendar ──
              SliverToBoxAdapter(
                child: _buildCalendar(isDark, gold, cardBg, cardBorder,
                    textPrimary, textSecondary),
              ),

              // ── Month Stats ──
              SliverToBoxAdapter(
                child: _buildMonthStats(isDark, gold, cardBg, cardBorder,
                    textPrimary, textSecondary),
              ),

              // ✅ Banner Ad
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: AdService.bannerAdWidget(),
                ),
              ),

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
          if (!_isAuthenticated && !_isLoading) _buildAuthBlocker(isDark, gold),
        ],
      ),
    );
  }

  Widget _buildAuthBlocker(bool isDark, Color gold) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        color: (isDark ? Colors.black : Colors.white).withOpacity(0.8),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_rounded, size: 64, color: gold),
              const SizedBox(height: 20),
              const Text(
                'سجل دخولك لتفعيل رحلة رمضان',
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'يجب تسجيل الدخول بحساب Google\nلحفظ عبادتك ومزامنتها والمنافسة في لوحة الأبطال',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Cairo', fontSize: 14),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () async {
                  setState(() => _isLoading = true);
                  try {
                    await AuthService.signInWithGoogle();
                    if (mounted) {
                      setState(() {
                        _isAuthenticated = true;
                        _isLoading = false;
                      });
                      _load(); // Sync data
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              e.toString().replaceAll('Exception: ', ''))));
                    }
                  }
                },
                icon: const Icon(Icons.login),
                label: const Text('تسجيل الدخول بواسطة Google',
                    style: TextStyle(fontFamily: 'Cairo')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: gold,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tile Builder ──
  Widget _buildTile(WorshipItem item, bool done, bool isDark, Color gold,
      Color cardBg, Color cardBorder, Color textPrimary) {
    final locked = !_isPrayerUnlocked(item.key) && !done;

    return GestureDetector(
      onTap: () => _toggle(item.key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: done
              ? gold.withOpacity(isDark ? 0.12 : 0.08)
              : locked
                  ? (isDark
                      ? Colors.white.withOpacity(0.02)
                      : Colors.grey.withOpacity(0.04))
                  : cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: done ? gold.withOpacity(0.4) : cardBorder,
            width: done ? 1.5 : 1,
          ),
          boxShadow: done
              ? [BoxShadow(color: gold.withOpacity(0.1), blurRadius: 8)]
              : null,
        ),
        child: Opacity(
          opacity: locked ? 0.4 : 1.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Emoji
              Text(item.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              // Label
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 10,
                  fontWeight: done ? FontWeight.w700 : FontWeight.w500,
                  color: done ? gold : textPrimary.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // Check indicator or lock
              if (locked)
                Icon(Icons.lock_outline_rounded,
                    size: 16, color: textPrimary.withOpacity(0.3))
              else
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? gold : Colors.transparent,
                    border: Border.all(
                      color: done ? gold : textPrimary.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: done
                      ? Icon(
                          Icons.check_rounded,
                          size: 13,
                          color:
                              isDark ? const Color(0xFF0A0E1A) : Colors.white,
                        )
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Daily Content Section ──
  Widget _buildDailyContent(bool isDark, Color gold, Color cardBg,
      Color cardBorder, Color textPrimary, Color textSecondary) {
    final content = RamadanService.getRandomContent();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Text('📖 آية اليوم',
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: gold)),
          const SizedBox(height: 12),
          Text(
            '﴿ ${content.ayah} ﴾',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'UthmanTN',
              fontSize: 18,
              height: 2.0,
              color: textPrimary.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 6),
          Text(content.ayahReference,
              style: TextStyle(
                  fontFamily: 'Cairo', fontSize: 12, color: textSecondary)),
          const Divider(height: 28),
          Text('🤲 دعاء اليوم',
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: gold)),
          const SizedBox(height: 8),
          Text(
            content.dua,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              height: 1.8,
              color: textPrimary.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  // ── 30-Day Calendar ──
  Widget _buildCalendar(bool isDark, Color gold, Color cardBg, Color cardBorder,
      Color textPrimary, Color textSecondary) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('تقويم رمضان',
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary)),
              const SizedBox(width: 6),
              const Text('📅', style: TextStyle(fontSize: 18)),
            ],
          ),
          const SizedBox(height: 14),
          // Grid
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: List.generate(30, (i) {
              final dayNum = i + 1;
              final isToday = dayNum == _day;
              final comp = _calendarData[i];
              final isFuture = comp < 0;

              Color bg;
              Color textColor;

              if (isFuture) {
                bg = isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.grey.withOpacity(0.08);
                textColor = textSecondary.withOpacity(0.4);
              } else if (comp >= 0.8) {
                bg = gold.withOpacity(0.2);
                textColor = gold;
              } else if (comp >= 0.5) {
                bg = Colors.orange.withOpacity(0.15);
                textColor = Colors.orange;
              } else if (comp > 0) {
                bg = Colors.red.withOpacity(0.1);
                textColor = Colors.redAccent;
              } else {
                bg = isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.grey.withOpacity(0.08);
                textColor = textSecondary;
              }

              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                  border: isToday ? Border.all(color: gold, width: 2) : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$dayNum',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                    color: textColor,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(gold.withOpacity(0.2), '٨٠٪+', textSecondary),
              const SizedBox(width: 12),
              _legendDot(
                  Colors.orange.withOpacity(0.15), '٥٠٪+', textSecondary),
              const SizedBox(width: 12),
              _legendDot(Colors.red.withOpacity(0.1), '<٥٠٪', textSecondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label, Color textColor) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 4),
        Text(label,
            style:
                TextStyle(fontFamily: 'Cairo', fontSize: 11, color: textColor)),
      ],
    );
  }

  // ── Month Stats ──
  Widget _buildMonthStats(bool isDark, Color gold, Color cardBg,
      Color cardBorder, Color textPrimary, Color textSecondary) {
    final totalDone = _stats['totalDone'] ?? 0;
    final totalPossible = _stats['totalPossible'] ?? 1;
    final streak = _stats['streak'] ?? 0;
    final daysTracked = _stats['daysTracked'] ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('إحصائياتك',
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary)),
              const SizedBox(width: 6),
              const Text('📊', style: TextStyle(fontSize: 18)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _statCard('$streak', 'سلسلة 🔥', gold, isDark),
              const SizedBox(width: 8),
              _statCard(
                '${totalPossible > 0 ? (totalDone * 100 ~/ totalPossible) : 0}%',
                'الإنجاز الكلي',
                Colors.teal,
                isDark,
              ),
              const SizedBox(width: 8),
              _statCard(
                  '$daysTracked', 'أيام التتبع', Colors.deepPurple, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, Color accent, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: accent.withOpacity(isDark ? 0.08 : 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: accent)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    color: isDark ? Colors.white60 : Colors.black54)),
          ],
        ),
      ),
    );
  }

  String _categoryEmoji(String cat) {
    switch (cat) {
      case 'الصلاة':
        return '🕌';
      case 'القرآن والذكر':
        return '📖';
      case 'الإحسان':
        return '💝';
      default:
        return '🌙';
    }
  }
}
