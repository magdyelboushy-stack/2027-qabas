import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart' as fg;
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // ✅ Import FLN
import 'package:mihrab/core/services/location_service.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/desktop_utils.dart';

import 'package:flutter/services.dart'; // ✅ Import MethodChannel
import 'package:permission_handler/permission_handler.dart'; // ✅ Import permission handler

// The callback function should always be a top-level function.
@pragma('vm:entry-point')
void startCallback() {
  fg.FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

// ✅ Top-level callback for FLN Background Actions
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  // Ensure we can call platform channels
  WidgetsFlutterBinding.ensureInitialized();
  
  if (notificationResponse.actionId == 'update_location') {
      // Attempt to get location in background
      final loc = await LocationService.getAndSaveLocation();
      if (loc != null) {
        debugPrint("📍 NEW BACKGROUND LOCATION: Lat=${loc['latitude']}, Long=${loc['longitude']}");
      } else {
        debugPrint("❌ Failed to get location in background");
      }
  } else if (notificationResponse.actionId == 'stop_service') {
      debugPrint("🛑 STOPPING SERVICE FROM BACKGROUND TAP");
      await fg.FlutterForegroundTask.stopService();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('persistent_notification_enabled', false);
  }
}

class BackgroundService {
  static Future<void> init() async {
    // ✅ Skip on desktop platforms (foreground task not supported)
    if (DesktopUtils.isDesktop) return;
    fg.FlutterForegroundTask.init(
      androidNotificationOptions: fg.AndroidNotificationOptions(
        channelId: 'qabas_prayer_service',
        channelName: 'Qabas Prayer Service',
        channelDescription: 'Service to show prayer times and location',
        channelImportance: fg.NotificationChannelImportance.LOW, // ✅ Changed to LOW (Visible but silent)
        priority: fg.NotificationPriority.LOW,
        visibility: fg.NotificationVisibility.VISIBILITY_PUBLIC,
      ),
      iosNotificationOptions: const fg.IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: fg.ForegroundTaskOptions(
        eventAction: fg.ForegroundTaskEventAction.repeat(900000),
        autoRunOnBoot: false,
        allowWakeLock: false,
        allowWifiLock: false,
      ),
    );
  }

  static Future<void> startService() async {
    if (DesktopUtils.isDesktop) return; // ✅ Skip on desktop
    if (await fg.FlutterForegroundTask.isRunningService) {
      await fg.FlutterForegroundTask.stopService();
    }
    
    // ✅ Check permissions before starting to prevent crashes (Android 14+ NPE fix)
    var locationStatus = await Permission.locationAlways.status;
    if (!locationStatus.isGranted) {
      locationStatus = await Permission.locationWhenInUse.status;
    }
    var notificationStatus = await Permission.notification.status;
    
    if (!locationStatus.isGranted || !notificationStatus.isGranted) {
      debugPrint("BackgroundService: Missing permissions. Cannot start service.");
      // Ensure shared prefs state is off
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('persistent_notification_enabled', false);
      } catch (_) {}
      return; // Skip starting service
    }

    debugPrint("BackgroundService: Starting service...");
    try {
      await fg.FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'Qabas Running',
      notificationText: 'Initializing...',
      notificationIcon: const fg.NotificationIcon(
        metaDataName: 'com.pravera.flutter_foreground_task.notification_icon',
      ),
      // We rely on FLN Buttons now, but we keep these just in case.
      notificationButtons: [
        const fg.NotificationButton(id: 'btn_update_location', text: 'Update Location'),
        const fg.NotificationButton(id: 'btn_open_app', text: 'Open Qabas'),
        const fg.NotificationButton(id: 'stop_service', text: 'Stop Service'),
      ],
      callback: startCallback,
    );
    } catch (e) {
      debugPrint("BackgroundService: Error starting service: $e");
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('persistent_notification_enabled', false);
      } catch (_) {}
    }
  }

  static Future<void> stopService() async {
    await fg.FlutterForegroundTask.stopService();
  }
}

class MyTaskHandler extends fg.TaskHandler {
  double? _lat;
  double? _long;
  String _regionName = "Not Determined";
  bool _isStopping = false; // ✅ Guard to prevent re-showing during stop
  DateTime? _lastLocationRefresh;
  
