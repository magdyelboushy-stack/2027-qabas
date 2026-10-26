import 'package:flutter/material.dart';
import 'dart:ui';

class SetupWizardBackground extends StatelessWidget {
  final double pageOffset;
  final List<Color> pageColors;
  final bool isDark;

  const SetupWizardBackground({
    super.key,
    required this.pageOffset,
    required this.pageColors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final currentPageIndex = pageOffset.round().clamp(0, pageColors.length - 1);
    final primaryColor = pageColors[currentPageIndex];

    return Stack(
      children: [
        // Main gradient background
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                isDark ? const Color(0xFF071814) : const Color(0xFFF5F5F5),
                primaryColor.withOpacity(isDark ? 0.1 : 0.05),
                isDark ? const Color(0xFF071814) : const Color(0xFFF5F5F5),
              ],
            ),
          ),
        ),

        // Moving blob 1 - Primary
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          top: -120,
          right: -120 - (pageOffset * 120),
          child: Container(
            width: 450,
            height: 450,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  primaryColor.withOpacity(isDark ? 0.4 : 0.2),
                  primaryColor.withOpacity(isDark ? 0.1 : 0.05),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 120,
                  spreadRadius: 40,
                ),
              ],
            ),
          ),
        ),

        // Moving blob 2 - Secondary
        AnimatedPositioned(
          duration: const Duration(milliseconds: 400),
          bottom: -80,
          left: -80 - (pageOffset * 80),
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.cyanAccent.withOpacity(isDark ? 0.2 : 0.1),
                  Colors.blueAccent.withOpacity(isDark ? 0.05 : 0.02),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.15),
                  blurRadius: 100,
                  spreadRadius: 30,
                ),
              ],
            ),
          ),
        ),

        // Islamic pattern overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.05),
            ),
            child: CustomPaint(
              painter: IslamicPatternPainter(
                color: Colors.white.withOpacity(isDark ? 0.02 : 0.01),
              ),
            ),
          ),
        ),

        // Blur layer for depth
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
          ),
        ),

        // Subtle gradient overlay for readability
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(isDark ? 0.05 : 0.02),
                  Colors.black.withOpacity(isDark ? 0.1 : 0.05),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class IslamicPatternPainter extends CustomPainter {
  final Color color;

  IslamicPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const spacing = 60.0;
    const radius = 15.0;

    // Draw geometric pattern
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // Draw circles
        canvas.drawCircle(Offset(x, y), radius, paint);
        
        // Draw connecting lines
        if (x + spacing < size.width) {
          canvas.drawLine(
            Offset(x + radius, y),
            Offset(x + spacing - radius, y),
            paint,
          );
        }
        if (y + spacing < size.height) {
          canvas.drawLine(
            Offset(x, y + radius),
            Offset(x, y + spacing - radius),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
