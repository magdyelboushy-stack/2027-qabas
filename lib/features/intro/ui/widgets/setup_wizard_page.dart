import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme_provider.dart';
import 'package:get/get.dart';
import '../../../../core/translations/app_locale_keys.dart';

class SetupWizardPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Widget child;
  final VoidCallback onNext;
  final String nextButtonText;
  final bool showNextButton;
  final double pageOffset;
  final Animation<double> floatAnimation;

  const SetupWizardPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.child,
    required this.onNext,
    this.nextButtonText = AppLocaleKeys.nextBtn,
    this.showNextButton = true,
    required this.pageOffset,
    required this.floatAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Stack(
      children: [
        // Scrollable Content
        Positioned.fill(
          bottom: showNextButton ? 90 : 20,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),

                // Floating Icon
                AnimatedBuilder(
                  animation: floatAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(pageOffset * 200, floatAnimation.value),
                      child: child,
                    );
                  },
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.05),
                          isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.02),
                        ],
                      ),
                      border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.2)
                              : Colors.black.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                            color: accentColor.withOpacity(0.3),
                            blurRadius: 40,
                            offset: const Offset(0, 20))
                      ],
                    ),
                    child: Icon(icon, size: 90, color: accentColor),
                  ),
                ),

                const SizedBox(height: 60),

                // Text Section
                Transform.translate(
                  offset: Offset(pageOffset * 100, 0),
                  child: Column(
                    children: [
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: accentColor.withOpacity(0.8),
                          fontSize: 14,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        title,
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                  color: isDark
                                      ? Colors.black54
                                      : Colors.grey.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5))
                            ]),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Page Content
                child,

                const SizedBox(height: 20), // Bottom padding
              ],
            ),
          ),
        ),

        // Pinned Button with SafeArea
        if (showNextButton)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: GestureDetector(
                  onTap: onNext,
                  child: Container(
                    width: double.infinity,
                    height: 55,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Text(
                      nextButtonText.tr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class SetupOptionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const SetupOptionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 180,
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.2)
              : (isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1)),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 30,
                color: isSelected
                    ? color
                    : (isDark ? Colors.white70 : Colors.black54)),
            const SizedBox(height: 15),
            Text(title,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? color
                        : (isDark ? Colors.white : Colors.black))),
            if (isSelected) ...[
              const SizedBox(height: 8),
              Icon(Icons.check_circle, color: color, size: 20),
            ]
          ],
        ),
      ),
    );
  }
}
