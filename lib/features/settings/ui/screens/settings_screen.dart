import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:get/get.dart';
import '../../../../core/translations/app_locale_keys.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../adhkar/data/adhkar_preferences.dart';

// Services and Models
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/services/download_manager.dart';
import '../../../auth/data/auth_service.dart';
import '../../../prayers/logic/notification_manager.dart';
// Import Adhan Selection Screen
// Import Adhan Display Settings Screen
// ✅ Import Advanced Settings
import 'package:mihrab/features/auth/ui/screens/auth_screen.dart';
import '../../../../core/ui/widgets/glass_snackbar.dart';
import '../../../../core/services/background_service.dart'; // ✅ Import BackgroundService
import '../../../home/ui/screens/home_screen.dart'; // ✅ Import HomeScreen
import 'package:shared_preferences/shared_preferences.dart'; // ✅ Import SharedPreferences
import '../../../prayers/ui/screens/notification_debug_screen.dart'; // ✅ Debug Screen
import '../../../../core/services/ad_service.dart'; // ✅ AdMob

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  bool _notificationsEnabled = true;
  bool _persistentNotificationEnabled =
      true; // ✅ Add state for persistent notification
  bool _isUserLoggedIn = false;
  bool _adhkarHapticsEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    AdService.showInterstitialAd(); // ✅ Interstitial ad
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadSettings(); // Refresh when user comes back to the app
    }
  }

  Future<void> _loadSettings() async {
    // Load global notification state
    final enabled = await NotificationManager.getGlobalNotifications();

    // Load persistent notification state
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // ✅ Essential to see changes from background isolate
    final persistentEnabled =
        prefs.getBool('persistent_notification_enabled') ?? true;

    // Check if user is Guest or Registered
    final isGuest = await AuthService.isGuest();
    final adhkarHapticsEnabled = await AdhkarPreferences.isHapticsEnabled();

    if (mounted) {
      setState(() {
        _notificationsEnabled = enabled;
        _persistentNotificationEnabled = persistentEnabled;
        _isUserLoggedIn = !isGuest;
        _adhkarHapticsEnabled = adhkarHapticsEnabled;
      });
    }
  }

  // --- 1. Notification Control ---
  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    await NotificationManager.setGlobalNotifications(value);

    if (value) {
      // Re-enable scheduling
      await NotificationManager.scheduleAdhkar();
      // (Prayers will be scheduled automatically when opening Prayer Times)
    } else {
      // Cancel all notifications
      await NotificationManager.cancelAllNotifications();
    }
  }

  // ✅ Toggle Persistent Notification
  Future<void> _togglePersistentNotification(bool value) async {
    setState(() => _persistentNotificationEnabled = value);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('persistent_notification_enabled', value);

    if (value) {
      await BackgroundService.startService();
    } else {
      await BackgroundService.stopService();
    }
  }

  Future<void> _toggleAdhkarHaptics(bool value) async {
    setState(() => _adhkarHapticsEnabled = value);
    await AdhkarPreferences.setHapticsEnabled(value);
  }

  // --- 2. Clear Storage ---
  Future<void> _clearDownloads(BuildContext context) async {
    final confirm = await _showConfirmationDialog(
      context,
      title: AppLocaleKeys.clearDownloadsTitle.tr,
      content: AppLocaleKeys.clearDownloadsContent.tr,
      confirmText: AppLocaleKeys.clearAction.tr,
      isDanger: true,
    );

    if (confirm == true) {
      await DownloadManager.clearAllDownloads();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocaleKeys.storageClearedSuccess.tr,
                style: TextStyle()),
            backgroundColor: Colors.green));
      }
    }
  }

  // --- 3. Delete Account ---
  Future<void> _deleteAccount(BuildContext context) async {
    // Show Loading immediately
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    try {
      // 1. Call Delete Endpoint & Clear Data
      await AuthService.deleteAccount(context);

      // 2. Hide Loading
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context); // Pop Dialog
      }

      // 3. Show Premium Glass SnackBar
      if (mounted) {
        showGlassSnackBar(context, AppLocaleKeys.allDataDeletedSuccess.tr,
            isError: true);
      }

      // 4. Force Navigation to Auth Screen immediately
      if (mounted) {
        // Add small delay to let user see the message
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const AuthScreen()),
              (route) => false);
        }
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context))
        Navigator.pop(context); // Hide loading
      // Even on error, we might want to logout locally
    }
  }

  // Unified Confirmation Dialog
  Future<bool?> _showConfirmationDialog(BuildContext context,
      {required String title,
      required String content,
      required String confirmText,
      bool isDanger = false}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16312B),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.white.withOpacity(0.1))),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(content,
            style: const TextStyle(
              color: Colors.white70,
            )),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLocaleKeys.commonCancel.tr,
                  style: TextStyle(
                    color: Colors.white,
                  ))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: isDanger
                    ? const Color(0xFFAA3A46)
                    : const Color(0xFF3DAA78)),
            child: Text(confirmText,
                style: TextStyle(
                    color: isDanger ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _showLanguageDialog(BuildContext context, bool isDark, Color textColor, Color subTextColor, Color iconColor) async {
    final isArabic = Get.locale?.languageCode == 'ar';

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          title: Text(
            AppLocaleKeys.language.tr,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                value: 'ar',
                groupValue: isArabic ? 'ar' : 'en',
                onChanged: (val) => _changeLanguage('ar', ctx),
                title: Text('العربية', style: TextStyle(color: textColor)),
                activeColor: iconColor,
              ),
              RadioListTile<String>(
                value: 'en',
                groupValue: isArabic ? 'ar' : 'en',
                onChanged: (val) => _changeLanguage('en', ctx),
                title: Text('English', style: TextStyle(color: textColor)),
                activeColor: iconColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changeLanguage(String code, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language_code', code);

    final locale = code == 'ar' ? const Locale('ar', 'EG') : const Locale('en', 'US');
    await Get.updateLocale(locale);

    Navigator.pop(context);
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication)) {
      // Log removed
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Get.locale?.languageCode == 'ar';
    String settingsText({required String ar, required String en}) =>
        isArabic ? ar : en;

    // Dynamic Text Colors
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white54 : Colors.black54;
    final iconColor =
        isDark ? const Color(0xFF79D8C4) : const Color(0xFF0F6A5C);

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Stack(
          children: [
            // 1. Background
            Container(
              decoration: isDark
                  ? const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF153C34), Color(0xFF0D2722)],
                      ),
                    )
                  : BoxDecoration(color: Colors.grey[100]),
            ),

            // Dimming Layer (Dark Mode only)
            if (isDark)
              Container(color: const Color(0xFF071C18).withOpacity(0.88)),

            // 2. Content
            SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isArabic
                                ? Icons.arrow_back_ios_new_rounded
                                : Icons.arrow_forward_ios_rounded,
                            color: textColor,
                          ),
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            } else {
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const HomeScreen()));
                            }
                          },
                        ),
                        const SizedBox(width: 10),
                        Text(
                          AppLocaleKeys.settingsTitle.tr,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Menu List
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // --- Appearance Section ---
                        _buildSectionHeader(
                            AppLocaleKeys.settingsAppearanceSection.tr, isDark),
                        _buildGlassCard(isDark, [
                          // Dark Mode Switch
                          SwitchListTile(
                            value: themeProvider.themeMode == ThemeMode.dark,
                            onChanged: (val) => themeProvider.setThemeMode(
                                val ? ThemeMode.dark : ThemeMode.light),
                            activeColor: iconColor,
                            title: Text(AppLocaleKeys.settingsDarkMode.tr,
                                style: TextStyle(
                                  color: textColor,
                                )),
                            subtitle:
                                Text(AppLocaleKeys.settingsDarkModeDesc.tr,
                                    style: TextStyle(
                                      color: subTextColor,
                                      fontSize: 12,
                                    )),
                            secondary: Icon(Icons.dark_mode, color: iconColor),
                          ),
                          Divider(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.grey.shade300),
                          SwitchListTile(
                            value: _adhkarHapticsEnabled,
                            onChanged: _toggleAdhkarHaptics,
                            activeColor: iconColor,
                            title: Text(
                              settingsText(
                                ar: 'هزة عداد الأذكار',
                                en: 'Adhkar Counter Vibration',
                              ),
                              style: TextStyle(
                                color: textColor,
                              ),
                            ),
                            subtitle: Text(
                              settingsText(
                                ar: 'اهتزاز الهاتف عند الضغط على عداد الأذكار',
                                en: 'Make the phone vibrate when tapping the adhkar counter',
                              ),
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 12,
                              ),
                            ),
                            secondary: Icon(
                              Icons.vibration_rounded,
                              color: iconColor,
                            ),
                          ),
                          Divider(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.grey.shade300),

                          // Language Selector
                          ListTile(
                            title: Text(AppLocaleKeys.language.tr,
                                style: TextStyle(
                                  color: textColor,
                                )),
                            subtitle: Text(
                              isArabic ? 'العربية' : 'English',
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 12,
                              ),
                            ),
                            leading: Icon(Icons.language, color: iconColor),
                            trailing: Icon(Icons.arrow_forward_ios,
                                color: subTextColor, size: 16),
                            onTap: () => _showLanguageDialog(context, isDark, textColor, subTextColor, iconColor),
                          ),
                          Divider(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.grey.shade300),

                          // Font Size Slider
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppLocaleKeys.settingsMushafFontSize.tr,
                                    style: TextStyle(
                                      color: textColor,
                                    )),
                                Row(
                                  children: [
                                    Icon(Icons.text_fields,
                                        size: 16, color: subTextColor),
                                    Expanded(
                                      child: SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          activeTrackColor: iconColor,
                                          inactiveTrackColor: isDark
                                              ? Colors.white12
                                              : Colors.grey.shade300,
                                          thumbColor:
                                              isDark ? Colors.white : iconColor,
                                        ),
                                        child: Slider(
                                          value: themeProvider.fontScale,
                                          min: 0.8,
                                          max: 1.4,
                                          divisions: 6,
                                          label:
                                              "${(themeProvider.fontScale * 100).round()}%",
                                          onChanged: (val) =>
                                              themeProvider.setFontScale(val),
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.text_fields,
                                        size: 24, color: textColor),
                                  ],
                                ),

                                // Preview
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.black26
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: isDark
                                          ? null
                                          : Border.all(
                                              color: Colors.grey.shade300)),
                                  child: Text(
                                    "بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 22 * themeProvider.fontScale,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]),
                        const SizedBox(height: 25),

                        // --- Adhan Section ---
                        _buildSectionHeader(
                            AppLocaleKeys.settingsAdhanSection.tr, isDark),
                        _buildGlassCard(isDark, [
                          SwitchListTile(
                            value: _notificationsEnabled,
                            onChanged: _toggleNotifications,
                            activeColor: iconColor,
                            title: Text(AppLocaleKeys.settingsEnableAdhan.tr,
                                style: TextStyle(
                                  color: textColor,
                                )),
                            subtitle:
                                Text(AppLocaleKeys.settingsEnableAdhanDesc.tr,
                                    style: TextStyle(
                                      color: subTextColor,
                                      fontSize: 12,
                                    )),
                            secondary: Icon(Icons.volume_up, color: iconColor),
                          ),
                          Divider(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.grey.shade300),
                          /* REMOVED: Adhan configuration - now accessible via Home Prayer Card tap
                          ListTile(
                            title: Text("تغيير صوت المؤذن", style: TextStyle(color: textColor, )),
                            subtitle: Text("اختر بين مكة، مصر، أو التكبير فقط", style: TextStyle(color: subTextColor, fontSize: 12, )),
                            leading: Icon(Icons.mosque, color: iconColor),
                            trailing: Icon(Icons.arrow_forward_ios, color: subTextColor, size: 16),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdhanSelectionScreen())),
                          ),
                          Divider(color: isDark ? Colors.white10 : Colors.grey.shade300),
                          ListTile(
                            title: Text("إعدادات عرض الأذان", style: TextStyle(color: textColor, )),
                            subtitle: Text("تخصيص شاشة الأذان الكاملة", style: TextStyle(color: subTextColor, fontSize: 12, )),
                            leading: Icon(Icons.fullscreen, color: iconColor),
                            trailing: Icon(Icons.arrow_forward_ios, color: subTextColor, size: 16),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdhanDisplaySettingsScreen())),
                          ),
                          Divider(color: isDark ? Colors.white10 : Colors.grey.shade300),
                          ListTile(
                            title: Text("الإعدادات المتقدمة (الهيئة والمذهب)", style: TextStyle(color: textColor, )),
                            subtitle: Text("تخصيص طريقة الحساب، المذهب، وتصحيح الوقت", style: TextStyle(color: subTextColor, fontSize: 12, )),
                            leading: Icon(Icons.tune, color: iconColor),
                            trailing: Icon(Icons.arrow_forward_ios, color: subTextColor, size: 16),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdvancedAdhanSettingsScreen())),
                          ),
                          */
                          Divider(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.grey.shade300),

                          // ✅ Persistent Notification Toggle
                          SwitchListTile(
                            value: _persistentNotificationEnabled,
                            onChanged: _togglePersistentNotification,
                            activeColor: iconColor,
                            title: Text(
                                AppLocaleKeys.settingsPersistentNotification.tr,
                                style: TextStyle(
                                  color: textColor,
                                )),
                            subtitle: Text(
                                AppLocaleKeys
                                    .settingsPersistentNotificationDesc.tr,
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 12,
                                )),
                            secondary: Icon(Icons.notifications_active,
                                color: iconColor),
                          ),
                        ]),
                        const SizedBox(height: 25),

                        // --- Storage Section ---
                        _buildSectionHeader(
                            AppLocaleKeys.settingsStorageSection.tr, isDark),
                        _buildGlassCard(isDark, [
                          ListTile(
                            title:
                                Text(AppLocaleKeys.settingsClearRecitations.tr,
                                    style: TextStyle(
                                      color: textColor,
                                    )),
                            subtitle: Text(
                                AppLocaleKeys.settingsClearRecitationsDesc.tr,
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 12,
                                )),
                            leading: const Icon(Icons.delete_sweep,
                                color: Colors.orangeAccent),
                            onTap: () => _clearDownloads(context),
                          ),
                          Divider(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.grey.shade300),
                          ListTile(
                            title: Text(
                                '${AppLocaleKeys.settingsNotificationDebug.tr} 🔧',
                                style: TextStyle(
                                  color: textColor,
                                )),
                            subtitle: Text(
                                AppLocaleKeys.settingsNotificationDebugDesc.tr,
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 12,
                                )),
                            leading: const Icon(Icons.bug_report,
                                color: Colors.blue),
                            trailing: Icon(Icons.arrow_forward_ios,
                                color: subTextColor, size: 16),
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const NotificationDebugScreen())),
                          ),
                        ]),
                        const SizedBox(height: 25),

                        // --- Account Section ---
                        if (_isUserLoggedIn) ...[
                          _buildSectionHeader(
                              AppLocaleKeys.settingsAccountSection.tr, isDark),
                          _buildGlassCard(isDark, [
                            ListTile(
                              title: Text(
                                  AppLocaleKeys.settingsDeleteAccount.tr,
                                  style: TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  AppLocaleKeys.settingsDeleteAccountDesc.tr,
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 12,
                                  )),
                              leading: const Icon(Icons.person_remove,
                                  color: Colors.redAccent),
                              onTap: () => _deleteAccount(context),
                            ),
                          ]),
                          const SizedBox(height: 25),
                        ],

                        // --- Contact Section ---
                        _buildSectionHeader(
                            AppLocaleKeys.settingsContactSection.tr, isDark),
                        _buildGlassCard(isDark, [
                          ListTile(
                            title: Text(AppLocaleKeys.settingsWhatsapp.tr,
                                style: TextStyle(
                                  color: textColor,
                                )),
                            leading: const Icon(Icons.chat,
                                color: Colors.greenAccent),
                            onTap: () =>
                                _launchUrl('https://wa.me/+201156820932'),
                          ),
                        ]),
                        const SizedBox(height: 50),
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
      padding: const EdgeInsets.only(bottom: 10, right: 5),
      child: Text(title,
          style: TextStyle(
            color: isDark
                ? const Color(0xFF79D8C4).withOpacity(0.88)
                : const Color(0xFF0F6A5C),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          )),
    );
  }

  Widget _buildGlassCard(bool isDark, List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.shade200),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
          ),
          child: Column(children: children),
        ),
      ),
    );
  }
}
