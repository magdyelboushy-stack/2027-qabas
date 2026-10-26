import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran/quran.dart' as quran_utils;
import 'package:provider/provider.dart';
import 'package:qcf_quran/qcf_quran.dart';
import '../../data/services/surah_database_service.dart';
import '../../logic/quran_audio_provider.dart';
import '../../../../core/translations/app_locale_keys.dart';
import 'advanced_repeat_sheet.dart';
import 'reciter_selector.dart';
import 'word_details_sheet.dart' as import_word_details;
import 'mini_audio_player.dart';
import 'ayah_details_tutorial_overlay.dart';

/// نافذة تفاصيل الآية الشاملة — Offline بالكامل
class AyahDetailsSheet extends StatefulWidget {
  final int surahNumber;
  final int ayahNumber;
  final String surahName;
  final String ayahText;
  final bool isDark;
  final void Function(int colorIndex)? onBookmark;
  final Set<int> existingBookmarkColors;

  const AyahDetailsSheet({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    required this.ayahText,
    required this.isDark,
    this.onBookmark,
    this.existingBookmarkColors = const {},
  });

  static Future<void> show(
    BuildContext context, {
    required int surahNumber,
    required int ayahNumber,
    required String surahName,
    required String ayahText,
    required bool isDark,
    void Function(int colorIndex)? onBookmark,
    Set<int> existingBookmarkColors = const {},
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => AyahDetailsSheet(
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
  State<AyahDetailsSheet> createState() => _AyahDetailsSheetState();
}

class _AyahDetailsSheetState extends State<AyahDetailsSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _dbService = SurahDatabaseService.instance;
  late Set<int> _bookmarkedColors;

  // Tutorial state
  bool _showTutorial = false;

  // GlobalKeys for tutorial targeting
  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _ayahTextKey = GlobalKey();
  final GlobalKey _tabsKey = GlobalKey();
  final GlobalKey _playControlsKey = GlobalKey();
  final GlobalKey _repeatSettingsKey = GlobalKey();

  // Bookmark colors
  static const List<Color> _bmColors = [
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFFFA726),
  ];

  // Data
  bool _isLoadingTafsir = true;
  bool _isLoadingEerab = true;
  bool _isLoadingNozool = true;
  bool _isLoadingWords = true;

  String? _tafsirText;
  String? _eerabText;
  String? _nozoolText;
  String? _tajweedText;
  String? _englishText;
  List<Map<String, dynamic>> _wordsList = [];

  // Tafsir selection
  String _selectedTafsir = 'السعدي';
  final List<String> _tafsirNames = [
    'السعدي',
    'ابن كثير',
    'الطبري',
    'البغوي',
    'المختصر',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _bookmarkedColors = Set<int>.from(widget.existingBookmarkColors);
    _loadAllData();
    _checkTutorial();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    _loadTafsir();
    _loadEerab();
    _loadExtras();
    _loadWords();
  }

  Future<void> _checkTutorial() async {
    final shouldShow = await AyahDetailsTutorialOverlay.shouldShow();
    if (shouldShow && mounted) {
      // Delay to allow UI rendering
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _showTutorial = true;
          });
        }
      });
    }
  }

  Rect _getRect(GlobalKey key) {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && stackBox != null) {
      final size = renderBox.size;
      final offset = renderBox.localToGlobal(Offset.zero, ancestor: stackBox);
      return Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);
    }
    return Rect.zero;
  }

  Future<void> _loadWords() async {
    setState(() => _isLoadingWords = true);
    try {
      _wordsList = await _dbService.getAyaWordsWithMeanings(
          widget.surahNumber, widget.ayahNumber);
          
      // Fetch API words for audio
      final audioProvider = Provider.of<QuranAudioProvider>(context, listen: false);
      final apiWords = await audioProvider.getAyahWords(widget.surahNumber, widget.ayahNumber);
      
      // Merge audio URLs
      for (int i = 0; i < _wordsList.length && i < apiWords.length; i++) {
        _wordsList[i]['audio_url'] = apiWords[i].audioUrl;
      }
    } catch (e) {
      debugPrint('❌ Error loading words: $e');
    }
    if (mounted) setState(() => _isLoadingWords = false);
  }

  Future<void> _loadTafsir() async {
    setState(() => _isLoadingTafsir = true);
    try {
      _tafsirText = await _dbService.getTafsirByName(
        _selectedTafsir,
        widget.surahNumber,
        widget.ayahNumber,
      );
    } catch (e) {
      debugPrint('❌ Error loading tafsir: $e');
    }
    if (mounted) setState(() => _isLoadingTafsir = false);
  }

  Future<void> _loadEerab() async {
    setState(() => _isLoadingEerab = true);
    try {
      _eerabText =
          await _dbService.getAyaEerab(widget.surahNumber, widget.ayahNumber);
    } catch (e) {
      debugPrint('❌ Error loading eerab: $e');
    }
    if (mounted) setState(() => _isLoadingEerab = false);
  }

  Future<void> _loadExtras() async {
    setState(() => _isLoadingNozool = true);
    try {
      final results = await Future.wait([
        _dbService.getAyaNozool(widget.surahNumber, widget.ayahNumber),
        _dbService.getAyaTajweed(widget.surahNumber, widget.ayahNumber),
        _dbService.getEnglishTranslation(widget.surahNumber, widget.ayahNumber),
      ]);
      _nozoolText = results[0];
      _tajweedText = results[1];
      _englishText = results[2];
    } catch (e) {
      debugPrint('❌ Error loading extras: $e');
    }
    if (mounted) setState(() => _isLoadingNozool = false);
  }

  // ═══════════════════════════════════════════════════════
  //  ألوان التصميم
  // ═══════════════════════════════════════════════════════
  Color get _bgColor => widget.isDark 
      ? const Color(0xFF121A12) 
      : const Color(0xFFF8F4E8);
  
  Color get _surfaceColor => widget.isDark 
      ? const Color(0xFF1A2E1A) 
      : Colors.white;
  
  Color get _accentColor => widget.isDark 
      ? const Color(0xFF8BC34A) 
      : const Color(0xFF2E7D32);

  Color get _goldColor => widget.isDark 
      ? const Color(0xFFD4A437) 
      : const Color(0xFFB8860B);
  
  Color get _textColor => widget.isDark 
      ? const Color(0xFFE8E8E8) 
      : const Color(0xFF1A1A1A);
  
  Color get _subtextColor => widget.isDark 
      ? const Color(0xFF8A9A8A) 
      : const Color(0xFF6B7B6B);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      key: _stackKey,
      children: [
        Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: screenWidth * 0.92,
              height: screenHeight * 0.78,
              decoration: BoxDecoration(
                color: _bgColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                children: [
                  // ── المقبض ──
                  _buildHandle(),

                  // ── الترويسة ──
                  _buildHeader(),

                  // ── التابات ──
                  _buildTabBar(),

                  const SizedBox(height: 4),

                  // ── المحتوى ──
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAyahPlayTab(),
                        _buildWordsTab(),
                        _buildTafsirTab(),
                        _buildEerabTab(),
                        _buildExtrasTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ════════════════════════════════════════════
        //  TUTORIAL OVERLAY
        // ════════════════════════════════════════════
        if (_showTutorial)
          Positioned.fill(
            child: AyahDetailsTutorialOverlay(
              isDark: widget.isDark,
              onComplete: () {
                setState(() => _showTutorial = false);
              },
              ayahTextRect: _getRect(_ayahTextKey),
              tabsRect: _getRect(_tabsKey),
              playControlsRect: _getRect(_playControlsKey),
              repeatSettingsRect: _getRect(_repeatSettingsKey),
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  //  المقبض
  // ═══════════════════════════════════════════════════════
  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Container(
        width: 42,
        height: 5,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _goldColor.withValues(alpha: 0.3),
              _goldColor.withValues(alpha: 0.7),
              _goldColor.withValues(alpha: 0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  الترويسة الرئيسية
  // ═══════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: widget.isDark
              ? [const Color(0xFF1A3A1A), const Color(0xFF0F250F)]
              : [const Color(0xFFF0EDD0), const Color(0xFFE8E0C0)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _goldColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withValues(alpha: widget.isDark ? 0.08 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── معلومات السورة والآية ──
          Expanded(
            child: Row(
              children: [
                // أيقونة السورة
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _accentColor.withValues(alpha: 0.15),
                        _accentColor.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _accentColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _toArabicNumeral(widget.surahNumber),
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _accentColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocaleKeys.surahNameLabel.trParams({'name': widget.surahName}),
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                      ),
                    ),
                    Text(
                      AppLocaleKeys.ayahNumberLabel.trParams({
                        'number': Get.locale?.languageCode == 'ar'
                            ? _toArabicNumeral(widget.ayahNumber)
                            : widget.ayahNumber.toString(),
                      }),
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: _subtextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── أزرار العلامات المرجعية ──
          if (widget.onBookmark != null)
            ...List.generate(4, (i) {
              final isBookmarked = _bookmarkedColors.contains(i);
              return Padding(
                padding: const EdgeInsets.only(left: 3),
                child: GestureDetector(
                  onTap: () {
                    if (!isBookmarked) {
                      widget.onBookmark!(i);
                      setState(() => _bookmarkedColors.add(i));
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isBookmarked
                          ? _bmColors[i].withValues(alpha: 0.2)
                          : _bmColors[i].withValues(alpha: 0.06),
                      border: Border.all(
                        color: isBookmarked
                            ? _bmColors[i]
                            : _bmColors[i].withValues(alpha: 0.3),
                        width: isBookmarked ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_outline_rounded,
                      color: _bmColors[i],
                      size: 13,
                    ),
                  ),
                ),
              );
            }),
          const SizedBox(width: 6),

          // ── زر الإغلاق ──
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
              ),
              child: Icon(
                Icons.close_rounded,
                color: _subtextColor,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  شريط التابات
  // ═══════════════════════════════════════════════════════
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 44,
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _accentColor.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: widget.isDark ? Colors.white : Colors.white,
        unselectedLabelColor: _subtextColor,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _accentColor,
              _accentColor.withValues(alpha: 0.85),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 10,
        ),
        labelPadding: EdgeInsets.zero,
        padding: const EdgeInsets.all(3),
        tabs: [
          Tab(text: AppLocaleKeys.tabAyah.tr),
          Tab(text: AppLocaleKeys.tabWords.tr),
          Tab(text: AppLocaleKeys.tabTafsir.tr),
          Tab(text: AppLocaleKeys.tabEerab.tr),
          Tab(text: AppLocaleKeys.tabMore.tr),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  بناء نص الآية بخط المصحف
  // ═══════════════════════════════════════════════════════
  Widget _buildMushafAyahText() {
    final pageNumber = getPageNumber(widget.surahNumber, widget.ayahNumber);
    final pageFont = "QCF_P${pageNumber.toString().padLeft(3, '0')}";
    final verseText = getVerseQCF(
      widget.surahNumber,
      widget.ayahNumber,
      verseEndSymbol: false,
    );

    final displayText = verseText.isNotEmpty
        ? "${verseText.substring(0, 1)}\u200A${verseText.substring(1)}"
        : widget.ayahText;

    return RichText(
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      text: TextSpan(
        children: [
          TextSpan(
            text: displayText,
            style: TextStyle(
              fontFamily: pageFont,
              package: 'qcf_quran',
              fontSize: 32,
              color: _textColor,
              height: 1.9,
            ),
          ),
          TextSpan(
            text: getVerseNumberQCF(widget.surahNumber, widget.ayahNumber),
            style: TextStyle(
              fontFamily: pageFont,
              package: 'qcf_quran',
              fontSize: 32,
              color: _goldColor,
              height: 1.9,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  بطاقة محتوى أنيقة
  // ═══════════════════════════════════════════════════════
  Widget _elegantCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    bool highlighted = false,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted 
              ? _accentColor.withValues(alpha: 0.3)
              : _goldColor.withValues(alpha: 0.08),
          width: highlighted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.15 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // ═══════════════════════════════════════════════════════
  //  تاب الآية — تشغيل + تكرار
  // ═══════════════════════════════════════════════════════
  Widget _buildAyahPlayTab() {
    return Consumer<QuranAudioProvider>(
      builder: (context, audioProvider, _) {
        final isCurrentAyah =
            audioProvider.currentSurah == widget.surahNumber &&
                audioProvider.currentAyah == widget.ayahNumber;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── نص الآية (قابل للتمرير) ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Container(
                  key: _ayahTextKey,
                  child: _elegantCard(
                    highlighted: isCurrentAyah && audioProvider.isPlaying,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: _buildMushafAyahText(),
                  ),
                ),
              ),
            ),
            
            // ── أزرار التحكم الثابتة بالأسفل ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: _bgColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(widget.isDark ? 0.3 : 0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 12,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── اختيار القارئ ──
                  ReciterSelector(
                    isDark: widget.isDark,
                    selectedReciterId: audioProvider.selectedReciterId,
                    reciters: audioProvider.reciters,
                    onReciterChanged: (id) => audioProvider.setReciter(id),
                  ),
                  const SizedBox(height: 14),

                  // ── إعدادات التكرار المتقدم ──
                  GestureDetector(
                    key: _repeatSettingsKey,
                    onTap: () {
                      AdvancedRepeatSheet.show(
                        context,
                        surahNumber: widget.surahNumber,
                        initialStartAyah: widget.ayahNumber,
                        isDark: widget.isDark,
                      );
                    },
                    child: _elegantCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _goldColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.repeat_rounded, size: 18, color: _goldColor),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocaleKeys.repeatSettings.tr,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _textColor,
                                ),
                              ),
                              Text(
                                audioProvider.isAdvancedRepeat 
                                    ? AppLocaleKeys.advancedRepeatActive.tr 
                                    : AppLocaleKeys.advancedRepeatDesc.tr,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 11,
                                  color: audioProvider.isAdvancedRepeat ? _accentColor : _subtextColor,
                                  fontWeight: audioProvider.isAdvancedRepeat ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Icon(
                            Icons.chevron_left_rounded,
                            color: _subtextColor,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── حالة التكرار ──
                  if (isCurrentAyah && audioProvider.isRepeating)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _accentColor.withValues(alpha: 0.08),
                            _goldColor.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _accentColor.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.repeat_rounded, size: 16, color: _accentColor),
                          const SizedBox(width: 8),
                          Text(
                            'التكرار ${audioProvider.currentRepeat} من ${audioProvider.repeatCount}',
                            style: TextStyle(
                              color: _accentColor,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── أزرار التحكم ──
                  Container(
                    key: _playControlsKey,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // زر إيقاف
                        if (isCurrentAyah &&
                            (audioProvider.isPlaying || audioProvider.isRepeating)) ...[
                          _playControlButton(
                            icon: Icons.stop_rounded,
                            label: 'إيقاف',
                            color: const Color(0xFFE53935),
                            onTap: () => audioProvider.stop(),
                          ),
                          const SizedBox(width: 16),
                        ],
                        // زر التشغيل الرئيسي
                        _mainPlayButton(
                          isPlaying: isCurrentAyah && audioProvider.isPlaying,
                          isLoading: audioProvider.isLoading,
                          onTap: () {
                            if (isCurrentAyah && audioProvider.isPlaying) {
                              audioProvider.pause();
                            } else if (isCurrentAyah && !audioProvider.isPlaying) {
                              audioProvider.resume();
                            } else {
                              audioProvider.playAyah(
                                  widget.surahNumber, widget.ayahNumber);
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  if (audioProvider.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          audioProvider.errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontFamily: 'Cairo',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _counterButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled
              ? _accentColor.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled
                ? _accentColor.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.1),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? _accentColor : Colors.grey.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _mainPlayButton({
    required bool isPlaying,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_accentColor, _accentColor.withValues(alpha: 0.8)],
          ),
          boxShadow: [
            BoxShadow(
              color: _accentColor.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 34,
              ),
      ),
    );
  }

  Widget _playControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: _subtextColor,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  تاب الكلمات
  // ═══════════════════════════════════════════════════════
  Widget _buildWordsTab() {
    if (_isLoadingWords) {
      return Center(child: CircularProgressIndicator(color: _accentColor));
    }

    if (_wordsList.isEmpty) {
      return _buildEmptyState(
        icon: Icons.text_fields_rounded,
        message: 'لم يتم العثور على معاني لكلمات هذه الآية',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _wordsList.length,
      itemBuilder: (context, index) {
        final word = _wordsList[index];
        final wordText = word['title'] as String;
        final meaning = word['meaning'] as String;
        final wordIndex = word['word_id'] as int;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _elegantCard(
            padding: EdgeInsets.zero,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _importWordDetailsSheetAndShow(context, wordText, wordIndex),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      // ── أيقونة الصوت ──
                      if (word['audio_url'] != null)
                        Consumer<QuranAudioProvider>(
                          builder: (context, audioProvider, _) {
                            return GestureDetector(
                              onTap: () => audioProvider.playWord(word['audio_url']),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: _accentColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.volume_up_rounded,
                                  color: _accentColor,
                                  size: 18,
                                ),
                              ),
                            );
                          },
                        )
                      else
                        const SizedBox(width: 36),
                      
                      const SizedBox(width: 12),
                      
                      // ── المعنى ──
                      Expanded(
                        child: Text(
                          meaning,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            color: _subtextColor,
                            height: 1.5,
                          ),
                          textDirection: TextDirection.rtl,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // ── الكلمة ──
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _accentColor.withValues(alpha: 0.08),
                              _goldColor.withValues(alpha: 0.04),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          wordText,
                          style: TextStyle(
                            fontFamily: 'UthmanTN',
                            fontSize: 22,
                            color: _accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _importWordDetailsSheetAndShow(
      BuildContext context, String wordText, int wordIndex) {
    import_word_details.WordDetailsSheet.show(
      context,
      wordText: wordText,
      surahNumber: widget.surahNumber,
      ayahNumber: widget.ayahNumber,
      wordIndex: wordIndex,
      isDark: widget.isDark,
    );
  }

  // ═══════════════════════════════════════════════════════
  //  تاب التفسير
  // ═══════════════════════════════════════════════════════
  Widget _buildTafsirTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── اختيار المفسر ──
          _elegantCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: DropdownButton<String>(
              value: _selectedTafsir,
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: _bgColor,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: _accentColor),
              style: TextStyle(
                color: _textColor,
                fontSize: 14,
                fontFamily: 'Cairo',
              ),
              items: _tafsirNames.map((name) {
                return DropdownMenuItem<String>(
                  value: name,
                  child: Row(
                    children: [
                      Icon(Icons.menu_book_rounded, size: 16, color: _goldColor),
                      const SizedBox(width: 8),
                      Text(
                        'تفسير $name',
                        style: TextStyle(color: _textColor, fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedTafsir = value);
                  _loadTafsir();
                }
              },
            ),
          ),
          const SizedBox(height: 14),

          // ── محتوى التفسير ──
          if (_isLoadingTafsir)
            _buildLoadingState()
          else if (_tafsirText != null && _tafsirText!.isNotEmpty)
            _elegantCard(
              child: Text(
                _tafsirText!,
                style: TextStyle(
                  fontSize: 16,
                  color: _textColor,
                  height: 2.0,
                  fontFamily: 'Cairo',
                ),
                textDirection: TextDirection.rtl,
              ),
            )
          else
            _buildEmptyState(
              icon: Icons.menu_book_outlined,
              message: 'لم يتم العثور على تفسير لهذه الآية',
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  تاب الإعراب
  // ═══════════════════════════════════════════════════════
  Widget _buildEerabTab() {
    if (_isLoadingEerab) {
      return _buildLoadingState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_eerabText != null && _eerabText!.isNotEmpty)
            _elegantCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionHeader(
                    icon: Icons.account_tree_rounded,
                    title: 'إعراب الآية',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _eerabText!,
                    style: TextStyle(
                      fontSize: 16,
                      color: _textColor,
                      height: 2.0,
                      fontFamily: 'Cairo',
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            )
          else
            _buildEmptyState(
              icon: Icons.account_tree_outlined,
              message: 'لم يتم العثور على إعراب لهذه الآية',
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  تاب المزيد
  // ═══════════════════════════════════════════════════════
  Widget _buildExtrasTab() {
    if (_isLoadingNozool) {
      return _buildLoadingState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildContentSection(
            icon: Icons.history_edu_rounded,
            title: 'أسباب النزول',
            content: _nozoolText,
          ),
          const SizedBox(height: 12),

          _buildContentSection(
            icon: Icons.music_note_rounded,
            title: 'أحكام التجويد',
            content: _tajweedText,
          ),
          const SizedBox(height: 12),

          _buildContentSection(
            icon: Icons.translate_rounded,
            title: 'English Translation',
            content: _englishText,
            isLtr: true,
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection({
    required IconData icon,
    required String title,
    required String? content,
    bool isLtr = false,
  }) {
    return _elegantCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader(icon: icon, title: title),
          const SizedBox(height: 10),
          if (content != null && content.isNotEmpty)
            Text(
              content,
              textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
              style: TextStyle(
                fontFamily: isLtr ? null : 'Cairo',
                fontSize: 15,
                color: _textColor,
                height: 1.8,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'غير متوفر لهذه الآية',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: _subtextColor.withValues(alpha: 0.6),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  عناصر مشتركة
  // ═══════════════════════════════════════════════════════
  Widget _sectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _goldColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: _goldColor),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _accentColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(50),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                color: _accentColor,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'جارٍ التحميل...',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: _subtextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(50),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _subtextColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _subtextColor.withValues(alpha: 0.4), size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: _subtextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static String _toArabicNumeral(int n) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((d) => digits[int.parse(d)]).join();
  }
}
