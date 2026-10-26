import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/quran_audio_provider.dart';
import '../../data/models/quran_word_model.dart';
import 'tafsir_sheet.dart';
import 'reciter_selector.dart';
import 'repeat_counter.dart';

/// BottomSheet يظهر عند الضغط على آية - يعرض خيارات التشغيل والتفسير
class AyahOptionsSheet extends StatefulWidget {
  final int surahNumber;
  final int ayahNumber;
  final String surahName;
  final String ayahText;
  final bool isDark;
  final void Function(int colorIndex)? onBookmark;
  final Set<int> existingBookmarkColors;

  const AyahOptionsSheet({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    required this.ayahText,
    required this.isDark,
    this.onBookmark,
    this.existingBookmarkColors = const {},
  });

  /// عرض الـ Sheet
  static void show(BuildContext context, {
    required int surahNumber,
    required int ayahNumber,
    required String surahName,
    required String ayahText,
    required bool isDark,
    void Function(int colorIndex)? onBookmark,
    Set<int> existingBookmarkColors = const {},
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AyahOptionsSheet(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        surahName: surahName,
        ayahText: ayahText,
        isDark: isDark,
        onBookmark: onBookmark,
        existingBookmarkColors: existingBookmarkColors,
      ),
    );
  }

  @override
  State<AyahOptionsSheet> createState() => _AyahOptionsSheetState();
}

