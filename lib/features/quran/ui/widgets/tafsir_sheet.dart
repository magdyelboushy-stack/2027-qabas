import 'package:flutter/material.dart';
import '../../data/services/quran_foundation_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ويدجت عرض التفسير داخل AyahOptionsSheet
class TafsirSheet extends StatefulWidget {
  final int surahNumber;
  final int ayahNumber;
  final bool isDark;

  const TafsirSheet({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
    required this.isDark,
  });

  @override
  State<TafsirSheet> createState() => _TafsirSheetState();
}

class _TafsirSheetState extends State<TafsirSheet> {
  bool _isLoading = true;
  String _tafsirText = '';
  String? _error;
  int _selectedTafsirId = 16; // الميسر افتراضياً

  // التفاسير العربية المتاحة
  final List<Map<String, dynamic>> _arabicTafsirs = [
    {'id': 16, 'name': 'تفسير الميسر', 'author': 'المیسر'},
    {'id': 14, 'name': 'تفسير ابن كثير', 'author': 'ابن كثير'},
    {'id': 15, 'name': 'تفسير الطبري', 'author': 'الطبري'},
    {'id': 91, 'name': 'تفسير السعدي', 'author': 'السعدي'},
    {'id': 90, 'name': 'تفسير القرطبي', 'author': 'القرطبي'},
    {'id': 93, 'name': 'الوسيط', 'author': 'طنطاوي'},
    {'id': 94, 'name': 'تفسير البغوي', 'author': 'البغوي'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedTafsir().then((_) => _loadTafsir());
  }

  Future<void> _loadSavedTafsir() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedTafsirId = prefs.getInt('selected_tafsir_id') ?? 16;
  }

  Future<void> _saveTafsir(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_tafsir_id', id);
  }

  Future<void> _loadTafsir() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await QuranFoundationApi.getTafsirForAyah(
        _selectedTafsirId,
        widget.surahNumber,
        widget.ayahNumber,
      );

      // معالجة النص - حذف HTML tags
      String rawText = '';
      if (data.containsKey('text')) {
        rawText = data['text'] as String? ?? '';
      } else if (data.containsKey('tafsir')) {
        final tafsirData = data['tafsir'];
        if (tafsirData is Map) {
          rawText = tafsirData['text'] as String? ?? '';
        }
      } else if (data.containsKey('tafsirs') && data['tafsirs'] is List) {
        final tafsirs = data['tafsirs'] as List;
        if (tafsirs.isNotEmpty) {
          rawText = tafsirs[0]['text'] as String? ?? '';
        }
      }

      // تنظيف HTML
      _tafsirText = rawText
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'")
          .replaceAll(RegExp(r'\n{3,}'), '\n\n')
          .trim();

      if (_tafsirText.isEmpty) {
        _error = 'لم يتم العثور على تفسير لهذه الآية';
      }
    } catch (e) {
      _error = 'فشل جلب التفسير. تحقق من الاتصال بالإنترنت';
      debugPrint('❌ خطأ في جلب التفسير: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : Colors.black87;
    final accentColor =
        widget.isDark ? Colors.cyanAccent : const Color(0xFF8B6F47);
    final cardColor =
        widget.isDark ? Colors.white.withOpacity(0.08) : Colors.white;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // اختيار المفسر
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<int>(
              value: _selectedTafsirId,
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor:
                  widget.isDark ? const Color(0xFF2A2A2A) : Colors.white,
              icon: Icon(Icons.keyboard_arrow_down, color: accentColor),
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontFamily: 'Cairo',
              ),
              items: _arabicTafsirs.map((tafsir) {
                return DropdownMenuItem<int>(
                  value: tafsir['id'] as int,
                  child: Row(
                    children: [
                      Icon(Icons.menu_book, size: 16, color: accentColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tafsir['name'] as String,
                          style: TextStyle(color: textColor),
                        ),
                      ),
                      Text(
                        tafsir['author'] as String,
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedTafsirId = value);
                  _saveTafsir(value);
                  _loadTafsir();
                }
              },
            ),
          ),

          const SizedBox(height: 16),

          // محتوى التفسير
          if (_isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: CircularProgressIndicator(color: accentColor),
              ),
            )
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, color: Colors.grey, size: 48),
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _loadTafsir,
                      icon: Icon(Icons.refresh, color: accentColor),
                      label: Text('إعادة المحاولة',
                          style: TextStyle(color: accentColor)),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _tafsirText,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                  height: 2.0,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
        ],
      ),
    );
  }
}
