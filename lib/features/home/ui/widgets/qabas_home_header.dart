import 'dart:async';
import 'dart:ui';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/theme_provider.dart';
import 'prayer_sky_painter.dart';
import '../../../../core/translations/app_locale_keys.dart';

class QabasHomeHeader extends StatefulWidget {
  final String hijriString;
  final int unreadNotificationsCount;
  final VoidCallback onBellTapped;
  final VoidCallback onMenuTapped;
  final VoidCallback onHijriTapped;
  final VoidCallback onCenterButtonTapped;

  const QabasHomeHeader({
    super.key,
    required this.hijriString,
    required this.unreadNotificationsCount,
    required this.onBellTapped,
    required this.onMenuTapped,
    required this.onHijriTapped,
    required this.onCenterButtonTapped,
  });

  @override
  State<QabasHomeHeader> createState() => _QabasHomeHeaderState();
}

class _QabasHomeHeaderState extends State<QabasHomeHeader>
    with SingleTickerProviderStateMixin {
  PrayerTimes? _prayerTimes;
  Prayer? _targetPrayer;
  Prayer? _previousPrayer;
  DateTime? _previousPrayerTime;
  Prayer? _upcomingPrayer;
  DateTime? _upcomingPrayerTime;
  Timer? _timer;
  Duration _displayTime = Duration.zero;
  bool _use24HourFormat = true;

  late AnimationController _skyAnimController;
  late Animation<double> _skyAnim;

  @override
  void initState() {
    super.initState();
    _skyAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _skyAnim =
        CurvedAnimation(parent: _skyAnimController, curve: Curves.easeInOut);
    _loadCachedPrayerTimes();
    _fetchPrayerTimes();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateLogic();
    });
  }

  @override
  void dispose() {
    _skyAnimController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadCachedPrayerTimes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _use24HourFormat = prefs.getBool('time_format_24hour') ?? true;
      });
      final isManual = prefs.getBool('manual_location_chosen') ?? false;
      if (isManual) {
        final lat = prefs.getDouble('cached_lat');
        final lng = prefs.getDouble('cached_lng');
        if (lat != null && lng != null) {
          await _calculateAndSet(lat, lng);
          return;
        }
      }
      final lat = prefs.getDouble('cached_lat');
      final lng = prefs.getDouble('cached_lng');
      if (lat != null && lng != null) await _calculateAndSet(lat, lng);
    } catch (_) {}
  }

  Future<void> _calculateAndSet(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    final methodId = prefs.getString('calculation_method') ?? 'egyptian';
    CalculationMethod method;
    switch (methodId) {
      case 'karachi':
        method = CalculationMethod.karachi;
        break;
      case 'umm_al_qura':
        method = CalculationMethod.umm_al_qura;
        break;
      case 'dubai':
        method = CalculationMethod.dubai;
        break;
      case 'mwl':
        method = CalculationMethod.muslim_world_league;
        break;
      case 'isna':
        method = CalculationMethod.north_america;
        break;
      case 'kuwait':
        method = CalculationMethod.kuwait;
        break;
      case 'qatar':
        method = CalculationMethod.qatar;
        break;
      case 'turkey':
        method = CalculationMethod.turkey;
        break;
      default:
        method = CalculationMethod.egyptian;
    }
    final params = method.getParameters();
    params.madhab = (prefs.getString('madhab') ?? 'shafi') == 'hanafi'
        ? Madhab.hanafi
        : Madhab.shafi;
    params.adjustments.fajr = prefs.getInt('offset_fajr') ?? 0;
    params.adjustments.sunrise = prefs.getInt('offset_sunrise') ?? 0;
    params.adjustments.dhuhr = prefs.getInt('offset_dhuhr') ?? 0;
    params.adjustments.asr = prefs.getInt('offset_asr') ?? 0;
    params.adjustments.maghrib = prefs.getInt('offset_maghrib') ?? 0;
    params.adjustments.isha = prefs.getInt('offset_isha') ?? 0;
    if (!mounted) return;
    setState(() {
      _prayerTimes = PrayerTimes.today(Coordinates(lat, lng), params);
    });
    _updateLogic();
  }

  Future<void> _fetchPrayerTimes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('location_skipped') ?? false) return;
      if (prefs.getBool('manual_location_chosen') ?? false) {
        await _loadCachedPrayerTimes();
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      final position = await Geolocator.getCurrentPosition();
      await prefs.setDouble('cached_lat', position.latitude);
      await prefs.setDouble('cached_lng', position.longitude);
      await _calculateAndSet(position.latitude, position.longitude);
    } catch (_) {}
  }

  void _updateLogic() {
    if (_prayerTimes == null) return;
    final now = DateTime.now();

    // ✅ Check if day changed (midnight) and reload
    if (_prayerTimes!.fajr.year != now.year ||
        _prayerTimes!.fajr.month != now.month ||
        _prayerTimes!.fajr.day != now.day) {
      _loadCachedPrayerTimes();
      return;
    }

    if (_prayerTimes!.fajr.year != now.year ||
        _prayerTimes!.fajr.month != now.month ||
        _prayerTimes!.fajr.day != now.day) {
      _loadCachedPrayerTimes();
      return;
    }
    final currentPrayer = _prayerTimes!.currentPrayer();
    final nextPrayer = _prayerTimes!.nextPrayer();

    if (currentPrayer != Prayer.none && currentPrayer != Prayer.sunrise) {
      final prayerTime = _prayerTimes!.timeForPrayer(currentPrayer)!;
      final timePassed = now.difference(prayerTime);
      final iqamaMinutes = currentPrayer == Prayer.maghrib ? 10 : 15;
      if (timePassed.inMinutes < iqamaMinutes) {
        setState(() {
          _targetPrayer = currentPrayer;
          _displayTime = Duration(minutes: iqamaMinutes) - timePassed;
          _previousPrayer = _prev(currentPrayer);
          _previousPrayerTime = _prayerTimes!.timeForPrayer(_previousPrayer!);
          _upcomingPrayer = _next(currentPrayer);
          _upcomingPrayerTime = _prayerTimes!.timeForPrayer(_upcomingPrayer!);
        });
        return;
      }
    }

    DateTime nextTime;
    Prayer nextTarget;
    if (nextPrayer == Prayer.none) {
      nextTarget = Prayer.fajr;
      nextTime = _prayerTimes!.fajr.add(const Duration(days: 1));
    } else {
      nextTarget = nextPrayer;
      nextTime = _prayerTimes!.timeForPrayer(nextPrayer)!;
    }
    setState(() {
      _targetPrayer = nextTarget;
      _displayTime = nextTime.difference(now);
      _previousPrayer = _prev(nextTarget);
      _previousPrayerTime =
          _previousPrayer == Prayer.isha && nextTarget == Prayer.fajr
              ? _prayerTimes!.isha
              : _prayerTimes!.timeForPrayer(_previousPrayer!);
      _upcomingPrayer = nextTarget;
      _upcomingPrayerTime = nextTime;
    });
  }

  Prayer _prev(Prayer p) {
    switch (p) {
      case Prayer.fajr:
        return Prayer.isha;
      case Prayer.sunrise:
        return Prayer.fajr;
      case Prayer.dhuhr:
        return Prayer.sunrise;
      case Prayer.asr:
        return Prayer.dhuhr;
      case Prayer.maghrib:
        return Prayer.asr;
      case Prayer.isha:
        return Prayer.maghrib;
      default:
        return Prayer.isha;
    }
  }

  Prayer _next(Prayer p) {
    switch (p) {
      case Prayer.fajr:
        return Prayer.sunrise;
      case Prayer.sunrise:
        return Prayer.dhuhr;
      case Prayer.dhuhr:
        return Prayer.asr;
      case Prayer.asr:
        return Prayer.maghrib;
      case Prayer.maghrib:
        return Prayer.isha;
      case Prayer.isha:
        return Prayer.fajr;
      default:
        return Prayer.fajr;
    }
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)} : ${two(d.inMinutes.remainder(60))} : ${two(d.inSeconds.remainder(60))}';
  }

  String _name(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return AppLocaleKeys.fajrPrayer.tr;
      case Prayer.sunrise:
        return AppLocaleKeys.sunrisePrayer.tr;
      case Prayer.dhuhr:
        return AppLocaleKeys.dhuhrPrayer.tr;
      case Prayer.asr:
        return AppLocaleKeys.asrPrayer.tr;
      case Prayer.maghrib:
        return AppLocaleKeys.maghribPrayer.tr;
      case Prayer.isha:
        return AppLocaleKeys.ishaPrayer.tr;
      default:
        return '';
    }
  }

  String _nextLabel() => AppLocaleKeys.nextPrayerAfterTime.trParams({'time': _fmt(_displayTime).toString()});

  String _windowLabel() {
    if (_previousPrayer == null || _upcomingPrayer == null) return '';
    return AppLocaleKeys.betweenPrayers.trParams({'prev': _name(_previousPrayer!).toString(), 'next': _name(_upcomingPrayer!).toString()});
  }

  IconData _icon(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return Icons.foggy;
      case Prayer.dhuhr:
        return Icons.wb_sunny_outlined;
      case Prayer.asr:
        return Icons.light_mode;
      case Prayer.maghrib:
        return Icons.cloud_outlined;
      case Prayer.isha:
        return Icons.nightlight_round;
      default:
        return Icons.access_time;
    }
  }

  String _time(DateTime? t) =>
      t == null ? '--:--' : (_use24HourFormat ? DateFormat('HH:mm').format(t) : DateFormat('hh:mm a').format(t));

  Future<void> _toggleLanguage() async {
    final cur = Get.locale?.languageCode ?? 'ar';
    final next = cur == 'ar' ? 'en' : 'ar';
    final locale =
        next == 'ar' ? const Locale('ar', 'EG') : const Locale('en', 'US');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language_code', next);
    await Get.updateLocale(locale);
  }

  Widget _circleBtn({required Widget child, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Center(child: child),
        ),
      );

  Widget _prayerItem(Prayer prayer, DateTime? time) {
    final isActive = prayer == _targetPrayer;

    final textColor =
        isActive ? Colors.white : Colors.white.withValues(alpha: 0.82);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _name(prayer),
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              fontFamily: 'Cairo',
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.9),
                  blurRadius: 8,
                ),
                Shadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.26)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  _icon(prayer),
                  color: Colors.black.withValues(alpha: 0.45),
                  size: 18,
                ),
                Icon(_icon(prayer), color: Colors.white, size: 17),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _time(time),
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'Cairo',
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.9),
                  blurRadius: 8,
                ),
                Shadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: isActive ? 14 : 4,
            height: 4,
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }

  Widget _windowItem({
    required String label,
    required DateTime time,
    required bool emphasized,
  }) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: emphasized ? Colors.white : Colors.white70,
              fontSize: emphasized ? 13 : 12,
              fontWeight: FontWeight.w800,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 1),
          Text(
            _time(time),
            style: TextStyle(
              color: emphasized ? Colors.white : Colors.white70,
              fontSize: emphasized ? 20 : 18,
              fontWeight: FontWeight.w800,
              fontFamily: 'Cairo',
              height: 1.0,
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final targetPrayer = _targetPrayer ?? Prayer.none;
    final currentSky = _prayerTimes?.currentPrayer() ?? Prayer.none;
    final activeSky = currentSky == Prayer.none ? Prayer.isha : currentSky;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final headerTotalHeight = screenHeight * 0.45;
    final headerBgHeight = headerTotalHeight - 34;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        height: headerTotalHeight,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // ── Clipped background ──────────────────────────────────────
            ClipPath(
              clipper: _HeaderClipper(),
              child: SizedBox(
                height: headerBgHeight,
                width: double.infinity,
                child: Stack(
                  children: [
                    // 1) السماء الديناميكية
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _skyAnim,
                        builder: (_, __) => CustomPaint(
                          painter: PrayerSkyPainter(
                            prayer: activeSky,
                            isDark: isDark,
                            animValue: _skyAnim.value,
                          ),
                        ),
                      ),
                    ),
                    // 2) تعتيم للنصوص
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.08),
                              Colors.black.withValues(alpha: 0.28),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // 3) نمط الخلفية
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.04,
                        child: Image.asset('assets/background.png',
                            fit: BoxFit.cover),
                      ),
                    ),
                    // 4) المحتوى — Positioned.fill يحدد الـ height بالكامل
                    Positioned.fill(
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 84),
                          child: Column(
                            children: [
                              // ── Top bar ─────────────────────────────────
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: widget.onHijriTapped,
                                      child: Text(
                                        widget.hijriString,
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      _circleBtn(
                                        onTap: () => themeProvider.setThemeMode(
                                            isDark
                                                ? ThemeMode.light
                                                : ThemeMode.dark),
                                        child: Icon(
                                          isDark
                                              ? Icons.light_mode_rounded
                                              : Icons.dark_mode_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _circleBtn(
                                        onTap: _toggleLanguage,
                                        child: Text(
                                          Get.locale?.languageCode == 'ar'
                                              ? 'EN'
                                              : 'AR',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _circleBtn(
                                        onTap: widget.onMenuTapped,
                                        child: const Icon(Icons.menu_rounded,
                                            color: Colors.white, size: 22),
                                      ),
                                      const SizedBox(width: 8),
                                      _circleBtn(
                                        onTap: widget.onBellTapped,
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            const Icon(
                                                Icons
                                                    .notifications_none_rounded,
                                                color: Colors.white,
                                                size: 22),
                                            if (widget
                                                    .unreadNotificationsCount >
                                                0)
                                              Positioned(
                                                top: 1,
                                                left: 1,
                                                child: Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Color(0xFFE53935),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              // ── Prayer content ───────────────────────────
                              if (_prayerTimes == null)
                                const Expanded(
                                  child: Center(
                                    child: CircularProgressIndicator(
                                        color: Colors.white),
                                  ),
                                )
                              else ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(_name(targetPrayer),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          fontFamily: 'Cairo',
                                        )),
                                    const SizedBox(width: 8),
                                    Icon(_icon(targetPrayer),
                                        color: Colors.white, size: 20),
                                  ],
                                ),

                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _time(_prayerTimes
                                          ?.timeForPrayer(targetPrayer)),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 42,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Cairo',
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                ),

                                Text(_nextLabel(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Cairo',
                                    )),

                                const SizedBox(height: 4),

                                if (_previousPrayer != null &&
                                    _upcomingPrayer != null &&
                                    _previousPrayerTime != null &&
                                    _upcomingPrayerTime != null)
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _windowLabel(),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.10),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _windowItem(
                                              label: _name(_previousPrayer!),
                                              time: _previousPrayerTime!,
                                              emphasized: false,
                                            ),
                                            Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12),
                                              width: 6,
                                              height: 6,
                                              decoration: const BoxDecoration(
                                                color: Colors.white54,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            _windowItem(
                                              label: _name(_upcomingPrayer!),
                                              time: _upcomingPrayerTime!,
                                              emphasized: true,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                const Spacer(),

                                // ── الصلوات الخمس ──────────────────────────
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                        child: _prayerItem(
                                            Prayer.fajr, _prayerTimes?.fajr)),
                                    Expanded(
                                        child: _prayerItem(
                                            Prayer.dhuhr, _prayerTimes?.dhuhr)),
                                    Expanded(
                                        child: _prayerItem(
                                            Prayer.asr, _prayerTimes?.asr)),
                                    Expanded(
                                        child: _prayerItem(Prayer.maghrib,
                                            _prayerTimes?.maghrib)),
                                    Expanded(
                                        child: _prayerItem(
                                            Prayer.isha, _prayerTimes?.isha)),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── FAB ────────────────────────────────────────────────────
            Positioned(
              bottom: 6,
              child: GestureDetector(
                onTap: widget.onCenterButtonTapped,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF34A890), Color(0xFF117365)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF117365).withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.tune_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..lineTo(0, size.height - 36);
    path.quadraticBezierTo(20, size.height - 12, 45, size.height - 12);
    path.lineTo(size.width / 2 - 50, size.height - 12);
    path.quadraticBezierTo(
      size.width / 2 - 35,
      size.height - 12,
      size.width / 2 - 35,
      size.height - 30,
    );
    path.arcToPoint(
      Offset(size.width / 2 + 35, size.height - 30),
      radius: const Radius.circular(38),
      clockwise: false,
    );
    path.quadraticBezierTo(
      size.width / 2 + 35,
      size.height - 12,
      size.width / 2 + 50,
      size.height - 12,
    );
    path.lineTo(size.width - 45, size.height - 12);
    path.quadraticBezierTo(
      size.width - 20,
      size.height - 12,
      size.width,
      size.height - 36,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
