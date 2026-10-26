import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/translations/app_locale_keys.dart';

class StateRadiosBanner extends StatelessWidget {
  final VoidCallback onTap;

  const StateRadiosBanner({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnglish = Get.locale?.languageCode == 'en';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradient = isDark
        ? const [Color(0xFF173A35), Color(0xFF1B5248), Color(0xFF245F53)]
        : const [Color(0xFFC7BE56), Color(0xFF35A17D), Color(0xFF157C6D)];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Directionality(
        textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.14),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: isDark ? 0.10 : 0.18,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.radio_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocaleKeys.stateRadiosNewFeature.tr,
                            textAlign:
                                isEnglish ? TextAlign.left : TextAlign.right,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.82),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocaleKeys.stateRadiosTitle.tr,
                            textAlign:
                                isEnglish ? TextAlign.left : TextAlign.right,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            AppLocaleKeys.stateRadiosDescription.tr,
                            textAlign:
                                isEnglish ? TextAlign.left : TextAlign.right,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Cairo',
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: isDark ? 0.10 : 0.18,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isEnglish
                            ? Icons.arrow_forward_ios_rounded
                            : Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
