import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/translations/app_locale_keys.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/services/location_service.dart';
import '../../../prayers/logic/prayer_times_controller.dart';
import 'package:adhan/adhan.dart'; // Ensure adhan is imported

class NearbyMosquesScreen extends StatefulWidget {
  const NearbyMosquesScreen({super.key});

  @override
  State<NearbyMosquesScreen> createState() => _NearbyMosquesScreenState();
}

class _NearbyMosquesScreenState extends State<NearbyMosquesScreen> {
  Map<String, double>? _currentLocation;
  bool _isLoading = true;
  PrayerTimes? _prayerTimes;

  @override
  void initState() {
     super.initState();
     _loadData();
  }

  Future<void> _loadData() async {
    // 1. Get Location
    final loc = await LocationService.getAndSaveLocation();
    
    // 2. Get Prayer Times
    final controller = PrayerTimesController();
    final times = await controller.getStoredOrDefaultPrayerTimes();
    
    if (mounted) {
      setState(() {
        _currentLocation = loc;
        _prayerTimes = times;
        _isLoading = false;
      });
    }
  }

  Future<void> _launchMaps() async {
    if (_currentLocation == null) return;
    
    final lat = _currentLocation!['latitude'];
    final lng = _currentLocation!['longitude'];
    
    // Geo URI for searching mosques nearby
    final Uri uri = Uri.parse("geo:$lat,$lng?q=mosques");
    
    // Fallback web URL if geo intent fails
    final Uri webUri = Uri.parse("https://www.google.com/maps/search/mosques/@$lat,$lng,15z");

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Error launching map: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark;
    
    return Scaffold(
       backgroundColor: isDark ? const Color(0xFF071814) : const Color(0xFFF5F5F5),
       appBar: AppBar(
         title: Text(AppLocaleKeys.nearbyMosques.tr),
         backgroundColor: Colors.transparent,
         elevation: 0,
         centerTitle: true,
       ),
       body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 1. Header Card (Location & Action)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                       colors: [Color(0xFF1E4D3E), Color(0xFF0E241E)],
                       begin: Alignment.topLeft,
                       end: Alignment.bottomRight
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.mosque, size: 50, color: Color(0xFFFFD700)),
                      const SizedBox(height: 15),
                      Text(
                        AppLocaleKeys.searchNearbyMosques.tr,
                         style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        AppLocaleKeys.mapDescription.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _launchMaps,
                          icon: const Icon(Icons.map, color: Colors.black),
                          label: Text(AppLocaleKeys.showOnMap.tr, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD700),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 25),
                
                // 2. Estimated Iqama Times
                if (_prayerTimes != null) ...[
                   Align(
                     alignment: Alignment.centerRight, 
                     child: Text(
                       AppLocaleKeys.suggestedIqamaTimes.tr, 
                       style: TextStyle(
                         fontSize: 18, 
                         fontWeight: FontWeight.bold, 
                         color: isDark ? Colors.white : Colors.black
                        )
                      )
                   ),
                   const SizedBox(height: 10),
                   _buildIqamaCard(AppLocaleKeys.fajr.tr, _prayerTimes!.fajr, 20, isDark),
                   _buildIqamaCard(AppLocaleKeys.dhuhr.tr, _prayerTimes!.dhuhr, 15, isDark),
                   _buildIqamaCard(AppLocaleKeys.asr.tr, _prayerTimes!.asr, 15, isDark),
                   _buildIqamaCard(AppLocaleKeys.maghrib.tr, _prayerTimes!.maghrib, 10, isDark),
                   _buildIqamaCard(AppLocaleKeys.isha.tr, _prayerTimes!.isha, 15, isDark),
                ]
              ],
            ),
        ),
    );
  }

  Widget _buildIqamaCard(String name, DateTime azanTime, int iqamaOffsetMinutes, bool isDark) {
     final iqamaTime = azanTime.add(Duration(minutes: iqamaOffsetMinutes));
     final dateFormat = DateFormat('h:mm a', 'ar');
     
     return Container(
       margin: const EdgeInsets.only(bottom: 10),
       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
       decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
       ),
       child: Row(
         mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
            Row(children: [
              Icon(Icons.access_time_filled, color: isDark ? Colors.cyanAccent : const Color(0xFF1E4D3E), size: 20),
              const SizedBox(width: 10),
              Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            ]),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("${AppLocaleKeys.adhanTimeLabel.tr} ${dateFormat.format(azanTime)}", style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text("${AppLocaleKeys.iqamaTimeLabel.tr} ${dateFormat.format(iqamaTime)}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFFFFD700))),
              ],
            )
         ],
       ),
     );
  }
}
