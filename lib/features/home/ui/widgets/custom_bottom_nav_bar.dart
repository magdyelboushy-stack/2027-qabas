import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../settings/ui/screens/settings_screen.dart';
import '../../../quran/ui/screens/shaykhs_screen.dart';
import '../../../../core/translations/app_locale_keys.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final GlobalKey? keyAdhkar;
  final GlobalKey? keySebha;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.keyAdhkar,
    this.keySebha,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String settingsLabel = AppLocaleKeys.settingsTab.tr;
    final String audioLabel = AppLocaleKeys.recitersTab.tr;
    final String quranLabel = AppLocaleKeys.mushafTab.tr;

    final Color activeColor = const Color(0xFF56C7B0);
    final Color inactiveColor = isDark ? const Color(0xFF7A9E93) : const Color(0xFF98B3AB);
    final Color barBgColor = isDark
        ? const Color(0xFF122824).withValues(alpha: 0.98)
        : Colors.white.withValues(alpha: 0.96);

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        // ── 1. جسم البار المنحوت (The Notched Bar) ─────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: CustomPaint(
            size: const Size(double.infinity, 70),
            painter: _NotchedBarPainter(
              color: barBgColor,
              shadowColor: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: SizedBox(
                height: 70,
                child: Row(
                  children: [
                    // يمين: الإعدادات والمصحف
                    Expanded(
                      flex: 2,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _NavItem(
                            key: keySebha,
                            icon: Icons.settings_rounded,
                            label: settingsLabel,
                            isActive: selectedIndex == 4,
                            onTap: () => Get.to(() => const SettingsScreen()),
                            activeColor: activeColor,
                            inactiveColor: inactiveColor,
                          ),
                          _NavItem(
                            icon: Icons.menu_book_rounded,
                            label: quranLabel,
                            isActive: selectedIndex == 1,
                            onTap: () => onItemTapped(1),
                            activeColor: activeColor,
                            inactiveColor: inactiveColor,
                          ),
                        ],
                      ),
                    ),

                    // مساحة فارغة في المنتصف للزرار الكبير
                    const SizedBox(width: 80),

                    // شمال: قراء العالم الإسلامي
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: _NavItem(
                          key: keyAdhkar,
                          icon: Icons.headphones_rounded,
                          label: AppLocaleKeys.islamicWorldRecitersTab.tr,
                          isActive: selectedIndex == 3,
                          onTap: () => Get.to(() => const ShaykhsScreen()),
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── 2. الزرار الكبير (The Floating Button) ──────────────────────
        Positioned(
          bottom: 35, // رفعة الزرار عشان يركب في النوتش
          child: _HomeButton(
            isActive: selectedIndex == 0,
            onTap: () => onItemTapped(0),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

}

// ─────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;
  final Color inactiveColor;

  const _NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : inactiveColor;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: isActive ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
class _HomeButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;

  const _HomeButton({required this.isActive, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: isDark 
              ? [const Color(0xFF56C7B0), const Color(0xFF198873)] 
              : [const Color(0xFF56C7B0), const Color(0xFF0F6A5C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F6A5C).withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: isDark ? const Color(0xFF122824) : Colors.white, width: 4),
        ),
        child: const Icon(Icons.home_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// الرسام الخاص بشكل البار المنحوت
class _NotchedBarPainter extends CustomPainter {
  final Color color;
  final Color shadowColor;

  _NotchedBarPainter({required this.color, required this.shadowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    const double r = 30; // Radius of bar corners
    const double notchR = 45; // Radius of the center notch

    // رسم مسار البار مع الفتحة في المنتصف
    path.moveTo(r, 0);
    path.lineTo(size.width / 2 - notchR, 0);
    
    // القوس الخاص بالزرار الكبير
    path.arcToPoint(
      Offset(size.width / 2 + notchR, 0),
      radius: const Radius.circular(notchR),
      clockwise: false,
    );

    path.lineTo(size.width - r, 0);
    path.quadraticBezierTo(size.width, 0, size.width, r);
    path.lineTo(size.width, size.height - r);
    path.quadraticBezierTo(size.width, size.height, size.width - r, size.height);
    path.lineTo(r, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - r);
    path.lineTo(0, r);
    path.quadraticBezierTo(0, 0, r, 0);

    // إضافة الظل
    canvas.drawShadow(path, shadowColor, 10, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}