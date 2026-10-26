import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/radio_station.dart';
import '../../data/models/recitation.dart';
import '../../data/models/shaykh.dart';
import '../../data/radio_stations_data.dart';
import 'media_player_screen.dart';

class StateRadiosScreen extends StatelessWidget {
  const StateRadiosScreen({super.key});

  bool get _isEnglish => Get.locale?.languageCode == 'en';

  void _openRadioPlayer(BuildContext context, RadioStation station) {
    final shaykh = Shaykh(
      id: 'radio_${station.id}',
      name: station.name,
      bio: _isEnglish ? 'Live stream inside the app' : 'بث مباشر داخل التطبيق',
      imageUrl: '',
      category: 'radio',
    );

    final recitation = Recitation(
      id: 'radio_live_${station.id}',
      title: station.name,
      audioUrl: station.streamUrl,
      reciterName: station.name,
      mushafName: _isEnglish ? 'Live radio' : 'إذاعة مباشرة',
      audioSource: 'radio',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MediaPlayerScreen(
          shaykh: shaykh,
          currentRecitation: recitation,
          allRecitations: [recitation],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // ألوان متسقة مع باقي التطبيق
    final background =
        isDark ? const Color(0xFF0D1F1A) : const Color(0xFFF8F6EE);
    final cardColor = isDark ? const Color(0xFF152920) : Colors.white;
    final borderColor =
        isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFE4EDE8);
    final textColor = isDark ? Colors.white : const Color(0xFF1A3D2F);
    final subColor = isDark ? Colors.white54 : const Color(0xFF7A9488);
    // في الداكن نستخدم أخضر أفتح عشان يبان على الخلفية الداكنة
    final accentGreen =
        isDark ? const Color(0xFF3D9970) : const Color(0xFF224F34);
    final accentLight =
        isDark ? const Color(0xFF254D3A) : const Color(0xFFEAF2EC);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        title: Text(
          _isEnglish ? 'State Radios' : 'إذاعات الدول',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: textColor,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Header Card ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: accentGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.radio_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEnglish
                              ? 'Quran radios from around the world'
                              : 'إذاعات القرآن من دول مختلفة',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isEnglish
                              ? '${stateRadioStations.length} live stations'
                              : '${stateRadioStations.length} إذاعة مباشرة',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── List ─────────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              itemCount: stateRadioStations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final station = stateRadioStations[index];
                return _RadioTile(
                  station: station,
                  isEnglish: _isEnglish,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  textColor: textColor,
                  subColor: subColor,
                  accentGreen: accentGreen,
                  accentLight: accentLight,
                  isDark: isDark,
                  onTap: () => _openRadioPlayer(context, station),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tile Widget ───────────────────────────────────────────────────────────────
class _RadioTile extends StatelessWidget {
  final RadioStation station;
  final bool isEnglish;
  final Color cardColor;
  final Color borderColor;
  final Color textColor;
  final Color subColor;
  final Color accentGreen;
  final Color accentLight;
  final bool isDark;
  final VoidCallback onTap;

  const _RadioTile({
    required this.station,
    required this.isEnglish,
    required this.cardColor,
    required this.borderColor,
    required this.textColor,
    required this.subColor,
    required this.accentGreen,
    required this.accentLight,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // أيقونة الإذاعة
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: accentLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.graphic_eq_rounded,
                    color: accentGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),

                // النصوص
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEnglish ? station.countryEn : station.country,
                        style: TextStyle(
                          color: subColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isEnglish ? station.nameEn : station.name,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Badge "بث مباشر"
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accentLight,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: accentGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isEnglish ? 'Live' : 'بث مباشر',
                              style: TextStyle(
                                color: accentGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // زرار التشغيل
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: accentGreen,
                    size: 24,
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
