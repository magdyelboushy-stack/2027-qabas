import 'package:flutter/material.dart';
import '../../data/services/surah_database_service.dart';

/// نافذة تفاصيل الكلمة — تظهر عند الضغط على كلمة في المصحف
class WordDetailsSheet extends StatefulWidget {
  final String wordText;
  final int surahNumber;
  final int ayahNumber;
  final int wordIndex; // 1-based index of word in ayah
  final bool isDark;
  final VoidCallback? onPlayAudio;

  const WordDetailsSheet({
    super.key,
    required this.wordText,
    required this.surahNumber,
    required this.ayahNumber,
    required this.wordIndex,
    required this.isDark,
    this.onPlayAudio,
  });

  static void show(BuildContext context, {
    required String wordText,
    required int surahNumber,
    required int ayahNumber,
    required int wordIndex,
    required bool isDark,
    VoidCallback? onPlayAudio,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WordDetailsSheet(
        wordText: wordText,
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        wordIndex: wordIndex,
        isDark: isDark,
        onPlayAudio: onPlayAudio,
      ),
    );
  }

  @override
  State<WordDetailsSheet> createState() => _WordDetailsSheetState();
}

class _WordDetailsSheetState extends State<WordDetailsSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _dbService = SurahDatabaseService.instance;

  bool _isLoading = true;
  String? _meaning;
  String? _eerab;
  String? _tasreef;
  String? _tajweed;
  String? _englishTranslation;
  List<Map<String, dynamic>> _occurrences = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load word data in parallel
      final futures = await Future.wait([
        _dbService.getWordMeaning(widget.surahNumber, widget.ayahNumber, widget.wordIndex),
        _dbService.getWordEerab(widget.surahNumber, widget.ayahNumber, widget.wordIndex),
        _dbService.getWordTasreef(widget.surahNumber, widget.ayahNumber, widget.wordIndex),
        _dbService.getAyaTajweed(widget.surahNumber, widget.ayahNumber),
        _dbService.getEnglishTranslation(widget.surahNumber, widget.ayahNumber),
        _dbService.searchWordInQuran(widget.wordText),
      ]);

      _meaning = futures[0] as String?;
      _eerab = futures[1] as String?;
      _tasreef = futures[2] as String?;
      _tajweed = futures[3] as String?;
      _englishTranslation = futures[4] as String?;
      _occurrences = (futures[5] as List<Map<String, dynamic>>?) ?? [];
    } catch (e) {
      debugPrint('❌ Error loading word data: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? const Color(0xFF0E241E) : const Color(0xFFFFFBE0);
    final textColor = widget.isDark ? Colors.white : Colors.black87;
    final accent = widget.isDark ? const Color(0xFFFFD700) : const Color(0xFF00695C);
    final cardColor = widget.isDark ? Colors.white.withOpacity(0.06) : Colors.white;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, -5)),
            ],
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: widget.isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // ── Header: Word + Play Button ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    // Play audio button
                    if (widget.onPlayAudio != null)
                      GestureDetector(
                        onTap: widget.onPlayAudio,
                        child: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent,
                            boxShadow: [BoxShadow(color: accent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                          ),
                          child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    if (widget.onPlayAudio != null) const SizedBox(width: 12),

                    // Word text
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: accent.withOpacity(0.2)),
                        ),
                        child: Text(
                          widget.wordText,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: 'UthmanTN',
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),
                    // Close
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: widget.isDark ? Colors.white38 : Colors.black38),
                    ),
                  ],
                ),
              ),

              // ── Tabs ──
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: accent,
                  unselectedLabelColor: widget.isDark ? Colors.white38 : Colors.black38,
                  indicatorColor: accent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 11),
                  tabs: const [
                    Tab(text: 'المعنى', icon: Icon(Icons.lightbulb_outline, size: 16)),
                    Tab(text: 'الإعراب', icon: Icon(Icons.account_tree_outlined, size: 16)),
                    Tab(text: 'التصريف', icon: Icon(Icons.transform, size: 16)),
                    Tab(text: 'البحث', icon: Icon(Icons.search, size: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── Tab Content ──
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: accent))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildMeaningTab(textColor, accent, cardColor),
                          _buildEerabTab(textColor, accent, cardColor),
                          _buildTasreefTab(textColor, accent, cardColor),
                          _buildSearchTab(textColor, accent, cardColor),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// تاب المعنى + التجويد + الترجمة
  Widget _buildMeaningTab(Color textColor, Color accent, Color cardColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // المعنى العربي
          _buildSection(
            icon: Icons.lightbulb_outline,
            title: 'معنى الكلمة',
            content: _meaning,
            textColor: textColor,
            accent: accent,
            cardColor: cardColor,
          ),
          const SizedBox(height: 12),

          // حكم التجويد
          _buildSection(
            icon: Icons.music_note_outlined,
            title: 'حكم التجويد',
            content: _tajweed,
            textColor: textColor,
            accent: accent,
            cardColor: cardColor,
          ),
          const SizedBox(height: 12),

          // الترجمة الإنجليزية (على مستوى الآية)
          _buildSection(
            icon: Icons.translate,
            title: 'English Translation (Ayah)',
            content: _englishTranslation,
            textColor: textColor,
            accent: accent,
            cardColor: cardColor,
            isLtr: true,
          ),
        ],
      ),
    );
  }

  /// تاب الإعراب
  Widget _buildEerabTab(Color textColor, Color accent, Color cardColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildSection(
        icon: Icons.account_tree_outlined,
        title: 'إعراب الكلمة',
        content: _eerab,
        textColor: textColor,
        accent: accent,
        cardColor: cardColor,
        fontSize: 16,
      ),
    );
  }

  /// تاب التصريف
  Widget _buildTasreefTab(Color textColor, Color accent, Color cardColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildSection(
        icon: Icons.transform,
        title: 'تصريف الكلمة',
        content: _tasreef,
        textColor: textColor,
        accent: accent,
        cardColor: cardColor,
        fontSize: 16,
      ),
    );
  }

  /// تاب البحث — أين وردت الكلمة
  Widget _buildSearchTab(Color textColor, Color accent, Color cardColor) {
    if (_occurrences.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: widget.isDark ? Colors.white12 : Colors.black12),
            const SizedBox(height: 8),
            Text('لم يتم العثور على نتائج', style: TextStyle(fontFamily: 'Cairo', color: widget.isDark ? Colors.white24 : Colors.black26)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            'وردت "${widget.wordText}" ${_occurrences.length} مرة في القرآن',
            textDirection: TextDirection.rtl,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: accent, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: _occurrences.length,
            itemBuilder: (_, i) {
              final occ = _occurrences[i];
              final suraId = occ['sura_id'] ?? 1;
              final ayaIndex = occ['aya_index'] ?? 1;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accent.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withOpacity(0.1),
                      ),
                      alignment: Alignment.center,
                      child: Text('${i + 1}', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: accent, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'سورة $suraId — آية $ayaIndex',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: textColor),
                      ),
                    ),
                    Text(
                      occ['word']?.toString() ?? '',
                      style: TextStyle(fontFamily: 'UthmanTN', fontSize: 16, color: accent),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Helper: Build a content section
  Widget _buildSection({
    required IconData icon,
    required String title,
    required String? content,
    required Color textColor,
    required Color accent,
    required Color cardColor,
    double fontSize = 15,
    bool isLtr = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold, color: accent)),
            ],
          ),
          const SizedBox(height: 10),
          if (content != null && content.isNotEmpty)
            Text(
              content,
              textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
              style: TextStyle(
                fontFamily: isLtr ? null : 'Cairo',
                fontSize: fontSize,
                color: textColor,
                height: 1.8,
              ),
            )
          else
            Text(
              'غير متوفر',
              textDirection: TextDirection.rtl,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: widget.isDark ? Colors.white24 : Colors.black26),
            ),
        ],
      ),
    );
  }
}
