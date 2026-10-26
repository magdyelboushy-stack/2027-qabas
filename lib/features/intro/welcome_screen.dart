import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:mihrab/features/intro/setup_wizard_screen.dart';
import '../../core/translations/app_locale_keys.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  // Colors
  static const Color creamColor = Color(0xFFFBF9F1);
  static const Color mintGreenColor = Color(0xFFE5F0EA);
  static const Color darkGreenColor = Color(0xFF224F34);
  static const Color mutedTextColor = Color(0xFF7A8D81);
  static const Color badgeBgColor = Color(0xFFFBE5C8);
  static const Color badgeTextColor = Color(0xFFB57C34);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _floatController;

  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;

  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  late Animation<double> _cardOpacity;
  late Animation<Offset> _cardSlide;

  late Animation<double> _actionsOpacity;
  late Animation<Offset> _actionsSlide;

  late Animation<Offset> _floatAnimation;

  @override
  void initState() {
    super.initState();

    // Entrance animations (1.5 seconds total for smoothness)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Floating animation (repeats infinitely)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Define staggered intervals
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );
    _logoScale = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack)),
    );

    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.2, 0.6, curve: Curves.easeOut)),
    );
    _textSlide =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic)),
    );

    _cardOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.4, 0.8, curve: Curves.easeOut)),
    );
    _cardSlide =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic)),
    );

    _actionsOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.6, 1.0, curve: Curves.easeOut)),
    );
    _actionsSlide =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _entranceController,
          curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic)),
    );

    _floatAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.03)).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    // Start entrance
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              WelcomeScreen.creamColor,
              WelcomeScreen.mintGreenColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 1),

                // Animated Logo
                FadeTransition(
                  opacity: _logoOpacity,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: _buildLogo(),
                  ),
                ),

                const SizedBox(height: 24),

                // Animated Title and Subtitle
                FadeTransition(
                  opacity: _textOpacity,
                  child: SlideTransition(
                    position: _textSlide,
                    child: Column(
                      children: [
                        Text(
                          AppLocaleKeys.welcomeTitle.tr,
                          style: GoogleFonts.cairo(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: WelcomeScreen.darkGreenColor,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocaleKeys.welcomeSubtitle.tr,
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: WelcomeScreen.mutedTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // Animated Ayah Card with Floating effect
                FadeTransition(
                  opacity: _cardOpacity,
                  child: SlideTransition(
                    position: _cardSlide,
                    child: SlideTransition(
                      position: _floatAnimation,
                      child: const AyahCardWidget(),
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // Animated Actions (Button & Language)
                FadeTransition(
                  opacity: _actionsOpacity,
                  child: SlideTransition(
                    position: _actionsSlide,
                    child: Column(
                      children: [
                        PrimaryButtonWidget(
                          title: AppLocaleKeys.startJourney.tr,
                          icon: Icons.west_rounded, // Always points left
                          onTap: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('has_seen_onboarding', true);
                            Get.to(() => const SetupWizardScreen(),
                                transition: Transition.fadeIn);
                          },
                        ),

                        const SizedBox(height: 24),

                        // Secondary Action (Language)
                        Center(
                          child: _SecondaryActionWidget(
                            title: AppLocaleKeys.language.tr,
                            icon: Icons.language_rounded,
                            onTap: () {
                              if (Get.locale?.languageCode == 'ar') {
                                Get.updateLocale(const Locale('en', 'US'));
                              } else {
                                Get.updateLocale(const Locale('ar', 'EG'));
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 128,
      height: 128,
      decoration: BoxDecoration(
        color: WelcomeScreen.darkGreenColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: WelcomeScreen.darkGreenColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Image.asset(
          'assets/logo.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.spa_rounded,
            size: 50,
            color: WelcomeScreen.creamColor,
          ),
        ),
      ),
    );
  }
}

class AyahCardWidget extends StatelessWidget {
  const AyahCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: WelcomeScreen.badgeBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  AppLocaleKeys.verseOfTheDay.tr,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: WelcomeScreen.badgeTextColor,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Quote Mark
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    color: WelcomeScreen.darkGreenColor.withOpacity(0.2),
                    size: 32,
                  ),
                ],
              ),

              // Ayah
              Text(
                AppLocaleKeys.bismillah.tr,
                textAlign: TextAlign.center,
                style: GoogleFonts.amiri(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: WelcomeScreen.darkGreenColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),

              // Translation
              Text(
                '"Verily, in the remembrance of Allah do hearts find rest."'.tr,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: WelcomeScreen.mutedTextColor,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  RotatedBox(
                    quarterTurns: 2,
                    child: Icon(
                      Icons.format_quote_rounded,
                      color: WelcomeScreen.darkGreenColor.withOpacity(0.2),
                      size: 32,
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

class PrimaryButtonWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const PrimaryButtonWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: WelcomeScreen.darkGreenColor,
          borderRadius: BorderRadius.circular(100), // iOS Capsule style
          boxShadow: [
            BoxShadow(
              color: WelcomeScreen.darkGreenColor.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryActionWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _SecondaryActionWidget({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: WelcomeScreen.mutedTextColor,
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: WelcomeScreen.mutedTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
