import 'package:flutter/material.dart';
import '../../logic/ramadan_service.dart';

/// Daily worship tracker card — supports light/dark themes.
class WorshipTrackerCard extends StatefulWidget {
  const WorshipTrackerCard({super.key});

  @override
  State<WorshipTrackerCard> createState() => _WorshipTrackerCardState();
}

class _WorshipTrackerCardState extends State<WorshipTrackerCard> {
  Map<String, bool> _worship = {
    'quran': false,
    'qiyam': false,
    'taraweeh': false,
    'dhikr': false,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorship();
  }

  Future<void> _loadWorship() async {
    final data = await RamadanService.getTodayWorship();
    if (mounted) setState(() { _worship = data; _isLoading = false; });
  }

  Future<void> _toggle(String key) async {
    final newVal = !(_worship[key] ?? false);
    setState(() => _worship[key] = newVal);
    await RamadanService.toggleWorship(key, newVal);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final completedCount = _worship.values.where((v) => v).length;
    final isDuring = RamadanService.isDuringRamadan();

    final bgColor = isDark ? const Color(0xFF1a1a2e) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtleText = isDark ? Colors.white.withOpacity(0.6) : Colors.black54;
    final borderColor = completedCount == 4
        ? const Color(0xFFFFD700).withOpacity(0.4)
        : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06));
    final itemBgUndone = isDark ? Colors.white.withOpacity(0.04) : Colors.grey.withOpacity(0.06);
    final itemBorderUndone = isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.12);
    final labelUndone = isDark ? Colors.white.withOpacity(0.7) : Colors.black54;
    final checkBorderUndone = isDark ? Colors.white.withOpacity(0.3) : Colors.grey.withOpacity(0.4);
    final checkIconBg = isDark ? const Color(0xFF1a1a2e) : Colors.white;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: bgColor,
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isDuring)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: completedCount == 4
                        ? const Color(0xFFFFD700).withOpacity(0.15)
                        : (isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.08)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    completedCount == 4 ? '✨ ما شاء الله' : '$completedCount / 4',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: completedCount == 4 ? const Color(0xFFFFD700) : subtleText,
                    ),
                  ),
                ),
              Text(
                'العبادة اليومية',
                style: TextStyle(
                  fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildWorshipItem('quran', '📖', 'قرآن', isDark, itemBgUndone, itemBorderUndone, labelUndone, checkBorderUndone, checkIconBg),
          const SizedBox(height: 6),
          _buildWorshipItem('qiyam', '🌙', 'قيام', isDark, itemBgUndone, itemBorderUndone, labelUndone, checkBorderUndone, checkIconBg),
          const SizedBox(height: 6),
          _buildWorshipItem('taraweeh', '🕌', 'تراويح', isDark, itemBgUndone, itemBorderUndone, labelUndone, checkBorderUndone, checkIconBg),
          const SizedBox(height: 6),
          _buildWorshipItem('dhikr', '📿', 'ذكر', isDark, itemBgUndone, itemBorderUndone, labelUndone, checkBorderUndone, checkIconBg),
        ],
      ),
    );
  }

  Widget _buildWorshipItem(String key, String emoji, String label,
      bool isDark, Color itemBgUndone, Color itemBorderUndone,
      Color labelUndone, Color checkBorderUndone, Color checkIconBg) {
    final done = _worship[key] ?? false;
    return GestureDetector(
      onTap: () => _toggle(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: done ? const Color(0xFFFFD700).withOpacity(0.1) : itemBgUndone,
          border: Border.all(
            color: done ? const Color(0xFFFFD700).withOpacity(0.3) : itemBorderUndone,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 26, height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? const Color(0xFFFFD700) : Colors.transparent,
                border: Border.all(
                  color: done ? const Color(0xFFFFD700) : checkBorderUndone,
                  width: 2,
                ),
              ),
              child: done
                  ? Icon(Icons.check_rounded, size: 16, color: checkIconBg)
                  : null,
            ),
            Row(
              children: [
                Text(label, style: TextStyle(
                  fontFamily: 'Cairo', fontSize: 15,
                  fontWeight: done ? FontWeight.w700 : FontWeight.w500,
                  color: done ? const Color(0xFFFFD700) : labelUndone,
                  decoration: done ? TextDecoration.lineThrough : null,
                  decorationColor: const Color(0xFFFFD700).withOpacity(0.4),
                )),
                const SizedBox(width: 8),
                Text(emoji, style: const TextStyle(fontSize: 18)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
