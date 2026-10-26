import 'package:get/get.dart';
// Enhanced Surah Reading Screen - Madani Premium Style
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../data/models/shaykh.dart';
import '../../data/reciter_service.dart';
import '../../data/recitation_service.dart';
import 'media_player_screen.dart';
import '../../../../core/services/last_read_service.dart';
import 'package:mihrab/features/quran/logic/global_audio_manager.dart';

class SurahReadingScreen extends StatefulWidget {
  final Map<String, dynamic> surahData;
  final int? startAtAyah;

  const SurahReadingScreen({
    super.key,
    required this.surahData,
    this.startAtAyah,
  });

  @override
  State<SurahReadingScreen> createState() => _SurahReadingScreenState();
}

class _SurahReadingScreenState extends State<SurahReadingScreen> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  int? _highlightedAyah;
  bool _isFavorite = false;
  String? _savedSurah;
  String? _savedAyah;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();

    if (widget.startAtAyah != null) {
      _highlightedAyah = widget.startAtAyah;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _scrollToAyah(widget.startAtAyah!);
      });
    }

    _checkFavoriteStatus();
    _loadLastRead();

    String cleanSurahName = _removeArabicDiacritics(widget.surahData['name'] ?? 'سورة');
    LastReadService.saveLastRead(cleanSurahName, '1');
  }
    
  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  String _cleanStringForMatching(String s) {
    s = s.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
    s = s.replaceAll(RegExp(r'[أإآٱ]'), 'ا');
    s = s.replaceAll('ى', 'ي');
    s = s.replaceAll('ة', 'ه');
    s = s.replaceAll('ؤ', 'و');
    s = s.replaceAll('ئ', 'ي');
    s = s.replaceAll('سورة', '');
    s = s.replaceAll(RegExp(r'[0-9\-]'), '');
    s = s.replaceAll(RegExp(r'[^\w\u0600-\u06FF]'), '');
    return s.toLowerCase().trim();
  }

  Future<void> _checkAndPlaySurah(Shaykh shaykh) async {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
      );
    }

    try {
      final recitations = await RecitationService.getRecitationsForShaykh(shaykh.id);

      String currentNameAr = _cleanStringForMatching(widget.surahData['name'].toString());
      String currentNameEn = _cleanStringForMatching(widget.surahData['englishName']?.toString() ?? '');

      final target = recitations.firstWhere(
            (r) {
          String rTitle = _cleanStringForMatching(r.title);
          return rTitle == currentNameAr ||
              rTitle == currentNameEn ||
              rTitle.contains(currentNameAr) ||
              (currentNameEn.isNotEmpty && rTitle.contains(currentNameEn));
        },
        orElse: () => throw Exception("Surah not found"),
      );

      if (mounted) {
        Navigator.pop(context);
        GlobalAudioManager().isPlayerExpanded.value = true;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => MediaPlayerScreen(
              shaykh: shaykh,
              currentRecitation: target,
              allRecitations: recitations,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Get.locale?.languageCode == 'ar' 
                ? 'عذراً، تلاوة سورة "${widget.surahData['name']}" غير متوفرة لهذا الشيخ.' 
                : 'Sorry, the recitation of Surah "${widget.surahData['englishName'] ?? widget.surahData['name']}" is not available for this reciter.', 
              style: const TextStyle()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRecitersBottomSheet(BuildContext context) async {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator()));
    final List<Shaykh> shaykhs = await ReciterService.getAllReciters();
    if (mounted) Navigator.pop(context);
    if (mounted) {
      showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(color: isDark ? const Color(0xFF1E4D3E) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(25))),
              child: Column(
                children: [
                  const SizedBox(height: 15),
                  Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10))),
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Text(
                      Get.locale?.languageCode == 'ar' ? "اختر الشيخ" : "Select Reciter", 
                      style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold, )),
                  ),
                  Divider(color: Colors.grey.withOpacity(0.2)),
                  Expanded(
                    child: ListView.builder(
                      itemCount: shaykhs.length,
                      itemBuilder: (c, i) => ListTile(
                        leading: CircleAvatar(backgroundImage: NetworkImage(shaykhs[i].imageUrl)),
                        title: Text(shaykhs[i].name, style: TextStyle(color: isDark ? Colors.white : Colors.black, )),
                        onTap: () { Navigator.pop(context); _checkAndPlaySurah(shaykhs[i]); },
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
      );
    }
  }

  void _scrollToAyah(int ayahNumber) {
    if (ayahNumber > 0) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_itemScrollController.isAttached) {
          _itemScrollController.scrollTo(index: ayahNumber, duration: const Duration(seconds: 1), curve: Curves.easeInOutCubic, alignment: 0.15);
        }
      });
    }
  }

  Future<void> _loadLastRead() async {
    final data = await LastReadService.getLastRead();
    if (data != null && mounted) {
      setState(() { _savedSurah = data['surah']; _savedAyah = data['ayah']; });
    }
  }

  Future<void> _saveBookmark(String surahName, int ayahNumber) async {
    String cleanName = _removeArabicDiacritics(surahName);
    await LastReadService.saveLastRead(cleanName, ayahNumber.toString());
    await _loadLastRead();
    if (mounted) _showStyledSnackBar(context, Get.locale?.languageCode == 'ar' ? 'تم حفظ العلامة عند الآية $ayahNumber' : 'Bookmark saved at Ayah $ayahNumber', icon: Icons.bookmark_added, color: Colors.green);
  }

  void _copyAyah(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showStyledSnackBar(context, Get.locale?.languageCode == 'ar' ? 'تم نسخ الآية' : 'Ayah copied', icon: Icons.copy);
  }

  void _showStyledSnackBar(BuildContext context, String message, {IconData? icon, Color color = Colors.cyanAccent}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [if (icon != null) ...[Icon(icon, color: Colors.black87, size: 20), const SizedBox(width: 10)], Expanded(child: Text(message, style: const TextStyle( color: Colors.black87, fontWeight: FontWeight.bold)))]),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _removeArabicDiacritics(String text) {
    return text.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
  }

  void _checkFavoriteStatus() async {
    if(mounted) setState(() => _isFavorite = false);
  }

  void _showAyahOptions(BuildContext context, Map<String, dynamic> ayah) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(color: isDark ? const Color(0xFF121931) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(25)), border: Border(top: BorderSide(color: isDark ? Colors.cyanAccent : Colors.blue, width: 1))),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10))),
              Padding(padding: const EdgeInsets.all(20), child: Text(Get.locale?.languageCode == 'ar' ? "خيارات الآية ${ayah['numberInSurah']}" : "Options for Ayah ${ayah['numberInSurah']}", style: TextStyle(color: isDark ? Colors.cyanAccent : Colors.blue, fontSize: 18, fontWeight: FontWeight.bold, ))),
              Divider(color: Colors.grey.withOpacity(0.2)),
              _buildOptionTile(Icons.copy, Get.locale?.languageCode == 'ar' ? "نسخ الآية" : "Copy Ayah", () { Navigator.pop(context); _copyAyah(ayah['text']); }, isDark),
              _buildOptionTile(Icons.menu_book_rounded, Get.locale?.languageCode == 'ar' ? "التفسير الميسر" : "Easy Tafsir", () { Navigator.pop(context); _showStyledSnackBar(context, Get.locale?.languageCode == 'ar' ? 'قريباً: التفسير' : 'Coming soon: Tafsir', icon: Icons.info_outline); }, isDark),
              _buildOptionTile(Icons.bookmark_border_rounded, Get.locale?.languageCode == 'ar' ? "حفظ كعلامة" : "Save Bookmark", () { Navigator.pop(context); _saveBookmark(widget.surahData['name'], ayah['numberInSurah']); }, isDark),
              _buildOptionTile(Icons.play_circle_outline, Get.locale?.languageCode == 'ar' ? "تشغيل هذه الآية" : "Play this Ayah", () { Navigator.pop(context); _showRecitersBottomSheet(context); }, isDark),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String title, VoidCallback onTap, bool isDark) {
    final color = isDark ? Colors.white : Colors.black87;
    return ListTile(leading: Icon(icon, color: color), title: Text(title, style: TextStyle(color: color, )), onTap: onTap);
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> ayahs = widget.surahData['ayahs'] ?? [];
    final themeProvider = Provider.of<ThemeProvider>(context);
    final String displaySurahName = _removeArabicDiacritics(widget.surahData['name'] ?? 'السورة');
    final String cleanSurahForCheck = _removeArabicDiacritics(displaySurahName);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF071814) : const Color(0xFFFFFBE0);
    final textColor = isDark ? Colors.white : Colors.black;
    final iconColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      body: GestureDetector(
        onTap: _toggleFullScreen,
        child: Stack(
          children: [
            // ✅ Premium Background
            if (isDark)
              Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1E4D3E), Color(0xFF0E241E)])))
            else
              Container(decoration: const BoxDecoration(gradient: RadialGradient(colors: [Color(0xFFFFF4E0), Color(0xFFFFFBE0)], center: Alignment.center, radius: 1.2))),

            Column(
              children: [
                // ✅ Header with smooth hide animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _isFullScreen ? 0 : 90,
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(children: [
                          IconButton(icon: Icon(Icons.arrow_back_ios, color: iconColor), onPressed: () => Navigator.pop(context)),
                          const Spacer(),
                          Text(displaySurahName, style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold, )),
                          const Spacer(),
                          const SizedBox(width: 40)
                        ]),
                      ),
                    ),
                  ),
                ),
                
                // ✅ Ayahs List
                Expanded(
                  child: ScrollablePositionedList.builder(
                    itemScrollController: _itemScrollController,
                    itemPositionsListener: _itemPositionsListener,
                    padding: EdgeInsets.fromLTRB(20, 10, 20, _isFullScreen ? 20 : MediaQuery.of(context).padding.bottom + 20),
                    itemCount: ayahs.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Column(children: [_buildSurahHeaderCard(widget.surahData), const SizedBox(height: 30)]);
                      }
                      final ayah = ayahs[index - 1];
                      int currentAyahNum = ayah['numberInSurah'];
                      bool isHighlighted = currentAyahNum == _highlightedAyah;
                      bool isSaved = (_savedSurah == cleanSurahForCheck && _savedAyah == currentAyahNum.toString());
                      return _buildAyahItem(context, ayah, themeProvider, isHighlighted, isSaved, displaySurahName, isDark);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurahHeaderCard(Map<String, dynamic> data) {
    String displayName = _removeArabicDiacritics(data['name'] ?? 'اسم السورة');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
         borderRadius: BorderRadius.circular(20), 
         gradient: const LinearGradient(
            begin: Alignment.topLeft, 
            end: Alignment.bottomRight, 
            colors: [Color(0xFF8CE2FE), Color(0xFF5E9DFA)]
         ), 
         boxShadow: [BoxShadow(color: const Color(0xFF5E9DFA).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))]
      ),
      child: Column(
        children: [
          Row(
             mainAxisAlignment: MainAxisAlignment.spaceAround, 
             children: [
                Image.asset('assets/quran_book.png', width: 100, height: 100, fit: BoxFit.contain, errorBuilder: (c,o,s) => const Icon(Icons.menu_book, size: 80, color: Colors.white)), 
                Column(
                   children: [
                      Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, )), 
                      Text(data['englishName'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 16, )), 
                      const SizedBox(height: 10), 
                      Text(
                        '${data['revelationType']} • ${data['numberOfAyahs']} ${Get.locale?.languageCode == 'ar' ? "آيات" : "Ayahs"}', 
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, ))
                   ]
                )
             ]
          ),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => _showRecitersBottomSheet(context), icon: const Icon(Icons.play_arrow_rounded, size: 28, color: Color(0xFF5E9DFA)), label: Text(Get.locale?.languageCode == 'ar' ? "الاستماع للسورة" : "Listen to Surah", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, )), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF5E9DFA), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 0))),
        ],
      ),
    );
  }

  Widget _buildAyahItem(BuildContext context, Map<String, dynamic> ayah, ThemeProvider themeProvider, bool isHighlighted, bool isSaved, String surahName, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    final numberBg = isDark ? const Color(0xFF121931) : Colors.white;
    final numberText = isDark ? Colors.white : Colors.black;
    final highlightColor = isDark ? const Color(0xFF2A8B68) : const Color(0xFFD4A574);
    final savedIconColor = isSaved ? Colors.amber : (isDark ? Colors.cyanAccent : const Color(0xFFD4A574));
    final iconColor = isDark ? Colors.cyanAccent : const Color(0xFFD4A574);
    final menuIconColor = isDark ? Colors.white : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
         color: isHighlighted ? highlightColor.withOpacity(0.15) : Colors.transparent, 
         borderRadius: BorderRadius.circular(10), 
         border: isHighlighted ? Border.all(color: highlightColor, width: 1) : null
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
               color: numberBg, 
               borderRadius: BorderRadius.circular(10), 
               boxShadow: isDark ? [] : [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 4)]
            ),
            child: Row(
              children: [
                Container(
                   width: 30, 
                   height: 30, 
                   decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF00E5FF) : const Color(0xFFD4A574).withOpacity(0.3), 
                      shape: BoxShape.circle, 
                      boxShadow: [BoxShadow(color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFFD4A574)).withOpacity(0.4), blurRadius: 5)]
                   ), 
                   child: Center(child: Text('${ayah['numberInSurah']}', style: TextStyle(color: numberText, fontWeight: FontWeight.bold, fontSize: 12)))
                ),
                const Spacer(),
                IconButton(icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: savedIconColor, size: 22), onPressed: () => _saveBookmark(surahName, ayah['numberInSurah'])),
                IconButton(icon: Icon(Icons.copy, color: iconColor, size: 20), onPressed: () => _copyAyah(ayah['text'])),
                IconButton(icon: Icon(Icons.more_vert, color: menuIconColor, size: 20), onPressed: () => _showAyahOptions(context, ayah)),
              ],
            ),
          ),
          const SizedBox(height: 15),
          
          // ✅ Ayah Text - Centered with premium styling
          Padding(
             padding: const EdgeInsets.symmetric(horizontal: 8.0), 
             child: Text(
                ayah['text'] ?? '', 
                textAlign: TextAlign.center, 
                style: TextStyle(
                   color: textColor, 
                   fontFamily: 'QuranFont', 
                   fontSize: 32 * themeProvider.fontScale, 
                   height: 2.2, 
                   fontWeight: FontWeight.w500,
                   shadows: isDark ? [] : [
                      Shadow(
                         color: Colors.black.withOpacity(0.05),
                         blurRadius: 2,
                         offset: const Offset(0, 1),
                      )
                   ]
                )
             )
          ),
          
          const SizedBox(height: 20),
          Divider(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black12, thickness: 1),
        ],
      ),
    );
  }
}