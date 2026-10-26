import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:qcf_quran/qcf_quran.dart';
// ignore: implementation_imports
// ignore: implementation_imports
import '../../../../core/utils/desktop_utils.dart';
import 'package:quran/quran.dart' as quran_utils;
import 'package:provider/provider.dart';
import '../../logic/quran_audio_provider.dart';

/// ──────────────────────────────────────────────────────────
///  Custom Mushaf PageView — vendored from qcf_quran package
///  Fixes:
///    ✅ FittedBox instead of scrollable ListView (no overflow)
///    ✅ AutomaticKeepAliveClientMixin (no lag on swipe)
///    ✅ BouncingScrollPhysics for smooth feel
/// ──────────────────────────────────────────────────────────

class CustomPageviewQuran extends StatefulWidget {
  final int initialPageNumber;
  final PageController? controller;
  final double sp;
  final double h;
  final ValueChanged<int>? onPageChanged;
  final double? fontSize;
  final QcfThemeData? theme;
  final Color? Function(int surahNumber, int verseNumber)? verseBackgroundColor;
  final void Function(int surahNumber, int verseNumber)? onLongPress;
  final void Function(int surahNumber, int verseNumber)? onLongPressUp;
  final void Function(int surahNumber, int verseNumber)? onLongPressCancel;
  final void Function(
          int surahNumber, int verseNumber, LongPressStartDetails details)?
      onLongPressDown;
  final void Function(int surahNumber, int verseNumber)? onTap;
  final ScrollPhysics? physics;

  const CustomPageviewQuran({
    super.key,
    this.initialPageNumber = 1,
    this.controller,
    this.onPageChanged,
    this.fontSize,
    this.sp = 1,
    this.h = 1,
    this.theme,
    this.verseBackgroundColor,
    this.onLongPress,
    this.onLongPressUp,
    this.onLongPressCancel,
    this.onLongPressDown,
    this.onTap,
    this.physics,
  }) : assert(initialPageNumber >= 1 && initialPageNumber <= totalPagesCount);

  @override
  State<CustomPageviewQuran> createState() => _CustomPageviewQuranState();
}

class _CustomPageviewQuranState extends State<CustomPageviewQuran> {
  PageController? _internalController;
  PageController get _controller => widget.controller ?? _internalController!;
  bool get _ownsController => widget.controller == null;

  @override
  void initState() {
    super.initState();
    if (_ownsController) {
      _internalController = PageController(
        initialPage: widget.initialPageNumber - 1,
      );
    }
  }

