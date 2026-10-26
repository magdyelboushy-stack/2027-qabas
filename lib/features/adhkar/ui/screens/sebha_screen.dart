import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/ui/widgets/glass_snackbar.dart';
import '../../data/adhkar_preferences.dart';
import '../../../../core/translations/app_locale_keys.dart';

class SebhaScreen extends StatefulWidget {
  const SebhaScreen({super.key});

  @override
  State<SebhaScreen> createState() => _SebhaScreenState();
}

class _SebhaScreenState extends State<SebhaScreen>
    with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _adhkarList = [
    {'text': 'سبحان الله', 'target': 33, 'count': 0},
    {'text': 'الحمد لله', 'target': 33, 'count': 0},
    {'text': 'الله أكبر', 'target': 33, 'count': 0},
    {'text': 'لا إله إلا الله', 'target': 100, 'count': 0},
    {'text': 'أستغفر الله', 'target': 100, 'count': 0},
    {'text': 'اللهم صل وسلم على نبينا محمد', 'target': 10, 'count': 0},
  ];

  final PageController _pageController = PageController(viewportFraction: 0.9);

  int _currentIndex = 0;
  late final AnimationController _tapController;
  late final Animation<double> _tapScale;

  bool get _isArabic => Get.locale?.languageCode != 'en';

  String _t({
    required String ar,
    required String en,
  }) =>
      _isArabic ? ar : en;

  @override
  void initState() {
    super.initState();
    _loadCustomAdhkar();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      lowerBound: 0.96,
      upperBound: 1.0,
    )..value = 1.0;
    _tapScale = CurvedAnimation(
      parent: _tapController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tapController.dispose();
    _saveCustomAdhkar();
    super.dispose();
  }

  Future<void> _loadCustomAdhkar() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('custom_sebha_adhkar');
    if (raw == null) return;

    try {
      final decoded = json.decode(raw) as List<dynamic>;
      if (!mounted) return;
      setState(() {
        for (final item in decoded) {
          final map = Map<String, dynamic>.from(item);
          final exists = _adhkarList.any((e) => e['text'] == map['text']);
          if (!exists) _adhkarList.add(map);
        }
      });
    } catch (_) {}
  }

  Future<void> _saveCustomAdhkar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_sebha_adhkar', json.encode(_adhkarList));
  }

  Future<void> _increment() async {
    await AdhkarPreferences.lightImpact();
    _tapController.reverse().then((_) => _tapController.forward());

    setState(() {
      final current = _adhkarList[_currentIndex]['count'] as int;
      final target = _adhkarList[_currentIndex]['target'] as int;
      if (current < target) {
        _adhkarList[_currentIndex]['count'] = current + 1;
      }
    });

    final current = _adhkarList[_currentIndex]['count'] as int;
    final target = _adhkarList[_currentIndex]['target'] as int;
    if (current < target) return;

    await AdhkarPreferences.mediumImpact();
    if (_currentIndex < _adhkarList.length - 1) {
      showGlassSnackBar(
        context,
        _t(
          ar: AppLocaleKeys.acceptedMovingToNext.tr,
          en: 'Accepted, moving to the next dhikr',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    } else {
      showGlassSnackBar(
        context,
        _t(
          ar: AppLocaleKeys.acceptedCompletedAll.tr,
          en: 'May Allah accept, you completed all adhkar',
        ),
      );
    }
  }

  Future<void> _resetCount() async {
    await AdhkarPreferences.mediumImpact();
    setState(() {
      _adhkarList[_currentIndex]['count'] = 0;
    });
    showGlassSnackBar(
      context,
      _t(ar: AppLocaleKeys.counterResetMsg.tr, en: 'Counter reset'),
    );
  }

  Future<void> _deleteCurrentDhikr() async {
    if (_currentIndex < 6) {
      showGlassSnackBar(
        context,
        _t(
          ar: AppLocaleKeys.cannotDeleteBasicAdhkar.tr,
          en: 'Default adhkar cannot be deleted',
        ),
        isError: true,
      );
      return;
    }

    setState(() {
      _adhkarList.removeAt(_currentIndex);
      if (_currentIndex >= _adhkarList.length) {
        _currentIndex = _adhkarList.length - 1;
      }
    });
    await _saveCustomAdhkar();
    if (!mounted) return;
    showGlassSnackBar(
      context,
      _t(ar: AppLocaleKeys.dhikrDeletedMsg.tr, en: 'Dhikr deleted'),
    );
  }

  void _showManageDialog({Map<String, dynamic>? existing}) {
    final isEditing = existing != null;
    final textController =
        TextEditingController(text: existing?['text']?.toString() ?? '');
    final countController = TextEditingController(
      text: (existing?['target']?.toString() ?? ''),
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF16312B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF17352E);
    final subColor = isDark ? Colors.white70 : const Color(0xFF6A8479);
    final accent = const Color(0xFF2A8B68);

    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            isEditing
                ? _t(ar: AppLocaleKeys.editDhikrItem.tr, en: 'Edit dhikr')
                : _t(ar: AppLocaleKeys.newDhikrItem.tr, en: 'New dhikr'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontFamily: 'Cairo',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                textAlign: _isArabic ? TextAlign.right : TextAlign.left,
                style: TextStyle(color: textColor, fontFamily: 'Cairo'),
                decoration: InputDecoration(
                  labelText: _t(ar: AppLocaleKeys.dhikrTextTitle.tr, en: 'Dhikr text'),
                  labelStyle: TextStyle(color: subColor),
                  filled: true,
                  fillColor: isDark ? Colors.black12 : const Color(0xFFF5F8F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: countController,
                keyboardType: TextInputType.number,
                textAlign: _isArabic ? TextAlign.right : TextAlign.left,
                style: TextStyle(color: textColor, fontFamily: 'Cairo'),
                decoration: InputDecoration(
                  labelText: _t(ar: AppLocaleKeys.targetCountTitle.tr, en: 'Target count'),
                  hintText: _t(ar: AppLocaleKeys.forExample33.tr, en: 'e.g. 33'),
                  labelStyle: TextStyle(color: subColor),
                  filled: true,
                  fillColor: isDark ? Colors.black12 : const Color(0xFFF5F8F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            if (isEditing)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _deleteCurrentDhikr();
                },
                child: Text(
                  _t(ar: AppLocaleKeys.deleteAction.tr, en: 'Delete'),
                  style: const TextStyle(
                    color: Color(0xFFD45B5B),
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                _t(ar: AppLocaleKeys.cancelAction.tr, en: 'Cancel'),
                style: TextStyle(
                  color: subColor,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            FilledButton(
              onPressed: () async {
                final text = textController.text.trim();
                final target = int.tryParse(countController.text.trim()) ?? 0;
                if (text.isEmpty || target <= 0) return;

                setState(() {
                  if (isEditing) {
                    existing['text'] = text;
                    existing['target'] = target;
                    if ((existing['count'] as int) > target) {
                      existing['count'] = 0;
                    }
                  } else {
                    _adhkarList.add({
                      'text': text,
                      'target': target,
                      'count': 0,
                    });
                    _currentIndex = _adhkarList.length - 1;
                  }
                });

                await _saveCustomAdhkar();
                if (!mounted) return;
                Navigator.pop(ctx);

                if (!isEditing) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_pageController.hasClients) {
                      _pageController.animateToPage(
                        _currentIndex,
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  });
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: accent,
              ),
              child: Text(
                isEditing
                    ? _t(ar: AppLocaleKeys.saveAction.tr, en: 'Save')
                    : _t(ar: AppLocaleKeys.addActionBtn.tr, en: 'Add'),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentDhikr = _adhkarList[_currentIndex];
    final count = currentDhikr['count'] as int;
    final target = currentDhikr['target'] as int;
    final progress = target == 0 ? 0.0 : count / target;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topColor = isDark ? const Color(0xFF071814) : const Color(0xFFF7FBF8);
    final bottomColor =
        isDark ? const Color(0xFF0E241E) : const Color(0xFFE4F0EA);
    final cardColor = isDark ? const Color(0xFF132D26) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF17352E);
    final subColor = isDark ? Colors.white70 : const Color(0xFF6A8479);
    final borderColor =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFD7E8DF);
    final accent = const Color(0xFF74D7C0);
    final accentDark = const Color(0xFF2A8B68);

    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bottomColor,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [topColor, bottomColor],
            ),
          ),
          child: SafeArea(
            child: GestureDetector(
              onTap: _increment,
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        _HeaderCircleButton(
                          icon: _isArabic
                              ? Icons.arrow_back_ios_new_rounded
                              : Icons.arrow_forward_ios_rounded,
                          onTap: () => Navigator.pop(context),
                          color: titleColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _t(ar: AppLocaleKeys.alMasbaha.tr, en: 'Masbaha'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _HeaderCircleButton(
                          icon: Icons.edit_note_rounded,
                          onTap: () =>
                              _showManageDialog(existing: currentDhikr),
                          color: titleColor,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _TopBadge(
                          label: _t(
                            ar: AppLocaleKeys.targetWithCount.trParams({'target': target.toString()}),
                            en: 'Target $target',
                          ),
                          isDark: isDark,
                          textColor: titleColor,
                        ),
                        const Spacer(),
                        _TopBadge(
                          label: _t(
                            ar: AppLocaleKeys.remainingWithCount.trParams({'remaining': (target - count).toString()}),
                            en: '${target - count} left',
                          ),
                          isDark: isDark,
                          textColor: titleColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 170,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _adhkarList.length,
                      onPageChanged: (index) =>
                          setState(() => _currentIndex = index),
                      itemBuilder: (context, index) {
                        final item = _adhkarList[index];
                        final active = index == _currentIndex;
                        return AnimatedScale(
                          scale: active ? 1 : 0.95,
                          duration: const Duration(milliseconds: 220),
                          child: Opacity(
                            opacity: active ? 1 : 0.72,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      borderRadius: BorderRadius.circular(28),
                                      border: Border.all(color: borderColor),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accent.withOpacity(0.10),
                                          blurRadius: 18,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: accent.withOpacity(0.14),
                                          ),
                                          child: Icon(
                                            Icons.spa_rounded,
                                            color: accentDark,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          item['text'],
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: titleColor,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                            fontFamily: 'Cairo',
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Spacer(),
                  ScaleTransition(
                    scale: _tapScale,
                    child: SizedBox(
                      width: 270,
                      height: 270,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 270,
                            height: 270,
                            child: CircularProgressIndicator(
                              value: 1,
                              strokeWidth: 18,
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : const Color(0xFFDCEAE4),
                            ),
                          ),
                          SizedBox(
                            width: 270,
                            height: 270,
                            child: CircularProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              strokeWidth: 18,
                              strokeCap: StrokeCap.round,
                              color: accentDark,
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$count',
                                style: TextStyle(
                                  color: titleColor,
                                  fontSize: 76,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Cairo',
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _t(ar: AppLocaleKeys.ofTarget.trParams({'target': target.toString()}), en: 'of $target'),
                                style: TextStyle(
                                  color: subColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _t(
                      ar: AppLocaleKeys.tapAnywhereToPraise.tr,
                      en: 'Tap anywhere to count and long press to reset',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: subColor,
                      fontSize: 13,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                    child: Row(
                      children: [
                        Expanded(
                          child: _BottomPillButton(
                            icon: Icons.restart_alt_rounded,
                            label: _t(ar: AppLocaleKeys.resetAction.tr, en: 'Reset'),
                            color: const Color(0xFFD45B5B),
                            onTap: _resetCount,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _BottomPillButton(
                            icon: Icons.add_circle_outline_rounded,
                            label: _t(ar: AppLocaleKeys.newDhikrItem.tr, en: 'New dhikr'),
                            color: accentDark,
                            onTap: () => _showManageDialog(),
                          ),
                        ),
                      ],
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
}

class _HeaderCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _HeaderCircleButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.06),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

class _TopBadge extends StatelessWidget {
  final String label;
  final bool isDark;
  final Color textColor;

  const _TopBadge({
    required this.label,
    required this.isDark,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFD7E8DF),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }
}

class _BottomPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BottomPillButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
