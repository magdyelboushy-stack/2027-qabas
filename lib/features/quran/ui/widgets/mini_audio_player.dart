import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran/quran.dart' as quran_utils;
import '../../logic/quran_audio_provider.dart';
import 'audio_settings_sheet.dart';

/// مشغل صوتي مصغر يظهر في أسفل شاشة المصحف
class MiniAudioPlayer extends StatelessWidget {
  const MiniAudioPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<QuranAudioProvider>(
      builder: (context, audio, _) {
        // لا نعرض المشغل لو مفيش جلسة نشطة
        if (!audio.hasActiveSession) return const SizedBox.shrink();

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final surahName = audio.currentSurahName;
        final ayahNum = audio.currentAyah ?? 0;
        final reciterName = audio.currentReciterName;

        return Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: () => _showSettingsSheet(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1A2F2A)
                    : const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2E7D32).withOpacity(0.4)
                      : const Color(0xFFB8860B).withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.4)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // ── زر إغلاق ──
                  _buildIconButton(
                    icon: Icons.close_rounded,
                    onTap: () => audio.stop(),
                    color: isDark ? Colors.white38 : Colors.black38,
                    size: 20,
                  ),
                  const SizedBox(width: 8),

                  // ── معلومات الآية ──
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$surahName  •  آية $ayahNum',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFF81C784)
                                : const Color(0xFF2E7D32),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          reciterName,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 6),

                  // ── مؤشرات الإعدادات ──
                  if (audio.continuousPlayback)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2E7D32).withOpacity(0.2)
                            : const Color(0xFF2E7D32).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.playlist_play_rounded,
                        size: 16,
                        color: isDark
                            ? const Color(0xFF81C784)
                            : const Color(0xFF2E7D32),
                      ),
                    ),
                  if (audio.repeatCount != 1) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFFFF8F00).withOpacity(0.2)
                            : const Color(0xFFFF8F00).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.repeat_rounded,
                            size: 14,
                            color: isDark
                                ? const Color(0xFFFFB74D)
                                : const Color(0xFFFF8F00),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            audio.repeatCount == -1 ? '∞' : '${audio.repeatCount}',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFFFB74D)
                                  : const Color(0xFFFF8F00),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(width: 8),

                  // ── زر السابق ──
                  _buildIconButton(
                    icon: Icons.skip_previous_rounded,
                    onTap: () => audio.playPreviousAyah(),
                    color: isDark ? Colors.white70 : Colors.black54,
                    size: 24,
                  ),

                  const SizedBox(width: 4),

                  // ── زر التشغيل / الإيقاف ──
                  _buildPlayPauseButton(audio, isDark),

                  const SizedBox(width: 4),

                  // ── زر التالي ──
                  _buildIconButton(
                    icon: Icons.skip_next_rounded,
                    onTap: () => audio.playNextAyahManual(),
                    color: isDark ? Colors.white70 : Colors.black54,
                    size: 24,
                  ),

                  const SizedBox(width: 4),

                  // ── زر الإعدادات ──
                  _buildIconButton(
                    icon: Icons.tune_rounded,
                    onTap: () => _showSettingsSheet(context),
                    color: isDark
                        ? const Color(0xFFFFD700)
                        : const Color(0xFFB8860B),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayPauseButton(QuranAudioProvider audio, bool isDark) {
    if (audio.isLoading) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? const Color(0xFF2E7D32)
              : const Color(0xFF2E7D32),
        ),
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        if (audio.isPlaying) {
          audio.pause();
        } else {
          audio.resume();
        }
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF2E7D32), const Color(0xFF1B5E20)]
                : [const Color(0xFF2E7D32), const Color(0xFF1B5E20)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          audio.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    double size = 22,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, color: color, size: size),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AudioSettingsSheet(),
    );
  }
}
