import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme_provider.dart';

/// Luxurious Islamic background for authentication screens
class AuthBackground extends StatefulWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  State<AuthBackground> createState() => _AuthBackgroundState();
}

class _AuthBackgroundState extends State<AuthBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    // Colors coordinated with religious theme
    final Color bgStart = isDark
        ? const Color(0xFF0A1128)
        : const Color(0xFFF5F0E8); // Warm cream
    final Color bgEnd = isDark
        ? const Color(0xFF1C2541)
        : const Color(0xFFE8DFD0); // Islamic beige
    final Color accentColor = isDark
        ? const Color(0xFFD4AF37) // Gold
        : const Color(0xFF00695C); // Islamic green
    final Color patternColor = isDark
        ? const Color(0xFFD4AF37).withOpacity(0.04)
        : const Color(0xFF00695C).withOpacity(0.04);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // 1. Gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [bgStart, bgEnd],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),

            // 2. Subtle Islamic geometric pattern
            Positioned.fill(
              child: CustomPaint(
                painter: _IslamicPatternPainter(
                  color: patternColor,
                  isDark: isDark,
                ),
              ),
            ),

            // 3. Crescent decoration at the top
            Positioned(
              top: -60,
              right: -40,
              child: _buildCrescentDecoration(accentColor, isDark),
            ),

            // 4. Floating gold/green particles
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _particleController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _FloatingParticlesPainter(
                      progress: _particleController.value,
                      color: accentColor,
                      isDark: isDark,
                    ),
                  );
                },
              ),
            ),

            // 5. Subtle blur layer
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                child: Container(color: Colors.transparent),
              ),
            ),

            // 6. Bottom decoration
            Positioned(
              bottom: -30,
              left: -50,
              child: _buildBottomDecoration(accentColor, isDark),
            ),

            // 7. Main content
            SafeArea(
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrescentDecoration(Color color, bool isDark) {
    return SizedBox(
      width: 200,
      height: 200,
      child: CustomPaint(
        painter: _CrescentPainter(
          color: color.withOpacity(isDark ? 0.08 : 0.06),
        ),
      ),
    );
  }

  Widget _buildBottomDecoration(Color color, bool isDark) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(isDark ? 0.1 : 0.08),
            color.withOpacity(0.0),
          ],
        ),
      ),
    );
  }
}

/// Islamic geometric pattern painter
class _IslamicPatternPainter extends CustomPainter {
  final Color color;
  final bool isDark;

  _IslamicPatternPainter({required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const spacing = 60.0;

    // Draw grid of octagons
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        _drawOctagon(canvas, Offset(x, y), spacing * 0.35, paint);
      }
    }
  }

  void _drawOctagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45 - 22.5) * pi / 180;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Crescent painter
class _CrescentPainter extends CustomPainter {
  final Color color;

  _CrescentPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width * 0.45;
    final innerRadius = size.width * 0.35;
    final innerOffset = Offset(center.dx + outerRadius * 0.3, center.dy - outerRadius * 0.1);

    // Draw crescent via two overlapping circles
    final outerPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: outerRadius));
    final innerPath = Path()
      ..addOval(Rect.fromCircle(center: innerOffset, radius: innerRadius));

    final crescentPath = Path.combine(PathOperation.difference, outerPath, innerPath);
    canvas.drawPath(crescentPath, paint);

    // Small star next to the crescent
    _drawStar(canvas, Offset(center.dx + outerRadius * 0.7, center.dy - outerRadius * 0.5), 8, paint);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 144 - 90) * pi / 180;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Gold/green floating particles
class _FloatingParticlesPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isDark;

  _FloatingParticlesPainter({
    required this.progress,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);

    for (int i = 0; i < 25; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final radius = 1.0 + rng.nextDouble() * 2.5;
      final phase = rng.nextDouble() * 2 * pi;

      final x = baseX + sin(progress * 2 * pi * speed + phase) * 30;
      final y = baseY - (progress * size.height * 0.15 * speed) % size.height;
      final adjustedY = y < 0 ? y + size.height : y;

      final opacity = (0.15 + 0.2 * sin(progress * 2 * pi + phase)).clamp(0.05, 0.35);

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(Offset(x, adjustedY), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingParticlesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
