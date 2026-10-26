import 'dart:async';
// ✅ Added for Circular Design
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Required for caching
// ✅ For reschedule
import '../../../../core/theme/theme_provider.dart';
import '../../../settings/ui/screens/unified_prayer_settings_screen.dart'; // ✅ Import Unified Settings
import '../../../prayers/ui/screens/prayer_countdown_screen.dart'; // ✅ Import new detailing screen
import 'package:get/get.dart';
import '../../../../core/translations/app_locale_keys.dart';

class PrayerTimesCard extends StatefulWidget {
  const PrayerTimesCard({super.key});

  @override
  State<PrayerTimesCard> createState() => _PrayerTimesCardState();
}

class _PrayerTimesCardState extends State<PrayerTimesCard> {
  PrayerTimes? _prayerTimes;
  Prayer? _targetPrayer;
  bool _use24HourFormat = true;

  Timer? _timer;
  Duration _displayTime = Duration.zero;
  bool _isIqamaMode = false;
  String _statusText = AppLocaleKeys.loadingText.tr; // نص مؤقت سيختفي بسرعة
  double _progressValue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTimeFormat();
    // 1. Load cached data immediately
    _loadCachedPrayerTimes();

    // 2. Fetch updated location in background
    _fetchPrayerTimes();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) _updateLogic();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadTimeFormat() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _use24HourFormat = prefs.getBool('time_format_24hour') ?? true;
    });
  }

  // New: Load from cache
  Future<void> _loadCachedPrayerTimes() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ Check if manual location is set
      final isManual = prefs.getBool('manual_location_chosen') ?? false;

      if (isManual) {
        final double? lat = prefs.getDouble('cached_lat');
        final double? lng = prefs.getDouble('cached_lng');
        if (lat != null && lng != null) {
          _calculateAndSet(lat, lng);
          return;
        }
      }

      // ✅ Fallback to cached GPS
      final double? lat = prefs.getDouble('cached_lat');
      final double? lng = prefs.getDouble('cached_lng');

      if (lat != null && lng != null) {
        _calculateAndSet(lat, lng);
      }
    } catch (_) {}
  }

  Future<void> _calculateAndSet(double lat, double lng) async {
    // ✅ Use Controller to get consistent calculation parameters (Method, Madhab, Offsets)
    final prefs = await SharedPreferences.getInstance();

    // We manually construct the params here using the same logic as the Controller
    // to ensure consistency without refactoring the entire Controller to accept custom coords easily
    // OR better: Instantiate Controller and use a helper if available, but for now let's mirror logic
    // to be safe and quick, consistent with `PrayerTimesController._calculateTimes`

    final methodId = prefs.getString('calculation_method') ?? 'egyptian';
    CalculationMethod method = CalculationMethod.egyptian;
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

    // ✅ offsets
    params.adjustments.fajr = prefs.getInt('offset_fajr') ?? 0;
    params.adjustments.sunrise = prefs.getInt('offset_sunrise') ?? 0;
    params.adjustments.dhuhr = prefs.getInt('offset_dhuhr') ?? 0;
    params.adjustments.asr = prefs.getInt('offset_asr') ?? 0;
    params.adjustments.maghrib = prefs.getInt('offset_maghrib') ?? 0;
    params.adjustments.isha = prefs.getInt('offset_isha') ?? 0;

    final coords = Coordinates(lat, lng);

    if (mounted) {
      setState(() {
        _prayerTimes = PrayerTimes.today(coords, params);
      });
      _updateLogic();
    }
  }

  Future<void> _fetchPrayerTimes() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ 1. Check if user skipped location setup
      final skipped = prefs.getBool('location_skipped') ?? false;
      if (skipped) {
        // Don't fetch GPS, just return (UI will show prompt)
        return;
      }

      // ✅ 2. Check manual location
      final manualChosen = prefs.getBool('manual_location_chosen') ?? false;
      if (manualChosen) {
        // Just refresh logic from stored manual coords
        _loadCachedPrayerTimes();
        return;
      }

      // ✅ 3. Fetch GPS
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition();
      await prefs.setDouble('cached_lat', position.latitude);
      await prefs.setDouble('cached_lng', position.longitude);

      _calculateAndSet(position.latitude, position.longitude);
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

    final currentPrayer = _prayerTimes!.currentPrayer();
    final nextPrayer = _prayerTimes!.nextPrayer();

    // 1. منطق الإقامة (15 دقيقة / 10 دقائق)
    if (currentPrayer != Prayer.none && currentPrayer != Prayer.sunrise) {
      final prayerTime = _prayerTimes!.timeForPrayer(currentPrayer)!;
      final timePassed = now.difference(prayerTime);
      int iqamaMinutes = (currentPrayer == Prayer.maghrib) ? 10 : 15;

      if (timePassed.inMinutes < iqamaMinutes) {
        setState(() {
          _isIqamaMode = true;
          _targetPrayer = currentPrayer;
          _displayTime = timePassed;
          _statusText = AppLocaleKeys.prayerPassedSince.tr;
          _progressValue = timePassed.inSeconds / (iqamaMinutes * 60);
        });
        return;
      }
    }

    // 2. منطق الصلاة القادمة
    setState(() {
      _isIqamaMode = false;
      _statusText = AppLocaleKeys.remainingForPrayer.tr;

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

      // Prevent division by zero
      int totalSeconds = nextTime.difference(prevTime).inSeconds;
      if (totalSeconds == 0) totalSeconds = 1;

      int elapsedSeconds = now.difference(prevTime).inSeconds;
      _progressValue = (elapsedSeconds / totalSeconds).clamp(0.0, 1.0);
    });
  }

  Prayer _getPrevPrayer(Prayer p) {
    switch (p) {
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

  @override
  Widget build(BuildContext context) {
    final isDark =
        Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark;

    final cardColor = isDark ? const Color(0xFF0A1128) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final accentColor =
        _isIqamaMode ? const Color(0xFF00E676) : const Color(0xFFFFD700);
    final secondaryTextColor = isDark ? Colors.white54 : Colors.black45;

    // ✅ Show "Select Location" Prompt if no prayer times
    if (_prayerTimes == null) {
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off_rounded,
                size: 40, color: Colors.grey),
            const SizedBox(height: 10),
            Text(AppLocaleKeys.locationNotSetMsg.tr,
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            ElevatedButton(
              onPressed: () {
                // ✅ Navigate to Unified Prayer Settings (which contains Manual Location)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const UnifiedPrayerSettingsScreen()),
                ).then((_) => _loadCachedPrayerTimes()); // Refresh on return
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700)),
              child: Text(AppLocaleKeys.setNowBtn.tr,
                  style: TextStyle(color: Colors.black)),
            )
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          splashColor:
              const Color(0xFFFFD700).withOpacity(0.2), // ✅ Golden Splash
          highlightColor: const Color(0xFFFFD700).withOpacity(0.1),
          onTap: () {
            // ✅ Navigate to the Circular Detail Screen when tapped
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const PrayerCountdownScreen()),
            ).then((_) => _loadCachedPrayerTimes());
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 1. Top Section
                // 1. Top Section (Reverted to Linear Design)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                                _isIqamaMode ? Icons.mosque : Icons.access_time,
                                color: accentColor,
                                size: 16),
                            const SizedBox(width: 5),
                            Text(_statusText,
                                style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _formatDuration(_displayTime),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(_getPrayerIcon(_targetPrayer ?? Prayer.none),
                            color: accentColor, size: 32),
                        const SizedBox(height: 5),
                        Text(
                          _getPrayerName(_targetPrayer ?? Prayer.none),
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  ],
                ),

                const SizedBox(height: 20),

                // 2. Progress Bar (Reverted to Linear)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value:
                        _isIqamaMode ? _progressValue : (1.0 - _progressValue),
                    backgroundColor:
                        isDark ? Colors.white10 : Colors.grey.shade200,
                    color: accentColor,
                    minHeight: 6,
                  ),
                ),

                const SizedBox(height: 20),

                // 3. Prayers List (Reverted spacing)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: _buildPrayerItem(
                            Prayer.fajr, AppLocaleKeys.fajrPrayer.tr, isDark, accentColor)),
                    Expanded(
                        child: _buildPrayerItem(
                            Prayer.dhuhr, AppLocaleKeys.dhuhrPrayer.tr, isDark, accentColor)),
                    Expanded(
                        child: _buildPrayerItem(
                            Prayer.asr, AppLocaleKeys.asrPrayer.tr, isDark, accentColor)),
                    Expanded(
                        child: _buildPrayerItem(
                            Prayer.maghrib, AppLocaleKeys.maghribPrayer.tr, isDark, accentColor)),
                    Expanded(
                        child: _buildPrayerItem(
                            Prayer.isha, AppLocaleKeys.ishaPrayer.tr, isDark, accentColor)),
                  ],
                ),

                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerItem(
      Prayer p, String name, bool isDark, Color accentColor) {
    bool isActive = p == _targetPrayer;

    return Column(
      children: [
        Text(
          name,
          style: TextStyle(
            color: isActive
                ? accentColor
                : (isDark ? Colors.white38 : Colors.black38),
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? accentColor.withOpacity(0.2) : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive
                  ? accentColor
                  : (isDark ? Colors.white10 : Colors.black12),
            ),
          ),
          child: Icon(
            _getPrayerIcon(p),
            size: 14,
            color: isActive
                ? accentColor
                : (isDark ? Colors.white38 : Colors.black38),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _use24HourFormat
            ? DateFormat('HH:mm', 'ar').format(_prayerTimes!.timeForPrayer(p)!)
            : DateFormat('hh:mm a', 'ar').format(_prayerTimes!.timeForPrayer(p)!),
          style: TextStyle(
            color: isActive
                ? accentColor
                : (isDark ? Colors.white30 : Colors.black26),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  String _getPrayerName(Prayer p) {
    switch (p) {
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
        return "";
    }
  }

  IconData _getPrayerIcon(Prayer p) {
    switch (p) {
      case Prayer.fajr:
        return FontAwesomeIcons.cloudSun;
      case Prayer.sunrise:
        return FontAwesomeIcons.sun;
      case Prayer.dhuhr:
        return FontAwesomeIcons.solidSun;
      case Prayer.asr:
        return FontAwesomeIcons.cloudSun;
      case Prayer.maghrib:
        return FontAwesomeIcons.cloudMoon;
      case Prayer.isha:
        return FontAwesomeIcons.moon;
      default:
        return FontAwesomeIcons.clock;
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }
}
