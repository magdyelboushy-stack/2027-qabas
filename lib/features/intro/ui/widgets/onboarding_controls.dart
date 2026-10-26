import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/translations/app_locale_keys.dart';

class OnboardingControls extends StatelessWidget {
  final int totalPages;
  final double pageOffset;
  final bool isLastPage;
  final VoidCallback onNextPressed;
  final VoidCallback onSkipPressed;

  const OnboardingControls({
    super.key,
    required this.totalPages,
    required this.pageOffset,
    required this.isLastPage,
    required this.onNextPressed,
    required this.onSkipPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: Column(
        children: [
          // Enhanced page indicators
          _buildPageIndicators(),

          const SizedBox(height: 40),

          // Main action button
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: onNextPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastPage
                    ? Colors.cyanAccent
                    : Colors.white.withOpacity(0.15),
                foregroundColor: isLastPage ? Colors.black : Colors.white,
                elevation: isLastPage ? 12 : 0,
                shadowColor:
                    isLastPage ? Colors.cyanAccent.withOpacity(0.4) : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: isLastPage
                      ? BorderSide.none
                      : BorderSide(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLastPage ? AppLocaleKeys.startYourJourney.tr : AppLocaleKeys.nextBtn.tr,
                      key: ValueKey<bool>(isLastPage),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (!isLastPage) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                    if (isLastPage) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.rocket_launch, size: 18),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Skip button
          if (!isLastPage)
            TextButton(
              onPressed: onSkipPressed,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocaleKeys.skipBtnText.tr,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.skip_next,
                    size: 16,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 48), // Maintain spacing
        ],
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        double distance = (pageOffset - index).abs();
        double width = (1.0 - distance).clamp(0.0, 1.0) * 24 + 12;
        double height = (1.0 - distance).clamp(0.0, 1.0) * 4 + 6;

        // Dynamic colors based on page
        Color pageColor = _getPageColor(index);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: width,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: distance < 0.5 ? pageColor : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(height / 2),
            boxShadow: distance < 0.5
                ? [
                    BoxShadow(
                      color: pageColor.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  Color _getPageColor(int index) {
    switch (index) {
      case 0:
        return Colors.cyanAccent;
      case 1:
        return Colors.orangeAccent;
      case 2:
        return Colors.purpleAccent;
      case 3:
        return Colors.greenAccent;
      default:
        return Colors.cyanAccent;
    }
  }
}
