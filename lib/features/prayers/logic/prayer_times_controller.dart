import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerTimesController {
  // Default coordinates (Hawamdia) if no prior data exists
  static final Coordinates _defaultCoords = Coordinates(29.8467, 31.3567);

  // 1. Fast retrieval of stored or default times
  Future<PrayerTimes> getStoredOrDefaultPrayerTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final double? lat = prefs.getDouble('cached_lat');
    final double? lng = prefs.getDouble('cached_lng');

    Coordinates coords;
    if (lat != null && lng != null) {
      coords = Coordinates(lat, lng);
    } else {
      coords = _defaultCoords;
    }

    return _calculateTimes(coords, prefs);
  }

  Future<PrayerTimes> getPrayerTimesForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final double? lat = prefs.getDouble('cached_lat');
    final double? lng = prefs.getDouble('cached_lng');
    Coordinates coords;
    if (lat != null && lng != null) {
      coords = Coordinates(lat, lng);
    } else {
      coords = _defaultCoords;
    }
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
      case 'singapore': method = CalculationMethod.singapore; break;
      case 'tehran': method = CalculationMethod.tehran; break;
      case 'turkey': method = CalculationMethod.turkey; break;
      default: method = CalculationMethod.egyptian;
    }
    final params = method.getParameters();
    final madhabId = prefs.getString('madhab') ?? 'shafi';
    params.madhab = madhabId == 'hanafi' ? Madhab.hanafi : Madhab.shafi;
    final offsetFajr = prefs.getInt('offset_fajr') ?? 0;
    final offsetSunrise = prefs.getInt('offset_sunrise') ?? 0;
    final offsetDhuhr = prefs.getInt('offset_dhuhr') ?? 0;
    final offsetAsr = prefs.getInt('offset_asr') ?? 0;
    final offsetMaghrib = prefs.getInt('offset_maghrib') ?? 0;
    final offsetIsha = prefs.getInt('offset_isha') ?? 0;
    params.adjustments.fajr = offsetFajr;
    params.adjustments.sunrise = offsetSunrise;
    params.adjustments.dhuhr = offsetDhuhr;
    params.adjustments.asr = offsetAsr;
    params.adjustments.maghrib = offsetMaghrib;
    params.adjustments.isha = offsetIsha;

    // ✅ Fix for accuracy: High latitude rule and precise angles for Egypt
    if (methodId == 'egyptian') {
      params.highLatitudeRule = HighLatitudeRule.twilight_angle;
    }

    final dc = DateComponents(date.year, date.month, date.day);
    return PrayerTimes(coords, dc, params);
  }

  // 2. Background fresh location update
  Future<PrayerTimes?> fetchFreshLocationAndUpdate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final manualChosen = prefs.getBool('manual_location_chosen') ?? false;
      if (manualChosen) {
        return null;
      }
      
      Position position = await _determinePosition();

      await prefs.setDouble('cached_lat', position.latitude);
      await prefs.setDouble('cached_lng', position.longitude);

      return _calculateTimes(Coordinates(position.latitude, position.longitude), prefs);
    } catch (e) {
      return null;
    }
  }

  // ✅ Dynamic Calculation
  PrayerTimes _calculateTimes(Coordinates coords, SharedPreferences prefs) {
    // 1. Get Calculation Method
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
      case 'singapore': method = CalculationMethod.singapore; break;
      case 'tehran': method = CalculationMethod.tehran; break;
      case 'turkey': method = CalculationMethod.turkey; break;
      default: method = CalculationMethod.egyptian;
    }

    final params = method.getParameters();

    // 2. Get Madhab
    final madhabId = prefs.getString('madhab') ?? 'shafi';
    params.madhab = madhabId == 'hanafi' ? Madhab.hanafi : Madhab.shafi;

    // 3. Get Offsets (Minutes)
    final offsetFajr = prefs.getInt('offset_fajr') ?? 0;
    final offsetSunrise = prefs.getInt('offset_sunrise') ?? 0;
    final offsetDhuhr = prefs.getInt('offset_dhuhr') ?? 0;
    final offsetAsr = prefs.getInt('offset_asr') ?? 0;
    final offsetMaghrib = prefs.getInt('offset_maghrib') ?? 0;
    final offsetIsha = prefs.getInt('offset_isha') ?? 0;

    // Apply adjustments
    params.adjustments.fajr = offsetFajr;
    params.adjustments.sunrise = offsetSunrise;
    params.adjustments.dhuhr = offsetDhuhr;
    params.adjustments.asr = offsetAsr;
    params.adjustments.maghrib = offsetMaghrib;
    params.adjustments.isha = offsetIsha;

    // ✅ Fix for accuracy: High latitude rule and precise angles for Egypt
    if (methodId == 'egyptian') {
      params.highLatitudeRule = HighLatitudeRule.twilight_angle;
    }

    return PrayerTimes.today(coords, params);
  }

  // Permissions handling
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('GPS disabled');

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) throw Exception('Permission denied');
    }
    if (permission == LocationPermission.deniedForever) throw Exception('Permission denied forever');

    return await Geolocator.getCurrentPosition();
  }

  // Auto-update location daily or on demand
  Future<bool> updateLocationAutomatically() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final manualChosen = prefs.getBool('manual_location_chosen') ?? false;

      if (manualChosen) return false;

      Position position = await _determinePosition();
      await prefs.setDouble('cached_lat', position.latitude);
      await prefs.setDouble('cached_lng', position.longitude);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Reset location to default (Hawamdia)
  Future<void> resetLocationToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('cached_lat', _defaultCoords.latitude);
    await prefs.setDouble('cached_lng', _defaultCoords.longitude);
    await prefs.setBool('manual_location_chosen', false);
    await prefs.remove('manual_city');
    await prefs.remove('manual_country');
    await prefs.remove('cached_city');
    await prefs.remove('cached_country');
  }

  String getArabicPrayerName(Prayer prayer) {
    const names = {
      Prayer.fajr: 'الفجر',
      Prayer.sunrise: 'الشروق',
      Prayer.dhuhr: 'الظهر',
      Prayer.asr: 'العصر',
      Prayer.maghrib: 'المغرب',
      Prayer.isha: 'العشاء',
    };
    return names[prayer] ?? '';
  }
}
