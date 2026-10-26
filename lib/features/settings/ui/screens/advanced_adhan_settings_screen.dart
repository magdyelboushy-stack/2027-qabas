import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:mihrab/core/translations/app_locale_keys.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../prayers/logic/notification_manager.dart';
import '../../../../core/widgets/glass_card.dart';

class AdvancedAdhanSettingsScreen extends StatefulWidget {
  const AdvancedAdhanSettingsScreen({super.key});

  @override
  State<AdvancedAdhanSettingsScreen> createState() => _AdvancedAdhanSettingsScreenState();
}

class _AdvancedAdhanSettingsScreenState extends State<AdvancedAdhanSettingsScreen> {
  // 1. Global Settings
  String _selectedMethod = 'egyptian';
  String _selectedMadhab = 'shafi';
  
  // 2. Per-Prayer Settings (Offsets & Sounds)
  final Map<String, int> _offsets = {
    'fajr': 0, 'sunrise': 0, 'dhuhr': 0, 'asr': 0, 'maghrib': 0, 'isha': 0
  };
  final Map<String, String> _sounds = {
    'fajr': 'mulla', 'dhuhr': 'mulla', 'asr': 'mulla', 'maghrib': 'mulla', 'isha': 'mulla'
  };
  final Map<String, bool> _muted = {
    'fajr': false, 'dhuhr': false, 'asr': false, 'maghrib': false, 'isha': false
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedMethod = prefs.getString('calculation_method') ?? 'egyptian';
      _selectedMadhab = prefs.getString('madhab') ?? 'shafi';
      
      // Load offsets
      for (var prayer in _offsets.keys) {
        _offsets[prayer] = prefs.getInt('offset_$prayer') ?? 0;
      }
      // Load sounds (default to 'mulla' or 'fajr_mulla' logic if needed, but simple for now)
      for (var prayer in _sounds.keys) {
        _sounds[prayer] = prefs.getString('sound_$prayer') ?? 'mulla';
      }
      // Load muted state
      for (var prayer in _muted.keys) {
        _muted[prayer] = prefs.getBool('mute_$prayer') ?? false;
      }
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('calculation_method', _selectedMethod);
    await prefs.setString('madhab', _selectedMadhab);
    
    for (var entry in _offsets.entries) {
      await prefs.setInt('offset_${entry.key}', entry.value);
    }
    for (var entry in _sounds.entries) {
      await prefs.setString('sound_${entry.key}', entry.value);
    }
    for (var entry in _muted.entries) {
      await prefs.setBool('mute_${entry.key}', entry.value);
    }

    // 🔥 Reschedule Notifications to apply changes
    await NotificationManager.rescheduleAllNotifications();
    
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocaleKeys.settingsSavedSuccessAdhan.tr),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark;
    
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final iconColor = isDark ? Colors.cyanAccent : Theme.of(context).primaryColor;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: isDark
                  ? const BoxDecoration(
                      image: DecorationImage(image: AssetImage('assets/background.png'), fit: BoxFit.cover),
                    )
                  : BoxDecoration(color: Colors.grey[100]),
            ),
            if (isDark) Container(color: const Color(0xFF071814).withOpacity(0.85)),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios, color: textColor),
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "إعدادات الأذان المتقدمة",
                          style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            children: [
                              _buildSectionHeader('طريقة الحساب والمذهب', isDark),
                              _buildCalculationSettings(isDark, textColor, subTextColor, iconColor),
                              const SizedBox(height: 25),
                              _buildSectionHeader('تخصيص الصلوات', isDark),
                              _buildPrayerList(isDark, textColor, subTextColor, iconColor),
                              const SizedBox(height: 25),
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: _saveSettings,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: iconColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  ),
                                  child: Text(
                                    'حفظ التغييرات',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.black : Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: isDark ? Colors.cyanAccent : Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildCalculationSettings(bool isDark, Color textColor, Color subTextColor, Color iconColor) {
    return GlassCard(
      borderRadius: BorderRadius.circular(15),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _selectedMethod,
            dropdownColor: isDark ? const Color(0xFF1A2F4A) : Colors.white,
            decoration: InputDecoration(
              labelText: AppLocaleKeys.calculationMethod.tr,
              labelStyle: TextStyle(color: iconColor, fontWeight: FontWeight.w600),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.calculate_rounded, color: iconColor),
            ),
            style: TextStyle(color: textColor, fontSize: 14),
            items: const [
              DropdownMenuItem(value: 'egyptian', child: Text('الهيئة المصرية العامة للمساحة')),
              DropdownMenuItem(value: 'umm_al_qura', child: Text('أم القرى (السعودية)')),
              DropdownMenuItem(value: 'mwl', child: Text('رابطة العالم الإسلامي')),
              DropdownMenuItem(value: 'karachi', child: Text('جامعة العلوم الإسلامية بكراتشي')),
              DropdownMenuItem(value: 'isna', child: Text('أمريكا الشمالية (ISNA)')),
              DropdownMenuItem(value: 'dubai', child: Text('دبي')),
              DropdownMenuItem(value: 'kuwait', child: Text('الكويت')),
              DropdownMenuItem(value: 'qatar', child: Text('قطر')),
              DropdownMenuItem(value: 'turkey', child: Text('تركيا')),
            ],
            onChanged: (val) => setState(() => _selectedMethod = val!),
          ),
          const SizedBox(height: 12),
          Divider(color: isDark ? Colors.white10 : Colors.grey.shade300),
          SwitchListTile(
            title: Text('المذهب الحنفي (العصر)', style: TextStyle(color: textColor)),
            subtitle: Text('تفعيل لحساب العصر حسب المذهب الحنفي', style: TextStyle(color: subTextColor, fontSize: 12)),
            value: _selectedMadhab == 'hanafi',
            activeColor: iconColor,
            onChanged: (val) => setState(() => _selectedMadhab = val ? 'hanafi' : 'shafi'),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerList(bool isDark, Color textColor, Color subTextColor, Color iconColor) {
    final prayers = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']; // English keys for map
    final displayNames = ['الفجر', 'الشروق', 'الظهر', 'العصر', 'المغرب', 'العشاء'];

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: prayers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final key = prayers[index].toLowerCase();
        final name = displayNames[index];
        // Don't show sound settings for Sunrise (no Adhan)
        final isSunrise = key == 'sunrise';

        return GlassCard(
          borderRadius: BorderRadius.circular(15),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                  const Spacer(),
                  if (!isSunrise)
                    Container(
                      decoration: BoxDecoration(
                        color: _muted[key] == true ? Colors.red.withOpacity(0.08) : Colors.green.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: Icon(_muted[key] == true ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                            color: _muted[key] == true ? Colors.red : Colors.green),
                        onPressed: () => setState(() => _muted[key] = !(_muted[key] ?? false)),
                      ),
                    ),
                ],
              ),
              Divider(color: isDark ? Colors.white10 : Colors.grey.shade300),
              if (!isSunrise) ...[
                // Sound Selector
                Row(
                  children: [
                    Icon(Icons.person, size: 18, color: iconColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _sounds[key],
                        isExpanded: true,
                        underline: Container(),
                        dropdownColor: isDark ? const Color(0xFF1A2F4A) : Colors.white,
                        items: _getSoundOptions(key),
                        onChanged: (val) => setState(() => _sounds[key] = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              
              // Time Adjuster
              Row(
                children: [
                  Icon(Icons.access_time, size: 18, color: iconColor),
                  const SizedBox(width: 10),
                  Text("تعديل الوقت: ", style: TextStyle(fontSize: 12, color: textColor)),
                  const Spacer(),
                  _buildStepper(key, isDark, iconColor, textColor),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepper(String key, bool isDark, Color iconColor, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.remove, size: 16, color: iconColor),
            onPressed: () => setState(() => _offsets[key] = (_offsets[key] ?? 0) - 1),
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            padding: EdgeInsets.zero,
          ),
          Text("${_offsets[key]} د", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
          IconButton(
            icon: Icon(Icons.add, size: 16, color: iconColor),
            onPressed: () => setState(() => _offsets[key] = (_offsets[key] ?? 0) + 1),
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<String>> _getSoundOptions(String key) {
    // Verified list based on assets/sounds/
    // abd_toba.mp3, fajr_mulla.mp3, fajr_qassas.mp3, mohamed_hosny.mp3, mulla.mp3, qassas.mp3, ramadan.mp3, refaat.mp3, takbeer.mp3
    
    final options = [
      const DropdownMenuItem(value: 'mulla', child: Text('ناصر القطامي (مكة)')),
      const DropdownMenuItem(value: 'qassas', child: Text('عبدالمجيد السريحي (القصاص)')),
      const DropdownMenuItem(value: 'mohamed_hosny', child: Text('محمد حسني')),
      const DropdownMenuItem(value: 'abd_toba', child: Text('عبد التواب')),
      const DropdownMenuItem(value: 'ramadan', child: Text('رمضان')),
      const DropdownMenuItem(value: 'refaat', child: Text('محمد رفعت')),
      const DropdownMenuItem(value: 'takbeer', child: Text('تكيبرات فقط')),
    ];

    // If it's Fajr, we might want to allow specific Fajr versions if the user wants to force them,
    // OR we relies on the system to swap them. 
    // Ideally, for simplicity, we show the main muezzin names.
    // The system should switch to 'fajr_mulla' if 'mulla' is selected for Fajr.
    // I will handle this in NotificationManager payload logic to ensure AudioService plays the correct file.
    
    return options;
  }
}
