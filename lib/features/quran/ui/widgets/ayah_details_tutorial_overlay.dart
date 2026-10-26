import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/translations/app_locale_keys.dart';

class _AyahTutorialStep {
  final Rect targetRect;
  final String title;
  final String description;
  final IconData icon;
  final Alignment tooltipAlignment;

  const _AyahTutorialStep({
    required this.targetRect,
    required this.title,
    required this.description,
    required this.icon,
    this.tooltipAlignment = Alignment.bottomCenter,
  });
}

class _SpotlightPainter extends CustomPainter {
  final Rect targetRect;
  final double animationValue;
  final double padding;

  _SpotlightPainter({
    required this.targetRect,
    required this.animationValue,
    this.padding = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.82 * animationValue);

    final fullPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutout = RRect.fromRectAndRadius(
      targetRect.inflate(padding),
      const Radius.circular(16),
    );
    final cutoutPath = Path()..addRRect(cutout);

    final combinedPath = Path.combine(PathOperation.difference, fullPath, cutoutPath);
    canvas.drawPath(combinedPath, paint);

    final borderPaint = Paint()
      ..color = const Color(0xFF4CAF50).withOpacity(0.6 * animationValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(cutout, borderPaint);

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

class AyahDetailsTutorialOverlay extends StatefulWidget {
  final bool isDark;
  final VoidCallback onComplete;

  final Rect ayahTextRect;
  final Rect tabsRect;
  final Rect playControlsRect;
  final Rect repeatSettingsRect;

  const AyahDetailsTutorialOverlay({
    super.key,
    required this.isDark,
    required this.onComplete,
    required this.ayahTextRect,
    required this.tabsRect,
    required this.playControlsRect,
    required this.repeatSettingsRect,
  });

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('ayah_details_tutorial_shown') ?? false);
  }

  static Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ayah_details_tutorial_shown', true);
  }

  @override
  State<AyahDetailsTutorialOverlay> createState() => _AyahDetailsTutorialOverlayState();
}

class _AyahDetailsTutorialOverlayState extends State<AyahDetailsTutorialOverlay>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  List<_AyahTutorialStep> _steps = [];

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
      _AyahTutorialStep(
        targetRect: widget.ayahTextRect,
        title: AppLocaleKeys.tutAyahTitle.tr,
        description: AppLocaleKeys.tutAyahDesc.tr,
        icon: Icons.menu_book_rounded,
        tooltipAlignment: Alignment.bottomCenter,
      ),
      _AyahTutorialStep(
        targetRect: widget.tabsRect,
        title: AppLocaleKeys.tutTafsirTitle.tr,
        description: AppLocaleKeys.tutTafsirDesc.tr,
        icon: Icons.tab_rounded,
        tooltipAlignment: Alignment.bottomCenter,
      ),
      _AyahTutorialStep(
        targetRect: widget.repeatSettingsRect,
        title: AppLocaleKeys.tutRepeatTitle.tr,
        description: AppLocaleKeys.tutRepeatDesc.tr,
        icon: Icons.repeat_rounded,
        tooltipAlignment: Alignment.topCenter,
      ),
      _AyahTutorialStep(
        targetRect: widget.playControlsRect,
        title: AppLocaleKeys.tutAudioTitle.tr,
        description: AppLocaleKeys.tutAudioDesc.tr,
        icon: Icons.play_arrow_rounded,
        tooltipAlignment: Alignment.topCenter,
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

  void _complete() {
    _fadeController.reverse().then((_) {
      AyahDetailsTutorialOverlay.markComplete();
      widget.onComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_steps.isEmpty || _currentStep >= _steps.length) return const SizedBox.shrink();

    final step = _steps[_currentStep];
    final isAr = Get.locale?.languageCode == 'ar';
    final screenSize = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: Listenable.merge([_fadeAnimation, _pulseAnimation]),
      builder: (context, _) {
        return Stack(
          children: [
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
            _buildTooltip(step, screenSize, isAr),
            Positioned(
              bottom: 24,
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

  Widget _buildTooltip(_AyahTutorialStep step, Size screenSize, bool isAr) {
    double top;
    double left = 20;
    double right = 20;

    if (step.tooltipAlignment == Alignment.bottomCenter) {
      top = step.targetRect.bottom + 24;
    } else if (step.tooltipAlignment == Alignment.topCenter) {
      top = step.targetRect.top - 180;
    } else {
      top = step.targetRect.center.dy - 80;
    }

    top = top.clamp(40.0, screenSize.height - 240.0);

    return Positioned(
      top: top,
      left: left,
      right: right,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _pulseAnimation,
          child: Material(
            color: Colors.transparent,
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
                  Text(
                    step.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      height: 1.6,
                      color: widget.isDark ? Colors.white70 : const Color(0xFF555555),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigation(bool isAr) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
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
      ),
    );
  }
}
