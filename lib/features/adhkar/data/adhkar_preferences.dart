import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdhkarPreferences {
  static const String _hapticsKey = 'adhkar_haptics_enabled';

  static Future<bool> isHapticsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hapticsKey) ?? true;
  }

  static Future<void> setHapticsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticsKey, enabled);
  }

  static Future<void> lightImpact() async {
    if (await isHapticsEnabled()) {
      HapticFeedback.lightImpact();
    }
  }

  static Future<void> mediumImpact() async {
    if (await isHapticsEnabled()) {
      HapticFeedback.mediumImpact();
    }
  }

  static Future<void> selectionClick() async {
    if (await isHapticsEnabled()) {
      HapticFeedback.selectionClick();
    }
  }
}
