import 'dart:async';
import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import '../../../../core/theme/theme_provider.dart';
import '../../../settings/ui/screens/unified_prayer_settings_screen.dart';
import 'package:get/get.dart';
import '../../../../core/translations/app_locale_keys.dart';

class PrayerCountdownScreen extends StatefulWidget {
  const PrayerCountdownScreen({super.key});

  @override
  State<PrayerCountdownScreen> createState() => _PrayerCountdownScreenState();
}

class _PrayerCountdownScreenState extends State<PrayerCountdownScreen> {
  PrayerTimes? _prayerTimes;
  Prayer? _targetPrayer;
  Timer? _timer;
  Duration _displayTime = Duration.zero;
  bool _isIqamaMode = false;
  bool _use24HourFormat = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateLogic());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _use24HourFormat = prefs.getBool('time_format_24hour') ?? true;
    });

    // Manual or Cached Location
    double? lat;
    double? lng;
    
    if (prefs.getBool('manual_location_chosen') ?? false) {
      lat = prefs.getDouble('cached_lat');
      lng = prefs.getDouble('cached_lng');
    } else {
      lat = prefs.getDouble('cached_lat');
      lng = prefs.getDouble('cached_lng');
    }

    if (lat != null && lng != null) {
      _calculateAndSet(lat, lng, prefs);
    }
  }

  void _calculateAndSet(double lat, double lng, SharedPreferences prefs) {
      final methodId = prefs.getString('calculation_method') ?? 'egyptian';
      CalculationMethod method = CalculationMethod.egyptian;
      switch (methodId) {
        case 'karachi': method = CalculationMethod.karachi; break;
        case 'umm_al_qura': method = CalculationMethod.umm_al_qura; break;
        case 'dubai': method = CalculationMethod.dubai; break;
        case 'mwl': method = CalculationMethod.muslim_world_league; break;
        case 'isna': method = CalculationMethod.north_america; break;
        case 'kuwait': method = CalculationMethod.kuwait; break;
        case 'qatar': method = CalculationMethod.qatar; break;
        case 'turkey': method = CalculationMethod.turkey; break;
        default: method = CalculationMethod.egyptian;
      }

      final params = method.getParameters();
      params.madhab = (prefs.getString('madhab') ?? 'shafi') == 'hanafi' ? Madhab.hanafi : Madhab.shafi;
      params.adjustments.fajr = prefs.getInt('offset_fajr') ?? 0;
      params.adjustments.sunrise = prefs.getInt('offset_sunrise') ?? 0;
      params.adjustments.dhuhr = prefs.getInt('offset_dhuhr') ?? 0;
      params.adjustments.asr = prefs.getInt('offset_asr') ?? 0;
      params.adjustments.maghrib = prefs.getInt('offset_maghrib') ?? 0;
      params.adjustments.isha = prefs.getInt('offset_isha') ?? 0;

      if (mounted) {
        setState(() {
          _prayerTimes = PrayerTimes.today(Coordinates(lat, lng), params);
        });
        _updateLogic();
      }
  }

  void _updateLogic() {
    if (_prayerTimes == null) return;
    final now = DateTime.now();

    // ✅ Check if day changed (midnight) and reload
    if (_prayerTimes!.fajr.year != now.year ||
        _prayerTimes!.fajr.month != now.month ||
        _prayerTimes!.fajr.day != now.day) {
      _loadData();
      return;
    }

    final currentPrayer = _prayerTimes!.currentPrayer();
    final nextPrayer = _prayerTimes!.nextPrayer();

    // Iqama Logic
    if (currentPrayer != Prayer.none && currentPrayer != Prayer.sunrise) {
      final prayerTime = _prayerTimes!.timeForPrayer(currentPrayer)!;
      final timePassed = now.difference(prayerTime);
      int iqamaMinutes = (currentPrayer == Prayer.maghrib) ? 10 : 15;

      if (timePassed.inMinutes < iqamaMinutes) {
        setState(() {
          _isIqamaMode = true;
          _targetPrayer = currentPrayer;
          _displayTime = timePassed;
        });
        return;
      }
    }

    // Countdown Logic
    setState(() {
      _isIqamaMode = false;
      DateTime nextTime;
      DateTime prevTime;

      if (nextPrayer == Prayer.none) {
        _targetPrayer = Prayer.fajr;
        nextTime = _prayerTimes!.fajr.add(const Duration(days: 1));
        prevTime = _prayerTimes!.isha;
      } else {
        _targetPrayer = nextPrayer;
        nextTime = _prayerTimes!.timeForPrayer(nextPrayer)!;
        Prayer prevP = _getPrevPrayer(nextPrayer);
        prevTime = _prayerTimes!.timeForPrayer(prevP)!;
      }

      _displayTime = nextTime.difference(now);
    });
  }

  Prayer _getPrevPrayer(Prayer p) {
    switch(p) {
      case Prayer.sunrise: return Prayer.fajr;
      case Prayer.dhuhr: return Prayer.sunrise;
      case Prayer.asr: return Prayer.dhuhr;
      case Prayer.maghrib: return Prayer.asr;
      case Prayer.isha: return Prayer.maghrib;
      default: return Prayer.isha;
    }
  }

  String _getPrayerName(Prayer? p) {
    switch (p) {
      case Prayer.fajr: return "الفجر";
      case Prayer.sunrise: return "الشروق";
      case Prayer.dhuhr: return "الظهر";
      case Prayer.asr: return "العصر";
      case Prayer.maghrib: return "المغرب";
      case Prayer.isha: return "العشاء";
      default: return "";
    }
  }

  IconData _getPrayerIcon(Prayer p) {
    switch (p) {
      case Prayer.fajr: return FontAwesomeIcons.mosque;
      case Prayer.sunrise: return FontAwesomeIcons.sun; 
      case Prayer.dhuhr: return FontAwesomeIcons.mosque;
      case Prayer.asr: return FontAwesomeIcons.mosque; 
      case Prayer.maghrib: return FontAwesomeIcons.mosque;
      case Prayer.isha: return FontAwesomeIcons.mosque;
      default: return FontAwesomeIcons.mosque;
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark;

    // Islamic Elegant Theme - Deep Blue & Gold
    final backgroundColor = isDark ? const Color(0xFF0A1628) : const Color(0xFFF8F9FC);
    final cardColor = isDark ? const Color(0xFF0F1F35) : const Color(0xFFFFFFFF);
    final surfaceColor = isDark ? const Color(0xFF1A2F4A) : const Color(0xFFF1F3F8);
    final accentGold = isDark ? const Color(0xFFD4AF37) : const Color(0xFFC4971A);
    final accentBlue = isDark ? const Color(0xFF2D5F8D) : const Color(0xFF3A7BC8);
    final textColor = isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1A2332);
    final subTextColor = isDark ? const Color(0xFFB8C5D6) : const Color(0xFF5A6B7D);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: _prayerTimes == null 
          ? Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(accentGold),
            ))
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark 
                    ? [const Color(0xFF0A1628), const Color(0xFF0D1D33), const Color(0xFF0A1628)]
                    : [const Color(0xFFF8F9FC), const Color(0xFFFFFFFF), const Color(0xFFF8F9FC)],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Header with Islamic pattern
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: accentGold.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back_ios_rounded, color: textColor, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Row(
                            children: [
                              Icon(FontAwesomeIcons.mosque, color: accentGold, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                AppLocaleKeys.prayerTimesTitleCount.tr,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Cairo',
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(Icons.settings_outlined, color: accentGold),
                            onPressed: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const UnifiedPrayerSettingsScreen()),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Main countdown card with Islamic decorations
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                              ? [const Color(0xFF1A2F4A), const Color(0xFF0F1F35)]
                              : [Colors.white, const Color(0xFFFAFBFD)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: accentGold.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          ],
                          border: Border.all(
                            color: accentGold.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Islamic pattern overlay
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: CustomPaint(
                                  painter: IslamicPatternPainter(
                                    color: accentGold.withOpacity(isDark ? 0.05 : 0.03),
                                  ),
                                ),
                              ),
                            ),
                            
                            // Content
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                              child: Column(
                                children: [
                                  // Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [accentGold.withOpacity(0.2), accentBlue.withOpacity(0.2)],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: accentGold.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _isIqamaMode ? FontAwesomeIcons.mosque : FontAwesomeIcons.clock,
                                          color: accentGold,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _isIqamaMode ? AppLocaleKeys.iqamaLabel.tr : AppLocaleKeys.nextPrayerLabel.tr,
                                          style: TextStyle(
                                            color: accentGold,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Prayer name with icon
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [accentGold, accentGold.withOpacity(0.7)],
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: accentGold.withOpacity(0.4),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          _getPrayerIcon(_targetPrayer ?? Prayer.fajr),
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        _getPrayerName(_targetPrayer),
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          fontFamily: 'Cairo',
                                          height: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  
                                  // Countdown timer with circular progress rings
                                  _buildCircularTimer(accentGold, accentBlue, surfaceColor),
                                  
                                  const SizedBox(height: 20),
                                  
                                  // Date badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: surfaceColor.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: accentBlue.withOpacity(0.2)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.calendar_today, size: 12, color: subTextColor),
                                        const SizedBox(width: 6),
                                        Text(
                                          DateFormat.yMMMd('ar').format(DateTime.now()),
                                          style: TextStyle(
                                            color: subTextColor,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Prayer times list
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                          border: Border(
                            top: BorderSide(color: accentGold.withOpacity(0.2), width: 1.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 20, bottom: 12, left: 20, right: 20),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [accentGold, accentBlue],
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    AppLocaleKeys.allTimesLabel.tr,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 8),
                                itemCount: 6,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final prayers = [
                                    Prayer.fajr,
                                    Prayer.sunrise,
                                    Prayer.dhuhr,
                                    Prayer.asr,
                                    Prayer.maghrib,
                                    Prayer.isha,
                                  ];
                                  final names = ["الفجر", "الشروق", "الظهر", "العصر", "المغرب", "العشاء"];
                                  return _buildPrayerTile(
                                    prayers[index],
                                    names[index],
                                    isDark,
                                    accentGold,
                                    accentBlue,
                                    textColor,
                                    subTextColor,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCircularTimer(Color accentGold, Color accentBlue, Color surfaceColor) {
    final hours = _displayTime.inHours;
    final minutes = _displayTime.inMinutes.remainder(60);
    final seconds = _displayTime.inSeconds.remainder(60);
    
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTimeUnit(hours, 24, AppLocaleKeys.hourLabel.tr, accentGold, accentBlue, surfaceColor),
          const SizedBox(width: 8),
          Text(':', style: TextStyle(color: accentGold, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          _buildTimeUnit(minutes, 60, AppLocaleKeys.minuteLabel.tr, accentGold, accentBlue, surfaceColor),
          const SizedBox(width: 8),
          Text(':', style: TextStyle(color: accentGold, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          _buildTimeUnit(seconds, 60, AppLocaleKeys.secondLabel.tr, accentGold, accentBlue, surfaceColor),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(int value, int maxValue, String label, Color accentGold, Color accentBlue, Color surfaceColor) {
    final progress = value / maxValue;
    
    return Column(
      children: [
        SizedBox(
          width: 85,
          height: 85,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              CustomPaint(
                size: const Size(85, 85),
                painter: CircularProgressPainter(
                  progress: 1.0,
                  color: surfaceColor.withOpacity(0.3),
                  strokeWidth: 6,
                ),
              ),
              
              // Progress circle with gradient
              CustomPaint(
                size: const Size(85, 85),
                painter: CircularProgressPainter(
                  progress: progress,
                  color: accentGold,
                  strokeWidth: 6,
                  useGradient: true,
                  gradientColors: [accentGold, accentBlue],
                ),
              ),
              
              // Inner glow circle
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: surfaceColor.withOpacity(0.4),
                  boxShadow: [
                    BoxShadow(
                      color: accentGold.withOpacity(0.2),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              
              // Number
              Text(
                value.toString().padLeft(2, '0'),
                style: TextStyle(
                  color: accentGold,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Cairo',
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: accentGold.withOpacity(0.7),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _buildPrayerTile(
    Prayer p,
    String name,
    bool isDark,
    Color accentGold,
    Color accentBlue,
    Color textColor,
    Color subTextColor,
  ) {
    bool isActive = p == _targetPrayer;
    final timeStr = _prayerTimes != null
      ? (_use24HourFormat
        ? DateFormat('HH:mm', 'ar').format(_prayerTimes!.timeForPrayer(p)!)
        : DateFormat('hh:mm a', 'ar').format(_prayerTimes!.timeForPrayer(p)!))
      : "--:--";
    
    return Container(
      decoration: BoxDecoration(
        gradient: isActive
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                ? [const Color(0xFF1A2F4A), const Color(0xFF152841)]
                : [const Color(0xFFFFFBF5), const Color(0xFFFFF8ED)],
            )
          : null,
        color: isActive ? null : (isDark ? const Color(0xFF0E1D30) : const Color(0xFFFAFBFD)),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive ? accentGold.withOpacity(0.4) : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive 
          ? [
              BoxShadow(
                color: accentGold.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ]
          : [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Prayer icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [accentGold, accentGold.withOpacity(0.7)],
                          )
                        : LinearGradient(
                            colors: isDark 
                              ? [const Color(0xFF1A2F4A), const Color(0xFF152841)]
                              : [const Color(0xFFF1F3F8), const Color(0xFFE8ECF4)],
                          ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: accentGold.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                  ),
                  child: Icon(
                    _getPrayerIcon(p),
                    size: 20,
                    color: isActive ? Colors.white : (isDark ? accentGold.withOpacity(0.7) : accentBlue),
                  ),
                ),
                
                const SizedBox(width: 14),
                
                // Prayer name
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                      color: textColor,
                      fontFamily: 'Cairo',
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                
                // Time
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive 
                      ? accentGold.withOpacity(0.15)
                      : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
                    borderRadius: BorderRadius.circular(10),
                    border: isActive 
                      ? Border.all(color: accentGold.withOpacity(0.3))
                      : null,
                  ),
                  child: Text(
                    timeStr,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isActive ? accentGold : subTextColor,
                      fontFamily: 'Cairo',
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

                if (isActive) ...[
                  const SizedBox(width: 10),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [accentGold, accentGold.withOpacity(0.7)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentGold.withOpacity(0.5),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Circular Progress Painter for timer rings
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final bool useGradient;
  final List<Color>? gradientColors;

  CircularProgressPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 8.0,
    this.useGradient = false,
    this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (useGradient && gradientColors != null && gradientColors!.length >= 2) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      paint.shader = SweepGradient(
        colors: gradientColors!,
        startAngle: 0,
        endAngle: math.pi * 2,
      ).createShader(rect);
    } else {
      paint.color = color;
    }

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    // Only draw if there's progress to show
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// Islamic Pattern Painter for decorative background
class IslamicPatternPainter extends CustomPainter {
  final Color color;

  IslamicPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const spacing = 40.0;
    
    // Draw geometric Islamic pattern
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        _drawIslamicStar(canvas, paint, Offset(x, y), 15);
      }
    }
  }

  void _drawIslamicStar(Canvas canvas, Paint paint, Offset center, double radius) {
    const points = 8;
    final path = Path();
    
    for (int i = 0; i < points; i++) {
      final angle = (i * 2 * math.pi / points) - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    path.close();
    canvas.drawPath(path, paint);
    
    // Inner circle
    canvas.drawCircle(center, radius * 0.3, paint);
  }

  @override
  bool shouldRepaint(IslamicPatternPainter oldDelegate) => false;
}