  @override
  void dispose() {
    if (_ownsController) _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = widget.theme ?? const QcfThemeData();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: effectiveTheme.pageBackgroundColor,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
            },
          ),
          child: PageView.builder(
            physics: widget.physics ?? const ClampingScrollPhysics(),
            controller: _controller,
            reverse: false,
            allowImplicitScrolling: true, // Pre-render adjacent pages for smoother swiping
            itemCount: totalPagesCount,
            onPageChanged: (index) => widget.onPageChanged?.call(index + 1),
            itemBuilder: (context, index) {
              final pageNumber = index + 1;
              return _KeepAlivePage(
                child: RepaintBoundary(
                  child: _CustomQcfPage(
                    pageNumber: pageNumber,
                    fontSize: widget.fontSize,
                    verseBackgroundColor: widget.verseBackgroundColor,
                    onLongPress: widget.onLongPress,
                    onLongPressUp: widget.onLongPressUp,
                    onLongPressCancel: widget.onLongPressCancel,
                    onLongPressDown: widget.onLongPressDown,
                    onTap: widget.onTap,
                    sp: widget.sp,
                    h: widget.h,
                    theme: effectiveTheme,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// ── Keep-alive wrapper to prevent rebuild lag ──
class _KeepAlivePage extends StatefulWidget {
  final Widget child;
  const _KeepAlivePage({required this.child});
  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// ── Custom QcfPage — clean layout without ornamental frame ──
class _CustomQcfPage extends StatelessWidget {
  final int pageNumber;
  final QcfThemeData theme;
  final double? fontSize;
  final double sp;
  final double h;
  final void Function(int, int)? onLongPress;
  final void Function(int, int)? onLongPressUp;
  final void Function(int, int)? onLongPressCancel;
  final void Function(int, int, LongPressStartDetails)? onLongPressDown;
  final void Function(int, int)? onTap;
  final Color? Function(int, int)? verseBackgroundColor;

  const _CustomQcfPage({
    required this.pageNumber,
    this.theme = const QcfThemeData(),
    this.fontSize,
    this.sp = 1.0,
    this.h = 1.0,
    this.onLongPress,
    this.onLongPressUp,
    this.onLongPressCancel,
    this.onLongPressDown,
    this.onTap,
    this.verseBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (pageNumber < 1 || pageNumber > 604) {
      return Center(child: Text('Invalid page number: $pageNumber'));
    }

    // نستمع هنا للتغييرات في الصوتيات حتى نعيد بناء الصفحة وتحديث التظليل
    try {
      Provider.of<QuranAudioProvider>(context);
    } catch (_) {}

    final ranges = getPageData(pageNumber);
    final pageFont = "QCF_P${pageNumber.toString().padLeft(3, '0')}";
    final baseFontSize = getFontSize(pageNumber, context) * sp;
    final screenSize = MediaQuery.of(context).size;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    final isDesktop = DesktopUtils.isDesktop;

    // ── Build verse spans ──
    final verseSpans = <InlineSpan>[];

    if (pageNumber == 1 || pageNumber == 2) {
      verseSpans
          .add(WidgetSpan(child: SizedBox(height: screenSize.height * .175)));
    }

    for (final r in ranges) {
      final surah = int.parse(r['surah'].toString());
      final start = int.parse(r['start'].toString());
      final end = int.parse(r['end'].toString());

      for (int v = start; v <= end; v++) {
        if (v == start && v == 1) {
          if (theme.showHeader) {
            // ── Ornamental Surah Header ──
            verseSpans.add(WidgetSpan(
              child: _OrnamentalSurahHeader(
                surahNumber: surah,
                theme: theme,
                isDesktop: isDesktop,
              ),
            ));
          }
          if (theme.showBasmala && pageNumber != 1 && pageNumber != 187) {
            if (theme.basmalaBuilder != null) {
              verseSpans.add(WidgetSpan(
                  child: theme.basmalaBuilder!(surah),
                  alignment: PlaceholderAlignment.middle));
              verseSpans.add(const TextSpan(text: "\n"));
            } else {
              if (surah != 97 && surah != 95) {
                verseSpans.add(TextSpan(
                  text: " ﱁ  ﱂﱃﱄ\n",
                  style: TextStyle(
                    fontFamily: "QCF_P001",
                    package: 'qcf_quran',
                    fontSize: getScreenType(context) == ScreenType.large
                        ? theme.basmalaFontSizeLarge * sp
                        : theme.basmalaFontSizeSmall * sp,
                    color: theme.basmalaColor,
                  ),
                ));
              } else {
                verseSpans.add(TextSpan(
                  text: "齃𧻓𥳐龎\n",
                  style: TextStyle(
                    fontFamily: "QCF_BSML",
                    package: 'qcf_quran',
                    fontSize: getScreenType(context) == ScreenType.large
                        ? theme.basmalaSpecialFontSizeLarge * sp
                        : theme.basmalaSpecialFontSizeSmall * sp,
                    color: theme.basmalaColor,
                  ),
                ));
              }
            }
          }
        }

        // Gestures
        GestureRecognizer? textRecognizer;
        if (isDesktop && onTap != null) {
          textRecognizer = TapGestureRecognizer()
            ..onTap = () => onTap?.call(surah, v);
        } else if (onTap != null) {
          // Allow tapping whole verse on mobile to open options
          textRecognizer = TapGestureRecognizer()
            ..onTap = () => onTap?.call(surah, v);
        } else if (onLongPress != null ||
            onLongPressDown != null ||
            onLongPressUp != null) {
          final lp = LongPressGestureRecognizer();
          lp.onLongPress = () => onLongPress?.call(surah, v);
          lp.onLongPressStart = (d) => onLongPressDown?.call(surah, v, d);
          lp.onLongPressUp = () => onLongPressUp?.call(surah, v);
          lp.onLongPressEnd = (d) => onLongPressCancel?.call(surah, v);
          textRecognizer = lp;
        }

        final verseBgColor = theme.verseBackgroundColor?.call(surah, v) ??
            verseBackgroundColor?.call(surah, v);

        InlineSpan verseNumberSpan;
        if (theme.verseNumberBuilder != null) {
          verseNumberSpan =
              theme.verseNumberBuilder!(surah, v, getVerseNumberQCF(surah, v));
        } else {
          verseNumberSpan = TextSpan(
            text: getVerseNumberQCF(surah, v),
            style: TextStyle(
              fontFamily: pageFont,
              package: 'qcf_quran',
              color: theme.verseNumberColor,
              height: theme.verseNumberHeight * h,
              backgroundColor: theme.verseNumberBackgroundColor ?? verseBgColor,
            ),
          );
        }

        // Always use QCF fonts for proper 15-line Mushaf layout (no splitting characters to maintain kerning)
        verseSpans.add(TextSpan(
          text: (v == ranges[0]['start']
              ? "${getVerseQCF(surah, v, verseEndSymbol: false).substring(0, 1)}\u200A${getVerseQCF(surah, v, verseEndSymbol: false).substring(1)}"
              : getVerseQCF(surah, v, verseEndSymbol: false)),
          recognizer: textRecognizer,
          style: verseBgColor != null
              ? TextStyle(backgroundColor: verseBgColor)
              : null,
          children: [verseNumberSpan],
        ));
      }
    }

    // ═══ Build the page — optimized layout without FittedBox ═══
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.maxWidth > 0 ? constraints.maxWidth : screenSize.width;
        final availableHeight =
            constraints.maxHeight > 0 ? constraints.maxHeight : screenSize.height;
        final scaleFactor = (availableWidth / 412.0).clamp(0.65, 1.4);

        final effectiveFontSize = isPortrait
            ? baseFontSize * scaleFactor
            : (pageNumber == 1 || pageNumber == 2)
                ? 20 * sp * scaleFactor
                : (baseFontSize - (17 * sp)) * scaleFactor;

        // Since we moved the page number to the top, we only need to reserve space for the top header (~45px).
        // This gives the text plenty of vertical space, preventing it from squishing.
        final textAreaHeight = availableHeight - 45;
        final lineCount = (pageNumber == 1 || pageNumber == 2) ? 7.5 : 15.0;
        
        // Calculate the optimal line height without shrinking the font width
        final calculatedLineHeight = textAreaHeight / (lineCount * effectiveFontSize);

        final effectiveHeight = isPortrait
            ? (pageNumber == 1 || pageNumber == 2)
                ? calculatedLineHeight.clamp(2.0, 3.5)
                : calculatedLineHeight.clamp(2.0, 3.2)
            : (pageNumber == 1 || pageNumber == 2)
                ? 4 * h
                : 4 * h;

        return Column(
          children: [
            // ── ترويسة معلومات المصحف مع رقم الصفحة ──
            if (pageNumber > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 8),
                child: _PageHeaderInfo(
                  pageNumber: pageNumber, 
                  theme: theme,
                ),
              ),
            
            // ── المصحف ──
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: theme.horizontalPadding),
                child: Text.rich(
                  TextSpan(children: verseSpans),
                  locale: const Locale("ar"),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  softWrap: true,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    fontFamily: pageFont,
                    package: 'qcf_quran',
                    fontSize: effectiveFontSize,
                    color: theme.verseTextColor,
                    height: effectiveHeight,
                    letterSpacing: theme.letterSpacing,
                    wordSpacing: theme.wordSpacing,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static String _toArabicNumeral(int n) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((d) => digits[int.parse(d)]).join();
  }
}

/// ── Ornamental Page Frame ──
/// Wraps the Quran page content with decorative Islamic borders
class _OrnamentalPageFrame extends StatelessWidget {
  final int pageNumber;
  final QcfThemeData theme;
  final bool isDesktop;
  final Widget child;

  const _OrnamentalPageFrame({
    required this.pageNumber,
    required this.theme,
    required this.isDesktop,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? const Color(0xFFB8860B) : const Color(0xFF2E7D32);
    final cornerColor =
        isDark ? const Color(0xFFDAA520) : const Color(0xFF1B5E20);

    return Stack(
      children: [
        // Content with padding for the ornamental border
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: child,
          ),
        ),

        // ── Ornamental Border Overlay ──
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _MushafBorderPainter(
                borderColor: borderColor,
                cornerColor: cornerColor,
                isDark: isDark,
              ),
            ),
          ),
        ),

        // ── Page Number at bottom ──
        Positioned(
          bottom: 6,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              _toArabicNumeral(pageNumber),
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? const Color(0xFFDAA520) : const Color(0xFF2E7D32),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _toArabicNumeral(int n) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((d) => digits[int.parse(d)]).join();
  }
}

/// ── Ornamental Surah Header ──
class _OrnamentalSurahHeader extends StatelessWidget {
  final int surahNumber;
  final QcfThemeData theme;
  final bool isDesktop;

  const _OrnamentalSurahHeader({
    required this.surahNumber,
    required this.theme,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor =
        isDark ? const Color(0xFFDAA520) : const Color(0xFF2E7D32);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Corner decorations
          Positioned(
            left: 4,
            child: _CornerFloral(color: accentColor, size: 18),
          ),
          Positioned(
            right: 4,
            child: _CornerFloral(color: accentColor, size: 18, mirror: true),
          ),
          // Surah name using QCF header font
          if (isDesktop)
            Text(
              'سورة ${quran_utils.getSurahNameArabic(surahNumber)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'UthmanicHafs',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            )
          else
            HeaderWidget(suraNumber: surahNumber, theme: theme),
        ],
      ),
    );
  }
}

/// ── Corner Floral Decoration ──
class _CornerFloral extends StatelessWidget {
  final Color color;
  final double size;
  final bool mirror;

  const _CornerFloral(
      {required this.color, this.size = 16, this.mirror = false});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scaleX: mirror ? -1 : 1,
      child: Icon(
        Icons.local_florist,
        color: color.withValues(alpha: 0.6),
        size: size,
      ),
    );
  }
}

/// ── Custom Painter for Mushaf Page Border ──
class _MushafBorderPainter extends CustomPainter {
  final Color borderColor;
  final Color cornerColor;
  final bool isDark;

  _MushafBorderPainter({
    required this.borderColor,
    required this.cornerColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Outer border
    final outerPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final innerPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Gold/Green accent line
    final accentPaint = Paint()
      ..color = cornerColor.withValues(alpha: 0.3)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const margin = 4.0;
    const innerMargin = 8.0;
    const cornerSize = 20.0;

    // Outer rect
    final outerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
          margin, margin, size.width - margin * 2, size.height - margin * 2),
      const Radius.circular(6),
    );
    canvas.drawRRect(outerRect, outerPaint);

    // Inner rect
    final innerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(innerMargin, innerMargin, size.width - innerMargin * 2,
          size.height - innerMargin * 2),
      const Radius.circular(4),
    );
    canvas.drawRRect(innerRect, innerPaint);

    // Middle accent line
    final midMargin = (margin + innerMargin) / 2;
    final midRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(midMargin, midMargin, size.width - midMargin * 2,
          size.height - midMargin * 2),
      const Radius.circular(5),
    );
    canvas.drawRRect(midRect, accentPaint);

    // Corner decorations (small diamond shapes)
    final cornerPaint = Paint()
      ..color = cornerColor
      ..style = PaintingStyle.fill;

    _drawCornerDecoration(
        canvas, Offset(margin + 2, margin + 2), cornerSize, cornerPaint);
    _drawCornerDecoration(
        canvas,
        Offset(size.width - margin - 2 - cornerSize, margin + 2),
        cornerSize,
        cornerPaint);
    _drawCornerDecoration(
        canvas,
        Offset(margin + 2, size.height - margin - 2 - cornerSize),
        cornerSize,
        cornerPaint);
    _drawCornerDecoration(
        canvas,
        Offset(size.width - margin - 2 - cornerSize,
            size.height - margin - 2 - cornerSize),
        cornerSize,
        cornerPaint);
  }

  void _drawCornerDecoration(
      Canvas canvas, Offset origin, double size, Paint paint) {
    final center = Offset(origin.dx + size / 2, origin.dy + size / 2);
    final path = Path();

    // Small diamond
    path.moveTo(center.dx, center.dy - size * 0.3);
    path.lineTo(center.dx + size * 0.3, center.dy);
    path.lineTo(center.dx, center.dy + size * 0.3);
    path.lineTo(center.dx - size * 0.3, center.dy);
    path.close();

    canvas.drawPath(path, paint..color = paint.color.withValues(alpha: 0.2));
    canvas.drawPath(
      path,
      Paint()
        ..color = paint.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ── ترويسة معلومات المصحف الثابتة ──
class _PageHeaderInfo extends StatelessWidget {
  final int pageNumber;
  final QcfThemeData theme;

  const _PageHeaderInfo({
    required this.pageNumber,
    required this.theme,
  });

  static const List<int> _juzStartPages = [
    1, 22, 42, 62, 82, 102, 121, 142, 162, 182, 201, 222, 242, 262, 282, 302,
    322, 342, 362, 382, 402, 422, 442, 462, 482, 502, 522, 542, 562, 582
  ];

  int _getJuzForPage(int page) {
    for (int i = _juzStartPages.length - 1; i >= 0; i--) {
      if (page >= _juzStartPages[i]) return i + 1;
    }
    return 1;
  }

  int _getSurahForPage(int page) {
    try {
      for (int surah = 114; surah >= 1; surah--) {
        if (quran_utils.getPageNumber(surah, 1) <= page) return surah;
      }
    } catch (_) {}
    return 1;
  }

  String _toArabicNum(dynamic num) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return num.toString().split('').map((d) {
      final i = int.tryParse(d);
      return i != null ? digits[i] : d;
    }).join();
  }

  Widget _buildText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: theme.headerTextColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final juzForPage = _getJuzForPage(pageNumber);
    final surahForPage = _getSurahForPage(pageNumber);
    final surahName = quran_utils.getSurahNameArabic(surahForPage);

    // الجزء ١
    final juzText = 'الجزء ${_toArabicNum(juzForPage)}';
    // البقرة
    final surahText = surahName;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // الجزء (يمين)
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: _buildText(juzText),
            ),
          ),
          
          // رقم الصفحة (وسط)
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.center,
              child: _OrnamentalPageNumber(
                pageNumber: pageNumber,
                color: theme.headerTextColor,
              ),
            ),
          ),
          
          // السورة (يسار)
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildText(surahText),
            ),
          ),
        ],
      ),
    );
  }
}

/// ── إطار رقم الصفحة المزخرف ──
class _OrnamentalPageNumber extends StatelessWidget {
  final int pageNumber;
  final Color color;

  const _OrnamentalPageNumber({
    required this.pageNumber,
    required this.color,
  });

  String _toArabicNum(dynamic num) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return num.toString().split('').map((d) {
      final i = int.tryParse(d);
      return i != null ? digits[i] : d;
    }).join();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.4),
            width: 1.0,
          ),
        ),
        child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // نقطة يمين
              Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              // الرقم
              Text(
                _toArabicNum(pageNumber),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              // نقطة يسار
              Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
    );
  }
}
