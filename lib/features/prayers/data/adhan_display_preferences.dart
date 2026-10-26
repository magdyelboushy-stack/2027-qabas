import 'package:shared_preferences/shared_preferences.dart';

class AdhanDisplayPreferences {
  static const String _themeKey = 'adhan_display_theme';
  static const String _fullscreenEnabledKey = 'adhan_fullscreen_enabled';
  static const String _autoDismissKey = 'adhan_auto_dismiss';
  static const String _showCountdownKey = 'adhan_show_countdown';

  // Theme
  static Future<String> getSelectedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? 'classic_mosque';
  }

  static Future<void> saveSelectedTheme(String themeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeId);
  }

  // Fullscreen enabled
  static Future<bool> isFullscreenEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_fullscreenEnabledKey) ?? true; // Default: enabled
  }

  static Future<void> setFullscreenEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_fullscreenEnabledKey, enabled);
  }

  // Auto dismiss
  static Future<bool> isAutoDismissEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoDismissKey) ?? true; // Default: enabled
  }

  static Future<void> setAutoDismiss(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoDismissKey, enabled);
  }

  // Show countdown
  static Future<bool> shouldShowCountdown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showCountdownKey) ?? false; // Default: disabled
  }

  static Future<void> setShowCountdown(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showCountdownKey, enabled);
  }
}
