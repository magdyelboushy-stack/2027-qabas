import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/translations/app_locale_keys.dart';

class PremiumAdhkarSection extends StatelessWidget {
  final VoidCallback onMorningTapped;
  final VoidCallback onEveningTapped;
  final VoidCallback onNewFeatureTapped;
  final bool showNewFeatureBanner;

  const PremiumAdhkarSection({
    super.key,
    required this.onMorningTapped,
    required this.onEveningTapped,
    required this.onNewFeatureTapped,
    this.showNewFeatureBanner = true,
  });

  static const Color _darkGreen = Color(0xFF1A3D2F);

  Widget _buildAdhkarCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final cardColor = isDark ? const Color(0xFF152920) : Colors.white;
    final titleColor = isDark ? Colors.white : _darkGreen;
    final subColor = isDark ? Colors.white38 : Colors.black38;
    final borderColor =
        isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFECF0EE);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                fontFamily: 'Cairo',
                color: titleColor,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'Cairo',
                color: subColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Get.locale?.languageCode == 'en'
                      ? Icons.arrow_forward_ios_rounded
                      : Icons.arrow_back_ios_new_rounded,
                  size: 11,
                  color: iconColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : _darkGreen;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              AppLocaleKeys.dailyAdhkar.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                fontFamily: 'Cairo',
                color: titleColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAdhkarCard(
                  context: context,
                  title: AppLocaleKeys.morningAdhkar.tr,
                  subtitle: AppLocaleKeys.morningAdhkarSubtitle.tr,
                  icon: Icons.wb_sunny_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  iconBg: const Color(0xFFFFF8E7),
                  onTap: onMorningTapped,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAdhkarCard(
                  context: context,
                  title: AppLocaleKeys.eveningAdhkar.tr,
                  subtitle: AppLocaleKeys.eveningAdhkarSubtitle.tr,
                  icon: Icons.nightlight_round,
                  iconColor: const Color(0xFF6366F1),
                  iconBg: const Color(0xFFEEEDFD),
                  onTap: onEveningTapped,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          if (showNewFeatureBanner) ...[
            const SizedBox(height: 12),
            _buildRadioBanner(context, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildRadioBanner(BuildContext context, bool isDark) {
    final bgColor = isDark ? const Color(0xFF1A3D2F) : const Color(0xFF224F34);
    return GestureDetector(
      onTap: onNewFeatureTapped,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.radio_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocaleKeys.liveStream.tr,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Cairo',
                      color: Colors.white.withOpacity(0.65),
                    ),
                  ),
                  Text(
                    AppLocaleKeys.quranRadio.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Cairo',
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Get.locale?.languageCode == 'en'
                  ? Icons.arrow_forward_ios_rounded
                  : Icons.arrow_back_ios_new_rounded,
              color: Colors.white54,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
