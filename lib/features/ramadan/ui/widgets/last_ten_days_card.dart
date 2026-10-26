import 'package:flutter/material.dart';
import '../../logic/ramadan_service.dart';

/// Last Ten Days Card — supports light/dark themes.
class LastTenDaysCard extends StatefulWidget {
  const LastTenDaysCard({super.key});

  @override
  State<LastTenDaysCard> createState() => _LastTenDaysCardState();
}

class _LastTenDaysCardState extends State<LastTenDaysCard> {
  Map<String, bool> _worship = {
    'qiyam_layl': false,
    'witr': false,
    'dua': false,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorship();
  }

  Future<void> _loadWorship() async {
    final data = await RamadanService.getLastTenWorship();
    if (mounted) setState(() { _worship = data; _isLoading = false; });
  }

  Future<void> _toggle(String key) async {
    final newVal = !(_worship[key] ?? false);
    setState(() => _worship[key] = newVal);
    await RamadanService.toggleLastTenWorship(key, newVal);
  }

  void _showAfwDua() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [const Color(0xFF1a0a2e), const Color(0xFF0D1B2A)]
                  : [const Color(0xFF4A148C), const Color(0xFF6A1B9A)],
            ),
            border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🤲', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 16),
              const Text(
                'اللهم إنك عفو\nكريم تحب العفو\nفاعف عنا',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'UthmanTN',
                  fontSize: 26,
                  height: 2.0,
                  color: Color(0xFFFFD700),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: const Text('آمين',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 16,
                      fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();
    if (!RamadanService.isLastTenDays()) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final day = RamadanService.currentRamadanDay();

    final gradientColors = isDark
        ? [const Color(0xFF1a0a2e), const Color(0xFF0D1B2A)]
        : [const Color(0xFF4A148C), const Color(0xFF6A1B9A)];
    final subtleText = isDark ? Colors.white.withOpacity(0.5) : Colors.white.withOpacity(0.7);
    final itemBgUndone = isDark ? Colors.white.withOpacity(0.04) : Colors.white.withOpacity(0.1);
    final itemBorderUndone = isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.15);
    final labelUndone = isDark ? Colors.white.withOpacity(0.7) : Colors.white.withOpacity(0.85);
    final checkBorderUndone = isDark ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.4);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.25),
            blurRadius: 14, offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('اليوم $day',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 12,
                    fontWeight: FontWeight.w600, color: Color(0xFFFFD700))),
              ),
              const Row(
                children: [
                  Text('العشر الأواخر',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 16,
                      fontWeight: FontWeight.w700, color: Color(0xFFFFD700))),
                  SizedBox(width: 6),
                  Text('🔥', style: TextStyle(fontSize: 18)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('اجتهد في هذه الليالي المباركة',
            textDirection: TextDirection.rtl,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: subtleText)),
          const SizedBox(height: 12),

          _buildItem('qiyam_layl', '🌙', 'قيام الليل', itemBgUndone, itemBorderUndone, labelUndone, checkBorderUndone, isDark),
          const SizedBox(height: 6),
          _buildItem('witr', '🤲', 'الوتر', itemBgUndone, itemBorderUndone, labelUndone, checkBorderUndone, isDark),
          const SizedBox(height: 6),
          _buildItem('dua', '💫', 'الدعاء', itemBgUndone, itemBorderUndone, labelUndone, checkBorderUndone, isDark),
          const SizedBox(height: 12),

          GestureDetector(
            onTap: _showAfwDua,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  const Color(0xFFFFD700).withOpacity(0.15),
                  const Color(0xFFFFD700).withOpacity(0.08),
                ]),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.25)),
              ),
              child: const Text(
                '🤲 اللهم إنك عفو تحب العفو فاعف عنا',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(fontFamily: 'Cairo', fontSize: 13,
                  fontWeight: FontWeight.w600, color: Color(0xFFFFD700)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(String key, String emoji, String label,
      Color itemBgUndone, Color itemBorderUndone, Color labelUndone,
      Color checkBorderUndone, bool isDark) {
    final done = _worship[key] ?? false;
    return GestureDetector(
      onTap: () => _toggle(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
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
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? const Color(0xFFFFD700) : Colors.transparent,
                border: Border.all(
                  color: done ? const Color(0xFFFFD700) : checkBorderUndone,
                  width: 2,
                ),
              ),
              child: done
                  ? Icon(Icons.check_rounded, size: 15,
                      color: isDark ? const Color(0xFF1a0a2e) : Colors.white)
                  : null,
            ),
            Row(
              children: [
                Text(label, style: TextStyle(
                  fontFamily: 'Cairo', fontSize: 14,
                  fontWeight: done ? FontWeight.w700 : FontWeight.w500,
                  color: done ? const Color(0xFFFFD700) : labelUndone,
                )),
                const SizedBox(width: 8),
                Text(emoji, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
