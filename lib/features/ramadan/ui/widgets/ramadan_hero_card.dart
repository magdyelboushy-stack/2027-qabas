import 'package:flutter/material.dart';
import '../../logic/ramadan_service.dart';
import '../screens/ramadan_hub_screen.dart';
import 'package:mihrab/core/services/api_service.dart';

/// رمضان كريم Hero Card — Tappable gateway to Ramadan Hub.
/// Before Ramadan: Shows countdown + "coming soon" dialog on tap.
/// During Ramadan: Navigates to the full Ramadan Hub screen.
/// Supports light and dark themes.
class RamadanHeroCard extends StatefulWidget {
  const RamadanHeroCard({super.key});

  @override
  State<RamadanHeroCard> createState() => _RamadanHeroCardState();
}

class _RamadanHeroCardState extends State<RamadanHeroCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _breathAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    if (!context.mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1️⃣ نحاول نجيب الحالة من السيرفر
    bool? isOpen;
    bool isOffline = false;

    try {
      final settings = await ApiService.getAppSettings()
          .timeout(const Duration(seconds: 3));

      // ✅ FIX: If settings is empty (offline/error) and local is NOT open, treat as offline
      if (settings.isEmpty && !RamadanService.isFeatureOpened()) {
        isOffline = true;
      }
      else if (settings.containsKey('ramadan_feature_open')) {
        final opened = settings['ramadan_feature_open'] == '1';
        RamadanService.setFeatureOpened(opened);
        isOpen = opened;
      } else {
        isOpen = RamadanService.isFeatureOpened();
      }
    } catch (_) {
      // فشل الاتصال → أوفلاين (only if local is not open)
      if (!RamadanService.isFeatureOpened()) {
        isOffline = true;
      }
    }

    if (!context.mounted) return;

    // 2️⃣ لو أوفلاين → رسالة "محتاج نت"
    if (isOffline) {
      _showInfoDialog(
        context: context,
        isDark: isDark,
        emoji: '📡',
        title: 'مفيش اتصال بالإنترنت',
        body: 'الخدمة دي محتاجة اتصال بالإنترنت.\nاتصل بالنت وحاول تاني.',
        buttonText: 'حسنًا',
      );
      return;
    }

    // 3️⃣ لو مقفول → رسالة "هيفتح في رمضان"
    if (isOpen != true) {
      final daysLeft = RamadanService.daysUntilRamadan();
      _showInfoDialog(
        context: context,
        isDark: isDark,
        emoji: '🌙',
        title: 'قسم رمضان قريبًا',
        body: 'سيتم فتح قسم رمضان في رمضان إن شاء الله.\n${daysLeft > 0 ? "باقي $daysLeft ${daysLeft == 1 ? "يوم" : daysLeft == 2 ? "يومان" : "أيام"} على رمضان" : "رمضان قريب جدًا"}',
        buttonText: 'اللهم بلغنا رمضان 🤲',
      );
      return;
    }

    // 4️⃣ مفتوح → يروح لصفحة رمضان
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RamadanHubScreen()),
    );
  }

  /// ديالوج رسائل عام
  void _showInfoDialog({
    required BuildContext context,
    required bool isDark,
    required String emoji,
    required String title,
    required String body,
    required String buttonText,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [const Color(0xFF0D1B2A), const Color(0xFF1B3A2D)]
                  : [const Color(0xFF1B5E20), const Color(0xFF2E7D32)],
            ),
            border: Border.all(
              color: const Color(0xFFFFD700).withOpacity(0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 44)),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFFD700),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                body,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFFD700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDuring = RamadanService.isDuringRamadan();
    final isOpen = RamadanService.isFeatureOpened();
    final dayNumber = RamadanService.currentRamadanDay();
    final daysLeft = RamadanService.daysUntilRamadan();
    final quote = RamadanService.getTodayQuote();

    // Theme-adaptive colors
    final gradientColors = isDark
        ? [const Color(0xFF0D1B2A), const Color(0xFF1B3A2D), const Color(0xFF0D1B2A)]
        : [const Color(0xFF1B5E20), const Color(0xFF2E7D32), const Color(0xFF1B5E20)];
    final titleColor = isDark ? const Color(0xFFFFD700) : const Color(0xFFFFD54F);
    final textColor = Colors.white;
    final subtleColor = Colors.white.withOpacity(isDark ? 0.75 : 0.85);
    final shadowColor = (isDark ? const Color(0xFF0D1B2A) : const Color(0xFF1B5E20)).withOpacity(0.3);
    final badgeBg = Colors.white.withOpacity(isDark ? 0.08 : 0.15);
    final badgeBorder = isDark
        ? const Color(0xFFFFD700).withOpacity(0.2)
        : Colors.white.withOpacity(0.2);

    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _breathAnimation,
        builder: (context, child) {
          return Opacity(opacity: _breathAnimation.value, child: child);
        },
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Moon + Title ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🌙', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text(
                    isOpen && isDuring ? 'رمضان كريم' : 'قريبًا.. رمضان',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Counter ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeBorder),
                ),
                child: Text(
                  isOpen && isDuring
                      ? 'اليوم $dayNumber من رمضان'
                      : 'باقي $daysLeft ${daysLeft == 1 ? "يوم" : daysLeft == 2 ? "يومان" : "أيام"} على رمضان',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ── Daily Quote ──
              Text(
                '﴿ $quote ﴾',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'UthmanTN',
                  fontSize: 15,
                  height: 1.7,
                  color: subtleColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 10),

              // ── CTA hint ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    size: 16,
                    color: Colors.white.withOpacity(0.4),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isDuring ? 'اضغط لفتح صفحة العبادات' : 'اضغط للمزيد',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}