  // ✅ FLN instance
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // ✅ Native Channel
  static const platform = MethodChannel('com.magdy.mihrab/notification');

  @override
  Future<void> onStart(DateTime timestamp, fg.TaskStarter starter) async {
    _isStopping = false; 
    try {
      debugPrint("BackgroundService: onStart called");
      await initializeDateFormatting('ar', null);
      HijriCalendar.setLocal('ar'); // ✅ Force Hijri Arabic

      // ✅ Initialize FLN
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/launcher_icon');
      
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
          
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) async {
             debugPrint("BackgroundService: Notification action received: ${details.actionId}");
             if (details.actionId == 'update_location') {
                 await _refreshLocation();
             } else if (details.actionId == 'open_app' || details.actionId == 'btn_open_app') {
                 fg.FlutterForegroundTask.launchApp();
             } else if (details.actionId == 'stop_service') {
                 debugPrint("BackgroundService: Stopping service via FLN button");
                 _isStopping = true;
                 await fg.FlutterForegroundTask.stopService();
                 final prefs = await SharedPreferences.getInstance();
                 await prefs.setBool('persistent_notification_enabled', false);
             }
        },
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      // Initial load
      await _loadLocation();
      _updateNotification();
    } catch (e) {
      debugPrint("BackgroundService: Error in onStart: $e");
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    if (_isStopping) return; // ✅ Don't update if we are trying to stop
    
    // ✅ Update every minute (Since repeat is now 60s)
    final now = DateTime.now();
    final shouldRefresh = _lastLocationRefresh == null
        || now.difference(_lastLocationRefresh!).inMinutes >= 30;
    if (shouldRefresh) {
      _loadLocation();
      _lastLocationRefresh = now;
    }
    _updateNotification();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    // Cleanup
  }

