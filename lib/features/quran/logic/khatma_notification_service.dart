import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:quran/quran.dart' as quran;
import '../data/khatma_model.dart';
import '../data/khatma_notification_messages.dart';
import 'khatma_ward_calculator.dart';

/// Smart notification service for the Khatma system.
/// Schedules contextual, motivational, and prayer-aware reminders.
class KhatmaNotificationService {
  static const int _baseId = 5000;
  static const String _channelKey = 'basic_channel_v2';

  // ═══════════════════════════════════════════════════════
  //  Main Scheduling
  // ═══════════════════════════════════════════════════════

  /// Schedule all khatma notifications for today.
  static Future<void> scheduleNotifications(KhatmaModel khatma) async {
    await cancelAll();

    if (!khatma.isActive || khatma.isCompleted || khatma.isPaused) return;

    final mode = khatma.notifyMode;

    if (mode == 'specific_time' || mode == 'both') {
      await _scheduleSpecificTime(khatma);
    }

    if (mode == 'after_prayer' || mode == 'both') {
      await _scheduleAfterPrayers(khatma);
    }

    // Schedule catch-up if behind
    if (khatma.isBehind) {
      await _scheduleCatchUpReminder(khatma);
    }

    // Schedule streak milestone if applicable
    await _checkAndScheduleStreakNotification(khatma);
  }

  // ═══════════════════════════════════════════════════════
  //  Specific Time Notification
  // ═══════════════════════════════════════════════════════

