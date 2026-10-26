import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/translations/app_locale_keys.dart';

enum QuranViewMode {
  list,   // وضع القائمة (آية آية)
  mushaf  // وضع المصحف (نص متصل)
}

/// ── ألوان خلفية المصحف ──
enum MushafThemePreset {
  classic,    // كلاسيكي - بيج
  white,      // أبيض
  sepia,      // سيبيا - بني فاتح
  greenLight, // أخضر فاتح
  nightBlue,  // أزرق ليلي - كحلي
  dark,       // داكن - أسود
}

class MushafThemeColors {
  final Color background;
  final Color textColor;
  final Color verseNumberColor;
  final Color headerColor;
  final Color infoBarBg;
  final Color infoBarText;
  final String nameKey;

  const MushafThemeColors({
    required this.background,
    required this.textColor,
    required this.verseNumberColor,
    required this.headerColor,
    required this.infoBarBg,
    required this.infoBarText,
    required this.nameKey,
  });

  /// هل الخلفية دي غامقة؟
  bool get isDarkBackground {
    final luminance = background.computeLuminance();
    return luminance < 0.4;
  }
}

/// خريطة الألوان لكل preset
const Map<MushafThemePreset, MushafThemeColors> mushafThemeMap = {
  MushafThemePreset.classic: MushafThemeColors(
    background: Color(0xFFF7F0DA),
    textColor: Color(0xFF23201A),
    verseNumberColor: Color(0xFF7B8A4A),
    headerColor: Color(0xFF7B8A4A),
    infoBarBg: Color(0xFFF7F0DA),
    infoBarText: Color(0xFF8A6E47),
    nameKey: AppLocaleKeys.themeClassic,
  ),
  MushafThemePreset.white: MushafThemeColors(
    background: Color(0xFFFFFFFE),
    textColor: Color(0xFF1A1A1A),
    verseNumberColor: Color(0xFF2E7D32),
    headerColor: Color(0xFF2E7D32),
    infoBarBg: Color(0xFFF5F5F5),
    infoBarText: Color(0xFF424242),
    nameKey: AppLocaleKeys.themeWhite,
  ),
  MushafThemePreset.sepia: MushafThemeColors(
    background: Color(0xFFF5E6C8),
    textColor: Color(0xFF3E2723),
    verseNumberColor: Color(0xFF8D6E63),
    headerColor: Color(0xFF6D4C41),
    infoBarBg: Color(0xFFF5E6C8),
    infoBarText: Color(0xFF5D4037),
    nameKey: AppLocaleKeys.themeSepia,
  ),
  MushafThemePreset.greenLight: MushafThemeColors(
    background: Color(0xFFE8F5E9),
    textColor: Color(0xFF1B5E20),
    verseNumberColor: Color(0xFF388E3C),
    headerColor: Color(0xFF2E7D32),
    infoBarBg: Color(0xFFE8F5E9),
    infoBarText: Color(0xFF2E7D32),
    nameKey: AppLocaleKeys.themeGreenLight,
  ),
  MushafThemePreset.nightBlue: MushafThemeColors(
    background: Color(0xFF0D1B2A),
    textColor: Color(0xFFE0E7EF),
    verseNumberColor: Color(0xFFFFD54F),
    headerColor: Color(0xFFFFD54F),
    infoBarBg: Color(0xFF0D1B2A),
    infoBarText: Color(0xFFB0BEC5),
    nameKey: AppLocaleKeys.themeNightBlue,
  ),
  MushafThemePreset.dark: MushafThemeColors(
    background: Color(0xFF121212),
    textColor: Color(0xFFE0E0E0),
    verseNumberColor: Color(0xFFFFD700),
    headerColor: Color(0xFFFFD700),
    infoBarBg: Color(0xFF1E1E1E),
    infoBarText: Color(0xFFBDBDBD),
    nameKey: AppLocaleKeys.themeDark,
  ),
};

class QuranSettingsProvider extends ChangeNotifier {
  QuranViewMode _viewMode = QuranViewMode.mushaf; // الوضع الافتراضي
  MushafThemePreset _mushafTheme = MushafThemePreset.classic;

  QuranViewMode get viewMode => _viewMode;
  MushafThemePreset get mushafTheme => _mushafTheme;
  MushafThemeColors get mushafColors => mushafThemeMap[_mushafTheme]!;

  QuranSettingsProvider() {
    _loadSettings();
  }

  void toggleViewMode() {
    if (_viewMode == QuranViewMode.list) {
      _viewMode = QuranViewMode.mushaf;
    } else {
      _viewMode = QuranViewMode.list;
    }
    _saveSettings();
    notifyListeners();
  }

  void setMushafTheme(MushafThemePreset theme) {
    _mushafTheme = theme;
    _saveSettings();
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isList = prefs.getBool('is_list_view') ?? false;
    _viewMode = isList ? QuranViewMode.list : QuranViewMode.mushaf;

    final themeIndex = prefs.getInt('mushaf_theme_preset') ?? 0;
    if (themeIndex >= 0 && themeIndex < MushafThemePreset.values.length) {
      _mushafTheme = MushafThemePreset.values[themeIndex];
    }
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_list_view', _viewMode == QuranViewMode.list);
    await prefs.setInt('mushaf_theme_preset', _mushafTheme.index);
  }
}