  @override
  void onNotificationButtonPressed(String id) async {
    debugPrint("BackgroundService: Native button pressed: $id");
    // Fallback for FG Task buttons
    if (id == 'btn_update_location' || id == 'update_location') {
      await _refreshLocation();
    } else if (id == 'btn_open_app' || id == 'open_app') {
      fg.FlutterForegroundTask.launchApp();
    } else if (id == 'stop_service') {
      // ✅ Stop the service explicitly
      debugPrint("BackgroundService: Stopping service via notification button");
      _isStopping = true;
      await fg.FlutterForegroundTask.stopService();
      
      // Also update shared preferences to reflect disabled state so it doesn't auto-start next time
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('persistent_notification_enabled', false);
      } catch (e) {
        debugPrint("Error updating prefs on stop: $e");
      }
    }
  }

  @override
  void onNotificationPressed() {
    fg.FlutterForegroundTask.launchApp();
  }

  Future<void> _loadLocation() async {
    final prefs = await SharedPreferences.getInstance();
    // Reload to check if updated by another isolate
    prefs.reload(); 
    
    // ✅ 1. Check Manual Location First
    final isManual = prefs.getBool('manual_location_chosen') ?? false;
    if (isManual) {
       double? lat = prefs.getDouble('manual_lat');
       double? lng = prefs.getDouble('manual_lng');
       String? city = prefs.getString('manual_city');
       
       if (lat != null && lng != null) {
         _lat = lat;
         _long = lng;
         _regionName = city ?? "Manually set location";
        _lastLocationRefresh = DateTime.now();
         return;
       }
    }

    // ✅ 2. Fallback to GPS
    // ✅ Use same keys as Setup Wizard: cached_lat, cached_lng, cached_city
    final newLat = prefs.getDouble('cached_lat');
    final newLong = prefs.getDouble('cached_lng');
    
    if (newLat != null && newLong != null) {
      _lat = newLat;
      _long = newLong;
      
       // Load Region Name
      String? region = prefs.getString('cached_city');
      if (region != null && region.isNotEmpty) {
          _regionName = region;
      } else {
          _regionName = "Set location";
      }
      _lastLocationRefresh = DateTime.now();
    } else {
       // If no location yet
       if (_regionName == "Not Determined") {
          _regionName = "Determining location...";
          _refreshLocation(); // Try to get it once
       }
    }
  }

  Future<void> _refreshLocation() async {
     
     // ✅ Prevent overwriting manual location with GPS
     final prefs = await SharedPreferences.getInstance();
     final isManual = prefs.getBool('manual_location_chosen') ?? false;
     if (isManual) {
       _loadLocation(); // Just reload manual data
       return;
     }

     debugPrint("Refreshing location...");
     // Temporary feedback in notification
     _regionName = "Updating location..."; 
     _updateNotification();
     
     final loc = await LocationService.getAndSaveLocation();
     if (loc != null) {
       _lat = loc['latitude'];
       _long = loc['longitude'];
       
       final prefs = await SharedPreferences.getInstance();
       final region = prefs.getString('user_region');
       if (region != null) {
           _regionName = region;
       } else {
           _regionName = "Location updated"; 
       }
        _lastLocationRefresh = DateTime.now();
       _updateNotification();
     } else {
       // Failed to get location
       final prefs = await SharedPreferences.getInstance();
       _regionName = prefs.getString('user_region') ?? "Update failed";
       _updateNotification();
     }
  }

  Future<void> _updateNotification() async {
    if (_lat == null || _long == null) {
      // For waiting state
      _showNotificationUI("Waiting for location", "Please update location", "", "", "", "", "", "", "");
       return;
    }

    final prefs = await SharedPreferences.getInstance();
    
    // 1. Get Calculation Method
    final methodId = prefs.getString('calculation_method') ?? 'egyptian';
    
    CalculationMethod adhanMethod = CalculationMethod.egyptian;
     switch (methodId) {
      case 'karachi': adhanMethod = CalculationMethod.karachi; break;
      case 'umm_al_qura': adhanMethod = CalculationMethod.umm_al_qura; break;
      case 'dubai': adhanMethod = CalculationMethod.dubai; break;
      case 'mwl': adhanMethod = CalculationMethod.muslim_world_league; break;
      case 'isna': adhanMethod = CalculationMethod.north_america; break;
      case 'kuwait': adhanMethod = CalculationMethod.kuwait; break;
      case 'qatar': adhanMethod = CalculationMethod.qatar; break;
      case 'singapore': adhanMethod = CalculationMethod.singapore; break;
      case 'tehran': adhanMethod = CalculationMethod.tehran; break;
      case 'turkey': adhanMethod = CalculationMethod.turkey; break;
      default: adhanMethod = CalculationMethod.egyptian;
    }

    final params = adhanMethod.getParameters();

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

    // ✅ Fix for accuracy: High latitude rule and precise angles for Egypt
    if (methodId == 'egyptian') {
      params.highLatitudeRule = HighLatitudeRule.twilight_angle;
    }

    // Apply adjustments
    params.adjustments.fajr = offsetFajr;
    params.adjustments.sunrise = offsetSunrise;
    params.adjustments.dhuhr = offsetDhuhr;
    params.adjustments.asr = offsetAsr;
    params.adjustments.maghrib = offsetMaghrib;
    params.adjustments.isha = offsetIsha;

    final myCoordinates = Coordinates(_lat!, _long!);
    final prayerTimes = PrayerTimes.today(myCoordinates, params);
    
    final next = _getNextPrayer(prayerTimes);
    final String nextName = next.name;
    final DateTime nextTime = next.time;
    final Duration diff = nextTime.difference(DateTime.now());
    
    String countdown = "";
    if (diff.isNegative) {
       countdown = "Now";
    } else {
       final hours = diff.inHours;
       final minutes = diff.inMinutes.remainder(60);
       final seconds = diff.inSeconds.remainder(60);
       
       final hStr = hours.toString();
       final mStr = minutes.toString().padLeft(2, '0');
       final sStr = seconds.toString().padLeft(2, '0');
       countdown = "$hStr:$mStr:$sStr";
    }

    final String timeString = () {
      final use24HourFormat = prefs.getBool('time_format_24hour') ?? true;
      return use24HourFormat
          ? DateFormat('HH:mm', 'ar').format(nextTime)
          : DateFormat('hh:mm a', 'ar').format(nextTime);
    }();

    final now = DateTime.now();
    final hijri = HijriCalendar.fromDate(now);
    final hDate = "${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear}";
    final gDate = DateFormat('d MMMM', 'ar').format(now);
    
    // Force RTL using invisible Unicode Right-to-Left Mark (\u200F)
    final rlm = '\u200F';
    final title = "$rlm$nextName"; 
    
    final collapsedBody = "$rlm$timeString  |  $countdown";

    // RESTORED DESIGN: Dark Blue Background + Gold Text
    final expandedBody = 
        "$rlm<font color='#FFD700'><b><big>$nextName</big></b></font>  $rlm<b>$timeString</b><br/>" 
        "$rlm<font color='#B2EBF2'>$countdown</font><br/>" 
        "$rlm<font color='#FFD700'>$hDate</font><br/>"
        "$rlm<font color='#AAAAAA'>$gDate</font><br/>"
        "$rlm<font color='#888888'>$_regionName</font>";
    
    _showNotificationUI(
      title, 
      collapsedBody, 
      expandedBody, 
      nextName,
      timeString,
      countdown,
      gDate,
      hDate,
      _regionName
    );
  }
  
  Future<void> _showNotificationUI(
      String title, 
      String collapsedBody, 
      String expandedBody, 
      String prayerName,
      String timeString,
      String countdown,
      String gDate,
      String hDate,
      String region
  ) async {
    // We skip the native call for now as per user issue report/preference
    /*
    try {
        await platform.invokeMethod('showCustomNotification', {
           'name': prayerName,
           'time': timeString,
           'countdown': countdown,
           'gregorian': gDate,
           'hijri': hDate,
           'region': region,
        });
        return; 
    } catch (e) { 
        debugPrint("Native Notification Failed: $e");
    }
    */

    // Rich Style using FLN with BigTextStyle (Fallback)
    final BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
      expandedBody, // HTML Content
      htmlFormatBigText: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
      summaryText: prayerName,
      htmlFormatSummaryText: true,
    );
    
    // Actions
    final List<AndroidNotificationAction> actions = [
        const AndroidNotificationAction(
            'update_location',
            'Update Location',
            showsUserInterface: false,
            cancelNotification: false,
        ),
        const AndroidNotificationAction(
            'stop_service',
            'Stop Service',
            showsUserInterface: false,
            cancelNotification: true,
        ),
        const AndroidNotificationAction(
            'btn_open_app',
            'Open Qabas',
            showsUserInterface: true,
            cancelNotification: false,
        ),
    ];

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
            'qabas_prayer_service', 
            'Qabas Prayer Service',
            channelDescription: 'Service to show prayer times and location',
            importance: Importance.low, // ✅ Changed to low
            priority: Priority.low,
            ongoing: true, // ✅ Must be true for Foreground Service
            autoCancel: false,
            styleInformation: bigTextStyleInformation,
            color: const Color(0xFF1E4D3E), // ✅ Dark Blue Background
            colorized: true, // ✅ Solid Color
            largeIcon: null, 
            actions: actions, 
        );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      256,
      title,
      collapsedBody, 
      platformChannelSpecifics,
    );
  }

  _PrayerInfo _getNextPrayer(PrayerTimes times) {
    final now = DateTime.now();
    if (now.isBefore(times.fajr)) return _PrayerInfo("Fajr", times.fajr);
    if (now.isBefore(times.sunrise)) return _PrayerInfo("Sunrise", times.sunrise);
    if (now.isBefore(times.dhuhr)) return _PrayerInfo("Dhuhr", times.dhuhr);
    if (now.isBefore(times.asr)) return _PrayerInfo("Asr", times.asr);
    if (now.isBefore(times.maghrib)) return _PrayerInfo("Maghrib", times.maghrib);
    if (now.isBefore(times.isha)) return _PrayerInfo("Isha", times.isha);
    
    return _PrayerInfo("Fajr (Tomorrow)", times.fajr.add(const Duration(days: 1))); 
  }
}

class _PrayerInfo {
  final String name;
  final DateTime time;
  _PrayerInfo(this.name, this.time);
}
