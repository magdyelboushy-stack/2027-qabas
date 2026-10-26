import 'package:flutter/material.dart';
import 'dart:ui';

class OnboardingBackground extends StatelessWidget {
  final double pageOffset;
  final List<Color> pageColors;
  final bool isDark;

  const OnboardingBackground({
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
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF071814),
                primaryColor.withOpacity(0.1),
                const Color(0xFF071814),
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
                  primaryColor.withOpacity(0.4),
                  primaryColor.withOpacity(0.1),
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
                  Colors.cyanAccent.withOpacity(0.2),
                  Colors.blueAccent.withOpacity(0.05),
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

        // Moving blob 3 - Accent
        AnimatedPositioned(
          duration: const Duration(milliseconds: 500),
          top: MediaQuery.of(context).size.height * 0.4,
          left: -100 + (pageOffset * 60),
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.amberAccent.withOpacity(0.15),
                  Colors.orangeAccent.withOpacity(0.03),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Islamic pattern overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
            ),
            child: CustomPaint(
              painter: IslamicPatternPainter(
                color: Colors.white.withOpacity(0.02),
              ),
            ),
          ),
        ),

        // Blur layer for depth
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
          child: Container(
            color: Colors.black.withOpacity(0.15),
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
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.2),
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
