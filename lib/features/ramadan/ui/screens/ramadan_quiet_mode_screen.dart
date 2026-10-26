import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../logic/ramadan_service.dart';

/// Full-screen quiet Ramadan experience — supports light/dark themes.
/// Displays: One Ayah, One Dhikr, One Dua.
/// Swipe down to dismiss. No distractions.
class RamadanQuietModeScreen extends StatefulWidget {
  const RamadanQuietModeScreen({super.key});

  @override
  State<RamadanQuietModeScreen> createState() => _RamadanQuietModeScreenState();
}

class _RamadanQuietModeScreenState extends State<RamadanQuietModeScreen>
    with SingleTickerProviderStateMixin {
  late RamadanDailyContent _content;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  int _currentSection = 0;

  final List<String> _sectionTitles = ['آية اليوم', 'ذكر اليوم', 'دعاء اليوم'];
  final List<String> _sectionEmojis = ['📖', '📿', '🤲'];

  @override
  void initState() {
    super.initState();
    _content = RamadanService.getTodayContent();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _fadeController.dispose();
    super.dispose();
  }

  void _nextSection() {
    if (_currentSection < 2) {
      _fadeController.reverse().then((_) {
        setState(() => _currentSection++);
        _fadeController.forward();
      });
    }
  }

  void _prevSection() {
    if (_currentSection > 0) {
      _fadeController.reverse().then((_) {
        setState(() => _currentSection--);
        _fadeController.forward();
      });
    }
  }

  String _getCurrentText() {
    switch (_currentSection) {
      case 0:
        return _content.ayah;
      case 1:
        return _content.dhikr;
      case 2:
        return _content.dua;
      default:
        return '';
    }
  }

  String? _getCurrentRef() {
    if (_currentSection == 0) return _content.ayahReference;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme-adaptive colors
    final scaffoldBg =
        isDark ? const Color(0xFF080E1A) : const Color(0xFFF5F0E8);
    final gradientCenter = isDark
        ? const Color(0xFF0D1B2A).withOpacity(0.95)
        : const Color(0xFFE8DDD0).withOpacity(0.95);
    final gradientEdge =
        isDark ? const Color(0xFF080E1A) : const Color(0xFFF5F0E8);
    final hintColor = isDark
        ? Colors.white.withOpacity(0.25)
        : Colors.black.withOpacity(0.25);
    final pullBarColor =
        isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.15);
    final titleGold = isDark
        ? const Color(0xFFFFD700).withOpacity(0.8)
        : const Color(0xFFBF8000);
    final mainText = isDark ? Colors.white.withOpacity(0.9) : Colors.black87;
    final refColor =
        isDark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.4);
    final dotActive =
        isDark ? const Color(0xFFFFD700) : const Color(0xFFBF8000);
    final dotInactive = isDark
        ? Colors.white.withOpacity(0.15)
        : Colors.black.withOpacity(0.12);
    final counterColor = isDark
        ? Colors.white.withOpacity(0.25)
        : Colors.black.withOpacity(0.25);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 300) {
            Navigator.pop(context);
          }
        },
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! < -200) {
              _prevSection();
            } else if (details.primaryVelocity! > 200) _nextSection();
          }
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [gradientCenter, gradientEdge],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // ── Top hint ──
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: pullBarColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('اسحب للأسفل للخروج',
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: hintColor)),
                    ],
                  ),
                ),

                // ── Content ──
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_sectionEmojis[_currentSection],
                              style: const TextStyle(fontSize: 40)),
                          const SizedBox(height: 16),
                          Text(_sectionTitles[_currentSection],
                              style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: titleGold)),
                          const SizedBox(height: 28),
                          Text(
                            _currentSection == 0
                                ? '﴿ ${_getCurrentText()} ﴾'
                                : _getCurrentText(),
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontFamily:
                                  _currentSection == 0 ? 'UthmanTN' : 'Cairo',
                              fontSize: _currentSection == 0 ? 24 : 22,
                              fontWeight: _currentSection == 0
                                  ? FontWeight.normal
                                  : FontWeight.w500,
                              height: _currentSection == 0 ? 2.2 : 2.0,
                              color: mainText,
                            ),
                          ),
                          if (_getCurrentRef() != null) ...[
                            const SizedBox(height: 16),
                            Text(_getCurrentRef()!,
                                style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14,
                                    color: refColor)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Navigation dots ──
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) {
                          final isActive = i == _currentSection;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: isActive ? 24 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: isActive ? dotActive : dotInactive,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                      Text('${_currentSection + 1} / 3',
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: counterColor)),
                    ],
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
