import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:convert';
import 'dart:async';
import '../../../../core/utils/desktop_utils.dart';

import '../data/models/custom_alarm.dart';
import '../data/adhan_display_preferences.dart';
import '../ui/screens/adhan_fullscreen_display.dart';
import 'prayer_times_controller.dart';
import 'adhan_audio_service.dart';
import '../../ramadan/logic/ramadan_notification_service.dart';

class NotificationManager {
  static const String _globalKey = 'global_notifications_enabled';
  static const String _customAlarmsKey = 'custom_alarms_list';

  static ValueNotifier<bool> globalNotificationNotifier = ValueNotifier(true);
  static ValueNotifier<bool> channelsInitialized =
      ValueNotifier(false); // New: Notification channel readiness flag
  static bool _isRescheduling = false; // lock to prevent concurrent scheduling
  static DateTime? _lastAutoRescheduleAt;

  // ✅ Static reference to navigator key for navigation from background
  static GlobalKey<NavigatorState>? navigatorKey;

  // 1. Initialization
  static Future<void> initialize() async {
    // ✅ Skip on desktop platforms (not supported)
    if (DesktopUtils.isDesktop) return;
    await AwesomeNotifications().initialize(
      'resource://mipmap/launcher_icon', // ✅ FIX: Use launcher_icon as res_app_icon was 0 bytes
      [
        NotificationChannel(
          channelKey: 'basic_channel_v2', // ✅ Bump to v2
          channelName: 'General Notifications',
          channelDescription: 'Basic notifications channel',
          defaultColor: const Color(0xFF00E5FF),
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: false,
          enableVibration: false,
        ),
        // Adhan Channels - Bumped to v2
        _buildPrayerChannel('takbeer', 'Prayer Awareness (Takbeer Only)'),
        _buildPrayerChannel('mulla', 'Prayer (Makkah)'),
        _buildPrayerChannel('qassas', 'Prayer (Qassas)'),
        _buildPrayerChannel('ramadan', 'Prayer (Ramadan)'),
        _buildPrayerChannel('refaat', 'Prayer (Rifaat)'),
        _buildPrayerChannel('mohamed_hosny', 'Prayer (Mohamed Hosny)'), // ✅ New
        _buildPrayerChannel('abd_toba', 'Prayer (Abd Toba)'), // ✅ New
        _buildPrayerChannel('fajr_mulla', 'Fajr (Makkah)'),
        _buildPrayerChannel('fajr_qassas', 'Fajr (Qassas)'),

        NotificationChannel(
          channelKey: 'adhkar_channel_v2', // ✅ Bump to v2
          channelName: 'Adhkar',
          channelDescription: 'Daily Adhkar Notifications',
          defaultColor: Colors.purpleAccent,
          importance: NotificationImportance.High,
          playSound: true,
          enableVibration: false, // ✅ Disable vibration
        ),
      ],
      debug: false,
    );
    channelsInitialized.value = true;

    bool savedState = await getGlobalNotifications();
    globalNotificationNotifier.value = savedState;

    // ✅ Defer heavy rescheduling with proper delay to let UI render first
    Future.delayed(
      const Duration(seconds: 6),
      () => rescheduleAllNotificationsIfNeeded(),
    );
  }

  static Future<void> rescheduleAllNotificationsIfNeeded({
    Duration minInterval = const Duration(minutes: 2),
  }) async {
    final now = DateTime.now();
    if (_lastAutoRescheduleAt != null &&
        now.difference(_lastAutoRescheduleAt!) < minInterval) {
      debugPrint('Auto reschedule skipped to avoid duplicate startup work');
      return;
    }

    _lastAutoRescheduleAt = now;
    await rescheduleAllNotifications();
  }