  static Future<void> _scheduleSpecificTime(KhatmaModel khatma) async {
    if (khatma.specificTime == null) return;

    final parts = khatma.specificTime!.split(':');
    if (parts.length != 2) return;
    final hour = int.tryParse(parts[0]) ?? 7;
    final minute = int.tryParse(parts[1]) ?? 0;

    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final ward = KhatmaWardCalculator.getTodayWard(
      currentPage: khatma.currentPage,
      dailyTarget: khatma.todayTarget,
    );

    final isAr = Get.locale?.languageCode == 'ar';
    final dayIndex = khatma.daysElapsed;
    final message = KhatmaNotificationMessages.getMessageForStyle(khatma.notifStyle, dayIndex);

    final title = isAr ? '📖 وردك اليوم' : '📖 Your Daily Portion';
    final body = isAr
        ? '${ward.notificationTextAr}\n${message['ar']}'
        : '${ward.notificationTextEn}\n${message['en']}';

    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _baseId,
          channelKey: _channelKey,
          title: title,
          body: body,
          notificationLayout: NotificationLayout.BigText,
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
          autoDismissible: true,
          payload: {
            'type': 'khatma',
            'page': khatma.currentPage.toString(),
          },
        ),
        schedule: NotificationCalendar.fromDate(
          date: scheduled,
          preciseAlarm: true,
          allowWhileIdle: true,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error scheduling khatma time notification: $e');
    }
  }

  // ═══════════════════════════════════════════════════════
  //  After Prayer Notifications
  // ═══════════════════════════════════════════════════════

  static Future<void> _scheduleAfterPrayers(KhatmaModel khatma) async {
    try {
      final coords = await _getCoordinates();
      if (coords == null) return;

      final prayerTimes = _calculatePrayerTimes(coords);
      final delay = Duration(minutes: khatma.afterPrayerDelayMinutes);
      final now = DateTime.now();

      final prayers = [
        {'name_ar': 'الفجر', 'name_en': 'Fajr', 'time': prayerTimes.fajr},
        {'name_ar': 'الظهر', 'name_en': 'Dhuhr', 'time': prayerTimes.dhuhr},
        {'name_ar': 'العصر', 'name_en': 'Asr', 'time': prayerTimes.asr},
        {'name_ar': 'المغرب', 'name_en': 'Maghrib', 'time': prayerTimes.maghrib},
        {'name_ar': 'العشاء', 'name_en': 'Isha', 'time': prayerTimes.isha},
      ];

      final ward = KhatmaWardCalculator.getSessionWard(
        currentPage: khatma.currentPage,
        sessionPages: khatma.sessionPages,
      );

      final isAr = Get.locale?.languageCode == 'ar';
      final dayIndex = khatma.daysElapsed;

      for (int i = 0; i < prayers.length; i++) {
        final prayerTime = prayers[i]['time'] as DateTime;
        final scheduledTime = prayerTime.add(delay);

        if (scheduledTime.isBefore(now)) continue;

        String title;
        String body;

        if (khatma.todayRemaining <= 0) {
          // Already completed today
          title = isAr ? '✅ ماشاء الله!' : '✅ MashaAllah!';
          body = isAr
              ? 'أكملت ورد اليوم 🎉'
              : 'You completed today\'s portion 🎉';
        } else if (khatma.todayRemaining <= khatma.sessionPages) {
          // Almost done
          title = isAr ? '💪 باقي القليل!' : '💪 Almost done!';
          body = isAr
              ? 'باقي ${khatma.todayRemaining} صفحات فقط لإكمال ورد اليوم!'
              : 'Only ${khatma.todayRemaining} pages left to complete today\'s portion!';
        } else {
          // Normal reminder with message based on style
          final message = KhatmaNotificationMessages.getMessageForStyle(khatma.notifStyle, dayIndex + i);
          final prayerName = isAr ? prayers[i]['name_ar'] : prayers[i]['name_en'];
          title = isAr
              ? '📖 وقت القراءة — بعد $prayerName'
              : '📖 Reading Time — After $prayerName';
          body = isAr
              ? '${ward.notificationTextAr}\n${message['ar']}'
              : '${ward.notificationTextEn}\n${message['en']}';
        }

        try {
          await AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: _baseId + i + 1,
              channelKey: _channelKey,
              title: title,
              body: body,
              notificationLayout: NotificationLayout.BigText,
              category: NotificationCategory.Reminder,
              wakeUpScreen: true,
              autoDismissible: true,
              payload: {
                'type': 'khatma',
                'page': khatma.currentPage.toString(),
              },
            ),
            schedule: NotificationCalendar.fromDate(
              date: scheduledTime,
              preciseAlarm: true,
              allowWhileIdle: true,
            ),
          );
        } catch (e) {
          debugPrint('❌ Error scheduling after-prayer khatma: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Error in _scheduleAfterPrayers: $e');
    }
  }

  // ═══════════════════════════════════════════════════════
  //  Catch-up Reminder
  // ═══════════════════════════════════════════════════════

  static Future<void> _scheduleCatchUpReminder(KhatmaModel khatma) async {
    final now = DateTime.now();
    final rescueTime = now.add(const Duration(hours: 2));
    final dayIndex = khatma.daysElapsed;
    final isAr = Get.locale?.languageCode == 'ar';
    final message = KhatmaNotificationMessages.getCatchUpMessage(dayIndex);

    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _baseId + 10,
          channelKey: _channelKey,
          title: isAr ? '⏳ تذكير بالتعويض' : '⏳ Catch-up Reminder',
          body: isAr ? message['ar']! : message['en']!,
          notificationLayout: NotificationLayout.BigText,
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
          autoDismissible: true,
          payload: {
            'type': 'khatma_rescue',
            'page': khatma.currentPage.toString(),
          },
        ),
        schedule: NotificationCalendar.fromDate(
          date: rescueTime,
          preciseAlarm: true,
          allowWhileIdle: true,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error scheduling catch-up: $e');
    }
  }

  // ═══════════════════════════════════════════════════════
  //  Streak Notification
  // ═══════════════════════════════════════════════════════

  static Future<void> _checkAndScheduleStreakNotification(KhatmaModel khatma) async {
    final streakMsg = KhatmaNotificationMessages.getStreakMessage(khatma.streak);
    if (streakMsg == null) return;

    final isAr = Get.locale?.languageCode == 'ar';

    try {
      // Show immediately (not scheduled)
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _baseId + 20,
          channelKey: _channelKey,
          title: isAr ? '🔥 إنجاز جديد!' : '🔥 New Achievement!',
          body: isAr ? streakMsg['ar']! : streakMsg['en']!,
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Reminder,
          wakeUpScreen: false,
          autoDismissible: true,
          payload: {'type': 'khatma_streak'},
        ),
      );
    } catch (e) {
      debugPrint('❌ Error showing streak notification: $e');
    }
  }

  /// Schedule a rescue session notification.
  static Future<void> scheduleRescueReminder(KhatmaModel khatma) async {
    final now = DateTime.now();
    final rescueTime = now.add(const Duration(hours: 1));
    final isAr = Get.locale?.languageCode == 'ar';

    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _baseId + 11,
          channelKey: _channelKey,
          title: isAr ? '⚡ جلسة إنقاذ' : '⚡ Rescue Session',
          body: isAr
              ? 'فاتك ${khatma.todayRemaining} صفحات — 5 دقائق فقط لتعويض التأخر!'
              : 'You missed ${khatma.todayRemaining} pages — just 5 minutes to catch up!',
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
          autoDismissible: true,
          payload: {
            'type': 'khatma_rescue',
            'page': khatma.currentPage.toString(),
          },
        ),
        schedule: NotificationCalendar.fromDate(
          date: rescueTime,
          preciseAlarm: true,
          allowWhileIdle: true,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error scheduling rescue: $e');
    }
  }

  // ═══════════════════════════════════════════════════════
  //  Cancel
  // ═══════════════════════════════════════════════════════

  /// Cancel all khatma notifications.
  static Future<void> cancelAll() async {
    for (int i = 0; i <= 25; i++) {
      try {
        await AwesomeNotifications().cancel(_baseId + i);
      } catch (_) {}
    }
  }

  // ═══════════════════════════════════════════════════════
  //  Helpers
  // ═══════════════════════════════════════════════════════

  static Future<Coordinates?> _getCoordinates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('last_lat');
      final lng = prefs.getDouble('last_lng');
      if (lat != null && lng != null) {
        return Coordinates(lat, lng);
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      return Coordinates(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('❌ Could not get coordinates: $e');
      return Coordinates(30.0444, 31.2357); // Default: Cairo
    }
  }

  static PrayerTimes _calculatePrayerTimes(Coordinates coords) {
    final params = CalculationMethod.egyptian.getParameters();
    params.madhab = Madhab.shafi;
    final date = DateComponents.from(DateTime.now());
    return PrayerTimes(coords, date, params);
  }
}
