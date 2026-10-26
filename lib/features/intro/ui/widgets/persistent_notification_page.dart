import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:get/get.dart';
import '../../../../core/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/background_service.dart';
import '../../../../core/translations/app_locale_keys.dart';

class PersistentNotificationPage extends StatefulWidget {
  final VoidCallback onFinish;
  final double pageOffset;
  final Animation<double> floatAnimation;

  const PersistentNotificationPage({
    super.key,
    required this.onFinish,
    required this.pageOffset,
    required this.floatAnimation,
  });

  @override
  State<PersistentNotificationPage> createState() =>
      _PersistentNotificationPageState();
}

class _PersistentNotificationPageState
    extends State<PersistentNotificationPage> {
  bool _persistentNotificationEnabled = true;

  void _saveAndFinish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
        'persistent_notification_enabled', _persistentNotificationEnabled);

    // Start or stop the background service based on user choice
    if (_persistentNotificationEnabled) {
      await BackgroundService.startService();
    } else {
      await BackgroundService.stopService();
    }

    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    // Islamic Theme Base
    final primaryGlowColor =
        isDark ? const Color(0xFFD4AF37) : const Color(0xFFB8860B);

    return Stack(
      children: [
        Positioned.fill(
          bottom: 90,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 50),

                // Premium Glowing Header Icon
                AnimatedBuilder(
                  animation: widget.floatAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(widget.pageOffset * -200,
                          widget.floatAnimation.value * 1.5),
                      child: child,
                    );
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryGlowColor.withOpacity(0.3),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.05),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.notifications_active_rounded,
                                size: 50,
                                color: primaryGlowColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                Text(
                  AppLocaleKeys.persistentNotificationTitle.tr,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  AppLocaleKeys.persistentNotificationDesc.tr
                      .tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 45),

                // Premium Glass Notification Preview
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color:
                        isDark ? Colors.white.withOpacity(0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black26
                            : Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryGlowColor.withOpacity(0.8),
                              primaryGlowColor
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mosque_rounded,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "الصلاة القادمة: العصر".tr,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.timer_outlined,
                                    size: 16, color: primaryGlowColor),
                                const SizedBox(width: 6),
                                Text(
                                  "متبقي 2 ساعة و 15 دقيقة".tr,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 45),

                // Enable Toggle Glassmorphism
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black12),
                  ),
                  child: SwitchListTile(
                    title: Text(AppLocaleKeys.enablePersistentNotification.tr.tr,
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    value: _persistentNotificationEnabled,
                    activeColor: primaryGlowColor,
                    onChanged: (val) =>
                        setState(() => _persistentNotificationEnabled = val),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),

        // Pinned Bottom Button
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: GestureDetector(
                onTap: _saveAndFinish,
                child: Container(
                  width: double.infinity,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              primaryGlowColor,
                              primaryGlowColor.withOpacity(0.7)
                            ]
                          : [const Color(0xFF0D9488), primaryGlowColor],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primaryGlowColor.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Text(
                    AppLocaleKeys.finishAndStartApp.tr.tr,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
