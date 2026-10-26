import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimeFormatHelper {
  static Future<String> formatTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    final use24HourFormat = prefs.getBool('time_format_24hour') ?? true;

    if (use24HourFormat) {
      return DateFormat('HH:mm', 'ar').format(time);
    } else {
      return DateFormat('hh:mm a', 'ar').format(time);
    }
  }

  static Future<String> formatTimeWithLocale(DateTime time, String locale) async {
    final prefs = await SharedPreferences.getInstance();
    final use24HourFormat = prefs.getBool('time_format_24hour') ?? true;

    if (use24HourFormat) {
      return DateFormat('HH:mm', locale).format(time);
    } else {
      return DateFormat('hh:mm a', locale).format(time);
    }
  }

  static String formatTimeSync(DateTime time, bool use24HourFormat) {
    if (use24HourFormat) {
      return DateFormat('HH:mm', 'ar').format(time);
    } else {
      return DateFormat('hh:mm a', 'ar').format(time);
    }
  }

  static String formatTimeSyncWithLocale(DateTime time, bool use24HourFormat, String locale) {
    if (use24HourFormat) {
      return DateFormat('HH:mm', locale).format(time);
    } else {
      return DateFormat('hh:mm a', locale).format(time);
    }
  }
}
