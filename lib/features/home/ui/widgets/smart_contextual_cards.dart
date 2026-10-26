import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:adhan/adhan.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/translations/app_locale_keys.dart';
import '../../../prayers/logic/prayer_times_controller.dart';
import '../../../adhkar/data/adhkar_model.dart';
import '../../../adhkar/ui/screens/adhkar_details_screen.dart';

class SmartContextualCards extends StatefulWidget {
  const SmartContextualCards({super.key});

  @override
  State<SmartContextualCards> createState() => _SmartContextualCardsState();
}

class _SmartContextualCardsState extends State<SmartContextualCards> {
  PrayerTimes? _times;
  Timer? _timer;
  Map<String, dynamic>? _forbiddenData;

  static const Color _green = Color(0xFF1E4233);
  static const Color _gold = Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
    _loadForbiddenData();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadPrayerTimes() async {
    final controller = PrayerTimesController();
    final times = await controller.getStoredOrDefaultPrayerTimes();
    if (mounted) setState(() => _times = times);
  }

  Future<void> _loadForbiddenData() async {
    try {
      final str =
          await rootBundle.loadString('assets/json/forbidden_times.json');
      if (mounted) setState(() => _forbiddenData = json.decode(str));
    } catch (_) {}
  }

  Map<String, dynamic>? _getForbiddenInfo(PrayerTimes times, DateTime now) {
    if (_forbiddenData == null) return null;
    final list = _forbiddenData!['forbidden_times'] as List<dynamic>? ?? [];
    final sunrise = times.sunrise.toLocal();
    final dhuhr = times.dhuhr.toLocal();
    final asr = times.asr.toLocal();
    final maghrib = times.maghrib.toLocal();
    final fajr = times.fajr.toLocal();

    if (now.isAfter(fajr) &&
        now.isBefore(sunrise.add(const Duration(minutes: 20)))) {
      return list.firstWhere((e) => e['id'] == 'after_fajr',
          orElse: () => null);
    }
    if (now.isAfter(dhuhr.subtract(const Duration(minutes: 15))) &&
        now.isBefore(dhuhr)) {
      return list.firstWhere((e) => e['id'] == 'before_dhuhr',
          orElse: () => null);
    }
    if (now.isAfter(asr) && now.isBefore(maghrib)) {
      return list.firstWhere((e) => e['id'] == 'after_asr', orElse: () => null);
    }
    return null;
  }

  bool _isAfterPrayerTime(PrayerTimes times, DateTime now) {
    final prayers = [
      times.fajr.toLocal(),
      times.dhuhr.toLocal(),
      times.asr.toLocal(),
      times.maghrib.toLocal(),
      times.isha.toLocal(),
    ];
    return prayers.any(
      (pt) =>
          now.isAfter(pt) && now.isBefore(pt.add(const Duration(minutes: 15))),
    );
  }

  Future<void> _openAfterPrayerAdhkar() async {
    try {
      final str = await rootBundle.loadString('assets/json/B3DALSALL.JSON');
      final data = json.decode(str);
      final title = Get.locale?.languageCode == 'en'
          ? 'After Prayer Adhkar'
          : (data['title'] ?? 'أذكار بعد الصلاة');
      final content = data['content'] as List<dynamic>? ?? [];
      final items = content.asMap().entries.map((e) {
        final item = e.value;
        return DhikrItem(
          id: e.key,
          text: item['zekr'] ?? '',
          count: item['repeat'] ?? 1,
          audio: '',
          filename: '',
          bless: item['bless'] ?? '',
        );
      }).toList();
      final category = AdhkarCategory(
          id: 999, category: title, audio: '', filename: '', items: items);
      if (mounted) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AdhkarDetailsScreen(category: category)));
      }
    } catch (_) {}
  }

  void _showForbiddenDetails(Map<String, dynamic> info) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ForbiddenBottomSheet(
        info: info,
        note: _forbiddenData?['note'],
        isDark: isDark,
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: isDark ? color.withOpacity(0.12) : color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(isDark ? 0.25 : 0.35),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : color.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
                Get.locale?.languageCode == 'ar'
                    ? Icons.arrow_back_ios_new_rounded
                    : Icons.arrow_forward_ios_rounded,
                color: color.withOpacity(0.4),
                size: 14),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_times == null) return const SizedBox.shrink();
    final now = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEn = Get.locale?.languageCode == 'en';
    final List<Widget> cards = [];

    final forbiddenInfo = _getForbiddenInfo(_times!, now);
    if (forbiddenInfo != null) {
      // For forbidden times, if it's English, we use fallback titles since JSON is Arabic
      String title = isEn
          ? AppLocaleKeys.forbiddenTimeTitle.tr
          : (forbiddenInfo['title'] ?? 'وقت نهي عن الصلاة');

      cards.add(_buildCard(
        title: title,
        subtitle: AppLocaleKeys.tapForDetails.tr,
        icon: Icons.block_rounded,
        color: Colors.redAccent,
        onTap: () => _showForbiddenDetails(forbiddenInfo),
        isDark: isDark,
      ));
    }

    if (_isAfterPrayerTime(_times!, now)) {
      cards.add(_buildCard(
        title: AppLocaleKeys.afterPrayerAdhkar.tr,
        subtitle: AppLocaleKeys.dontForgetAdhkar.tr,
        icon: FontAwesomeIcons.handsPraying,
        color: const Color(0xFF42A5F5),
        onTap: _openAfterPrayerAdhkar,
        isDark: isDark,
      ));
    }

    if (cards.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Column(children: cards),
    );
  }
}

// ─── Bottom Sheet for forbidden times ────────────────────────────────────────
class _ForbiddenBottomSheet extends StatelessWidget {
  final Map<String, dynamic> info;
  final String? note;
  final bool isDark;

  const _ForbiddenBottomSheet({
    required this.info,
    required this.note,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isEn = Get.locale?.languageCode == 'en';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2A3A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.block_rounded,
                color: Colors.redAccent, size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            isEn ? AppLocaleKeys.forbiddenTimeTitle.tr : (info['title'] ?? ''),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1E4233),
            ),
          ),
          const SizedBox(height: 8),
          // Description (remains in Arabic if no EN translation in JSON, but direction follows locale)
          Text(
            info['description'] ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          // Daleel card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E4233).withOpacity(0.3)
                  : const Color(0xFF1E4233).withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: const Color(0xFFD4AF37).withOpacity(0.35)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment:
                      isEn ? MainAxisAlignment.start : MainAxisAlignment.end,
                  children: [
                    Text(AppLocaleKeys.daleelTitle.tr,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFD4AF37))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  info['daleel'] ?? '',
                  textAlign: isEn ? TextAlign.left : TextAlign.right,
                  textDirection: isEn ? TextDirection.ltr : TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.7,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.white : const Color(0xFF1E4233),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment:
                      isEn ? Alignment.centerRight : Alignment.centerLeft,
                  child: Text(
                    info['source'] ?? '',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEn ? 'Note: $note' : 'ملحوظة: $note',
                      textDirection:
                          isEn ? TextDirection.ltr : TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
