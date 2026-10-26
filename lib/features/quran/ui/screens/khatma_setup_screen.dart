import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../logic/khatma_service.dart';
import '../../logic/khatma_notification_service.dart';
import '../../../../core/translations/app_locale_keys.dart';

/// Setup wizard for creating a new Khatma with 4 steps.
class KhatmaSetupScreen extends StatefulWidget {
  const KhatmaSetupScreen({super.key});

  @override
  State<KhatmaSetupScreen> createState() => _KhatmaSetupScreenState();
}

class _KhatmaSetupScreenState extends State<KhatmaSetupScreen> {
  int _step = 0; // 0, 1, 2, 3

  // Step 1: Name and Duration
  final TextEditingController _nameController = TextEditingController();
  int _targetDays = 30;
  final List<int> _daysOptions = [7, 30, 40, -1]; // -1 for custom

  // Step 2: Division Mode
  String _divisionMode = 'page'; // 'page', 'juz', 'hizb'

  // Step 3: Session pages
  int _sessionPages = 2;
  final List<int> _sessionOptions = [2, 4, 5, 10];

  // Step 4: Notification mode
  String _notifyMode = 'after_prayer';
  TimeOfDay _specificTime = const TimeOfDay(hour: 7, minute: 0);
  int _prayerDelay = 15;
  String _notifStyle = 'motivational'; // 'tadabbur', 'motivational', 'short'

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark;
    final accent = isDark ? const Color(0xFF2A8B68) : const Color(0xFF00695C);
    final bg = isDark ? const Color(0xFF071814) : const Color(0xFFFFF8E1);
    final isAr = Get.locale?.languageCode == 'ar';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isAr ? AppLocaleKeys.createSmartKhatmaTitle.tr : 'Create Smart Khatma',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: accent)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator (4 steps)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: Row(
                children: List.generate(4, (i) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: i <= _step ? accent : accent.withOpacity(0.15),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildStep(isDark, accent, isAr),
              ),
            ),
            // Bottom buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: accent.withOpacity(0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => setState(() => _step--),
                        child: Text(isAr ? AppLocaleKeys.previousBtn.tr : 'Back',
                            style: TextStyle(fontFamily: 'Cairo', color: accent, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 4,
                      ),
                      onPressed: _step < 3 ? () => setState(() => _step++) : _createKhatma,
                      child: Text(
                        _step < 3 ? (isAr ? AppLocaleKeys.nextBtn.tr : 'Next') : (isAr ? AppLocaleKeys.startKhatmaRocket.tr : 'Start Khatma 🚀'),
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(bool isDark, Color accent, bool isAr) {
    switch (_step) {
      case 0: return _buildNameAndDurationStep(isDark, accent, isAr);
      case 1: return _buildDivisionStep(isDark, accent, isAr);
      case 2: return _buildSessionStep(isDark, accent, isAr);
      case 3: return _buildNotifyStep(isDark, accent, isAr);
      default: return const SizedBox();
    }
  }

  // ─── Step 1: Name and Duration ───
  Widget _buildNameAndDurationStep(bool isDark, Color accent, bool isAr) {
    return SingleChildScrollView(
      key: const ValueKey('step0'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Icon(Icons.flag_rounded, size: 56, color: accent.withOpacity(0.6))),
          const SizedBox(height: 16),
          Center(
            child: Text(isAr ? AppLocaleKeys.customizeKhatma.tr : 'Customize Khatma',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          ),
          const SizedBox(height: 32),
          Text(isAr ? AppLocaleKeys.khatmaNameOptional.tr : 'Khatma Name (Optional)',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: isAr ? AppLocaleKeys.khatmaNameHint.tr : 'e.g., Tadabbur, Ramadan...',
              hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
              filled: true,
              fillColor: accent.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: accent, width: 1.5)),
            ),
            style: TextStyle(fontFamily: 'Cairo', color: isDark ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 24),
          Text(isAr ? AppLocaleKeys.khatmaDuration.tr : 'Duration',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _daysOptions.map((days) {
              final isCustom = days == -1;
              final selected = isCustom ? !([7, 30, 40].contains(_targetDays)) : _targetDays == days;
              return GestureDetector(
                onTap: () {
                  if (isCustom) {
                    _showCustomDaysDialog(isDark, accent, isAr);
                  } else {
                    setState(() => _targetDays = days);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: MediaQuery.of(context).size.width / 2 - 32,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: selected ? accent : accent.withOpacity(isDark ? 0.08 : 0.06),
                    border: Border.all(color: selected ? accent : accent.withOpacity(0.2), width: selected ? 2 : 1),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isCustom 
                      ? (selected ? '$_targetDays ${isAr ? "يوم" : "days"}' : (isAr ? AppLocaleKeys.customDuration.tr : 'Custom'))
                      : '$days ${isAr ? "يوم" : "days"}',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.bold,
                        color: selected ? (isDark ? Colors.black : Colors.white) : (isDark ? Colors.white70 : Colors.black54)),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _showCustomDaysDialog(bool isDark, Color accent, bool isAr) async {
    int tempDays = _targetDays > 0 && !([7, 30, 40].contains(_targetDays)) ? _targetDays : 60;
    
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0E241E) : Colors.white,
          title: Text(isAr ? AppLocaleKeys.customDurationTitle.tr : 'Custom Duration', style: TextStyle(fontFamily: 'Cairo', color: isDark ? Colors.white : Colors.black87)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$tempDays ${isAr ? "يوم" : "days"}', style: TextStyle(fontFamily: 'Cairo', fontSize: 24, fontWeight: FontWeight.bold, color: accent)),
              Slider(
                value: tempDays.toDouble(),
                min: 3,
                max: 365,
                activeColor: accent,
                inactiveColor: accent.withOpacity(0.2),
                onChanged: (v) => setStateDialog(() => tempDays = v.round()),
              ),
              Text('${(604 / tempDays).ceil()} ${isAr ? "صفحة/يوم تقريباً" : "pages/day approx"}', 
                style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isAr ? AppLocaleKeys.cancelAction.tr : 'Cancel', style: TextStyle(fontFamily: 'Cairo', color: isDark ? Colors.white54 : Colors.black54))),
            TextButton(
              onPressed: () {
                setState(() => _targetDays = tempDays);
                Navigator.pop(ctx);
              },
              child: Text(isAr ? AppLocaleKeys.confirmAction.tr : 'Confirm', style: TextStyle(fontFamily: 'Cairo', color: accent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Step 2: Division Mode ───
  Widget _buildDivisionStep(bool isDark, Color accent, bool isAr) {
    final dailyPages = (604 / _targetDays).ceil();
    final dailyJuz = dailyPages / 20.0;
    final dailyHizb = dailyPages / 10.0;

    return Padding(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Icon(Icons.pie_chart_rounded, size: 56, color: accent.withOpacity(0.6)),
          const SizedBox(height: 16),
          Text(isAr ? AppLocaleKeys.divisionMethod.tr : 'Division Mode',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 8),
          Text(isAr ? AppLocaleKeys.howToMeasureWard.tr : 'How do you prefer to measure your daily portion?',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: isDark ? Colors.white54 : Colors.black45)),
          const SizedBox(height: 32),

          _divisionOption('page', isAr ? AppLocaleKeys.byPages.tr : 'By Pages', isAr ? '≈ $dailyPages صفحة/يوم' : '≈ $dailyPages pages/day', Icons.my_library_books_rounded, isDark, accent),
          const SizedBox(height: 12),
          _divisionOption('juz', isAr ? AppLocaleKeys.byJuzs.tr : 'By Juz', isAr ? '≈ ${dailyJuz.toStringAsFixed(1)} جزء/يوم' : '≈ ${dailyJuz.toStringAsFixed(1)} Juz/day', Icons.donut_large_rounded, isDark, accent),
          const SizedBox(height: 12),
          _divisionOption('hizb', isAr ? AppLocaleKeys.byHizbs.tr : 'By Hizb', isAr ? '≈ ${dailyHizb.toStringAsFixed(1)} حزب/يوم' : '≈ ${dailyHizb.toStringAsFixed(1)} Hizb/day', Icons.pie_chart_outline_rounded, isDark, accent),
        ],
      ),
    );
  }

  Widget _divisionOption(String mode, String title, String subtitle, IconData icon, bool isDark, Color accent) {
    final selected = _divisionMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _divisionMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selected ? accent.withOpacity(isDark ? 0.15 : 0.1) : Colors.transparent,
          border: Border.all(color: selected ? accent : accent.withOpacity(0.15), width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withOpacity(selected ? 0.2 : 0.08)),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  Text(subtitle, style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: accent)),
                ],
              ),
            ),
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: selected ? accent : accent.withOpacity(0.3), size: 22),
          ],
        ),
      ),
    );
  }

  // ─── Step 3: Session Pages ───
  Widget _buildSessionStep(bool isDark, Color accent, bool isAr) {
    final dailyPages = (604 / _targetDays).ceil();
    final sessions = (dailyPages / _sessionPages).ceil();

    return Padding(
      key: const ValueKey('step2'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Icon(Icons.auto_stories_rounded, size: 56, color: accent.withOpacity(0.6)),
          const SizedBox(height: 16),
          Text(isAr ? AppLocaleKeys.sessionCapacity.tr : 'Session Size',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 8),
          Text(isAr ? AppLocaleKeys.pagesPerSessionQuestion.tr : 'How many pages do you read per session?',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: isDark ? Colors.white54 : Colors.black45)),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _sessionOptions.map((pages) {
              final selected = _sessionPages == pages;
              return GestureDetector(
                onTap: () => setState(() => _sessionPages = pages),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 140,
                  height: 65,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: selected ? accent : accent.withOpacity(isDark ? 0.08 : 0.06),
                    border: Border.all(color: selected ? accent : accent.withOpacity(0.2), width: selected ? 2 : 1),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$pages ${isAr ? "صفحات" : "pages"}',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.bold,
                              color: selected ? (isDark ? Colors.black : Colors.white) : (isDark ? Colors.white70 : Colors.black54))),
                      Text('≈ ${(pages * 2.5).round()} ${isAr ? "دقائق" : "mins"}',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 11,
                              color: selected ? (isDark ? Colors.black54 : Colors.white70) : (isDark ? Colors.white38 : Colors.black26))),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: accent.withOpacity(isDark ? 0.08 : 0.06)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.repeat_rounded, size: 18, color: accent),
                const SizedBox(width: 8),
                Text(isAr ? '$sessions جلسة يومياً لإكمال الورد' : '$sessions sessions/day to complete portion',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600, color: accent)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 4: Notifications ───
  Widget _buildNotifyStep(bool isDark, Color accent, bool isAr) {
    return SingleChildScrollView(
      key: const ValueKey('step3'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Icon(Icons.notifications_active_rounded, size: 56, color: accent.withOpacity(0.6))),
          const SizedBox(height: 16),
          Center(
            child: Text(isAr ? AppLocaleKeys.khatmaNotifications.tr : 'Khatma Notifications',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          ),
          const SizedBox(height: 24),
          
          Text(isAr ? AppLocaleKeys.reminderTime.tr : 'Reminder Time', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 12),
          
          _notifyOption('after_prayer', isAr ? AppLocaleKeys.afterPrayers.tr : 'After Prayers', Icons.mosque_rounded, isDark, accent, isAr),
          if (_notifyMode == 'after_prayer' || _notifyMode == 'both') ...[
            const SizedBox(height: 8),
            _buildDelayPicker(isDark, accent, isAr),
          ],
          const SizedBox(height: 8),
          
          _notifyOption('specific_time', isAr ? 'وقت محدد' : 'Specific Time', Icons.access_time_rounded, isDark, accent, isAr),
          if (_notifyMode == 'specific_time' || _notifyMode == 'both') ...[
            const SizedBox(height: 8),
            _buildTimePickerButton(isDark, accent, isAr),
          ],
          const SizedBox(height: 8),
          _notifyOption('both', isAr ? 'كلاهما معاً' : 'Both', Icons.all_inclusive_rounded, isDark, accent, isAr),
          
          const SizedBox(height: 24),
          Text(isAr ? 'نمط الإشعار' : 'Notification Style', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 12),
          
          _styleOption('motivational', isAr ? 'تحفيزي' : 'Motivational', isAr ? 'رسائل معنوية وتشجيعية' : 'Encouraging messages', Icons.auto_awesome_rounded, isDark, accent),
          const SizedBox(height: 8),
          _styleOption('tadabbur', isAr ? 'تدبري' : 'Tadabbur', isAr ? 'آيات ومعاني للتأمل' : 'Verses and meanings', Icons.menu_book_rounded, isDark, accent),
          const SizedBox(height: 8),
          _styleOption('short', isAr ? 'مختصر' : 'Short', isAr ? 'تذكير بوقت القراءة فقط' : 'Just reading reminder', Icons.short_text_rounded, isDark, accent),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _notifyOption(String value, String title, IconData icon, bool isDark, Color accent, bool isAr) {
    final selected = _notifyMode == value;
    return GestureDetector(
      onTap: () => setState(() => _notifyMode = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected ? accent.withOpacity(isDark ? 0.15 : 0.1) : Colors.transparent,
          border: Border.all(color: selected ? accent : accent.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? accent : (isDark ? Colors.white54 : Colors.black54), size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: selected ? FontWeight.bold : FontWeight.normal, color: isDark ? Colors.white : Colors.black87))),
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: selected ? accent : accent.withOpacity(0.3), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _styleOption(String value, String title, String subtitle, IconData icon, bool isDark, Color accent) {
    final selected = _notifStyle == value;
    return GestureDetector(
      onTap: () => setState(() => _notifStyle = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected ? accent.withOpacity(0.05) : Colors.transparent,
          border: Border.all(color: selected ? accent.withOpacity(0.5) : Colors.transparent),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withOpacity(0.1)),
              child: Icon(icon, color: accent, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  Text(subtitle, style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: isDark ? Colors.white54 : Colors.black45)),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle_rounded, color: accent, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDelayPicker(bool isDark, Color accent, bool isAr) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: accent.withOpacity(0.05)),
      child: Row(
        children: [
          Text(isAr ? 'تأخير بعد الأذان:' : 'Delay after Adhan:', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
          const Spacer(),
          ...([10, 15, 20, 30]).map((m) {
            final sel = _prayerDelay == m;
            return GestureDetector(
              onTap: () => setState(() => _prayerDelay = m),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: sel ? accent : Colors.transparent),
                child: Text('$m ${isAr ? "د" : "m"}', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold, color: sel ? (isDark ? Colors.black : Colors.white) : (isDark ? Colors.white54 : Colors.black45))),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimePickerButton(bool isDark, Color accent, bool isAr) {
    return GestureDetector(
      onTap: () async {
        final t = await showTimePicker(context: context, initialTime: _specificTime);
        if (t != null) setState(() => _specificTime = t);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: accent.withOpacity(0.05)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_rounded, size: 16, color: accent),
            const SizedBox(width: 8),
            Text('${isAr ? "تغيير الوقت:" : "Change Time:"} ${_specificTime.format(context)}',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold, color: accent)),
          ],
        ),
      ),
    );
  }

  Future<void> _createKhatma() async {
    final timeStr = '${_specificTime.hour.toString().padLeft(2, '0')}:${_specificTime.minute.toString().padLeft(2, '0')}';
    final khatma = await KhatmaService.create(
      name: _nameController.text.trim(),
      targetDays: _targetDays,
      divisionMode: _divisionMode,
      sessionPages: _sessionPages,
      notifyMode: _notifyMode,
      notifStyle: _notifStyle,
      specificTime: timeStr,
      afterPrayerDelayMinutes: _prayerDelay,
    );

    // Schedule notifications
    await KhatmaNotificationService.scheduleNotifications(khatma);

    if (mounted) {
      Navigator.pop(context, khatma);
    }
  }
}
