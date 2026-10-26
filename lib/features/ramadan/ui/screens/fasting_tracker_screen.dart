import 'package:flutter/material.dart';
import 'package:mihrab/features/ramadan/logic/ramadan_service.dart';
import '../../../../core/services/ad_service.dart';

class FastingTrackerScreen extends StatefulWidget {
  const FastingTrackerScreen({super.key});

  @override
  State<FastingTrackerScreen> createState() => _FastingTrackerScreenState();
}

class _FastingTrackerScreenState extends State<FastingTrackerScreen> {
  bool _isLoading = true;
  final Map<int, bool> _fastingStatus = {};
  int _totalFasted = 0;
  int _missedDays = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    int total = 0;
    int missed = 0;
    final currentDay = RamadanService.currentRamadanDay();

    for (int i = 1; i <= 30; i++) {
      final isFasted = await RamadanService.isFasted(i);
      _fastingStatus[i] = isFasted;
      if (isFasted) {
        total++;
      } else if (i < currentDay && currentDay > 0) {
        missed++;
      }
    }

    if (mounted) {
      setState(() {
        _totalFasted = total;
        _missedDays = missed;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleDay(int day) async {
    // ⛔ لا يمكن التتبع قبل رمضان
    if (RamadanService.isBeforeRamadan()) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF1A1A2E) 
                : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.date_range_rounded, color: Colors.orange, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'لم يحن رمضان بعد',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'تتبع الصيام يبدأ مع أول يوم من رمضان إن شاء الله.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('حسناً', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
      return;
    }

    final currentVal = _fastingStatus[day] ?? false;
    final newVal = !currentVal;

    setState(() {
      _fastingStatus[day] = newVal;
      if (newVal) {
        _totalFasted++;
        final currentDay = RamadanService.currentRamadanDay();
        if (day < currentDay && currentDay > 0) {
          _missedDays--;
        }
      } else {
        _totalFasted--;
        final currentDay = RamadanService.currentRamadanDay();
        if (day < currentDay && currentDay > 0) {
          _missedDays++;
        }
      }
    });

    await RamadanService.toggleFasting(day, newVal);
    await RamadanService.syncProgress();
  }

  void _showIntentionDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final dialogText = isDark ? Colors.white : Colors.black87;
    final dialogSubText = isDark ? Colors.white70 : Colors.black54;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.nights_stay, color: Color(0xFFFFD700), size: 48),
              const SizedBox(height: 16),
              Text(
                'نية الصيام',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: dialogText,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'اللهم إني نويت أن أصوم رمضان كاملاً لوجهك الكريم إيماناً واحتساباً، اللهم فتقبله مني واغفر لي فيه وبارك لي فيه وزدني علماً وخشوعاً.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  color: dialogSubText,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'آمين',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme-aware colors
    final scaffoldBg = isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF8F5F0);
    final gold = isDark ? const Color(0xFFFFD700) : const Color(0xFFBF8000);
    final cardBg = isDark ? const Color(0xFF2C3E50) : Colors.white;
    final cardBorder = isDark ? const Color(0xFFFFD700).withOpacity(0.3) : Colors.black.withOpacity(0.08);
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text('سجل الصيام', style: TextStyle(fontFamily: 'Cairo', color: textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: gold))
          : Column(
              children: [
                // Intention Card
                GestureDetector(
                  onTap: _showIntentionDialog,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.volunteer_activism, color: gold),
                        const SizedBox(width: 12),
                        Text(
                          'نية صيام رمضان',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Summary Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF2C3E50), const Color(0xFF4CA1AF)]
                          : [const Color(0xFF5B86E5), const Color(0xFF36D1DC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _SummaryItem(
                        label: 'أيام الصيام',
                        value: '$_totalFasted',
                        color: Colors.lightGreenAccent,
                        icon: Icons.check_circle_outline,
                        isDark: isDark,
                      ),
                      Container(width: 1, height: 50, color: Colors.white24),
                      _SummaryItem(
                        label: 'الأيام الفائتة',
                        value: '$_missedDays',
                        color: Colors.redAccent,
                        icon: Icons.highlight_off,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                // Grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: 30,
                    itemBuilder: (context, index) {
                      final day = index + 1;
                      final isFasted = _fastingStatus[day] ?? false;
                      final currentDay = RamadanService.currentRamadanDay();
                      final isPast = day < currentDay && currentDay > 0;
                      final isToday = day == currentDay;

                      Color cardColor;
                      if (isFasted) {
                        cardColor = isDark ? const Color(0xFF1B5E20) : const Color(0xFF4CAF50);
                      } else if (isPast) {
                        cardColor = isDark ? const Color(0xFFB71C1C) : const Color(0xFFEF5350);
                      } else if (isToday) {
                        cardColor = isDark ? const Color(0xFF0D47A1) : const Color(0xFF42A5F5);
                      } else {
                        cardColor = isDark ? Colors.white10 : Colors.grey.shade200;
                      }

                      final dayTextColor = isDark || isFasted || isPast || isToday
                          ? Colors.white
                          : Colors.black87;

                      return GestureDetector(
                        onTap: () => _toggleDay(day),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: cardColor.withOpacity(isDark ? 0.8 : 0.9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isToday ? gold : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: isFasted || isToday
                                ? [
                                    BoxShadow(
                                      color: cardColor.withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$day',
                                style: TextStyle(
                                  color: dayTextColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Icon(
                                isFasted
                                    ? Icons.check
                                    : (isPast ? Icons.close : Icons.circle_outlined),
                                color: dayTextColor.withOpacity(0.7),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ✅ Banner Ad at bottom
                AdService.bannerAdWidget(),
              ],
            ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool isDark;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'Cairo',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.white.withOpacity(0.9),
            fontSize: 12,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }
}
