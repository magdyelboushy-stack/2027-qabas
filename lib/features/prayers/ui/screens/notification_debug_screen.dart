import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:adhan/adhan.dart';
import '../../logic/notification_manager.dart';
import '../../logic/prayer_times_controller.dart';

class NotificationDebugScreen extends StatefulWidget {
  const NotificationDebugScreen({super.key});

  @override
  State<NotificationDebugScreen> createState() =>
      _NotificationDebugScreenState();
}

class _NotificationDebugScreenState extends State<NotificationDebugScreen> {
  bool _globalEnabled = false;
  int _scheduledCount = 0;
  List<String> _scheduledPrayers = [];
  Map<String, dynamic> _settings = {};
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    try {
      // 1. Check global state
      final globalEnabled = await NotificationManager.getGlobalNotifications();

      // 2. Check scheduled notifications
      final scheduled =
          await AwesomeNotifications().listScheduledNotifications();
      final prayerNotifs = scheduled
          .where((n) => n.content?.channelKey == 'adhan_channel_v2')
          .toList();

      // 3. Load settings
      final prefs = await SharedPreferences.getInstance();
      final settings = {
        'adhan_sound': prefs.getString('adhan_sound') ?? 'not set',
        'sound_fajr': prefs.getString('sound_fajr') ?? 'not set',
        'sound_dhuhr': prefs.getString('sound_dhuhr') ?? 'not set',
        'sound_asr': prefs.getString('sound_asr') ?? 'not set',
        'sound_maghrib': prefs.getString('sound_maghrib') ?? 'not set',
        'sound_isha': prefs.getString('sound_isha') ?? 'not set',
        'latitude': prefs.getDouble('latitude')?.toString() ?? 'not set',
        'longitude': prefs.getDouble('longitude')?.toString() ?? 'not set',
        'city': prefs.getString('city') ?? 'not set',
        'country': prefs.getString('country') ?? 'not set',
        'calculation_method':
            prefs.getString('calculation_method') ?? 'not set',
      };

      // 4. Get prayer times
      PrayerTimes? times;
      String timesError = '';
      try {
        times = await PrayerTimesController().getStoredOrDefaultPrayerTimes();
      } catch (e) {
        timesError = 'Error getting prayer times: $e';
      }

      setState(() {
        _globalEnabled = globalEnabled;
        _scheduledCount = prayerNotifs.length;
        _scheduledPrayers = prayerNotifs
            .map((n) =>
                '${n.content?.title ?? 'Unknown'} - ${n.schedule?.toMap()}')
            .toList();
        _settings = settings;
        _errorMessage = times == null
            ? (timesError.isEmpty
                ? 'Prayer times not available! (Location not set?)'
                : timesError)
            : '';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading debug info: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تشخيص الإشعارات'),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Global State
          Card(
            child: ListTile(
              title: const Text('حالة الإشعارات العامة'),
              subtitle: Text(_globalEnabled ? 'مفعلة ✅' : 'معطلة ❌'),
              leading: Icon(
                _globalEnabled
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                color: _globalEnabled ? Colors.green : Colors.red,
              ),
            ),
          ),

          // Scheduled Count
          Card(
            child: ListTile(
              title: const Text('عدد الإشعارات المجدولة'),
              subtitle: Text('$_scheduledCount إشعار'),
              leading: Icon(
                Icons.schedule,
                color: _scheduledCount > 0 ? Colors.green : Colors.orange,
              ),
            ),
          ),

          // Scheduled Prayers
          if (_scheduledPrayers.isNotEmpty)
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'الإشعارات المجدولة:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ..._scheduledPrayers.map((s) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.check_circle,
                            color: Colors.green, size: 16),
                        title: Text(s),
                      )),
                ],
              ),
            ),

          // Settings
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'الإعدادات المحفوظة:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ..._settings.entries.map((e) => ListTile(
                      dense: true,
                      title: Text(e.key),
                      subtitle: Text(e.value.toString()),
                    )),
              ],
            ),
          ),

          // Error
          if (_errorMessage.isNotEmpty)
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ),

          // Action Buttons
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                // First check if global notifications are enabled
                final globalEnabled =
                    await NotificationManager.getGlobalNotifications();
                if (!globalEnabled) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          '⚠️ تفعيل الأذان مطفي! روح Settings وشغله الأول'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                final times = await PrayerTimesController()
                    .getStoredOrDefaultPrayerTimes();
                await NotificationManager.schedulePrayers(times);
                await NotificationManager.scheduleAdhkar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ تم إعادة جدولة الإشعارات بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
                // Wait a bit then reload
                await Future.delayed(const Duration(milliseconds: 500));
                _loadDebugInfo();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ خطأ أثناء الجدولة: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة جدولة الإشعارات'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
            ),
          ),

          ElevatedButton.icon(
            onPressed: _loadDebugInfo,
            icon: const Icon(Icons.sync),
            label: const Text('تحديث المعلومات'),
          ),
        ],
      ),
    );
  }
}