class _AyahOptionsSheetState extends State<AyahOptionsSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<QuranWordModel> _words = [];
  bool _isLoadingWords = false;
  int _repeatCount = 1;
  late Set<int> _bookmarkedColors;

  // Bookmark colors
  static const List<Color> _bmColors = [
    Color(0xFFE53935), // Red
    Color(0xFF1E88E5), // Blue
    Color(0xFF43A047), // Green
    Color(0xFFFFA726), // Orange
  ];
  static const List<String> _bmColorNames = ['أحمر', 'أزرق', 'أخضر', 'برتقالي'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _bookmarkedColors = Set<int>.from(widget.existingBookmarkColors);
    _loadWords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWords() async {
    setState(() => _isLoadingWords = true);
    try {
      final audioProvider = Provider.of<QuranAudioProvider>(context, listen: false);
      _words = await audioProvider.getAyahWords(widget.surahNumber, widget.ayahNumber);
    } catch (e) {
      debugPrint('❌ خطأ في جلب الكلمات: $e');
    }
    if (mounted) setState(() => _isLoadingWords = false);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFBE0);
    final textColor = widget.isDark ? Colors.white : Colors.black87;
    final accentColor = widget.isDark ? Colors.cyanAccent : const Color(0xFF8B6F47);
    final cardColor = widget.isDark ? Colors.white.withOpacity(0.08) : Colors.white;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.surahName,
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'آية ${widget.ayahNumber}',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const Spacer(),
                    // Bookmark colors
                    if (widget.onBookmark != null)
                      ...List.generate(4, (i) {
                        final isBookmarked = _bookmarkedColors.contains(i);
                        return Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: GestureDetector(
                            onTap: () {
                              if (!isBookmarked) {
                                widget.onBookmark!(i);
                                setState(() => _bookmarkedColors.add(i));
                              }
                            },
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _bmColors[i].withOpacity(isBookmarked ? 0.3 : 0.1),
                                border: Border.all(
                                  color: _bmColors[i].withOpacity(isBookmarked ? 1.0 : 0.5),
                                  width: isBookmarked ? 2 : 1,
                                ),
                              ),
                              child: isBookmarked
                                  ? Icon(Icons.check, color: _bmColors[i], size: 16)
                                  : Icon(Icons.bookmark_add_outlined, color: _bmColors[i], size: 14),
                            ),
                          ),
                        );
                      }),
                    const SizedBox(width: 4),
                    // Close button
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.grey, size: 20),
                    ),
                  ],
                ),
              ),

              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: accentColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: accentColor,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'الآية', icon: Icon(Icons.play_circle_outline, size: 18)),
                    Tab(text: 'الكلمة', icon: Icon(Icons.text_fields, size: 18)),
                    Tab(text: 'التفسير', icon: Icon(Icons.menu_book, size: 18)),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // ═══ تاب الآية (تشغيل + تكرار) ═══
                    _buildAyahTab(textColor, accentColor, cardColor),
                    
                    // ═══ تاب الكلمة ═══
                    _buildWordTab(textColor, accentColor, cardColor),
                    
                    // ═══ تاب التفسير ═══
                    TafsirSheet(
                      surahNumber: widget.surahNumber,
                      ayahNumber: widget.ayahNumber,
                      isDark: widget.isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// تاب الآية - تشغيل وتكرار
  Widget _buildAyahTab(Color textColor, Color accentColor, Color cardColor) {
    return Consumer<QuranAudioProvider>(
      builder: (context, audioProvider, _) {
        final isCurrentAyah = audioProvider.currentSurah == widget.surahNumber &&
            audioProvider.currentAyah == widget.ayahNumber;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // نص الآية
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: isCurrentAyah && audioProvider.isPlaying
                      ? Border.all(color: accentColor.withOpacity(0.5), width: 2)
                      : null,
                ),
                child: Text(
                  widget.ayahText,
                  style: TextStyle(
                    fontFamily: 'UthmanTN',
                    fontSize: 22,
                    color: textColor,
                    height: 2.0,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
              ),

              const SizedBox(height: 16),

              // اختيار القارئ
              ReciterSelector(
                isDark: widget.isDark,
                selectedReciterId: audioProvider.selectedReciterId,
                reciters: audioProvider.reciters,
                onReciterChanged: (id) => audioProvider.setReciter(id),
              ),

              const SizedBox(height: 16),

              // التكرار
              RepeatCounter(
                isDark: widget.isDark,
                count: _repeatCount,
                onChanged: (count) {
                  setState(() => _repeatCount = count);
                },
              ),

              const SizedBox(height: 16),

              // حالة التكرار
              if (isCurrentAyah && audioProvider.isRepeating)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'التكرار ${audioProvider.currentRepeat} من ${audioProvider.repeatCount}',
                    style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),

              // أزرار التحكم
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // زر إيقاف
                  if (isCurrentAyah && (audioProvider.isPlaying || audioProvider.isRepeating))
                    _controlButton(
                      icon: Icons.stop_rounded,
                      label: 'إيقاف',
                      color: Colors.red,
                      onTap: () => audioProvider.stop(),
                    ),

                  if (isCurrentAyah && (audioProvider.isPlaying || audioProvider.isRepeating))
                    const SizedBox(width: 12),

                  // زر تشغيل/إيقاف مؤقت
                  _controlButton(
                    icon: isCurrentAyah && audioProvider.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    label: isCurrentAyah && audioProvider.isPlaying ? 'إيقاف مؤقت' : 'تشغيل',
                    color: accentColor,
                    isMain: true,
                    isLoading: audioProvider.isLoading,
                    onTap: () {
                      if (isCurrentAyah && audioProvider.isPlaying) {
                        audioProvider.pause();
                      } else if (isCurrentAyah && !audioProvider.isPlaying) {
                        audioProvider.resume();
                      } else {
                        audioProvider.playAyah(
                          widget.surahNumber,
                          widget.ayahNumber,
                          repeat: _repeatCount,
                        );
                      }
                    },
                  ),
                ],
              ),

              // رسالة خطأ
              if (audioProvider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    audioProvider.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// تاب الكلمة - صوت كل كلمة
  Widget _buildWordTab(Color textColor, Color accentColor, Color cardColor) {
    if (_isLoadingWords) {
      return Center(child: CircularProgressIndicator(color: accentColor));
    }

    if (_words.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.grey, size: 48),
            const SizedBox(height: 12),
            Text('لم يتم العثور على كلمات', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Consumer<QuranAudioProvider>(
      builder: (context, audioProvider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'اضغط على أي كلمة لسماع نطقها',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // عرض الكلمات
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 12,
                children: _words.map((word) {
                  return GestureDetector(
                    onTap: word.hasAudio
                        ? () => audioProvider.playWord(word.audioUrl!)
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: word.hasAudio
                              ? accentColor.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // الكلمة العثمانية
                          Text(
                            word.textUthmani,
                            style: TextStyle(
                              fontFamily: 'UthmanTN',
                              fontSize: 24,
                              color: textColor,
                            ),
                          ),
                          if (word.translationText != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              word.translationText!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                          if (word.hasAudio) ...[
                            const SizedBox(height: 4),
                            Icon(Icons.volume_up, size: 14, color: accentColor),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isMain = false,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Column(
        children: [
          Container(
            width: isMain ? 64 : 48,
            height: isMain ? 64 : 48,
            decoration: BoxDecoration(
              color: color.withOpacity(isMain ? 1.0 : 0.15),
              shape: BoxShape.circle,
              boxShadow: isMain
                  ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]
                  : null,
            ),
            child: isLoading
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Icon(icon, color: isMain ? Colors.white : color, size: isMain ? 32 : 24),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
