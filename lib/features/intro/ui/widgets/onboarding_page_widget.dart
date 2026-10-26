import 'package:flutter/material.dart';
import 'dart:ui';

class OnboardingPageWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color accentColor;
  final Color backgroundColor;
  final double pageOffset;
  final Animation<double> floatAnimation;
  final int pageIndex;
  final int currentPageIndex;

  const OnboardingPageWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.backgroundColor,
    required this.pageOffset,
    required this.floatAnimation,
    required this.pageIndex,
    required this.currentPageIndex,
  });

  @override
  Widget build(BuildContext context) {
    double offset = pageIndex - pageOffset;
    final bool isCurrentPage = (pageOffset - pageIndex).abs() < 0.5;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 1),

          // Enhanced Floating Icon with Islamic Pattern
          AnimatedBuilder(
            animation: floatAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                    offset * 200, isCurrentPage ? floatAnimation.value : 0),
                child: Transform.scale(
                  scale: isCurrentPage ? 1.0 : 0.8,
                  child: child,
                ),
              );
            },
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accentColor.withOpacity(0.15),
                    accentColor.withOpacity(0.05),
                  ],
                ),
                border: Border.all(
                  color: accentColor.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.2),
                    blurRadius: 40,
                    spreadRadius: 10,
                    offset: const Offset(0, 20),
                  ),
                  // Inner glow effect
                  BoxShadow(
                    color: accentColor.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Islamic pattern decoration
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentColor.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  Icon(
                    icon,
                    size: 100,
                    color: accentColor,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 70),

          // Enhanced Text Section
          Transform.translate(
            offset: Offset(offset * 100, 0),
            child: Column(
              children: [
                Text(
                  subtitle,
                  style: TextStyle(
                    color: accentColor.withOpacity(0.9),
                    fontSize: 16,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                      Shadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    height: 1.7,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
