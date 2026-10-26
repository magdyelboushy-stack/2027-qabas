import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../../data/models/adhan_theme_model.dart';
import '../../data/adhan_display_preferences.dart';
import '../../logic/adhan_audio_service.dart'; // ✅ Corrected Import Path
import 'package:get/get.dart';
import '../../../../core/translations/app_locale_keys.dart';

class AdhanFullscreenDisplay extends StatefulWidget {
  final String prayerName;
  final String prayerTime;
  final String soundId; // ✅ Add soundId

  const AdhanFullscreenDisplay({
    super.key,
    required this.prayerName,
    required this.prayerTime,
    required this.soundId, // ✅ Required
  });

  @override
  State<AdhanFullscreenDisplay> createState() => _AdhanFullscreenDisplayState();
}

class _AdhanFullscreenDisplayState extends State<AdhanFullscreenDisplay>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  AdhanTheme _theme = AdhanTheme.classicMosque;
  Timer? _autoDismissTimer;
  double _baselineTopPadding = 0;
  bool _isResumed = true;
  bool _stoppedByNotificationShade = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final views = WidgetsBinding.instance.platformDispatcher.views;
    _baselineTopPadding = views.isNotEmpty ? views.first.viewPadding.top : 0;
    _loadTheme();
    _setupAnimations();
    _setupAutoDismiss();
    
    // Set fullscreen and keep screen on
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // ✅ Play Adhan Audio immediately
    _playAdhan();
  }

  Future<void> _loadTheme() async {
    final themeId = await AdhanDisplayPreferences.getSelectedTheme();
    setState(() {
      _theme = AdhanTheme.getById(themeId);
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  Future<void> _setupAutoDismiss() async {
    final autoDismiss = await AdhanDisplayPreferences.isAutoDismissEnabled();
    if (autoDismiss) {
      // Auto dismiss after 3 minutes (typical Adhan duration)
      _autoDismissTimer = Timer(const Duration(minutes: 3), () {
        _stopAdhanAndDismiss();
      });
    }
  }

  void _playAdhan() {
     AdhanAudioService().playAdhan(widget.soundId);
  }

  void _dismiss() {
    // Don't stop audio here automatically if we just dismiss (e.g. back button?)
    // But user expectation: if they leave screen, does it stop?
    // User said: "Don't stop when I pull notification shade".
    // If they press BACK, they might expect it to stop? Or background?
    // Usually BACK = Dismiss = Stop.
    // "Stop Button" = Stop.
    // "Notification Shade" = Continue.
    // "Home Button" = Continue.
    
    // So distinct between user closing app vs dismissing screen.
    // Actually, WillPopScope calls _dismiss.
    
    _animationController.reverse().then((_) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: SystemUiOverlay.values,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _autoDismissTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isResumed = state == AppLifecycleState.resumed;
  }

  @override
  void didChangeMetrics() {
    if (!_isResumed || _stoppedByNotificationShade) {
      return;
    }
    final views = WidgetsBinding.instance.platformDispatcher.views;
    final topPadding = views.isNotEmpty ? views.first.viewPadding.top : 0;
    if (topPadding > _baselineTopPadding + 20) {
      _stoppedByNotificationShade = true;
      AdhanAudioService().stopAdhan();
    }
  }

  void _stopAdhanAndDismiss() async {
    // ✅ 1. Stop notification sound via platform channel (Legacy cleanup)
    try {
      const platform = MethodChannel('com.magdy.mihrab/audio');
      await platform.invokeMethod('stopNotificationSound');
    } catch (e) {
      // Ignore
    }
    
    // ✅ 2. Stop JustAudio Service
    await AdhanAudioService().stopAdhan();

    // ✅ 3. Cancel all active notifications
    try {
      await AwesomeNotifications().cancelAll();
    } catch (e) {
      // Ignore error
    }
    
    _dismiss();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _dismiss();
        return false;
      },
      child: Scaffold(
        body: GestureDetector(
          onVerticalDragEnd: (details) {
            // Swipe down to dismiss
            if (details.primaryVelocity! > 300) {
              _dismiss();
            }
          },
          child: Stack(
            children: [
              // Background
              _buildBackground(),

              // Mosque silhouette (if enabled)
              if (_theme.showMosqueImage) _buildMosqueImage(),

              // Islamic patterns overlay (if enabled)
              if (_theme.showPatterns) _buildPatternsOverlay(),

              // Main content
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildContent(),
                ),
              ),

              // Swipe indicator
              _buildSwipeIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    if (_theme.backgroundImage != null) {
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_theme.backgroundImage!),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.black.withOpacity(0.4),
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _theme.backgroundGradient,
        ),
      ),
    );
  }

  Widget _buildMosqueImage() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.3,
        child: Image.asset(
          'assets/background.png', // Using existing mosque background
          fit: BoxFit.cover,
          color: Colors.black.withOpacity(0.5),
          colorBlendMode: BlendMode.darken,
        ),
      ),
    );
  }

  Widget _buildPatternsOverlay() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.1,
        child: CustomPaint(
          painter: IslamicPatternPainter(color: _theme.prayerNameColor),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SafeArea(
      child: Stack(
        children: [
          // Scrollable Content (Top Part)
          Positioned.fill(
            bottom: 100, // Leave space for the button
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40), // Top spacing

                  // "حان الآن" text
                  Text(
                    AppLocaleKeys.itIsNowTime.tr,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: _theme.prayerTimeColor.withOpacity(0.9),
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(0, 2),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 15),

                  // Prayer Name
                  Text(
                    AppLocaleKeys.prayerOfName.trParams({'prayerName': widget.prayerName.toString()}),
                    style: TextStyle(
                      fontSize: _theme.prayerNameSize,
                      fontWeight: FontWeight.bold,
                      color: _theme.prayerNameColor,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(0, 4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 15),

                  // Prayer Time
                  Text(
                    widget.prayerTime,
                    style: TextStyle(
                      fontSize: _theme.prayerTimeSize + 4,
                      fontWeight: FontWeight.w600,
                      color: _theme.prayerTimeColor,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(0, 2),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // Decorative divider
                  Container(
                    width: 100,
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _theme.prayerNameColor.withOpacity(0),
                          _theme.prayerNameColor,
                          _theme.prayerNameColor.withOpacity(0),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Next prayer info
                  _buildNextPrayerInfo(),
                ],
              ),
            ),
          ),

          // Pinned Bottom Button
          Positioned(
            left: 30,
            right: 30,
            bottom: 20,
            child: SizedBox(
              width: double.infinity,
              height: 60, // Fixed height for better touch target
              child: ElevatedButton.icon(
                onPressed: _stopAdhanAndDismiss,
                icon: const Icon(Icons.stop_circle, size: 28),
                label: Text(
                  AppLocaleKeys.stopAdhanButton.tr,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _theme.buttonColor,
                  foregroundColor: _theme.buttonTextColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 10,
                  shadowColor: _theme.buttonColor.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextPrayerInfo() {
    // Calculate next prayer
    final prayers = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'];
    final currentIndex = prayers.indexOf(widget.prayerName);
    final nextPrayer = currentIndex >= 0 && currentIndex < prayers.length - 1
        ? prayers[currentIndex + 1]
        : 'الفجر';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _theme.prayerNameColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            'الصلاة التالية',
            style: TextStyle(
              fontSize: 16,
              color: _theme.prayerTimeColor.withOpacity(0.8),
              
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            nextPrayer,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _theme.prayerNameColor,
              
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }



  Widget _buildSwipeIndicator() {
    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

// Custom painter for Islamic geometric patterns
class IslamicPatternPainter extends CustomPainter {
  final Color color;

  IslamicPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const spacing = 80.0;
    
    // Draw simple geometric pattern
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // Draw star pattern
        _drawStar(canvas, paint, Offset(x, y), 20);
      }
    }
  }

  void _drawStar(Canvas canvas, Paint paint, Offset center, double radius) {
    const points = 8;
    final path = Path();
    
    for (int i = 0; i < points * 2; i++) {
      final angle = (i * 3.14159) / points;
      final r = i.isEven ? radius : radius / 2;
      final x = center.dx + r * (i == 0 ? 0 : (angle == 0 ? 1 : (angle > 0 ? 1 : -1)));
      final y = center.dy + r * (i == 0 ? -1 : (angle == 0 ? 0 : (angle > 0 ? 1 : -1)));
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
