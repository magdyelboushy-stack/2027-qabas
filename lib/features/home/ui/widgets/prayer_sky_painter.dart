import 'dart:math' as math;
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';

/// استخدام:
/// في الـ Stack بتاع الهيدر بعد الـ gradient، ضيف:
///
/// CustomPaint(
///   painter: PrayerSkyPainter(prayer: targetPrayer, isDark: isDark),
///   child: SizedBox.expand(),
/// )

class PrayerSkyPainter extends CustomPainter {
  final Prayer prayer;
  final bool isDark;
  final double animValue; // من AnimationController (0.0 → 1.0)

  PrayerSkyPainter({
    required this.prayer,
    required this.isDark,
    this.animValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (prayer) {
      case Prayer.fajr:
        _paintFajr(canvas, size);
        break;
      case Prayer.sunrise:
        _paintSunrise(canvas, size);
        break;
      case Prayer.dhuhr:
        _paintDhuhr(canvas, size);
        break;
      case Prayer.asr:
        _paintAsr(canvas, size);
        break;
      case Prayer.maghrib:
        _paintMaghrib(canvas, size);
        break;
      case Prayer.isha:
      case Prayer.none:
      default:
        _paintIsha(canvas, size);
    }
  }

  // ─── الفجر ───────────────────────────────────────────────────────────────
  void _paintFajr(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // خلفية التدرج
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF060B18),
          Color(0xFF0F2035),
          Color(0xFF1B3A5C),
          Color(0xFF2E5F8A),
        ],
        stops: [0.0, 0.4, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // نجوم بتختفي (شفافية أقل من العشاء)
    _drawStars(canvas, size, count: 40, opacity: 0.55, seed: 1);

    // هلال
    _drawCrescent(
      canvas,
      center: Offset(w * 0.72, h * 0.22),
      radius: h * 0.09,
      color: const Color(0xFFCDE8F5),
      shadowColor: const Color(0xFF1B3A5C),
    );

    // ضوء الفجر على الأفق
    final horizonPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.bottomCenter,
        radius: 0.8,
        colors: [
          const Color(0xFF4A90D9).withValues(alpha: 0.5),
          const Color(0xFF1B3A5C).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.5, w, h * 0.5));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.5, w, h * 0.5), horizonPaint);

    // تلال داكنة
    _drawHills(canvas, size, color: const Color(0xFF040C18), opacity: 0.95);
  }

  // ─── الشروق ──────────────────────────────────────────────────────────────
  void _paintSunrise(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF12101E),
          Color(0xFF8B2635),
          Color(0xFFD4522A),
          Color(0xFFEE8B2B),
          Color(0xFFF5C842),
        ],
        stops: [0.0, 0.3, 0.55, 0.78, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // توهج الأفق
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, 1.0),
        radius: 0.9,
        colors: [
          const Color(0xFFF5C842).withValues(alpha: 0.45),
          const Color(0xFFD4522A).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), glowPaint);

    // الشمس على الأفق
    final sunCenter = Offset(w * 0.5, h * 0.88);
    final sunRadius = h * 0.18;
    _drawSun(canvas, center: sunCenter, radius: sunRadius, raysLength: 0);

    // تلال سوداء صلبة
    _drawHills(canvas, size, color: const Color(0xFF0A0605), opacity: 0.92);
  }

  // ─── الظهر ───────────────────────────────────────────────────────────────
  void _paintDhuhr(Canvas canvas, Size size) {
  final w = size.width;
  final h = size.height;

  final bgPaint = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF1565C0),
        Color(0xFF1E88E5),
        Color(0xFF42A5F5),
        Color(0xFF90CAF9),
      ],
      stops: [0.0, 0.35, 0.7, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, w, h));
  canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

  // شمس في الوسط فوق
  final sunCenter = Offset(w * 0.5, h * 0.16);
  _drawSun(canvas, center: sunCenter, radius: h * 0.12, raysLength: h * 0.06);

  // سحاب على الحواف بس
  final paint = Paint()..color = Colors.white.withValues(alpha: 0.45);
  final rng = math.Random(11);

  // سحابة يسار
  for (int b = 0; b < 4; b++) {
    final bx = w * 0.0 + b * w * 0.055;
    final by = h * 0.28 + rng.nextDouble() * h * 0.03;
    final r = h * (0.042 + rng.nextDouble() * 0.025);
    canvas.drawCircle(Offset(bx, by), r, paint);
  }

  // سحابة يمين
  final rng2 = math.Random(55);
  for (int b = 0; b < 4; b++) {
    final bx = w * 1.0 - b * w * 0.055;
    final by = h * 0.32 + rng2.nextDouble() * h * 0.03;
    final r = h * (0.042 + rng2.nextDouble() * 0.025);
    canvas.drawCircle(Offset(bx, by), r, paint);
  }

  // تلال خضراء داكنة
  _drawHills(canvas, size, color: const Color(0xFF1A4A1A), opacity: 0.55);
}

  // ─── العصر ───────────────────────────────────────────────────────────────
  void _paintAsr(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0D47A1),
          Color(0xFF1976D2),
          Color(0xFF42A5F5),
          Color(0xFFEFB843),
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // شمس على اليمين شوية تحت
    final sunCenter = Offset(w * 0.78, h * 0.38);
    _drawSun(
      canvas,
      center: sunCenter,
      radius: h * 0.1,
      raysLength: h * 0.045,
      color: const Color(0xFFFFE082),
    );

    // توهج دهبي في الأسفل
    final goldenGlow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFFEFB843).withValues(alpha: 0.35),
          const Color(0xFFEFB843).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.6, w, h * 0.4));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.6, w, h * 0.4), goldenGlow);

    // سحاب خفيف
    _drawClouds(canvas, size, color: const Color(0xFFBBDEFB), opacity: 0.5, offsetY: 0.25);

    _drawHills(canvas, size, color: const Color(0xFF0A2545), opacity: 0.7);
  }

  // ─── المغرب ──────────────────────────────────────────────────────────────
  void _paintMaghrib(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0D0520),
          Color(0xFF4A1060),
          Color(0xFF9C2D55),
          Color(0xFFD94F2A),
          Color(0xFFEE8B2B),
        ],
        stops: [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // شمس على الأفق
    final sunCenter = Offset(w * 0.5, h * 0.86);
    _drawSun(
      canvas,
      center: sunCenter,
      radius: h * 0.16,
      raysLength: 0,
      color: const Color(0xFFFF8F00),
    );

    // سحاب بنفسجي-أحمر
    _drawClouds(
      canvas,
      size,
      color: const Color(0xFF7B1FA2),
      opacity: 0.55,
      offsetY: 0.3,
    );
    _drawClouds(
      canvas,
      size,
      color: const Color(0xFFC62828),
      opacity: 0.4,
      offsetY: 0.48,
      seed: 99,
    );

    // نجوم بتطلع
    _drawStars(canvas, size, count: 18, opacity: 0.6, seed: 7);

    _drawHills(canvas, size, color: const Color(0xFF05010F), opacity: 0.95);
  }

  // ─── العشاء ──────────────────────────────────────────────────────────────
  void _paintIsha(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF000008),
          Color(0xFF05080F),
          Color(0xFF080D1A),
          Color(0xFF0C1220),
        ],
        stops: [0.0, 0.3, 0.65, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // درب اللبانة
    _drawMilkyWay(canvas, size);

    // نجوم كتير
    _drawStars(canvas, size, count: 90, opacity: 0.85, seed: 42);

    // قمر كامل
    _drawMoon(
      canvas,
      center: Offset(w * 0.25, h * 0.2),
      radius: h * 0.1,
    );

    _drawHills(canvas, size, color: const Color(0xFF010103), opacity: 0.98);
  }

  // ─── عناصر مشتركة ────────────────────────────────────────────────────────

  void _drawSun(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double raysLength,
    Color color = const Color(0xFFFFF9C4),
  }) {
    // توهج خارجي
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.45),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 2.2));
    canvas.drawCircle(center, radius * 2.2, glowPaint);

    // أشعة
    if (raysLength > 0) {
      final rayPaint = Paint()
        ..color = color.withValues(alpha: 0.55)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < 12; i++) {
        final angle = (i * math.pi * 2) / 12;
        final start = Offset(
          center.dx + math.cos(angle) * radius * 1.25,
          center.dy + math.sin(angle) * radius * 1.25,
        );
        final end = Offset(
          center.dx + math.cos(angle) * (radius * 1.25 + raysLength),
          center.dy + math.sin(angle) * (radius * 1.25 + raysLength),
        );
        canvas.drawLine(start, end, rayPaint);
      }
    }

    // قرص الشمس
    final sunPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white, color],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, sunPaint);
  }

  void _drawMoon(Canvas canvas, {required Offset center, required double radius}) {
    // توهج القمر
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFD4ECF7).withValues(alpha: 0.3),
          const Color(0xFF85C1E9).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 2));
    canvas.drawCircle(center, radius * 2, glowPaint);

    // وش القمر
    final moonPaint = Paint()..color = const Color(0xFFE8F5FD);
    canvas.drawCircle(center, radius, moonPaint);

    // تفاصيل بقع القمر
    final craterPaint = Paint()..color = const Color(0xFFBDD8EE).withValues(alpha: 0.6);
    canvas.drawCircle(Offset(center.dx - radius * 0.25, center.dy - radius * 0.2), radius * 0.18, craterPaint);
    canvas.drawCircle(Offset(center.dx + radius * 0.3, center.dy + radius * 0.25), radius * 0.14, craterPaint);
    canvas.drawCircle(Offset(center.dx - radius * 0.1, center.dy + radius * 0.35), radius * 0.1, craterPaint);
  }

  void _drawCrescent(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
    required Color shadowColor,
  }) {
    // توهج
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.8));
    canvas.drawCircle(center, radius * 1.8, glowPaint);

    // الهلال = دائرة ناقص دائرة متحركة
    final moonPaint = Paint()..color = color;
    canvas.drawCircle(center, radius, moonPaint);
    final shadowPaint = Paint()..color = shadowColor;
    canvas.drawCircle(
      Offset(center.dx + radius * 0.35, center.dy - radius * 0.1),
      radius * 0.85,
      shadowPaint,
    );
  }

  void _drawStars(
    Canvas canvas,
    Size size, {
    required int count,
    required double opacity,
    required int seed,
  }) {
    final rng = math.Random(seed);
    final paint = Paint();

    for (int i = 0; i < count; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height * 0.78;
      final r = rng.nextDouble() * 1.2 + 0.4;
      final starOpacity = (rng.nextDouble() * 0.5 + 0.5) * opacity;
      // نجوم زرقاء بيضاء بالتعاقب
      final isBlue = rng.nextBool();
      paint.color = (isBlue
              ? const Color(0xFFB0C8E8)
              : Colors.white)
          .withValues(alpha: starOpacity);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  void _drawMilkyWay(Canvas canvas, Size size) {
    final rng = math.Random(77);
    final paint = Paint();
    // شريط ضبابي مائل
    for (int i = 0; i < 120; i++) {
      final t = i / 120.0;
      final cx = size.width * (0.2 + t * 0.6) + rng.nextDouble() * 60 - 30;
      final cy = size.height * (0.1 + t * 0.5) + rng.nextDouble() * 25 - 12;
      final r = rng.nextDouble() * 1.5 + 0.3;
      paint.color = const Color(0xFF8BA4C8).withValues(alpha: rng.nextDouble() * 0.18 + 0.04);
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }
  }

  void _drawClouds(
    Canvas canvas,
    Size size, {
    required Color color,
    required double opacity,
    double offsetY = 0.35,
    int seed = 11,
  }) {
    final rng = math.Random(seed);
    final paint = Paint()..color = color.withValues(alpha: opacity);

    for (int c = 0; c < 3; c++) {
      final cx = size.width * (0.15 + c * 0.35 + rng.nextDouble() * 0.1);
      final cy = size.height * (offsetY + rng.nextDouble() * 0.1);
      // مجموعة دوائر تكوّن سحابة
      for (int b = 0; b < 4; b++) {
        final bx = cx + (b - 1.5) * size.width * 0.055;
        final by = cy + rng.nextDouble() * size.height * 0.04 - size.height * 0.02;
        final r = size.height * (0.045 + rng.nextDouble() * 0.035);
        canvas.drawCircle(Offset(bx, by), r, paint);
      }
    }
  }

  void _drawHills(
    Canvas canvas,
    Size size, {
    required Color color,
    required double opacity,
  }) {
    final paint = Paint()..color = color.withValues(alpha: opacity);
    final path = Path();

    path.moveTo(0, size.height * 0.82);
    path.quadraticBezierTo(
      size.width * 0.12, size.height * 0.68,
      size.width * 0.25, size.height * 0.76,
    );
    path.quadraticBezierTo(
      size.width * 0.38, size.height * 0.62,
      size.width * 0.5, size.height * 0.72,
    );
    path.quadraticBezierTo(
      size.width * 0.65, size.height * 0.60,
      size.width * 0.78, size.height * 0.70,
    );
    path.quadraticBezierTo(
      size.width * 0.90, size.height * 0.64,
      size.width, size.height * 0.74,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(PrayerSkyPainter oldDelegate) =>
      oldDelegate.prayer != prayer ||
      oldDelegate.isDark != isDark ||
      oldDelegate.animValue != animValue;
}