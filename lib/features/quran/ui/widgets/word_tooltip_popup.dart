import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/quran_word_model.dart';
import '../../logic/quran_audio_provider.dart';

/// Popup يظهر فوق الكلمة المضغوطة — يعرض المعنى والصوت
class WordTooltipPopup extends StatelessWidget {
  final QuranWordModel? word;
  final bool isLoading;
  final bool isDark;
  final VoidCallback onDismiss;

  const WordTooltipPopup({
    super.key,
    required this.word,
    required this.isLoading,
    required this.isDark,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? const Color(0xFFFFD700) : const Color(0xFF00695C);
    final bgColor = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFFFFBE0);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white60 : Colors.black54;

    return GestureDetector(
      onTap: onDismiss,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black.withOpacity(0.15),
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () {}, // Prevent dismiss when tapping popup itself
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 360),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: accent.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: accent.withOpacity(0.1),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: isLoading
                ? _buildLoading(accent)
                : word != null
                    ? _buildContent(context, accent, textColor, subColor)
                    : _buildError(subColor),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(Color accent) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            color: accent,
            strokeWidth: 2.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'جاري تحميل بيانات الكلمة...',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, Color accent, Color textColor, Color subColor) {
    final w = word!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // الزخرفة العلوية
        Container(
          width: 50,
          height: 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accent.withOpacity(0.0),
                accent.withOpacity(0.6),
                accent.withOpacity(0.0),
              ],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 14),

        // الكلمة بالرسم العثماني
        Text(
          w.textUthmani,
          style: TextStyle(
            fontFamily: 'UthmanTN',
            fontSize: 36,
            color: accent,
            height: 1.4,
          ),
          textDirection: TextDirection.rtl,
        ),

        const SizedBox(height: 8),

        // خط فاصل
        Container(
          width: 80,
          height: 1,
          color: accent.withOpacity(0.2),
        ),

        const SizedBox(height: 10),

        // المعنى (الترجمة)
        if (w.translationText != null && w.translationText!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accent.withOpacity(isDark ? 0.1 : 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'المعنى',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: subColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  w.translationText!,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // النطق (Transliteration)
        if (w.transliterationText != null && w.transliterationText!.isNotEmpty) ...[
          Text(
            w.transliterationText!,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              color: subColor,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
        ],

        // زر سماع الكلمة
        if (w.hasAudio)
          Consumer<QuranAudioProvider>(
            builder: (context, audioProvider, _) {
              return GestureDetector(
                onTap: () => audioProvider.playWord(w.audioUrl!),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: accent.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        audioProvider.isPlaying
                            ? Icons.volume_up_rounded
                            : Icons.play_arrow_rounded,
                        color: accent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'سماع الكلمة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

        const SizedBox(height: 8),

        // الزخرفة السفلية
        Container(
          width: 50,
          height: 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accent.withOpacity(0.0),
                accent.withOpacity(0.6),
                accent.withOpacity(0.0),
              ],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildError(Color subColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, color: subColor, size: 36),
        const SizedBox(height: 8),
        Text(
          'تعذر جلب بيانات الكلمة\nتأكد من الاتصال بالإنترنت',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            color: subColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
