import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'ramadan_service.dart';

/// Ramadan Notification Service — Iftar & Suhoor reminders.
/// Uses awesome_notifications with Maghrib time (Iftar) and Fajr - offset (Suhoor).
class RamadanNotificationService {
  // Notification IDs (unique, high numbers to avoid collision)
  static const int _iftarNotificationId = 9001;
  static const int _suhoorNotificationId = 9002;
  static const String _channelKey = 'ramadan_channel';

  // Prefs keys
  static const String _iftarEnabledKey = 'ramadan_iftar_enabled';
  static const String _suhoorEnabledKey = 'ramadan_suhoor_enabled';
  static const String _suhoorOffsetKey = 'ramadan_suhoor_offset_min';

  /// Initialize the Ramadan notification channel.
  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, // use default icon
      [
        NotificationChannel(
          channelKey: _channelKey,
          channelName: 'رمضان',
          channelDescription: 'إشعارات الإفطار والسحور',
          defaultColor: const Color(0xFFFFD700),
          importance: NotificationImportance.High,
          defaultRingtoneType: DefaultRingtoneType.Notification,
          playSound: true,
        ),
      ],
    );
  }

  /// Schedule Iftar notification at the given Maghrib time.
  static Future<void> scheduleIftar(DateTime maghribTime) async {
    if (!RamadanService.isDuringRamadan()) return;

    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_iftarEnabledKey) ?? true;
    if (!enabled) return;

    final dayNumber = RamadanService.currentRamadanDay();
    final now = DateTime.now();

    DateTime scheduledTime = maghribTime;
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _iftarNotificationId,
          channelKey: _channelKey,
          title: '🌙 حان موعد الإفطار',
          body: 'اللهم لك صمت وعلى رزقك أفطرت • اليوم $dayNumber من رمضان',
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
          autoDismissible: true,
          backgroundColor: const Color(0xFF0D1B2A),
        ),
        schedule: NotificationCalendar.fromDate(
          date: scheduledTime,
          preciseAlarm: true,
          allowWhileIdle: true,
        ),
      );
    } catch (e) {
      debugPrint("❌ Error scheduling Iftar notification: $e");
    }
  }

  /// Schedule Suhoor reminder at Fajr - offset minutes.
  static Future<void> scheduleSuhoor(DateTime fajrTime) async {
    if (!RamadanService.isDuringRamadan()) return;

    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_suhoorEnabledKey) ?? true;
    if (!enabled) return;

    final offsetMinutes = prefs.getInt(_suhoorOffsetKey) ?? 30;
    final scheduledTime = fajrTime.subtract(Duration(minutes: offsetMinutes));
    final now = DateTime.now();

    DateTime finalTime = scheduledTime;
    if (finalTime.isBefore(now)) {
      finalTime = finalTime.add(const Duration(days: 1));
    }

    final timeStr = DateFormat('HH:mm', 'ar').format(fajrTime);

    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _suhoorNotificationId,
          channelKey: _channelKey,
          title: '🍽️ تذكير السحور',
          body: 'باقي $offsetMinutes دقيقة على أذان الفجر ($timeStr) • تسحروا فإن في السحور بركة',
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
          autoDismissible: true,
          backgroundColor: const Color(0xFF1B3A2D),
        ),
        schedule: NotificationCalendar.fromDate(
          date: finalTime,
          preciseAlarm: true,
          allowWhileIdle: true,
        ),
      );
    } catch (e) {
      debugPrint("❌ Error scheduling Suhoor notification: $e");
    }
  }

  /// Schedule both Iftar and Suhoor from existing prayer times.
  /// Call this after prayer times are calculated.
  static Future<void> scheduleRamadanNotifications({
    required DateTime maghribTime,
    required DateTime fajrTime,
  }) async {
    if (!RamadanService.isDuringRamadan()) return;
    await scheduleIftar(maghribTime);
    await scheduleSuhoor(fajrTime);
  }

  /// Cancel all Ramadan notifications.
  static Future<void> cancelAll() async {
    await AwesomeNotifications().cancel(_iftarNotificationId);
    await AwesomeNotifications().cancel(_suhoorNotificationId);
  }

  // ── Preferences ──
  static Future<bool> isIftarEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_iftarEnabledKey) ?? true;
  }

  static Future<void> setIftarEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_iftarEnabledKey, v);
  }

  static Future<bool> isSuhoorEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_suhoorEnabledKey) ?? true;
  }

  static Future<void> setSuhoorEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_suhoorEnabledKey, v);
  }

  static Future<int> getSuhoorOffset() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_suhoorOffsetKey) ?? 30;
  }

  static Future<void> setSuhoorOffset(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_suhoorOffsetKey, minutes);
  }
}
