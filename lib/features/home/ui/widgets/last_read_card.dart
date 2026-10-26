import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ═══════════════════════════════════════════════════════════════
//  📖  LAST READ CARD — QABAS PREMIUM REDESIGN
//
//  Two states:
//    hasData  → green gradient hero card with 3D book slot,
//               surah name, ayah, and "استمرار" capsule button
//    noData   → soft prompt card
// ═══════════════════════════════════════════════════════════════

class LastReadCard extends StatelessWidget {
  final String lastReadSurah;
  final String lastReadAyah;
  final String? verseText;
  final VoidCallback? onTap;
  final bool isDisabled;

  const LastReadCard({
    super.key,
    required this.lastReadSurah,
    required this.lastReadAyah,
    this.verseText,
    this.onTap,
    this.isDisabled = false,
  });

  // ─── palette ──────────────────────────────────────────────
  static const Color kGreen     = Color(0xFF1E4233);
  static const Color kGreenMid  = Color(0xFF2A5E47);
  static const Color kGold      = Color(0xFFD4AF37);
  static const Color kGoldLight = Color(0xFFF0D080);

  String _cleanSurah(String raw) {
    String s = raw.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '').trim();
    if (s.startsWith('سورة سورة')) s = s.replaceFirst('سورة ', '');
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final hasData = lastReadSurah.isNotEmpty;
    final isDark  = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Opacity(
        opacity: isDisabled ? 0.55 : 1.0,
        child: hasData
            ? _buildDataCard(context, isDark)
            : _buildEmptyCard(context, isDark),
      ),
    );
  }

  // ─── CARD WITH DATA ───────────────────────────────────────

  Widget _buildDataCard(BuildContext context, bool isDark) {
    final surah = _cleanSurah(lastReadSurah);

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [kGreen, kGreenMid, Color(0xFF163828)],
          ),
          boxShadow: [
            BoxShadow(
              color: kGreen.withOpacity(0.45),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // ── background geo texture ─────────────────────
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: CustomPaint(painter: _CardTexturePainter()),
              ),
            ),

            // ── diagonal gold accent ───────────────────────
            Positioned(
              top: -30,
              right: -20,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kGold.withOpacity(0.06),
                ),
              ),
            ),

            // ── content ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: bismillah + arrow
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'بسم الله الرحمن الرحيم',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                          height: 2.0,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Main row: book image + text
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 3D book slot (replaced by real asset via Image.asset)
                      _BookPlaceholder(),
                      const SizedBox(width: 18),

                      // Text info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'continue_reading_recent'.tr,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.55),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              surah,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Ayah badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.2)),
                              ),
                              child: Text(
                                '${'ayah_number'.tr} $lastReadAyah',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            // Verse snippet
                            if (verseText != null && verseText!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                '"${verseText!.length > 60 ? '${verseText!.substring(0, 60)}...' : verseText!}"',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.65),
                                  fontStyle: FontStyle.italic,
                                  height: 1.5,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                            ],

                            const SizedBox(height: 16),

                            // Continue button
                            _ContinueButton(onTap: isDisabled ? null : onTap),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── EMPTY STATE ──────────────────────────────────────────

  Widget _buildEmptyCard(BuildContext context, bool isDark) {
    final bg     = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final border = isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: border, width: 1.5),
          boxShadow: isDark
              ? []
              : [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
        ),
        child: Column(
          children: [
            // Bismillah
            Text(
              'بسم الله الرحمن الرحيم',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                height: 2.0,
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.menu_book_rounded,
                    color: isDark ? Colors.cyanAccent : kGreen, size: 22),
                const SizedBox(width: 8),
                Text(
                  'continue_reading'.tr,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'not_started_reading'.tr,
              style: TextStyle(
                fontFamily: 'Cairo',
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'tap_to_start_reading'.tr,
              style: TextStyle(
                fontFamily: 'Cairo',
                color: (isDark ? Colors.white54 : Colors.black38),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Book placeholder — swapped to real asset automatically once
//  assets/quran_book.png / assets/quran_3d.png exist.
// ═══════════════════════════════════════════════════════════════

class _BookPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Try to load the real 3D book asset.
    // Falls back to the custom-painted placeholder if missing.
    return SizedBox(
      width: 80,
      height: 105,
      child: Image.asset(
        'assets/quran3d.jpg',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => CustomPaint(
          painter: _BookPainter(),
          size: const Size(80, 105),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Painted 3D-style book fallback
// ═══════════════════════════════════════════════════════════════

class _BookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.96), width: w * 0.7, height: h * 0.07),
      Paint()..color = Colors.black.withOpacity(0.25),
    );

    // Spine
    final spine = Paint()..color = const Color(0xFF1A3628);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.1, h * 0.06, w * 0.16, h * 0.88),
          const Radius.circular(3)),
      spine,
    );

    // Cover
    final cover = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFD4AF37), Color(0xFFB8960C), Color(0xFFEDD470)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(w * 0.18, h * 0.04, w * 0.72, h * 0.90));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.18, h * 0.04, w * 0.72, h * 0.90),
          const Radius.circular(4)),
      cover,
    );

    // Cover border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.22, h * 0.08, w * 0.64, h * 0.82),
          const Radius.circular(3)),
      Paint()
        ..color = const Color(0xFF1E4233).withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Arabic text label area
    final txtPaint = Paint()
      ..color = const Color(0xFF1E4233).withOpacity(0.25)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.26, h * 0.24, w * 0.52, h * 0.20),
          const Radius.circular(2)),
      txtPaint,
    );

    // Page edges
    final pagePaint = Paint()..color = const Color(0xFFF5ECC8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.83, h * 0.08, w * 0.08, h * 0.86),
          const Radius.circular(2)),
      pagePaint,
    );

    // Page lines
    final linePaint = Paint()
      ..color = Colors.black.withOpacity(0.07)
      ..strokeWidth = 0.5;
    for (double y = h * 0.14; y < h * 0.90; y += h * 0.07) {
      canvas.drawLine(Offset(w * 0.83, y), Offset(w * 0.91, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════════════
//  Continue button (iOS capsule style)
// ═══════════════════════════════════════════════════════════════

class _ContinueButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _ContinueButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: LastReadCard.kGold,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: LastReadCard.kGold.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'continue'.tr,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: LastReadCard.kGreen,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 12,
              color: LastReadCard.kGreen,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Card background texture painter
// ═══════════════════════════════════════════════════════════════

class _CardTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;

    for (double i = -size.height; i < size.width; i += 28) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), p);
    }

    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.fill;
    const spacing = 18.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}