import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../../../core/translations/app_locale_keys.dart';
import '../../logic/quran_audio_provider.dart';

/// شاشة إعدادات تشغيل الصوت (التكرار، التشغيل المستمر، اختيار القارئ)
class AudioSettingsSheet extends StatelessWidget {
  const AudioSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
    final gold = isDark ? const Color(0xFFFFD700) : const Color(0xFFB8860B);

    return Consumer<QuranAudioProvider>(
      builder: (context, audio, _) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom + 16,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0E241E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── المقبض ──
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // ── العنوان ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.settings_rounded, color: gold, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      AppLocaleKeys.audioSettingsTitle.tr,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: gold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── معلومات الآية الحالية ──
              if (audio.hasActiveSession)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? accent.withOpacity(0.08)
                        : accent.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: accent.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withOpacity(0.15),
                        ),
                        child: Icon(
                          audio.isPlaying
                              ? Icons.graphic_eq_rounded
                              : Icons.pause_circle_outline_rounded,
                          color: accent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocaleKeys.surahNameLabel.trParams({'name': audio.currentSurahName}) + '  •  ' + 
                              AppLocaleKeys.ayahNumberLabel.trParams({'number': audio.currentAyah.toString()}),
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              audio.currentReciterName,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // ── أزرار التحكم ──
              if (audio.hasActiveSession)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // السابق
                      _buildControlButton(
                        icon: Icons.skip_previous_rounded,
                        onTap: () => audio.playPreviousAyah(),
                        color: isDark ? Colors.white70 : Colors.black54,
                        isDark: isDark,
                      ),

                      // تشغيل / إيقاف
                      GestureDetector(
                        onTap: () {
                          if (audio.isLoading) return;
                          if (audio.isPlaying) {
                            audio.pause();
                          } else {
                            audio.resume();
                          }
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [accent, accent.withOpacity(0.7)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: audio.isLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Icon(
                                  audio.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                        ),
                      ),

                      // التالي
                      _buildControlButton(
                        icon: Icons.skip_next_rounded,
                        onTap: () => audio.playNextAyahManual(),
                        color: isDark ? Colors.white70 : Colors.black54,
                        isDark: isDark,
                      ),

                      // إيقاف تام
                      _buildControlButton(
                        icon: Icons.stop_rounded,
                        onTap: () {
                          audio.stop();
                          Navigator.pop(context);
                        },
                        color: Colors.redAccent,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
              Divider(
                color: isDark ? Colors.white12 : Colors.black12,
                indent: 20,
                endIndent: 20,
              ),
              const SizedBox(height: 8),

              // ══════════════════════════════════════
              // التشغيل المستمر
              // ══════════════════════════════════════
              _buildSettingTile(
                isDark: isDark,
                icon: Icons.playlist_play_rounded,
                iconColor: accent,
                title: AppLocaleKeys.continuousPlayback.tr,
                subtitle: AppLocaleKeys.continuousPlaybackDesc.tr,
                trailing: Switch.adaptive(
                  value: audio.continuousPlayback,
                  onChanged: (_) => audio.toggleContinuousPlayback(),
                  activeColor: accent,
                ),
              ),

              const SizedBox(height: 4),


              // ══════════════════════════════════════
              // سرعة التشغيل
              // ══════════════════════════════════════
              _buildSettingTile(
                isDark: isDark,
                icon: Icons.speed_rounded,
                iconColor: Colors.teal,
                title: AppLocaleKeys.playbackSpeed.tr,
                subtitle: '${audio.playbackSpeed}x',
                trailing: null,
                child: Padding(
                  padding: const EdgeInsets.only(right: 40, left: 20, bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_walk_rounded, size: 16, color: Colors.grey),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.teal,
                            inactiveTrackColor: isDark ? Colors.white12 : Colors.black12,
                            thumbColor: Colors.teal,
                            overlayColor: Colors.teal.withOpacity(0.2),
                            trackHeight: 4.0,
                          ),
                          child: Slider(
                            value: audio.playbackSpeed,
                            min: 0.5,
                            max: 2.0,
                            divisions: 6,
                            label: '${audio.playbackSpeed}x',
                            onChanged: (value) => audio.setPlaybackSpeed(value),
                          ),
                        ),
                      ),
                      const Icon(Icons.directions_run_rounded, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // ══════════════════════════════════════
              // اختيار القارئ
              // ══════════════════════════════════════
              _buildSettingTile(
                isDark: isDark,
                icon: Icons.person_rounded,
                iconColor: isDark ? const Color(0xFF64B5F6) : const Color(0xFF1565C0),
                title: AppLocaleKeys.reciterLabel.tr,
                subtitle: audio.currentReciterName,
                trailing: Icon(
                  Icons.chevron_left_rounded,
                  color: isDark ? Colors.white38 : Colors.black26,
                ),
                onTap: () => _showReciterPicker(context, audio, isDark),
              ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.04),
        ),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }

  Widget _buildSettingTile({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    Widget? child,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withOpacity(0.12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          trailing: trailing,
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        if (child != null) child,
      ],
    );
  }

  void _showReciterPicker(
    BuildContext context,
    QuranAudioProvider audio,
    bool isDark,
  ) {
    final accent = isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0E241E) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    AppLocaleKeys.chooseReciter.tr,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: audio.reciters.length,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemBuilder: (_, index) {
                        final reciter = audio.reciters[index];
                        final isSelected =
                            reciter.id == audio.selectedReciterId;
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? accent.withOpacity(0.15)
                                  : isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.black.withOpacity(0.04),
                              border: isSelected
                                  ? Border.all(color: accent, width: 2)
                                  : null,
                            ),
                            child: Icon(
                              isSelected
                                  ? Icons.check_rounded
                                  : Icons.person_outline_rounded,
                              color: isSelected
                                  ? accent
                                  : isDark
                                      ? Colors.white38
                                      : Colors.black38,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            reciter.arabicName,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? accent
                                  : isDark
                                      ? Colors.white
                                      : Colors.black87,
                            ),
                          ),
                          subtitle: reciter.style != null
                              ? Text(
                                  reciter.categoryName,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black38,
                                  ),
                                )
                              : null,
                          onTap: () {
                            audio.setReciter(reciter.id);
                            Navigator.pop(ctx);
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
