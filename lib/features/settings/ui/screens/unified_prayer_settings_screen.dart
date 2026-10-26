import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'dart:ui';
import 'dart:math' as math;

import '../../../../core/theme/theme_provider.dart';
import '../../../../core/translations/app_locale_keys.dart';
import '../../../prayers/logic/notification_manager.dart';
import '../../../prayers/data/models/adhan_theme_model.dart';
import '../../../prayers/data/adhan_display_preferences.dart';
import '../../../prayers/ui/screens/adhan_fullscreen_display.dart';
import '../../../prayers/logic/prayer_times_controller.dart';
import '../../../prayers/logic/adhan_audio_service.dart';
import '../../../intro/manual_location_screen.dart';

class UnifiedPrayerSettingsScreen extends StatefulWidget {
  const UnifiedPrayerSettingsScreen({super.key});

  @override
  State<UnifiedPrayerSettingsScreen> createState() =>
      _UnifiedPrayerSettingsScreenState();
}

class _UnifiedPrayerSettingsScreenState
    extends State<UnifiedPrayerSettingsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isDirty = false;

  // --- Logic Settings ---
  String _selectedMethod = 'egyptian';
  final Map<String, int> _offsets = {
    'fajr': 0,
    'sunrise': 0,
    'dhuhr': 0,
    'asr': 0,
    'maghrib': 0,
    'isha': 0
  };
  final Map<String, String> _sounds = {
    'fajr': 'mulla',
    'dhuhr': 'mulla',
    'asr': 'mulla',
    'maghrib': 'mulla',
    'isha': 'mulla'
  };
  final Map<String, bool> _muted = {
    'fajr': false,
    'dhuhr': false,
    'asr': false,
    'maghrib': false,
    'isha': false
  };

  // --- Display Settings ---
  String _selectedThemeId = 'classic_mosque';
  bool _fullscreenEnabled = true;
  bool _autoDismiss = true;
  bool _use24HourFormat = true;

  // --- Location Info ---
  String _locationSubtitle = "اضغط للاختيار من القائمة";

  // --- Audio Preview State ---
  String? _currentlyPlayingSound;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _animController.forward();
    _loadAllSettings();
  }

  Future<void> _loadAllSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _selectedMethod = prefs.getString('calculation_method') ?? 'egyptian';
    for (var prayer in _offsets.keys) {
      _offsets[prayer] = prefs.getInt('offset_$prayer') ?? 0;
    }

    String defaultSound = prefs.getString('adhan_sound') ?? 'mohamed_hosny';

    for (var prayer in _sounds.keys) {
      _sounds[prayer] = prefs.getString('sound_$prayer') ?? defaultSound;
    }
    for (var prayer in _muted.keys) {
      _muted[prayer] = prefs.getBool('mute_$prayer') ?? false;
    }

    _selectedThemeId = await AdhanDisplayPreferences.getSelectedTheme();
    _fullscreenEnabled = await AdhanDisplayPreferences.isFullscreenEnabled();
    _autoDismiss = await AdhanDisplayPreferences.isAutoDismissEnabled();
    _use24HourFormat = prefs.getBool('time_format_24hour') ?? true;

    String? city = prefs.getString('manual_city');
    String? country = prefs.getString('manual_country');
    bool isManual = prefs.getBool('manual_location_chosen') ?? false;

    if (isManual && city != null) {
      _locationSubtitle = "الموقع الحالي: $city, ${country ?? ''}";
    } else {
      String? cachedCity = prefs.getString('cached_city');
      if (cachedCity != null) {
        _locationSubtitle =
            "الموقع التلقائي: $cachedCity (${prefs.getString('cached_country') ?? ''})";
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAllSettings() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('calculation_method', _selectedMethod);

    for (var prayer in _offsets.keys) {
      await prefs.setInt('offset_$prayer', _offsets[prayer]!);
    }

    for (var prayer in _sounds.keys) {
      await prefs.setString('sound_$prayer', _sounds[prayer]!);
    }

    for (var prayer in _muted.keys) {
      await prefs.setBool('mute_$prayer', _muted[prayer]!);
    }

    await AdhanDisplayPreferences.saveSelectedTheme(_selectedThemeId);
    await AdhanDisplayPreferences.setFullscreenEnabled(_fullscreenEnabled);
    await AdhanDisplayPreferences.setAutoDismiss(_autoDismiss);
    await prefs.setBool('time_format_24hour', _use24HourFormat);

    await NotificationManager.rescheduleAllNotifications();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isDirty = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocaleKeys.settingsSavedSuccess.tr,
              style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context);
    }
  }

  void _previewFullscreen() {
    AdhanAudioService().stopAdhan();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdhanFullscreenDisplay(
          prayerName: 'الفجر',
          prayerTime: '4:30 صباحاً',
          soundId: 'mulla',
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _togglePlayPreview(String soundId) {
    if (_currentlyPlayingSound == soundId) {
      AdhanAudioService().stopAdhan();
      setState(() => _currentlyPlayingSound = null);
    } else {
      AdhanAudioService().stopAdhan();
      AdhanAudioService().playAdhan(soundId);
      setState(() => _currentlyPlayingSound = soundId);
    }
  }

  @override
  void dispose() {
    AdhanAudioService().stopAdhan();
    _animController.dispose();
    _currentlyPlayingSound = null;
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) {
      setState(() => _isDirty = true);
    }
  }

  Future<void> _resetLocationToDefault() async {
    final controller = PrayerTimesController();
    await controller.resetLocationToDefault();
    await _loadAllSettings();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocaleKeys.settingsLocationReset.tr,
              style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final accentGold = isDark ? const Color(0xFF2A8B68) : const Color(0xFF105B52);

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0E241E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: accentGold.withOpacity(0.3)),
          ),
          title: Row(
            children: [
              Icon(FontAwesomeIcons.floppyDisk, color: accentGold, size: 20),
              const SizedBox(width: 10),
              Text(AppLocaleKeys.saveChanges.tr,
                  style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
            ],
          ),
          content: Text(
            AppLocaleKeys.unsavedChanges.tr,
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(AppLocaleKeys.commonCancel.tr,
                  style: const TextStyle(color: Colors.red, fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                _saveAllSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentGold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(AppLocaleKeys.commonSave.tr,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'Cairo')),
            ),
          ],
        );
      },
    );
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final accentGold = isDark ? const Color(0xFF2A8B68) : const Color(0xFF105B52);
    final backgroundColor = isDark ? const Color(0xFF0E241E) : const Color(0xFFF5F7FA);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: textColor),
              onPressed: () => _onWillPop().then((canPop) {
                if (canPop && Navigator.canPop(context)) Navigator.pop(context);
              }),
            ),
            title: Text(
              "إعدادات الصلاة والأذان",
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: Stack(
            children: [
              Container(
                decoration: isDark
                    ? const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/background.png'),
                          fit: BoxFit.cover,
                        ),
                      )
                    : BoxDecoration(
                        color: backgroundColor,
                      ),
              ),
              if (isDark)
                Container(
                  color: const Color(0xFF071814).withOpacity(0.85),
                ),
              SafeArea(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: accentGold))
                    : FadeTransition(
                        opacity: _animController,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildSectionTitle(AppLocaleKeys.settingsLocationAndMethod.tr,
                                  FontAwesomeIcons.locationDot, accentGold),
                              const SizedBox(height: 15),
                              _buildLocationAndMethod(isDark, accentGold, textColor),
                              const SizedBox(height: 30),

                              _buildSectionTitle(AppLocaleKeys.settingsDisplayPreview.tr,
                                  FontAwesomeIcons.mobileScreen, accentGold),
                              const SizedBox(height: 15),
                              _buildDisplaySettings(isDark, accentGold, textColor),
                              const SizedBox(height: 30),

                              _buildSectionTitle(AppLocaleKeys.settingsSoundAndNotifications.tr,
                                  FontAwesomeIcons.volumeHigh, accentGold),
                              const SizedBox(height: 15),
                              _buildPrayerList(isDark, accentGold, textColor),
                              const SizedBox(height: 40),

                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentGold.withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    )
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isDirty ? _saveAllSettings : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accentGold,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    AppLocaleKeys.settingsSaveSettings.tr,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color accentGold) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accentGold.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: accentGold, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            fontFamily: 'Cairo',
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassContainer({required Widget child, required bool isDark, required Color accentGold}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildLocationAndMethod(bool isDark, Color accentGold, Color textColor) {
    return _buildGlassContainer(
      isDark: isDark,
      accentGold: accentGold,
      child: Column(
        children: [
          InkWell(
            onTap: () async {
              final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ManualLocationScreen()));
              if (result == true) {
                _loadAllSettings();
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A2F4A).withOpacity(0.5) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(FontAwesomeIcons.mapLocationDot, color: accentGold),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocaleKeys.settingsSetLocationGeographically.tr,
                          style: TextStyle(
                              color: textColor,
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _locationSubtitle,
                          style: TextStyle(
                              color: textColor.withOpacity(0.6),
                              fontFamily: 'Cairo',
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      color: textColor.withOpacity(0.5), size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _resetLocationToDefault,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(FontAwesomeIcons.arrowRotateLeft, color: Colors.red, size: 18),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      AppLocaleKeys.settingsResetDefaultLocation.tr,
                      style: TextStyle(
                          color: Colors.red,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2F4A).withOpacity(0.5) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedMethod,
              dropdownColor: isDark ? const Color(0xFF1A2F4A) : Colors.white,
              icon: Icon(Icons.keyboard_arrow_down, color: accentGold),
              decoration: InputDecoration(
                labelText: AppLocaleKeys.settingsCalculationMethod.tr,
                labelStyle: TextStyle(
                    color: accentGold,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600),
                border: InputBorder.none,
                prefixIcon: Icon(FontAwesomeIcons.calculator,
                    color: accentGold, size: 18),
              ),
              style: TextStyle(
                  color: textColor, fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold),
              items: const [
                DropdownMenuItem(value: 'egyptian', child: Text('الهيئة المصرية العامة للمساحة')),
                DropdownMenuItem(value: 'umm_al_qura', child: Text('أم القرى (السعودية)')),
                DropdownMenuItem(value: 'mwl', child: Text('رابطة العالم الإسلامي')),
                DropdownMenuItem(value: 'karachi', child: Text('جامعة العلوم بكراتشي')),
                DropdownMenuItem(value: 'isna', child: Text('أمريكا الشمالية (ISNA)')),
                DropdownMenuItem(value: 'dubai', child: Text('دبي')),
                DropdownMenuItem(value: 'kuwait', child: Text('الكويت')),
                DropdownMenuItem(value: 'qatar', child: Text('قطر')),
                DropdownMenuItem(value: 'turkey', child: Text('تركيا')),
              ],
              onChanged: (val) {
                setState(() => _selectedMethod = val!);
                _markDirty();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplaySettings(bool isDark, Color accentGold, Color textColor) {
    return _buildGlassContainer(
      isDark: isDark,
      accentGold: accentGold,
      child: Column(
        children: [
          SwitchListTile(
            title: Text(
              AppLocaleKeys.settingsShowFullscreen.tr,
              style: TextStyle(color: textColor, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              AppLocaleKeys.settingsShowFullscreen.tr,
              style: TextStyle(color: textColor.withOpacity(0.6), fontFamily: 'Cairo', fontSize: 12),
            ),
            value: _fullscreenEnabled,
            activeColor: accentGold,
            onChanged: (val) {
              setState(() => _fullscreenEnabled = val);
              _markDirty();
            },
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(FontAwesomeIcons.mobileScreenButton, color: accentGold, size: 20),
            ),
          ),
          Divider(color: textColor.withOpacity(0.1), height: 20),
          SwitchListTile(
            title: Text(
              AppLocaleKeys.settingsAutoCloseScreen.tr,
              style: TextStyle(color: textColor, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              AppLocaleKeys.settingsAutoCloseDesc.tr,
              style: TextStyle(color: textColor.withOpacity(0.6), fontFamily: 'Cairo', fontSize: 12),
            ),
            value: _autoDismiss,
            activeColor: accentGold,
            onChanged: (val) {
              setState(() => _autoDismiss = val);
              _markDirty();
            },
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(FontAwesomeIcons.clockRotateLeft, color: accentGold, size: 20),
            ),
          ),
          Divider(color: textColor.withOpacity(0.1), height: 20),
          SwitchListTile(
            title: Text(
              AppLocaleKeys.settingsTimeFormat.tr,
              style: TextStyle(color: textColor, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _use24HourFormat ? AppLocaleKeys.settings24HourFormat.tr : AppLocaleKeys.settings12HourFormat.tr,
              style: TextStyle(color: textColor.withOpacity(0.6), fontFamily: 'Cairo', fontSize: 12),
            ),
            value: _use24HourFormat,
            activeColor: accentGold,
            onChanged: (val) {
              setState(() => _use24HourFormat = val);
              _markDirty();
            },
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(FontAwesomeIcons.clock, color: accentGold, size: 20),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              AppLocaleKeys.settingsChooseDesign.tr,
              style: TextStyle(color: textColor, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: AdhanTheme.allThemes.length,
              itemBuilder: (context, index) {
                final theme = AdhanTheme.allThemes[index];
                final isSelected = _selectedThemeId == theme.id;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedThemeId = theme.id);
                    _markDirty();
                  },
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? accentGold : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: accentGold.withOpacity(0.4), blurRadius: 10)]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          theme.backgroundImage != null
                              ? Image.asset(theme.backgroundImage!, fit: BoxFit.cover)
                              : Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: theme.backgroundGradient,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                ),
                          if (isSelected)
                            Container(
                              color: Colors.black45,
                              child: const Icon(Icons.check, color: Colors.white, size: 30),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _previewFullscreen,
              icon: Icon(FontAwesomeIcons.eye, color: accentGold, size: 16),
              label: Text(AppLocaleKeys.preview.tr, style: TextStyle(color: accentGold, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: accentGold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPrayerList(bool isDark, Color accentGold, Color textColor) {
    final prayers = [
      {'id': 'fajr', 'nameKey': AppLocaleKeys.fajr, 'icon': FontAwesomeIcons.cloudSun},
      {'id': 'sunrise', 'nameKey': AppLocaleKeys.sunrise, 'icon': FontAwesomeIcons.sun},
      {'id': 'dhuhr', 'nameKey': AppLocaleKeys.dhuhr, 'icon': FontAwesomeIcons.sun},
      {'id': 'asr', 'nameKey': AppLocaleKeys.asr, 'icon': FontAwesomeIcons.cloudSun},
      {'id': 'maghrib', 'nameKey': AppLocaleKeys.maghrib, 'icon': FontAwesomeIcons.moon},
      {'id': 'isha', 'nameKey': AppLocaleKeys.isha, 'icon': FontAwesomeIcons.starAndCrescent},
    ];

    return _buildGlassContainer(
      isDark: isDark,
      accentGold: accentGold,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: prayers.length,
        separatorBuilder: (_, __) => Divider(color: textColor.withOpacity(0.1), height: 24),
        itemBuilder: (context, index) {
          final p = prayers[index];
          final pid = p['id'] as String;
          final isSunrise = pid == 'sunrise';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentGold.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(p['icon'] as IconData, color: accentGold, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    (p['nameKey'] as String).tr,
                    style: TextStyle(
                      color: textColor,
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (!isSunrise)
                    IconButton(
                      icon: Icon(
                        _muted[pid]! ? Icons.volume_off : Icons.volume_up,
                        color: _muted[pid]! ? Colors.redAccent : accentGold,
                      ),
                      onPressed: () {
                        setState(() => _muted[pid] = !_muted[pid]!);
                        _markDirty();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (!isSunrise)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: textColor.withOpacity(0.05)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      dropdownColor: isDark ? const Color(0xFF1A2F4A) : Colors.white,
                      value: _sounds[pid],
                      icon: Icon(Icons.keyboard_arrow_down, color: accentGold),
                      style: TextStyle(color: textColor, fontFamily: 'Cairo', fontSize: 14),
                      items: const [
                        DropdownMenuItem(value: 'mulla', child: Text('الشيخ علي ملا (الحرم المكي)')),
                        DropdownMenuItem(value: 'mohamed_hosny', child: Text('الشيخ محمد حسني')),
                        DropdownMenuItem(value: 'al_aqsa', child: Text('المسجد الأقصى')),
                        DropdownMenuItem(value: 'mahmoud_khalil', child: Text('الشيخ محمود خليل الحصري')),
                        DropdownMenuItem(value: 'abdul_basit', child: Text('الشيخ عبد الباسط عبد الصمد')),
                        DropdownMenuItem(value: 'mishary_alafasy', child: Text('الشيخ مشاري العفاسي')),
                        DropdownMenuItem(value: 'mansour_az_zahrani', child: Text('الشيخ منصور الزهراني')),
                      ],
                      onChanged: (val) {
                        setState(() => _sounds[pid] = val!);
                        _markDirty();
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(AppLocaleKeys.adjustTimeMinutes.tr, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: accentGold,
                        inactiveTrackColor: accentGold.withOpacity(0.2),
                        thumbColor: accentGold,
                        overlayColor: accentGold.withOpacity(0.2),
                      ),
                      child: Slider(
                        value: _offsets[pid]!.toDouble(),
                        min: -30,
                        max: 30,
                        divisions: 60,
                        label: _offsets[pid]!.toString(),
                        onChanged: (val) {
                          setState(() => _offsets[pid] = val.toInt());
                          _markDirty();
                        },
                      ),
                    ),
                  ),
                  Text('${_offsets[pid]} د', style: TextStyle(color: accentGold, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 14)),
                ],
              ),
              if (!isSunrise)
                 Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      icon: Icon(
                          _currentlyPlayingSound == _sounds[pid] ? Icons.stop : Icons.play_arrow,
                          color: accentGold, size: 16),
                      label: Text(
                          _currentlyPlayingSound == _sounds[pid] ? AppLocaleKeys.stopPreview.tr : AppLocaleKeys.previewSound.tr,
                          style: TextStyle(color: accentGold, fontFamily: 'Cairo', fontSize: 12)),
                      onPressed: () => _togglePlayPreview(_sounds[pid]!),
                    ),
                 ),
            ],
          );
        },
      ),
    );
  }
}
