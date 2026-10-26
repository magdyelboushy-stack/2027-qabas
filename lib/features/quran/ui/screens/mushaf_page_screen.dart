import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart'; // للتحكم في شريط الحالة (الساعة والبطارية)

class MushafPageScreen extends StatefulWidget {
  final int startPage;
  final String surahName;

  const MushafPageScreen({
    super.key,
    required this.startPage,
    required this.surahName,
  });

  @override
  State<MushafPageScreen> createState() => _MushafPageScreenState();
}

class _MushafPageScreenState extends State<MushafPageScreen> {
  late PageController _pageController;
  int _currentPage = 1;
  bool _isHeaderVisible = true; // للتحكم في إخفاء/إظهار القوائم

  @override
  void initState() {
    super.initState();
    _currentPage = widget.startPage;
    _pageController = PageController(initialPage: widget.startPage - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // دالة لتبديل ظهور الهيدر عند اللمس
  void _toggleHeader() {
    setState(() {
      _isHeaderVisible = !_isHeaderVisible;
    });
    // إخفاء/إظهار شريط الحالة العلوي (الساعة والبطارية) لتجربة غامرة
    if (_isHeaderVisible) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 1. اكتشاف الوضع الليلي من إعدادات التطبيق
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // لون الخلفية: أسود تماماً في الليلي، وكريمي (ورق) في الفاتح
    final bgColor = isDark ? Colors.black : const Color(0xFFFFFBE0);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ✅ Madani Background Gradient
          if (!isDark)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    colors: [Color(0xFFFFF8E1), Color(0xFFFFFBE0)],
                    center: Alignment.center,
                    radius: 0.8,
                  ),
                ),
              ),
            ),

          // --- 1. طبقة المصحف (الصور) ---
          GestureDetector(
            onTap: _toggleHeader, // عند الضغط في أي مكان يتم تبديل العرض
            child: PageView.builder(
              controller: _pageController,
              // reverse: true, // ⚠️ فعل هذا السطر لو صفحاتك بتمشي بالعكس (من اليسار لليمين)
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index + 1;
                });
              },
              itemCount: 604,
              itemBuilder: (context, index) {
                final pageNumber = index + 1;
                return InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ColorFiltered(
                      colorFilter: isDark
                          ? const ColorFilter.matrix([
                              -1, 0, 0, 0, 255, // Red (Invert)
                              0, -1, 0, 0, 255, // Green (Invert)
                              0, 0, -1, 0, 255, // Blue (Invert)
                              0, 0, 0, 1, 0, // Alpha (Keep)
                            ])
                          : const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.dst,
                            ), // لا تأثير في الوضع العادي
                      child: Container(
                        color: isDark
                            ? Colors.black
                            : const Color(
                                0xFFFFFBE0), // خلفية للصورة نفسها لتجنب الفراغات
                        child: CachedNetworkImage(
                          imageUrl: _getQuranPageUrl(pageNumber),
                          fit: BoxFit.fitWidth,
                          alignment: Alignment.topCenter,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(
                              color: isDark
                                  ? Colors.cyanAccent
                                  : const Color(0xFFD4AF37),
                            ),
                          ),
                          errorWidget: (context, url, error) => Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image,
                                  size: 50,
                                  color: isDark ? Colors.white54 : Colors.grey),
                              const SizedBox(height: 10),
                              Text(
                                "لا يوجد اتصال بالإنترنت",
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // --- 2. الهيدر العائم (يظهر ويختفي) ---
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            top: _isHeaderVisible ? 0 : -120, // يختفي للأعلى
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                  20, 50, 20, 20), // بادينج علوي عشان النوتش
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isDark
                        ? Colors.black.withOpacity(0.9)
                        : Colors.white.withOpacity(0.95),
                    isDark
                        ? Colors.black.withOpacity(0.0)
                        : Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // زر الرجوع
                  CircleAvatar(
                    backgroundColor: isDark
                        ? Colors.white10
                        : Colors.black.withOpacity(0.05),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back,
                          color: isDark ? Colors.white : Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  // معلومات السورة
                  Column(
                    children: [
                      Text(
                        widget.surahName,
                        style: TextStyle(
                          // يفضل استخدام خط أميري أو عثماني
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.cyanAccent : Colors.black87,
                          shadows: isDark
                              ? [
                                  const Shadow(
                                      color: Colors.cyanAccent, blurRadius: 10)
                                ]
                              : [],
                        ),
                      ),
                      Text(
                        "صفحة $_currentPage",
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),

                  // مكان فارغ للتوازن أو زر إضافي (فهرس مثلاً)
                  const SizedBox(width: 40),
                ],
              ),
            ),
          ),

          // --- 3. الفوتر العائم (اختياري: لرقم الصفحة بالأسفل) ---
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            bottom: _isHeaderVisible ? 20 : -60, // يختفي للأسفل
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black54 : Colors.white70,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "جزء ${((_currentPage - 1) ~/ 20) + 1}", // معادلة تقريبية للجزء
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getQuranPageUrl(int pageNumber) {
    String pageStr = pageNumber.toString().padLeft(3, '0');
    return 'https://android.quran.com/data/width_screen/img_$pageStr.png';
  }
}
