import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../utils/desktop_utils.dart';

class LocationService {
  // ✅ Use same keys as Setup Wizard and BackgroundService
  static const String _latKey = 'cached_lat';
  static const String _longKey = 'cached_lng';

  /// Request permission and save location if successful
  static Future<Map<String, double>?> getAndSaveLocation() async {
    // ✅ On desktop, use default Cairo location (GPS not available)
    if (DesktopUtils.isDesktop) {
      final prefs = await SharedPreferences.getInstance();
      const defaultLat = 30.0444;
      const defaultLng = 31.2357;
      await prefs.setDouble(_latKey, defaultLat);
      await prefs.setDouble(_longKey, defaultLng);
      await prefs.setString('cached_city', 'Cairo');
      return {'latitude': defaultLat, 'longitude': defaultLng};
    }

    // ✅ Don't request location if user chose manual location
    final prefs = await SharedPreferences.getInstance();
    final manualChosen = prefs.getBool('manual_location_chosen') ?? false;
    if (manualChosen) {
      return null;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('❌ Location services are disabled.');
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('❌ Location permissions are denied');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    Position? position;
    try {
      // 🚀 Strategy 1: Try Last Known Location (Instant)
      position = await Geolocator.getLastKnownPosition();

      // 🚀 Strategy 2: If null, try Current Location with Timeout
      position ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // Medium is faster/reliable
        timeLimit: const Duration(seconds: 5),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('❌ Error getting location: $e');
    }

    // 🚀 Strategy 3: Fallback to Cairo if everything fails
    if (position == null) {
      debugPrint('⚠️ Using Default Location (Cairo)');
      position = Position(
          longitude: 31.2357,
          latitude: 30.0444,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0);
    }

    // 4. Save coordinates
    await prefs.setDouble(_latKey, position.latitude);
    await prefs.setDouble(_longKey, position.longitude);

    // 5. Get region name (Geocoding)
    String? regionName;
    try {
      // ✅ Optimize: Add 3 seconds timeout to prevent blocking UI
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 3));

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        regionName = place.locality ??
            place.subAdministrativeArea ??
            place.administrativeArea ??
            "Current Location";
        await prefs.setString('cached_city', regionName);
      }
    } catch (e) {
      debugPrint('❌ Error or Timeout geocoding: $e');
      // If geocoding fails, use generic name or old cached one
      regionName = prefs.getString('cached_city') ?? "الموقع الحالي";
    }

    debugPrint(
        '✅ Location saved: ${position.latitude}, ${position.longitude}, Region: $regionName');

    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
    };
  }

  /// استرجاع الموقع المحفوظ
  static Future<Map<String, double>?> getSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_latKey);
    final long = prefs.getDouble(_longKey);

    if (lat != null && long != null) {
      return {'latitude': lat, 'longitude': long};
    }
    return null;
  }
}
