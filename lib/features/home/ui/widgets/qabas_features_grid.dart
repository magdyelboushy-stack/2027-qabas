import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

import '../../../../core/translations/app_locale_keys.dart';

class QabasFeaturesGrid extends StatelessWidget {
  final VoidCallback onQuranTapped;
  final VoidCallback onMasbahaTapped;
  final VoidCallback onQiblaTapped;
  final VoidCallback onCommunityTapped;
  final VoidCallback onHisnTapped;

  const QabasFeaturesGrid({
    super.key,
    required this.onQuranTapped,
    required this.onMasbahaTapped,
    required this.onQiblaTapped,
    required this.onCommunityTapped,
    required this.onHisnTapped,
  });

  @override
  Widget build(BuildContext context) {
    final isEnglish = Get.locale?.languageCode == 'en';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final features = <_FeatureItemData>[
      _FeatureItemData(
        title: AppLocaleKeys.quran.tr,
        assetPath: 'assets/images/feature_icons/quran.png',
        fallbackIcon: FontAwesomeIcons.bookQuran,
        onTap: onQuranTapped,
      ),
      _FeatureItemData(
        title: AppLocaleKeys.masbaha.tr,
        assetPath: 'assets/images/feature_icons/masbaha.png',
        fallbackIcon: FontAwesomeIcons.bahai,
        onTap: onMasbahaTapped,
      ),
      _FeatureItemData(
        title: AppLocaleKeys.qibla.tr,
        assetPath: 'assets/images/feature_icons/qibla.png',
        fallbackIcon: FontAwesomeIcons.compass,
        onTap: onQiblaTapped,
      ),

      _FeatureItemData(
        title: AppLocaleKeys.hisnAlmuslim.tr,
        assetPath: 'assets/images/feature_icons/hisn.png',
        fallbackIcon: FontAwesomeIcons.bookOpenReader,
        onTap: onHisnTapped,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF112824) : Colors.white,
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color:
                  (isDark ? const Color(0xFF071513) : const Color(0xFF0A5448))
                      .withValues(alpha: isDark ? 0.24 : 0.08),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocaleKeys.features.tr,
              textAlign: TextAlign.start,
              style: TextStyle(
                color:
                    isDark ? const Color(0xFF8CE2CF) : const Color(0xFF0F6A5C),
                fontSize: 26,
                fontWeight: FontWeight.w900,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 18),
            Directionality(
              textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: features
                    .map(
                      (feature) => Expanded(
                        child: _FeatureBubble(
                          data: feature,
                          isDark: isDark,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PagerDot(isActive: false, isDark: isDark),
                  const SizedBox(width: 6),
                  _PagerDot(isActive: false, isDark: isDark),
                  const SizedBox(width: 6),
                  _PagerDot(isActive: true, isDark: isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureBubble extends StatelessWidget {
  final _FeatureItemData data;
  final bool isDark;

  const _FeatureBubble({
    required this.data,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isDark
        ? (data.isHighlighted
            ? const Color(0xFF163D37)
            : const Color(0xFF18342F))
        : (data.isHighlighted
            ? const Color(0xFFE2F6F0)
            : const Color(0xFFF2F8F5));

    final titleColor = isDark
        ? (data.isHighlighted
            ? const Color(0xFF92E4D2)
            : const Color(0xFFBCD4CD))
        : (data.isHighlighted
            ? const Color(0xFF0F6A5C)
            : const Color(0xFF6D8A83));

    return GestureDetector(
      onTap: data.onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: bubbleColor,
                shape: BoxShape.circle,
                boxShadow: data.isHighlighted
                    ? [
                        BoxShadow(
                          color:
                              const Color(0xFF0F6A5C).withValues(alpha: 0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: _FeatureVisual(
                  assetPath: data.assetPath,
                  fallbackIcon: data.fallbackIcon,
                  color: titleColor,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              data.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: titleColor,
                fontSize: 11.5,
                fontWeight:
                    data.isHighlighted ? FontWeight.w900 : FontWeight.w700,
                fontFamily: 'Cairo',
                height: 1.18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureVisual extends StatelessWidget {
  final String assetPath;
  final IconData fallbackIcon;
  final Color color;

  const _FeatureVisual({
    required this.assetPath,
    required this.fallbackIcon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        return Icon(
          fallbackIcon,
          size: 19,
          color: color,
        );
      },
    );
  }
}

class _FeatureItemData {
  final String title;
  final String assetPath;
  final IconData fallbackIcon;
  final VoidCallback onTap;
  final bool isHighlighted;

  const _FeatureItemData({
    required this.title,
    required this.assetPath,
    required this.fallbackIcon,
    required this.onTap,
    this.isHighlighted = false,
  });
}

class _PagerDot extends StatelessWidget {
  final bool isActive;
  final bool isDark;

  const _PagerDot({
    required this.isActive,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isActive ? 9 : 7,
      height: isActive ? 9 : 7,
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF0F6A5C)
            : (isDark ? const Color(0xFF35554D) : const Color(0xFFD6E6E0)),
        shape: BoxShape.circle,
      ),
    );
  }
}
