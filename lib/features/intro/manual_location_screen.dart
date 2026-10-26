import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/widgets/glass_card.dart';
import '../prayers/logic/prayer_times_controller.dart';
import '../../../core/services/background_service.dart';
import '../../core/translations/app_locale_keys.dart';

class ManualLocationScreen extends StatefulWidget {
  const ManualLocationScreen({super.key});

  @override
  State<ManualLocationScreen> createState() => _ManualLocationScreenState();
}

class _ManualLocationScreenState extends State<ManualLocationScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _successMsg;

  Future<void> _searchAndSaveLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _error = AppLocaleKeys.pleaseEnterCity.tr);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _successMsg = null;
    });

    try {
      List<Location> locations = await locationFromAddress(query);

      if (locations.isNotEmpty) {
        final loc = locations.first;
        
        List<Placemark> placemarks = await placemarkFromCoordinates(loc.latitude, loc.longitude);
        String finalCity = query;
        String finalCountry = '';
        
        if (placemarks.isNotEmpty) {
           final p = placemarks.first;
           finalCity = p.locality ?? p.subAdministrativeArea ?? query;
           finalCountry = p.country ?? '';
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('cached_lat', loc.latitude);
        await prefs.setDouble('cached_lng', loc.longitude);
        await prefs.setString('cached_city', finalCity);
        await prefs.setString('cached_country', finalCountry);
        
        await prefs.setBool('manual_location_chosen', true);
        await prefs.setString('manual_city', finalCity);
        await prefs.setString('manual_country', finalCountry);

        setState(() {
          _successMsg = AppLocaleKeys.locationSetSuccess.trParams({'city': finalCity.toString(), 'country': finalCountry.toString()});
        });

        try {
          final controller = PrayerTimesController();
          await controller.fetchFreshLocationAndUpdate();
        } catch (_) {}
        
        try {
           await BackgroundService.startService();
        } catch (_) {}

        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
           Navigator.pop(context, true);
        }

      } else {
        setState(() => _error = AppLocaleKeys.couldNotFindLocation.tr);
      }
    } catch (e) {
      setState(() => _error = AppLocaleKeys.errorSearchingLocation.tr);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentGold = isDark ? const Color(0xFFD4AF37) : const Color(0xFFC4971A);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            AppLocaleKeys.setLocationManuallyTitle.tr,
            style: TextStyle(
              color: textColor,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: IconThemeData(color: textColor),
        ),
        body: Stack(
          children: [
            Container(
              decoration: isDark
                  ? const BoxDecoration(
                      image: DecorationImage(
                          image: AssetImage('assets/background.png'),
                          fit: BoxFit.cover),
                    )
                  : BoxDecoration(color: Colors.grey[100]),
            ),
            if (isDark)
              Container(color: const Color(0xFF071814).withOpacity(0.85)),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Icon(FontAwesomeIcons.earthAfrica,
                        size: 80, color: accentGold.withOpacity(0.8)),
                    const SizedBox(height: 30),
                    Text(
                      AppLocaleKeys.searchCityHint.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontFamily: 'Cairo',
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            style: TextStyle(color: textColor, fontFamily: 'Cairo'),
                            decoration: InputDecoration(
                              hintText: AppLocaleKeys.exampleCityHint.tr,
                              hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                              prefixIcon: Icon(Icons.search, color: accentGold),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSubmitted: (_) => _searchAndSaveLocation(),
                          ),
                          const SizedBox(height: 20),
                          if (_error != null)
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(
                                          color: Colors.red, fontFamily: 'Cairo'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_successMsg != null)
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.green.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline,
                                      color: Colors.green),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _successMsg!,
                                      style: const TextStyle(
                                          color: Colors.green, fontFamily: 'Cairo'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _searchAndSaveLocation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentGold,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.black)
                                  : Text(
                                      AppLocaleKeys.searchAndSaveAction.tr,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                            ),
                          ),
                        ],
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
}
