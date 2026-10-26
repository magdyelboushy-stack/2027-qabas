import 'package:flutter/material.dart';
import '../../../prayers/data/models/adhan_theme_model.dart';
import '../../../prayers/data/adhan_display_preferences.dart';
import '../../../prayers/ui/screens/adhan_fullscreen_display.dart';
import '../../../../core/widgets/glass_card.dart';

class AdhanDisplaySettingsScreen extends StatefulWidget {
  const AdhanDisplaySettingsScreen({super.key});

  @override
  State<AdhanDisplaySettingsScreen> createState() =>
      _AdhanDisplaySettingsScreenState();
}

class _AdhanDisplaySettingsScreenState
    extends State<AdhanDisplaySettingsScreen> {
  String _selectedThemeId = 'classic_mosque';
  bool _fullscreenEnabled = true;
  bool _autoDismiss = true;
  bool _showCountdown = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final themeId = await AdhanDisplayPreferences.getSelectedTheme();
    final fullscreen = await AdhanDisplayPreferences.isFullscreenEnabled();
    final autoDismiss = await AdhanDisplayPreferences.isAutoDismissEnabled();
    final countdown = await AdhanDisplayPreferences.shouldShowCountdown();

    setState(() {
      _selectedThemeId = themeId;
      _fullscreenEnabled = fullscreen;
      _autoDismiss = autoDismiss;
      _showCountdown = countdown;
    });
  }

  Future<void> _saveTheme(String themeId) async {
    await AdhanDisplayPreferences.saveSelectedTheme(themeId);
    setState(() {
      _selectedThemeId = themeId;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ التصميم ✅', style: TextStyle()),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _toggleFullscreen(bool value) async {
    await AdhanDisplayPreferences.setFullscreenEnabled(value);
    setState(() {
      _fullscreenEnabled = value;
    });
  }

  Future<void> _toggleAutoDismiss(bool value) async {
    await AdhanDisplayPreferences.setAutoDismiss(value);
    setState(() {
      _autoDismiss = value;
    });
  }

  Future<void> _toggleCountdown(bool value) async {
    await AdhanDisplayPreferences.setShowCountdown(value);
    setState(() {
      _showCountdown = value;
    });
  }

  void _previewFullscreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdhanFullscreenDisplay(
          prayerName: 'الفجر',
          prayerTime: '4:30 صباحاً',
          soundId: 'mulla', // ✅ Dummy sound for preview
        ),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark ? Colors.cyanAccent : Theme.of(context).primaryColor;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            // Background
            Container(
              decoration: isDark
                  ? const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/background.png'),
                        fit: BoxFit.cover,
                      ),
                    )
                  : BoxDecoration(color: Colors.grey[100]),
            ),

            // Dimming Layer
            if (isDark)
              Container(color: const Color(0xFF071814).withOpacity(0.85)),

            SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios, color: iconColor),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'إعدادات عرض الأذان',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        // Enable Fullscreen Toggle
                        _buildToggleCard(
                          title: 'تفعيل الشاشة الكاملة',
                          subtitle: 'عرض شاشة كاملة عند وقت الأذان',
                          value: _fullscreenEnabled,
                          onChanged: _toggleFullscreen,
                          isDark: isDark,
                        ),

                        const SizedBox(height: 20),

                        // Theme Selection Section
                        Text(
                          'اختر التصميم',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            
                          ),
                        ),

                        const SizedBox(height: 15),

                        // Theme Grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: AdhanTheme.allThemes.length,
                          itemBuilder: (context, index) {
                            final theme = AdhanTheme.allThemes[index];
                            final isSelected = theme.id == _selectedThemeId;
                            return _buildThemeCard(theme, isSelected, isDark);
                          },
                        ),

                        const SizedBox(height: 30),

                        // Additional Options
                        Text(
                          'خيارات إضافية',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            
                          ),
                        ),

                        const SizedBox(height: 15),

                        _buildToggleCard(
                          title: 'إغلاق تلقائي',
                          subtitle: 'إغلاق الشاشة تلقائياً بعد انتهاء الأذان',
                          value: _autoDismiss,
                          onChanged: _toggleAutoDismiss,
                          isDark: isDark,
                        ),

                        const SizedBox(height: 15),

                        _buildToggleCard(
                          title: 'عرض العد التنازلي',
                          subtitle: 'إظهار مؤقت العد التنازلي',
                          value: _showCountdown,
                          onChanged: _toggleCountdown,
                          isDark: isDark,
                        ),

                        const SizedBox(height: 30),

                        // Test Button
                        ElevatedButton.icon(
                          onPressed: _previewFullscreen,
                          icon: const Icon(Icons.visibility),
                          label: const Text(
                            'معاينة الشاشة الكاملة',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: iconColor,
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
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

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required bool isDark,
  }) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.black54;
    return GlassCard(
      borderRadius: BorderRadius.circular(15),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: subtitleColor,
            fontSize: 12,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: isDark ? Colors.cyanAccent : Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildThemeCard(AdhanTheme theme, bool isSelected, bool isDark) {
    final borderColor = isDark ? Colors.cyanAccent : Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: () => _saveTheme(theme.id),
      child: GlassCard(
        borderRadius: BorderRadius.circular(12),
        padding: EdgeInsets.zero,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: theme.backgroundGradient,
                ),
                borderRadius: BorderRadius.circular(12),
                border: isSelected ? Border.all(color: borderColor, width: 2) : null,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'الفجر',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.prayerNameColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '4:30',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.prayerTimeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  theme.nameAr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.check_circle, color: borderColor),
              ),
          ],
        ),
      ),
    );
  }
}
