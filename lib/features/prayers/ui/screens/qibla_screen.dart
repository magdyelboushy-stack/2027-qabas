import 'dart:math' as math;
import 'dart:ui';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../../../../core/translations/app_locale_keys.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  double? _heading;
  double? _qiblaDirection;
  bool _isLoading = true;
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = _t(
      ar: AppLocaleKeys.detectingLocation.tr,
      en: 'Detecting your location...',
    );
    _initQibla();
  }

  String _t({required String ar, required String en}) {
    return Get.locale?.languageCode == 'en' ? en : ar;
  }

  bool get _isArabic => Get.locale?.languageCode == 'ar';

  Future<void> _initQibla() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _status = _t(
                ar: AppLocaleKeys.pleaseEnableLocation.tr,
                en: 'Please enable location permission',
              );
              _isLoading = false;
            });
          }
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition();
      final coordinates = Coordinates(position.latitude, position.longitude);
      final qibla = Qibla(coordinates);

      if (mounted) {
        setState(() {
          _qiblaDirection = qibla.direction;
          _isLoading = false;
          _status = _t(
            ar: AppLocaleKeys.calibrateCompassHint.tr,
            en: 'Move your phone in a figure 8 to calibrate the compass',
          );
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _status = _t(
            ar: AppLocaleKeys.failedDetermineLocationGps.tr,
            en: 'Unable to detect location. Please enable GPS',
          );
          _isLoading = false;
        });
      }
    }

    FlutterCompass.events?.listen((CompassEvent event) {
      if (mounted) {
        setState(() {
          _heading = event.heading;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF17332D);
    final subTextColor =
        isDark ? Colors.white.withOpacity(0.72) : const Color(0xFF617770);
    final accentColor =
        isDark ? const Color(0xFF79D8C4) : const Color(0xFF157C6D);

    return Directionality(
      textDirection: Get.locale?.languageCode == 'en'
          ? TextDirection.ltr
          : TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            _t(ar: AppLocaleKeys.qiblaDirectionTitle.tr, en: 'Qibla Direction'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              _isArabic
                  ? Icons.arrow_back_ios_new_rounded
                  : Icons.arrow_forward_ios_rounded,
              color: textColor,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Stack(
          children: [
            Container(
              decoration: isDark
                  ? const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF153C34), Color(0xFF0D2722)],
                      ),
                    )
                  : const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFF8FCFB), Color(0xFFE7F2EE)],
                      ),
                    ),
            ),
            if (isDark)
              Container(
                color: const Color(0xFF071C18).withOpacity(0.88),
              ),
            SafeArea(
              child: Center(
                child: _isLoading
                    ? CircularProgressIndicator(color: accentColor)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildCompass(isDark, textColor, accentColor),
                          const SizedBox(height: 32),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 26),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.06)
                                  : Colors.white.withOpacity(0.78),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : const Color(0xFFDCEBE5),
                              ),
                            ),
                            child: Text(
                              _status,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompass(bool isDark, Color textColor, Color accentColor) {
    if (_heading == null || _qiblaDirection == null) {
      return Text(
        _t(ar: AppLocaleKeys.processingCompass.tr, en: 'Preparing the compass...'),
        style: TextStyle(color: textColor),
      );
    }

    final compassRotation = -_heading! * (math.pi / 180);
    final qiblaRotation = _qiblaDirection! * (math.pi / 180);

    final compassBgColor =
        isDark ? const Color(0xFF17332D).withOpacity(0.94) : Colors.white;
    final compassBorderColor =
        isDark ? Colors.white.withOpacity(0.14) : const Color(0xFFD7E8E1);
    final compassShadow = isDark
        ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ]
        : [
            BoxShadow(
              color: const Color(0xFF0A5448).withOpacity(0.12),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ];

    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: compassRotation,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: compassBgColor,
              gradient: isDark
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.08),
                        Colors.white.withOpacity(0.03),
                      ],
                    )
                  : null,
              border: Border.all(color: compassBorderColor, width: 2),
              boxShadow: compassShadow,
            ),
            child: Stack(
              children: [
                _buildCompassDirection(
                    'N', Alignment.topCenter, Colors.redAccent),
                _buildCompassDirection(
                  'S',
                  Alignment.bottomCenter,
                  textColor.withOpacity(0.5),
                ),
                _buildCompassDirection(
                  'E',
                  Alignment.centerRight,
                  textColor.withOpacity(0.5),
                ),
                _buildCompassDirection(
                  'W',
                  Alignment.centerLeft,
                  textColor.withOpacity(0.5),
                ),
                Transform.rotate(
                  angle: qiblaRotation,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Column(
                        children: [
                          Icon(Icons.mosque, color: accentColor, size: 40),
                          Container(
                            width: 2,
                            height: 30,
                            decoration: BoxDecoration(
                              color: accentColor,
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.8),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Icon(Icons.arrow_drop_up, color: textColor, size: 50),
        ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.white.withOpacity(0.92),
                shape: BoxShape.circle,
                border: Border.all(color: compassBorderColor),
              ),
              child: Center(
                child: Icon(Icons.location_on, color: accentColor, size: 30),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompassDirection(String text, Alignment alignment, Color color) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
