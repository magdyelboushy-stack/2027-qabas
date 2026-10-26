import 'package:flutter/material.dart';
import '../../logic/ramadan_service.dart';
import '../../../../core/services/ad_service.dart';

/// رحلة رمضان — Ramadan Journey
/// Gamified spiritual level tracker with XP, levels, and achievement badges.
/// Motivates users to complete more worship items daily.
/// Supports Light & Dark themes.
class RamadanJourneyScreen extends StatefulWidget {
  const RamadanJourneyScreen({super.key});

  @override
  State<RamadanJourneyScreen> createState() => _RamadanJourneyScreenState();
}

class _RamadanJourneyScreenState extends State<RamadanJourneyScreen>
    with TickerProviderStateMixin {
  int _xp = 0;
  List<Map<String, dynamic>> _achievements = [];
  bool _isLoading = true;
  late AnimationController _xpAnimController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _xpAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _load();
    // Show interstitial ad on screen entry
    AdService.showInterstitialAd();
  }

  @override
  void dispose() {
    _xpAnimController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final xp = await RamadanService.calculateTotalXP();
    final achievements = await RamadanService.getAchievements();
    if (mounted) {
      setState(() {
        _xp = xp;
        _achievements = achievements;
        _isLoading = false;
      });
      _xpAnimController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final scaffoldBg = isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF8F5F0);
    final gold = isDark ? const Color(0xFFFFD700) : const Color(0xFFBF8000);
    final cardBg = isDark ? const Color(0xFF141E30) : Colors.white;
    final cardBorder = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.05);
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white60 : Colors.black54;
    final headerGrad = isDark
        ? [const Color(0xFF1A0A30), const Color(0xFF0D1B2A)]
        : [const Color(0xFF4A148C), const Color(0xFF6A1B9A)];

    if (_isLoading) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        body: Center(child: CircularProgressIndicator(color: gold)),
      );
    }

    final level = RamadanService.getLevelForXP(_xp);
    final levelIdx = RamadanService.getLevelIndex(_xp);
    final progress = RamadanService.progressToNextLevel(_xp);
    final isMaxLevel = levelIdx >= RamadanService.levels.length - 1;
    final nextLevel = isMaxLevel
        ? level
        : RamadanService.levels[levelIdx + 1];

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ──
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: headerGrad[0],
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: headerGrad,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      // Animated level emoji
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (ctx, child) {
                          final scale = 1.0 + 0.08 * _pulseController.value;
                          return Transform.scale(scale: scale, child: child);
                        },
                        child: Text(
                          level['emoji'] as String,
                          style: const TextStyle(fontSize: 64),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Level name
                      Text(
                        level['name'] as String,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: gold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // XP counter
                      AnimatedBuilder(
                        animation: _xpAnimController,
                        builder: (ctx, child) {
                          final displayXP = (_xp * _xpAnimController.value).toInt();
                          return Text(
                            '$displayXP XP',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Progress bar to next level
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          children: [
                            AnimatedBuilder(
                              animation: _xpAnimController,
                              builder: (ctx, child) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: progress * _xpAnimController.value,
                                    minHeight: 10,
                                    backgroundColor: Colors.white.withOpacity(0.1),
                                    valueColor: AlwaysStoppedAnimation(gold),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  isMaxLevel ? 'أعلى مستوى! 👑' : 'التالي: ${nextLevel['emoji']} ${nextLevel['name']}',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.4),
                                  ),
                                ),
                                const Spacer(),
                                if (!isMaxLevel)
                                  Text(
                                    '${nextLevel['minXP']} XP',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(0.3),
                                    ),
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
            ),
          ),

          // ── Level Roadmap ──
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                      Text('مستويات الرحلة',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 16,
                              fontWeight: FontWeight.w700, color: textPrimary)),
                      const SizedBox(width: 6),
                      const Text('🗺️', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...List.generate(RamadanService.levels.length, (i) {
                    final lvl = RamadanService.levels[i];
                    final isReached = i <= levelIdx;
                    final isCurrent = i == levelIdx;
                    final lvlColor = isReached ? gold : textSecondary.withOpacity(0.3);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          // Level indicator
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isReached
                                  ? gold.withOpacity(isDark ? 0.15 : 0.1)
                                  : Colors.transparent,
                              border: Border.all(
                                color: lvlColor,
                                width: isCurrent ? 2.5 : 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(lvl['emoji'] as String,
                                style: TextStyle(fontSize: isReached ? 18 : 14)),
                          ),
                          const SizedBox(width: 12),
                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lvl['name'] as String,
                                  style: TextStyle(
                                    fontFamily: 'Cairo', fontSize: 14,
                                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                    color: isReached ? textPrimary : textSecondary.withOpacity(0.5),
                                  ),
                                ),
                                Text(
                                  '${lvl['minXP']} XP',
                                  style: TextStyle(
                                    fontFamily: 'Cairo', fontSize: 11,
                                    color: isReached ? gold : textSecondary.withOpacity(0.3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Status
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: gold.withOpacity(isDark ? 0.12 : 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('أنت هنا',
                                  style: TextStyle(fontFamily: 'Cairo', fontSize: 10,
                                      fontWeight: FontWeight.w700, color: gold)),
                            )
                          else if (isReached)
                            Icon(Icons.check_circle, size: 20, color: gold)
                          else
                            Icon(Icons.lock_outline, size: 18,
                                color: textSecondary.withOpacity(0.2)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // ── XP Breakdown ──
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                      Text('كيف تكسب XP؟',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 16,
                              fontWeight: FontWeight.w700, color: textPrimary)),
                      const SizedBox(width: 6),
                      const Text('💡', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _xpRow('🕌', 'صلاة فرض', '+10 XP', gold, textPrimary, textSecondary),
                  _xpRow('🕌', 'التراويح', '+15 XP', gold, textPrimary, textSecondary),
                  _xpRow('🌃', 'قيام الليل', '+20 XP', gold, textPrimary, textSecondary),
                  _xpRow('📖', 'قراءة قرآن', '+15 XP', gold, textPrimary, textSecondary),
                  _xpRow('🍽️', 'إفطار صائم', '+15 XP', gold, textPrimary, textSecondary),
                  _xpRow('💝', 'صدقة / صلة رحم', '+10 XP', gold, textPrimary, textSecondary),
                  _xpRow('💫', 'أذكار / استغفار / دعاء', '+5 XP', gold, textPrimary, textSecondary),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: gold.withOpacity(isDark ? 0.08 : 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: gold.withOpacity(0.15)),
                      ),
                      child: Text(
                        '🎯 يوم كامل = بونص +50 XP!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Cairo', fontSize: 13,
                          fontWeight: FontWeight.w700, color: gold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Achievements ──
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                      Text('الإنجازات',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 16,
                              fontWeight: FontWeight.w700, color: textPrimary)),
                      const SizedBox(width: 6),
                      const Text('🏅', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_achievements.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          Text('🏅', style: TextStyle(fontSize: 40,
                              color: textSecondary.withOpacity(0.2))),
                          const SizedBox(height: 8),
                          Text(
                            'واصل عباداتك وهتفتح إنجازات!',
                            style: TextStyle(
                              fontFamily: 'Cairo', fontSize: 14,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'أول إنجاز: أكمل ٣ أيام كاملة متتالية 🔥',
                            style: TextStyle(
                              fontFamily: 'Cairo', fontSize: 12,
                              color: textSecondary.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _achievements.map((a) {
                        return Container(
                          width: (MediaQuery.of(context).size.width - 76) / 2,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: gold.withOpacity(isDark ? 0.06 : 0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: gold.withOpacity(0.15)),
                          ),
                          child: Column(
                            children: [
                              Text(a['emoji'] as String,
                                  style: const TextStyle(fontSize: 28)),
                              const SizedBox(height: 4),
                              Text(a['title'] as String,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontFamily: 'Cairo', fontSize: 12,
                                      fontWeight: FontWeight.w700, color: textPrimary)),
                              Text(a['desc'] as String,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontFamily: 'Cairo', fontSize: 10,
                                      color: textSecondary)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),

          // ── Motivational quote ──
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1A0A30), const Color(0xFF0D1B2A)]
                      : [const Color(0xFF4A148C), const Color(0xFF6A1B9A)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  Text(_getMotivation(levelIdx),
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'Cairo', fontSize: 16,
                        fontWeight: FontWeight.w600, height: 1.8,
                        color: gold,
                      )),
                  const SizedBox(height: 8),
                  Text(
                    'كل عبادة تقربك خطوة من الجنة',
                    style: TextStyle(
                      fontFamily: 'Cairo', fontSize: 13,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ✅ Banner Ad
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AdService.bannerAdWidget(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _xpRow(String emoji, String title, String xp,
      Color gold, Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: gold.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(xp,
                style: TextStyle(fontFamily: 'Cairo', fontSize: 11,
                    fontWeight: FontWeight.w700, color: gold)),
          ),
          const Spacer(),
          Text(title,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 13,
                  color: textPrimary.withOpacity(0.7))),
          const SizedBox(width: 8),
          Text(emoji, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  String _getMotivation(int level) {
    switch (level) {
      case 0: return '🌱 بداية رائعة!\nكل خطوة نحو الله تستحق';
      case 1: return '🌿 ماشاء الله!\nجهدك بيّن.. واصل';
      case 2: return '🌳 تبارك الله!\nأنت في الطريق الصح';
      case 3: return '⭐ مواظب يا بطل!\nثباتك مُلهم';
      case 4: return '🌙 خاشع!\nربنا يثبتك ويزيدك';
      case 5: return '💎 مُحسن!\nأنت مثال يُحتذى';
      case 6: return '👑 صدّيق!\nربنا يتقبل منك';
      default: return '🌙 واصل رحلتك مع الله';
    }
  }
}