  static NotificationChannel _buildPrayerChannel(String id, String name) {
    try {
      return NotificationChannel(
        channelKey: 'channel_${id}_v2',
        channelName: name,
        channelDescription: 'Prayer notifications with $name voice',
        defaultColor: const Color(0xFF00E5FF),
        importance: NotificationImportance
            .High, // Must be high/max for full screen intent
        soundSource: 'resource://raw/$id',
        playSound: true,
        enableVibration: false,
        criticalAlerts:
            true, // ✅ Required for waking up the screen aggressively
        locked: false,
      );
    } catch (e) {
      rethrow;
    }
  }

  // ==============================================================
  // 2. Check notification permissions
  // ==============================================================
  static Future<bool> checkNotificationPermissions(BuildContext context) async {
    return await AwesomeNotifications().isNotificationAllowed();
  }

  // Request permission function (for use when needed)
  static Future<bool> requestPermissionsUserAction() async {
    return await AwesomeNotifications()
        .requestPermissionToSendNotifications(permissions: [
      NotificationPermission.Alert,
      NotificationPermission.Sound,
      NotificationPermission.Badge,
      NotificationPermission.FullScreenIntent,
      NotificationPermission.PreciseAlarms,
      NotificationPermission.CriticalAlert,
    ]);
  }

  static Future<void> requestBatteryOptimizations() async {
    await AwesomeNotifications().showNotificationConfigPage();
  }

