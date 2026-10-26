import 'package:flutter/material.dart';

class SetupWizardControls extends StatelessWidget {
  final int totalPages;
  final double pageOffset;
  final List<Color> pageColors;
  final bool isDark;

  const SetupWizardControls({
    super.key,
    required this.totalPages,
    required this.pageOffset,
    required this.pageColors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 10,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalPages, (index) {
          double distance = (pageOffset - index).abs();
          double width = (1.0 - distance).clamp(0.0, 1.0) * 20 + 10;
          double height = (1.0 - distance).clamp(0.0, 1.0) * 4 + 6;
          Color color = pageColors[index];

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: width,
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: distance < 0.5
                  ? color
                  : (isDark ? Colors.white24 : Colors.black12),
              borderRadius: BorderRadius.circular(height / 2),
              boxShadow: distance < 0.5 ? [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ] : null,
            ),
          );
        }),
      ),
    );
  }
}
