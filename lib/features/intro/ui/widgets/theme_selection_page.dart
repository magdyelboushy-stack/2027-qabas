import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:get/get.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/translations/app_locale_keys.dart';

class ThemeSelectionPage extends StatefulWidget {
  final VoidCallback onNext;
  final double pageOffset;
  final Animation<double> floatAnimation;

  const ThemeSelectionPage({
    super.key,
    required this.onNext,
    required this.pageOffset,
    required this.floatAnimation,
  });

  @override
  State<ThemeSelectionPage> createState() => _ThemeSelectionPageState();
}

class _ThemeSelectionPageState extends State<ThemeSelectionPage> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Stack(
      children: [
        Positioned.fill(
          bottom: 90,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),

                // Premium Glowing Header Icon
                AnimatedBuilder(
                  animation: widget.floatAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(widget.pageOffset * 200,
                          widget.floatAnimation.value * 1.5),
                      child: child,
                    );
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Inner Glow
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.amberAccent.withOpacity(0.15)
                                  : Colors.orangeAccent.withOpacity(0.2),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      // Glass Orb
                      ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.02),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                isDark
                                    ? Icons.brightness_3_rounded
                                    : Icons.wb_sunny_rounded,
                                size: 50,
                                color: isDark
                                    ? Colors.amberAccent
                                    : Colors.orangeAccent,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Text Section
                Transform.translate(
                  offset: Offset(widget.pageOffset * 100, 0),
                  child: Column(
                    children: [
                      Text(
                        AppLocaleKeys.spiritualityAndLuxury.tr,
                        style: TextStyle(
                          color: isDark
                              ? Colors.cyanAccent
                              : const Color(0xFF7A8D81),
                          fontSize: 14,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        AppLocaleKeys.appThemeTitle.tr,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : const Color(
                                  0xFF224F34), // WelcomeScreen.darkGreenColor
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        AppLocaleKeys.chooseThemeDesc.tr
                            .tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white70
                              : const Color(
                                  0xFF7A8D81), // WelcomeScreen.mutedTextColor
                          fontSize: 16,
                          height: 1.6,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 45),

                // Glowing Glass Theme Cards (Mihrab Shape)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _GlowingThemeCard(
                        title: AppLocaleKeys.lightThemeName.tr,
                        icon: Icons.light_mode_rounded,
                        activeColor: Colors.orangeAccent,
                        isSelected: !isDark,
                        isDarkGlobal: isDark,
                        onTap: () =>
                            themeProvider.setThemeMode(ThemeMode.light),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _GlowingThemeCard(
                        title: AppLocaleKeys.darkThemeName.tr,
                        icon: Icons.dark_mode_rounded,
                        activeColor: Colors.indigoAccent,
                        isSelected: isDark,
                        isDarkGlobal: isDark,
                        onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),

        // Pinned Button
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: GestureDetector(
                onTap: widget.onNext,
                child: Container(
                  width: double.infinity,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark
                        ? null
                        : const Color(
                            0xFF224F34), // WelcomeScreen.darkGreenColor
                    gradient: isDark
                        ? const LinearGradient(
                            colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(100), // Capsule style
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? const Color(0xFFD4AF37).withOpacity(0.3)
                            : const Color(0xFF224F34).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Text(
                    AppLocaleKeys.continueBtnText.tr.tr,
                    style: TextStyle(
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

class _GlowingThemeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color activeColor;
  final bool isSelected;
  final bool isDarkGlobal;
  final VoidCallback onTap;

  const _GlowingThemeCard({
    required this.title,
    required this.icon,
    required this.activeColor,
    required this.isSelected,
    required this.isDarkGlobal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 190,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkGlobal
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.03))
              : (isDarkGlobal
                  ? Colors.white.withOpacity(0.01)
                  : Colors.black.withOpacity(0.01)),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(90),
            topRight: Radius.circular(90),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(
            color: isSelected
                ? activeColor.withOpacity(isDarkGlobal ? 0.8 : 0.6)
                : (isDarkGlobal ? Colors.white10 : Colors.black12),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(90),
            topRight: Radius.circular(90),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? activeColor.withOpacity(0.2)
                        : Colors.transparent,
                  ),
                  child: Icon(
                    icon,
                    size: 40,
                    color: isSelected
                        ? activeColor
                        : (isDarkGlobal ? Colors.white54 : Colors.black54),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected
                        ? (isDarkGlobal
                            ? Colors.white
                            : const Color(0xFF224F34))
                        : (isDarkGlobal
                            ? Colors.white54
                            : const Color(0xFF7A8D81)),
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedOpacity(
                  opacity: isSelected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.check, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