  static Future<void> setupListeners() async {
    await AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onActionReceivedMethod,
      onNotificationCreatedMethod: _onNotificationCreatedMethod,
      onNotificationDisplayedMethod: _onNotificationDisplayedMethod,
    );
  }

  @pragma("vm:entry-point")
  static Future<void> _onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    // This is called when notification is created (scheduled)
  }

  @pragma("vm:entry-point")
  static Future<void> _onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    // This is called when notification is actually displayed
    final prayerId = receivedNotification.payload?['prayer_id'];
    if (prayerId != null && prayerId != 'test') {
      // Check if fullscreen is enabled
      final fullscreenEnabled =
          await AdhanDisplayPreferences.isFullscreenEnabled();

      try {
        final id = int.tryParse(prayerId);
        if (id != null) {
          Timer(const Duration(minutes: 4), () async {
            await AwesomeNotifications().cancel(id);
          });
        }
      } catch (_) {}

      // ✅ Navigate to fullscreen UI only when we have a valid context
      if (fullscreenEnabled &&
          navigatorKey != null &&
          navigatorKey!.currentContext != null) {
        final prayerName = receivedNotification.payload?['prayer_name'] ?? '';
        final prayerTime = receivedNotification.payload?['prayer_time'] ?? '';
        final soundId = receivedNotification.payload?['sound_id'] ??
            'mulla'; // ✅ Get sound_id
        // ✅ Prevent showing fullscreen if the prayer was more than 5 minutes ago
        // (This happens if Android delays the notification delivery while app is closed)
        bool shouldShowScreen = true;
        try {
          if (prayerTime.isNotEmpty &&
              receivedNotification.createdDate != null) {
            final now = DateTime.now();
            final createdTime = receivedNotification.createdDate!;
            // If the notification was actually created more than 15 seconds ago, don't show the screen automatically
            if (now.difference(createdTime).inSeconds > 15) {
              shouldShowScreen = false;
            }
          }
        } catch (_) {}

        if (shouldShowScreen) {
          // Navigate to fullscreen display automatically when notification shows
          navigatorKey!.currentState?.push(
            MaterialPageRoute(
              builder: (_) => AdhanFullscreenDisplay(
                prayerName: prayerName,
                prayerTime: prayerTime,
                soundId: soundId,
              ),
              fullscreenDialog: true,
            ),
          );
        }
      }
    }
  }

  @pragma("vm:entry-point")
  static Future<void> _onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    final prayerId = receivedAction.payload?['prayer_id'];
    final buttonKey = receivedAction.buttonKeyPressed;
    if (buttonKey == 'STOP') {
      try {
        await AdhanAudioService().stopAdhan();
      } catch (_) {}
      if (prayerId != null) {
        try {
          await AwesomeNotifications().cancel(int.tryParse(prayerId) ?? 0);
        } catch (_) {}
      }
      return;
    }
    if (prayerId != null && prayerId != 'test') {
      final fullscreenEnabled =
          await AdhanDisplayPreferences.isFullscreenEnabled();
      if (fullscreenEnabled &&
          navigatorKey != null &&
          navigatorKey!.currentContext != null) {
        final prayerName = receivedAction.payload?['prayer_name'] ?? '';
        final prayerTime = receivedAction.payload?['prayer_time'] ?? '';
        final soundId = receivedAction.payload?['sound_id'] ?? 'mulla';
        navigatorKey!.currentState?.push(
          MaterialPageRoute(
            builder: (_) => AdhanFullscreenDisplay(
              prayerName: prayerName,
              prayerTime: prayerTime,
              soundId: soundId,
            ),
            fullscreenDialog: true,
          ),
        );
      }
    }
  }

  // ✅ NEW: Auto-reschedule all notifications (called on app start and boot)
  static Future<void> rescheduleAllNotifications() async {
    // ✅ Skip on desktop platforms
    if (DesktopUtils.isDesktop) return;
    // ✅ Prevent concurrent scheduling
    if (_isRescheduling) {
      debugPrint('⚠️ Reschedule already in progress, skipping...');
      return;
    }
    _isRescheduling = true;
    try {
      debugPrint('🔔 Rescheduling all notifications...');

      // Initialize locale for date formatting
      await initializeDateFormatting('ar', null);

      // Check if notifications are globally enabled
      bool globalEnabled = globalNotificationNotifier.value;
      if (!globalEnabled) {
        debugPrint('🔕 Global notifications disabled, skipping reschedule');
        return;
      }

      // Check permissions
      bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) {
        debugPrint('⚠️ Notification permissions not granted');
        return;
      }

      final controller = PrayerTimesController();
      await cancelAllNotifications();
      final alarms = await getCustomAlarms();
      for (int i = 0; i < 7; i++) {
        final date = DateTime.now().add(Duration(days: i));
        final times = await controller.getPrayerTimesForDate(date);
        await _schedulePrayersForDate(times, dayOffset: i);

        // ✅ Increased throttle (500ms) to prevent UI jank during background scheduling
        await Future.delayed(const Duration(milliseconds: 500));

        await _scheduleCustomAlarmsForDate(times, alarms: alarms, dayOffset: i);
      }
      await scheduleAdhkar();

      debugPrint('✅ All notifications rescheduled successfully');
    } catch (e) {
      debugPrint('❌ Error rescheduling notifications: $e');
    } finally {
      _isRescheduling = false;
    }
  }

  // ==============================================================
  // 3. إدارة المنبهات المخصصة
  // ==============================================================

  static Future<void> addCustomAlarm(CustomAlarm alarm) async {
    // ✅ قبل الإضافة والجدولة، نتأكد أن الإشعارات مسموحة لتجنب الكراش
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      // محاولة طلب الإذن
      isAllowed =
          await AwesomeNotifications().requestPermissionToSendNotifications();
      if (!isAllowed) return; // لو رفض، نخرج ولا نكمل
    }

    List<CustomAlarm> alarms = await getCustomAlarms();
    alarms.add(alarm);
    await _saveAlarmsList(alarms);

    await rescheduleAllNotifications();
  }

  static Future<void> removeCustomAlarm(int id) async {
    List<CustomAlarm> alarms = await getCustomAlarms();
    alarms.removeWhere((a) => a.id == id);
    await _saveAlarmsList(alarms);

    await rescheduleAllNotifications();
  }

  static Future<List<CustomAlarm>> getCustomAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString(_customAlarmsKey);
    if (data == null) return [];
    try {
      List<dynamic> maps = json.decode(data);
      return maps.map((m) => CustomAlarm.fromJson(m)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> _saveAlarmsList(List<CustomAlarm> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    String data = json.encode(alarms.map((a) => a.toJson()).toList());
    await prefs.setString(_customAlarmsKey, data);
  }

  // ==============================================================
  // 4. الجدولة الذكية (الشاملة)
  // ==============================================================
  static Future<void> schedulePrayers(PrayerTimes times) async {
    // Check permissions
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      return;
    }

    await cancelAllNotifications();
    bool globalEnabled = globalNotificationNotifier.value;

    if (!globalEnabled) return;

    final prefs = await SharedPreferences.getInstance();

    // ✅ Load Per-Prayer Sound Preferences (Default to 'mulla')
    // ✅ Get default sound from Setup Wizard (what user chose during initial setup)
    String defaultSound = prefs.getString('adhan_sound') ?? 'mohamed_hosny';

    // Read per-prayer sounds, fallback to user's Setup choice
    String sFajr = prefs.getString('sound_fajr') ?? defaultSound;
    String sDhuhr = prefs.getString('sound_dhuhr') ?? defaultSound;
    String sAsr = prefs.getString('sound_asr') ?? defaultSound;
    String sMaghrib = prefs.getString('sound_maghrib') ?? defaultSound;
    String sIsha = prefs.getString('sound_isha') ?? defaultSound;

    // ✅ Load Mute Preferences
    bool mFajr = prefs.getBool('mute_fajr') ?? false;
    bool mDhuhr = prefs.getBool('mute_dhuhr') ?? false;
    bool mAsr = prefs.getBool('mute_asr') ?? false;
    bool mMaghrib = prefs.getBool('mute_maghrib') ?? false;
    bool mIsha = prefs.getBool('mute_isha') ?? false;

    // ✅ Schedule with specific settings (Always pass enabled=true, handle mute inside)
    await _scheduleSinglePrayer(times.fajr, 'صلاة الفجر', 1, true, sFajr,
        isFajr: true);
    await _scheduleSinglePrayer(times.dhuhr, 'صلاة الظهر', 2, true, sDhuhr);
    await _scheduleSinglePrayer(times.asr, 'صلاة العصر', 3, true, sAsr);
    await _scheduleSinglePrayer(
        times.maghrib, 'صلاة المغرب', 4, true, sMaghrib);
    await _scheduleSinglePrayer(times.isha, 'صلاة العشاء', 5, true, sIsha);

    // ✅ Ramadan notifications (Iftar at Maghrib, Suhoor before Fajr)
    await RamadanNotificationService.scheduleRamadanNotifications(
      maghribTime: times.maghrib,
      fajrTime: times.fajr,
    );

    // ملاحظة: جدولة المنبهات المخصصة أصبحت تتم أسبوعياً في rescheduleAllNotifications
  }

  static Future<void> _schedulePrayersForDate(PrayerTimes times,
      {required int dayOffset}) async {
    final prefs = await SharedPreferences.getInstance();
    final fullscreenEnabled =
        await AdhanDisplayPreferences.isFullscreenEnabled();
    String defaultSound = prefs.getString('adhan_sound') ?? 'mohamed_hosny';
    String sFajr = prefs.getString('sound_fajr') ?? defaultSound;
    String sDhuhr = prefs.getString('sound_dhuhr') ?? defaultSound;
    String sAsr = prefs.getString('sound_asr') ?? defaultSound;
    String sMaghrib = prefs.getString('sound_maghrib') ?? defaultSound;
    String sIsha = prefs.getString('sound_isha') ?? defaultSound;
    await _scheduleSinglePrayer(
        times.fajr, 'صلاة الفجر', 1 + dayOffset * 100, true, sFajr,
        isFajr: true);
    await _scheduleSinglePrayer(
        times.dhuhr, 'صلاة الظهر', 2 + dayOffset * 100, true, sDhuhr);
    await _scheduleSinglePrayer(
        times.asr, 'صلاة العصر', 3 + dayOffset * 100, true, sAsr);
    await _scheduleSinglePrayer(
        times.maghrib, 'صلاة المغرب', 4 + dayOffset * 100, true, sMaghrib);
    await _scheduleSinglePrayer(
        times.isha, 'صلاة العشاء', 5 + dayOffset * 100, true, sIsha);
  }

  static Future<void> _scheduleCustomAlarmsForDate(PrayerTimes times,
      {required List<CustomAlarm> alarms, required int dayOffset}) async {
    for (var alarm in alarms) {
      if (!alarm.isEnabled) continue;
      for (String pName in alarm.prayerNames) {
        DateTime? baseTime = _getPrayerTime(times, pName);
        if (baseTime == null) continue;
        DateTime targetTime = alarm.isBefore
            ? baseTime.subtract(Duration(minutes: alarm.offsetMinutes))
            : baseTime.add(Duration(minutes: alarm.offsetMinutes));
        // ✅ منع التعارض: لو المنبه يطابق وقت الصلاة نفسه، نتجاهله لتفادي ازدواج الإشعار/الصوت
        final diffSeconds = targetTime.difference(baseTime).inSeconds.abs();
        if (diffSeconds <= 30) {
          continue;
        }
        if (targetTime.isBefore(DateTime.now())) {
          // لو اليوم الحالي، نسمح بالتجاوز لليوم التالي لضمان عدم إطلاق فوري
          targetTime = targetTime.add(const Duration(days: 1));
        }
        int uniqueId =
            ((alarm.id + pName.hashCode).abs() % 100000000) + dayOffset * 10000;
        await _scheduleCustomNotification(alarm, targetTime, pName, uniqueId);
      }
    }
  }

  static Future<void> _scheduleSinglePrayer(
      DateTime time, String title, int id, bool isEnabled, String soundId,
      {bool isFajr = false}) async {
    if (isEnabled == false) return; // This means "Disabled completely"

    DateTime scheduledTime = time;
    final now = DateTime.now();

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    String channelKey;

    final prefs = await SharedPreferences.getInstance();
    final fullscreenEnabled =
        await AdhanDisplayPreferences.isFullscreenEnabled();
    // Map title to key: 'صلاة الفجر' -> 'fajr'
    String key = '';
    if (title.contains('الفجر')) {
      key = 'fajr';
    } else if (title.contains('الظهر'))
      key = 'dhuhr';
    else if (title.contains('العصر'))
      key = 'asr';
    else if (title.contains('المغرب'))
      key = 'maghrib';
    else if (title.contains('العشاء')) key = 'isha';

    bool isMuted = prefs.getBool('mute_$key') ?? false;

    if (isMuted) {
      channelKey = 'basic_channel_v2';
    } else {
      // Use normal adhan channel with sound (notification sound only, without fullscreen playback)
      channelKey = 'channel_${soundId}_v2';
      if (isFajr && (soundId == 'mulla' || soundId == 'qassas')) {
        channelKey = 'channel_fajr_${soundId}_v2';
      }
    }

    // Format time for display
    final use24HourFormat = prefs.getBool('time_format_24hour') ?? true;
    final timeString = use24HourFormat
        ? DateFormat('HH:mm', 'ar').format(scheduledTime)
        : DateFormat('hh:mm a', 'ar').format(scheduledTime);

    // Extract prayer name from title (remove "صلاة " prefix)
    final prayerName = title.replaceAll('صلاة ', '');

    String actualSoundId = soundId;
    if (isFajr) {
      if (soundId == 'mulla') {
        actualSoundId = 'fajr_mulla';
      } else if (soundId == 'qassas') actualSoundId = 'fajr_qassas';
      // Add other fajr variants if they exist, e.g. if we had fajr_abd_toba
    }

    // ✅ حماية الكود بـ try-catch لمنع الانهيار إذا تم رفض الإذن فجأة
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: channelKey,
          title: title,
          body:
              isMuted ? 'حان الآن موعد $title (صامت)' : 'حان الآن موعد $title',
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory
              .Alarm, // ✅ Must be Alarm for Fullscreen Android 10+
          wakeUpScreen: true, // ✅ Ensure screen wakes up
          fullScreenIntent: true, // ✅ Required to show over lock screen
          criticalAlert: true, // ✅ Max priority over DND
          autoDismissible: true,
          locked: false,
          backgroundColor: const Color(0xFF1E4D3E),
          payload: {
            'prayer_id': id.toString(),
            'prayer_name': prayerName,
            'prayer_time': timeString,
            'sound_id':
                actualSoundId, // ✅ Use the potentially modified ID for playback
          },
        ),
        schedule: NotificationCalendar.fromDate(
          date: scheduledTime,
          preciseAlarm: true,
          allowWhileIdle: true,
        ),
        actionButtons: [
          NotificationActionButton(
              key: 'STOP',
              label: 'إيقاف الصوت',
              actionType: ActionType.DismissAction,
              isDangerousOption: true,
              autoDismissible: true),
          NotificationActionButton(
              key: 'OPEN',
              label: 'فتح التطبيق',
              actionType: ActionType.Default,
              color: const Color(0xFF00E5FF)),
        ],
      );
    } catch (e) {
      debugPrint("❌ Error scheduling notification for $title: $e");
    }
  }

  // Helper method to extract prayer key from title
  static String _getPrayerKeyFromTitle(String title) {
    if (title.contains('الفجر')) return 'fajr';
    if (title.contains('الظهر')) return 'dhuhr';
    if (title.contains('العصر')) return 'asr';
    if (title.contains('المغرب')) return 'maghrib';
    if (title.contains('العشاء')) return 'isha';
    return '';
  }

  // Test Function
  static Future<void> testAdhanNow() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      bool granted = await requestPermissionsUserAction();
      if (!granted) return;
    }

    try {
      // 1. Basic Test (Simple channel)
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 88888,
          channelKey: 'basic_channel_v2', // ✅ Bump to v2
          title: 'تجربة بسيطة',
          body: 'إذا رأيت هذا، فإن الإشعارات تعمل.',
          category: NotificationCategory.Message,
          wakeUpScreen: true,
        ),
      );

      // 2. Alarm Test (Adhan channel)
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 99999,
          channelKey: 'channel_takbeer_v2', // ✅ Bump to v2 (Using default)
          title: 'تجربة الأذان',
          body: 'هذا مجرد اختبار للصوت والإشعار',
          category: NotificationCategory.Alarm,
          wakeUpScreen: true,
          fullScreenIntent: true,
          criticalAlert: true,
          autoDismissible: true,
          locked: false,
          payload: {'prayer_id': 'test'},
        ),
        actionButtons: [
          NotificationActionButton(
              key: 'STOP',
              label: 'إيقاف الصوت',
              actionType: ActionType.DismissAction,
              isDangerousOption: true,
              autoDismissible: true),
        ],
      );
      // Test actions
    } catch (_) {
      // Test failed
    }
  }

  static Future<void> _scheduleCustomNotification(
      CustomAlarm alarm, DateTime time, String pName, int id) async {
    String prayerAr = _getPrayerNameAr(pName);
    String timeDesc = alarm.isBefore ? "قبل" : "بعد";
    String body = "$timeDesc $prayerAr بـ ${alarm.offsetMinutes} دقيقة";

    // ✅ حماية الكود بـ try-catch
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: 'channel_${alarm.soundName}_v2', // ✅ Bump to v2
          title: "🔔 ${alarm.title}",
          body: body,
          category: NotificationCategory.Alarm,
          wakeUpScreen: true,
          fullScreenIntent: true,
          criticalAlert: true,
          backgroundColor: const Color(0xFF1E4D3E),
        ),
        schedule: NotificationCalendar.fromDate(
            date: time, preciseAlarm: true, allowWhileIdle: true),
        actionButtons: [
          NotificationActionButton(
              key: 'STOP',
              label: 'إيقاف',
              actionType: ActionType.DismissAction,
              isDangerousOption: true,
              autoDismissible: true),
        ],
      );
    } catch (_) {
      // Failed to schedule custom alarm
    }
  }

  // ✅ IMPROVED: Schedule Adhkar for next 7 days (Android 12+ compatible)
  static Future<void> scheduleAdhkar() async {
    if (!globalNotificationNotifier.value) return;

    try {
      debugPrint('🕌 Scheduling Adhkar notifications for next 7 days...');

      // Cancel existing Adhkar notifications (IDs 100-199 reserved for Adhkar)
      for (int i = 100; i < 200; i++) {
        await AwesomeNotifications().cancel(i);
      }

      final now = DateTime.now();

      // Schedule morning Adhkar (7:00 AM) for next 7 days
      for (int day = 0; day < 7; day++) {
        DateTime morningTime = DateTime(
          now.year,
          now.month,
          now.day + day,
          7, // 7:00 AM
          0,
          0,
        );

        // Skip if time has passed today
        if (morningTime.isBefore(now)) {
          continue;
        }

        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: 100 + day,
            channelKey: 'adhkar_channel_v2', // ✅ Bump to v2
            title: 'أذكار الصباح ☀️',
            body: 'ابدأ يومك بذكر الله',
            category: NotificationCategory.Reminder,
            wakeUpScreen: true,
            notificationLayout: NotificationLayout.Default,
          ),
          schedule: NotificationCalendar.fromDate(
            date: morningTime,
            preciseAlarm: true,
            allowWhileIdle: true,
          ),
        );
        debugPrint('  ✓ Morning Adhkar scheduled for: $morningTime');
        // ✅ Throttle
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // Schedule evening Adhkar (4:30 PM) for next 7 days
      for (int day = 0; day < 7; day++) {
        DateTime eveningTime = DateTime(
          now.year,
          now.month,
          now.day + day,
          16, // 4:30 PM
          30,
          0,
        );

        // Skip if time has passed today
        if (eveningTime.isBefore(now)) {
          continue;
        }

        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: 150 + day,
            channelKey: 'adhkar_channel_v2', // ✅ Bump to v2
            title: 'أذكار المساء 🌙',
            body: 'حصّن نفسك بالذكر',
            category: NotificationCategory.Reminder,
            wakeUpScreen: true,
            notificationLayout: NotificationLayout.Default,
          ),
          schedule: NotificationCalendar.fromDate(
            date: eveningTime,
            preciseAlarm: true,
            allowWhileIdle: true,
          ),
        );
        debugPrint('  ✓ Evening Adhkar scheduled for: $eveningTime');
        // ✅ Throttle
        await Future.delayed(const Duration(milliseconds: 50));
      }

      debugPrint('✅ Adhkar notifications scheduled successfully');
    } catch (e) {
      debugPrint('❌ Error scheduling Adhkar: $e');
    }
  }

  static Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAllSchedules();
  }

  static Future<bool> getGlobalNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_globalKey) ?? true;
  }

  static Future<void> setGlobalNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_globalKey, value);
    globalNotificationNotifier.value = value;
  }

  static Future<void> setPrayerNotification(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  // ✅ NEW: Reschedule prayers after mute status changes
  static Future<void> reschedulePrayersAfterMuteChange() async {
    try {
      final controller = PrayerTimesController();
      final times = await controller.getStoredOrDefaultPrayerTimes();
      await schedulePrayers(times);
    } catch (e) {
      debugPrint('Error rescheduling prayers after mute change: $e');
    }
  }

  static Future<bool> getPrayerNotification(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? true;
  }

  static DateTime? _getPrayerTime(PrayerTimes times, String pName) {
    switch (pName) {
      case 'fajr':
        return times.fajr;
      case 'dhuhr':
        return times.dhuhr;
      case 'asr':
        return times.asr;
      case 'maghrib':
        return times.maghrib;
      case 'isha':
        return times.isha;
      default:
        return null;
    }
  }

  static String _getPrayerNameAr(String pName) {
    switch (pName) {
      case 'fajr':
        return "الفجر";
      case 'dhuhr':
        return "الظهر";
      case 'asr':
        return "العصر";
      case 'maghrib':
        return "المغرب";
      case 'isha':
        return "العشاء";
      default:
        return "";
    }
  }
}

