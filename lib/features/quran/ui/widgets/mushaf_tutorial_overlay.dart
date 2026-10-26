import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/translations/app_locale_keys.dart';

/// Tutorial step definition
class _TutorialStep {
  final Rect targetRect;
  final String title;
  final String description;
  final IconData icon;
  final Alignment tooltipAlignment;

  const _TutorialStep({
    required this.targetRect,
    required this.title,
    required this.description,
    required this.icon,
    this.tooltipAlignment = Alignment.bottomCenter,
  });
}

/// Spotlight painter — draws dark overlay with a cutout hole
class _SpotlightPainter extends CustomPainter {
  final Rect targetRect;
  final double animationValue;
  final double padding;

  _SpotlightPainter({
    required this.targetRect,
    required this.animationValue,
    this.padding = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.82 * animationValue);

    // Full screen path
    final fullPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Cutout with padding and rounded corners
    final cutout = RRect.fromRectAndRadius(
      targetRect.inflate(padding),
      const Radius.circular(16),
    );
    final cutoutPath = Path()..addRRect(cutout);

    // Subtract cutout from full screen
    final combinedPath = Path.combine(PathOperation.difference, fullPath, cutoutPath);
    canvas.drawPath(combinedPath, paint);

    // Draw glowing border around cutout
    final borderPaint = Paint()
      ..color = const Color(0xFF4CAF50).withOpacity(0.6 * animationValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(cutout, borderPaint);

    // Pulsing glow
    final glowPaint = Paint()
      ..color = const Color(0xFF4CAF50).withOpacity(0.15 * animationValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(cutout.inflate(4), glowPaint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.targetRect != targetRect ||
      oldDelegate.animationValue != animationValue;
}

/// Full-screen mushaf tutorial overlay
class MushafTutorialOverlay extends StatefulWidget {
  final bool isDark;
  final VoidCallback onComplete;

  /// Rectangles for each element to highlight (passed from mushaf screen)
  final Rect quranPageRect;
  final Rect topBarRect;
  final Rect bottomNavRect;
  final Rect searchBtnRect;
  final Rect settingsBtnRect;

  const MushafTutorialOverlay({
    super.key,
    required this.isDark,
    required this.onComplete,
    required this.quranPageRect,
    required this.topBarRect,
    required this.bottomNavRect,
    required this.searchBtnRect,
    required this.settingsBtnRect,
  });

  /// Check if tutorial should be shown
  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('mushaf_tutorial_shown') ?? false);
  }

  /// Mark tutorial as complete
  static Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mushaf_tutorial_shown', true);
  }

  @override
  State<MushafTutorialOverlay> createState() => _MushafTutorialOverlayState();
}

class _MushafTutorialOverlayState extends State<MushafTutorialOverlay>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  List<_TutorialStep> _steps = [];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _buildSteps();
    _fadeController.forward();
  }

  void _buildSteps() {
    _steps = [
      // Step 1: Quran page (ayah area)
      _TutorialStep(
        targetRect: widget.quranPageRect,
        title: AppLocaleKeys.tutMushafPageTitle.tr,
        description: AppLocaleKeys.tutMushafPageDesc.tr,
        icon: Icons.touch_app_rounded,
        tooltipAlignment: Alignment.center,
      ),
      // Step 2: Top bar (search & settings)
      _TutorialStep(
        targetRect: widget.topBarRect,
        title: AppLocaleKeys.tutToolbarTitle.tr,
        description: AppLocaleKeys.tutToolbarDesc.tr,
        icon: Icons.settings_rounded,
        tooltipAlignment: Alignment.bottomCenter,
      ),
      // Step 3: Bottom navbar
      _TutorialStep(
        targetRect: widget.bottomNavRect,
        title: AppLocaleKeys.tutNavBarTitle.tr,
        description: AppLocaleKeys.tutNavBarDesc.tr,
        icon: Icons.navigation_rounded,
        tooltipAlignment: Alignment.topCenter,
      ),
      // Step 4: Search button
      _TutorialStep(
        targetRect: widget.searchBtnRect,
        title: AppLocaleKeys.tutSearchTitle.tr,
        description: AppLocaleKeys.tutSearchDesc.tr,
        icon: Icons.search_rounded,
        tooltipAlignment: Alignment.bottomCenter,
      ),
      // Step 5: Settings button
      _TutorialStep(
        targetRect: widget.settingsBtnRect,
        title: AppLocaleKeys.tutSettingsTitle.tr,
        description: AppLocaleKeys.tutSettingsDesc.tr,
        icon: Icons.tune_rounded,
        tooltipAlignment: Alignment.bottomCenter,
      ),
    ];
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      _fadeController.reverse().then((_) {
        setState(() => _currentStep++);
        _fadeController.forward();
      });
    } else {
      _complete();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _fadeController.reverse().then((_) {
        setState(() => _currentStep--);
        _fadeController.forward();
      });
    }
  }

  void _complete() {
    _fadeController.reverse().then((_) {
      MushafTutorialOverlay.markComplete();
      widget.onComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    final isAr = Get.locale?.languageCode == 'ar';
    final screenSize = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: Listenable.merge([_fadeAnimation, _pulseAnimation]),
      builder: (context, _) {
        return Stack(
          children: [
            // ── Spotlight overlay ──
            Positioned.fill(
              child: GestureDetector(
                onTap: _nextStep,
                child: CustomPaint(
                  painter: _SpotlightPainter(
                    targetRect: step.targetRect,
                    animationValue: _fadeAnimation.value,
                  ),
                ),
              ),
            ),

            // ── Tooltip card ──
            _buildTooltip(step, screenSize, isAr),

            // ── Step indicator & navigation ──
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildNavigation(isAr),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTooltip(_TutorialStep step, Size screenSize, bool isAr) {
    // Calculate tooltip position based on step alignment
    double top;
    double left = 20;
    double right = 20;

    if (step.tooltipAlignment == Alignment.bottomCenter) {
      top = step.targetRect.bottom + 24;
    } else if (step.tooltipAlignment == Alignment.topCenter) {
      top = step.targetRect.top - 180;
    } else {
      // Center
      top = step.targetRect.center.dy - 80;
    }

    // Clamp to screen
    top = top.clamp(MediaQuery.of(context).padding.top + 10, screenSize.height - 220);

    return Positioned(
      top: top,
      left: left,
      right: right,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.isDark
                    ? [const Color(0xFF1A3A1A), const Color(0xFF0F250F)]
                    : [Colors.white, const Color(0xFFF0EDD0)],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFF4CAF50).withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4CAF50).withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF4CAF50).withOpacity(0.12),
                  ),
                  child: Icon(
                    step.icon,
                    color: const Color(0xFF4CAF50),
                    size: 26,
                  ),
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  step.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.isDark ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  step.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    height: 1.6,
                    color: widget.isDark
                        ? Colors.white70
                        : const Color(0xFF555555),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigation(bool isAr) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Skip button
          TextButton(
            onPressed: _complete,
            child: Text(
              AppLocaleKeys.skip.tr,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),

          // Step dots
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_steps.length, (i) {
              final isActive = i == _currentStep;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isActive
                      ? const Color(0xFF4CAF50)
                      : Colors.white.withOpacity(0.3),
                ),
              );
            }),
          ),

          // Next / Done button
          TextButton(
            onPressed: _nextStep,
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50).withOpacity(0.2),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _currentStep == _steps.length - 1
                  ? AppLocaleKeys.tutGotIt.tr
                  : '${AppLocaleKeys.next.tr} →',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
