import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _fontSizeKey = 'font_size_multiplier';

  late SharedPreferences _prefs;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  double _fontScale = 1.0;
  double get fontScale => _fontScale;

  ThemeProvider() {
    _loadSettings();
  }

  bool get isDarkMode {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();

    final themeIndex = _prefs.getInt(_themeKey);
    if (themeIndex != null && themeIndex >= 0 && themeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[themeIndex];
    } else {
      _themeMode = ThemeMode.system;
    }

    _fontScale = _prefs.getDouble(_fontSizeKey) ?? 1.0;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    _prefs.setInt(_themeKey, mode.index);
    notifyListeners();
  }

  void toggleTheme() {
    setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }

  void setFontScale(double scale) {
    if (_fontScale == scale) return;
    _fontScale = scale;
    _prefs.setDouble(_fontSizeKey, scale);
    notifyListeners();
  }

  ThemeData getLightTheme() => _applyScaling(AppTheme.lightTheme);

  ThemeData getDarkTheme() => _applyScaling(AppTheme.darkTheme);

  ThemeData _applyScaling(ThemeData base) {
    if (_fontScale == 1.0) return base;
    return base.copyWith(
      textTheme: _scaleTextTheme(base.textTheme, _fontScale),
    );
  }

  ThemeData getThemeData(BuildContext context) {
    return isDarkMode ? getDarkTheme() : getLightTheme();
  }

  TextTheme _scaleTextTheme(TextTheme theme, double scale) {
    return theme.copyWith(
      displayLarge: _safeScale(theme.displayLarge, scale),
      displayMedium: _safeScale(theme.displayMedium, scale),
      displaySmall: _safeScale(theme.displaySmall, scale),
      headlineLarge: _safeScale(theme.headlineLarge, scale),
      headlineMedium: _safeScale(theme.headlineMedium, scale),
      headlineSmall: _safeScale(theme.headlineSmall, scale),
      titleLarge: _safeScale(theme.titleLarge, scale),
      titleMedium: _safeScale(theme.titleMedium, scale),
      titleSmall: _safeScale(theme.titleSmall, scale),
      bodyLarge: _safeScale(theme.bodyLarge, scale),
      bodyMedium: _safeScale(theme.bodyMedium, scale),
      bodySmall: _safeScale(theme.bodySmall, scale),
      labelLarge: _safeScale(theme.labelLarge, scale),
      labelMedium: _safeScale(theme.labelMedium, scale),
      labelSmall: _safeScale(theme.labelSmall, scale),
    );
  }

  TextStyle? _safeScale(TextStyle? style, double factor) {
    if (style == null) return null;
    final currentSize = style.fontSize ?? 14.0;
    return style.copyWith(fontSize: currentSize * factor);
  }
}
