import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:mihrab/features/ramadan/logic/ramadan_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/services/ad_service.dart';

/// Fawanees (Lanterns) Screen - Redesigned
/// An immersive 30-day journey visualized as a winding path of glowing lanterns.
class FawaneesScreen extends StatefulWidget {
  const FawaneesScreen({super.key});

  @override
  State<FawaneesScreen> createState() => _FawaneesScreenState();
}

class _FawaneesScreenState extends State<FawaneesScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _pulseController;
  late AnimationController _starController;
  
  // Current Ramadan Day (1-30)
  int _currentDay = 1;

  @override
  void initState() {
    super.initState();
    _currentDay = RamadanService.currentRamadanDay().clamp(1, 30);
    if (_currentDay == 0) _currentDay = 1;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Scroll to current day after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentDay();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _starController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentDay() {
    if (!_scrollController.hasClients) return;
    // Each item height is roughly 140.
    final offset = (_currentDay - 1) * 140.0;
    // Center it on screen if possible
    final targetOffset = math.max(0.0, offset - MediaQuery.of(context).size.height / 3);
    
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(seconds: 1),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('فوانيس رمضان', 
          style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 24)
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F0C29), // Deep Night Purple
              Color(0xFF302B63), // Rich Purple
              Color(0xFF24243E), // Dark Blue
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated Stars Background
            AnimatedBuilder(
              animation: _starController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _StarPainter(animationValue: _starController.value),
                  size: Size.infinite,
                );
              },
            ),
            
            // Path and Lanterns
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 100),
                  child: SizedBox(
                    height: 30 * 140.0 + 300, 
                    child: Stack(
                      children: [
                        // The Glowing Path
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _PathPainter(
                              days: 30,
                              itemHeight: 140.0,
                              color: const Color(0xFFFFD700),
                            ),
                          ),
                        ),
                        
                        // The Lanterns
                        ...List.generate(30, (index) {
                          final day = index + 1;
                          final isCompleted = day < _currentDay;
                          final isCurrent = day == _currentDay;
                          final isLocked = day > _currentDay;
                          
                          // Calculate Position (Sine Wave)
                          final y = index * 140.0 + 150;
                          final center = constraints.maxWidth / 2;
                          final amplitude = constraints.maxWidth / 3.2;
                          final x = center + amplitude * math.sin(index * 0.7);

                          return Positioned(
                            top: y,
                            left: x - 50, // Center 100px width
                            child: GestureDetector(
                              onTap: () => _showDayContent(context, day, isLocked),
                              child: _LanternItem(
                                day: day,
                                isCompleted: isCompleted,
                                isCurrent: isCurrent,
                                isLocked: isLocked,
                                pulseAnimation: _pulseController,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  void _showDayContent(BuildContext context, int day, bool isLocked) {
    if (isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يوم $day لم يأتِ بعد.. انتظرونا!', 
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(20),
        ),
      );
      return;
    }

    final content = RamadanService.getRandomContent();
    // Show native ad when opening day content
    AdService.showInterstitialAd();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DayContentSheet(day: day, content: content),
    );
  }
}

class _LanternItem extends StatelessWidget {
  final int day;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLocked;
  final Animation<double> pulseAnimation;

  const _LanternItem({
    required this.day,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLocked,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        double scale = 1.0;
        double glowRadius = 0.0;
        
        if (isCurrent) {
          scale = 1.0 + (pulseAnimation.value * 0.08);
          glowRadius = 15.0 + (pulseAnimation.value * 15.0);
        } else if (isCompleted) {
          glowRadius = 10.0;
        }

        return Transform.scale(
          scale: scale,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lantern Glow Container
              Container(
                width: 80,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: (isCurrent || isCompleted) ? [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(isCurrent ? 0.6 : 0.3),
                      blurRadius: glowRadius,
                      spreadRadius: glowRadius / 2,
                    )
                  ] : [],
                ),
                child: CustomPaint(
                  painter: _LanternPainter(
                    color: isLocked 
                        ? Colors.white24 
                        : (isCompleted ? const Color(0xFFFFA000) : const Color(0xFFFFD700)),
                    isLit: !isLocked,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Day Label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isCurrent 
                      ? const Color(0xFFFFD700) 
                      : (isCompleted ? Colors.white24 : Colors.black45),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isCurrent ? [
                    BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.4), blurRadius: 8)
                  ] : [],
                  border: Border.all(
                    color: isCurrent ? Colors.white : Colors.white10,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  'يوم $day',
                  style: TextStyle(
                    color: isCurrent ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Draws a beautiful traditional lantern shape
class _LanternPainter extends CustomPainter {
  final Color color;
  final bool isLit;

  _LanternPainter({required this.color, required this.isLit});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    final w = size.width;
    final h = size.height;

    // Center x
    final cx = w / 2;

    // Top Ring
    path.addOval(Rect.fromCenter(center: Offset(cx, h * 0.1), width: w * 0.2, height: h * 0.08));

    // Dome
    path.moveTo(cx - w * 0.1, h * 0.1);
    path.quadraticBezierTo(cx - w * 0.2, h * 0.2, cx - w * 0.35, h * 0.3);
    path.lineTo(cx + w * 0.35, h * 0.3);
    path.quadraticBezierTo(cx + w * 0.2, h * 0.2, cx + w * 0.1, h * 0.1);

    // Body (Glass part)
    path.moveTo(cx - w * 0.35, h * 0.3);
    path.lineTo(cx - w * 0.25, h * 0.7);
    path.lineTo(cx + w * 0.25, h * 0.7);
    path.lineTo(cx + w * 0.35, h * 0.3);

    // Base
    path.moveTo(cx - w * 0.25, h * 0.7);
    path.lineTo(cx - w * 0.1, h * 0.9);
    path.lineTo(cx + w * 0.1, h * 0.9);
    path.lineTo(cx + w * 0.25, h * 0.7);

    // Bottom tip
    path.moveTo(cx, h * 0.9);
    path.lineTo(cx, h);

    canvas.drawPath(path, paint);
    canvas.drawPath(path, outlinePaint);

    // Inner Glow if lit
    if (isLit) {
      final glowPaint = Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(Offset(cx, h * 0.5), w * 0.15, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LanternPainter old) => old.color != color || old.isLit != isLit;
}

class _PathPainter extends CustomPainter {
  final int days;
  final double itemHeight;
  final Color color;

  _PathPainter({required this.days, required this.itemHeight, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4); // Neon glow

    final path = Path();
    final center = size.width / 2;
    final amplitude = size.width / 3.2;

    // Start point (top of first lantern area)
    path.moveTo(center, 150 + 50);

    for (int i = 0; i < days - 1; i++) {
      final y1 = i * itemHeight + 150 + 50;
      final x1 = center + amplitude * math.sin(i * 0.7);
      
      final y2 = (i + 1) * itemHeight + 150 + 50;
      final x2 = center + amplitude * math.sin((i + 1) * 0.7);

      final cy1 = y1 + (y2 - y1) / 2;
      final cx1 = x1;
      final cy2 = y1 + (y2 - y1) / 2;
      final cx2 = x2;

      path.cubicTo(cx1, cy1, cx2, cy2, x2, y2);
    }

    // Draw dashed path
    final dashPath = Path();
    double dashWidth = 15.0;
    double dashSpace = 10.0;
    double distance = 0.0;
    for (ui.PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StarPainter extends CustomPainter {
  final double animationValue;
  final List<_Star> stars = List.generate(50, (index) => _Star());

  _StarPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (var star in stars) {
      final opacity = (math.sin(animationValue * 2 * math.pi * star.speed + star.offset) + 1) / 2;
      paint.color = Colors.white.withOpacity(opacity * 0.8);
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) => true;
}

class _Star {
  final double x = math.Random().nextDouble();
  final double y = math.Random().nextDouble();
  final double size = math.Random().nextDouble() * 2 + 1;
  final double speed = math.Random().nextDouble() * 0.5 + 0.5;
  final double offset = math.Random().nextDouble() * 2 * math.pi;
}

// ─── Modal Sheet (Reused & Enhanced) ───

class _DayContentSheet extends StatefulWidget {
  final int day;
  final RamadanDailyContent content;

  const _DayContentSheet({required this.day, required this.content});

  @override
  State<_DayContentSheet> createState() => _DayContentSheetState();
}

class _DayContentSheetState extends State<_DayContentSheet> {
  bool _isFasted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFastingStatus();
  }

  Future<void> _loadFastingStatus() async {
    final fasted = await RamadanService.isFasted(widget.day);
    if (mounted) {
      setState(() {
        _isFasted = fasted;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFasting() async {
    setState(() => _isFasted = !_isFasted);
    await RamadanService.toggleFasting(widget.day, _isFasted);
    RamadanService.syncProgress();
    
    if (_isFasted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🎉 تقبل الله صيامك! تم إضافة 50 نقطة XP', 
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E1E2C) : const Color(0xFFF8F5F0);
    final handleColor = isDark ? Colors.white12 : Colors.black12;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white70 : Colors.black54;
    final btnBg = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);
    final btnTextColor = isDark ? Colors.white : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.15), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 50, height: 5,
              decoration: BoxDecoration(color: handleColor, borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🌙', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Text(
                'حصاد اليوم ${widget.day}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (!_isLoading)
            GestureDetector(
              onTap: _toggleFasting,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  gradient: _isFasted 
                      ? const LinearGradient(
                          colors: [Color(0xFF00C853), Color(0xFF64DD17)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: isDark
                              ? [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)]
                              : [Colors.black.withOpacity(0.04), Colors.black.withOpacity(0.02)],
                        ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isFasted ? Colors.transparent : (isDark ? Colors.white12 : Colors.black12),
                    width: 1,
                  ),
                  boxShadow: _isFasted ? [
                    BoxShadow(
                      color: const Color(0xFF00C853).withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ] : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isFasted) ...[
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      _isFasted ? 'تم صيام اليوم ولله الحمد' : 'هل أتممت صيام اليوم؟',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        color: _isFasted ? Colors.white : textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _ContentCard(
                    title: 'آية اليوم',
                    icon: FontAwesomeIcons.bookQuran,
                    body: widget.content.ayah,
                    subtitle: widget.content.ayahReference,
                    accentColor: const Color(0xFFAB47BC),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  
                  _ContentCard(
                    title: 'دعاء اليوم',
                    icon: FontAwesomeIcons.handsPraying,
                    body: widget.content.dua,
                    accentColor: const Color(0xFF26A69A),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  
                  _ContentCard(
                    title: 'العمل الصالح',
                    icon: FontAwesomeIcons.handHoldingHeart,
                    body: 'تصدق ولو بالقليل، أو ساعد محتاجاً، أو صل رحمك.',
                    accentColor: const Color(0xFFFF7043),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: btnBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'إغلاق', 
                style: TextStyle(
                  color: btnTextColor, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 16,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  final String title;
  final String body;
  final String? subtitle;
  final Color accentColor;
  final IconData icon;
  final bool isDark;

  const _ContentCard({
    required this.title, 
    required this.body, 
    this.subtitle, 
    required this.accentColor,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF252538) : Colors.white;
    final cardBorder = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.06);
    final bodyColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white.withOpacity(0.5) : Colors.black45;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 8),
              Text(
                title, 
                style: TextStyle(
                  color: accentColor, 
                  fontSize: 14, 
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                )
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: bodyColor, 
              fontSize: 16,
              height: 1.6,
              fontFamily: 'Cairo',
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(
                color: subtitleColor,
                fontSize: 12,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
