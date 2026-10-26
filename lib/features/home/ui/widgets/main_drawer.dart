import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import '../../../../core/translations/app_locale_keys.dart';

import '../../../auth/data/auth_service.dart';
import '../../../auth/ui/screens/auth_screen.dart';
import '../../../prayers/ui/screens/qibla_screen.dart';
import '../../../quran/ui/screens/favorites_screen.dart';

import '../../../settings/ui/screens/downloads_screen.dart';
import '../../../settings/ui/screens/feedback_screen.dart';
import '../../../settings/ui/screens/profile_screen.dart';
import '../../../settings/ui/screens/settings_screen.dart';
import 'package:url_launcher/url_launcher.dart';

// MainDrawer converted to StatefulWidget
class MainDrawer extends StatefulWidget {
  final VoidCallback? onShowTutorial; // ✅ New callback
  const MainDrawer({super.key, this.onShowTutorial});

  @override
  State<MainDrawer> createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {
  Map<String, dynamic>? _userData;
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    // Check user status on init
    _checkUserStatus();
  }

  void _checkUserStatus() async {
    try {
      final user = await AuthService.getCurrentUser();
      final isGuest = await AuthService.isGuest();

      if (mounted) {
        setState(() {
          _userData = user;
          _isGuest = isGuest;
        });
      }
    } catch (e) {
      // Error loading user status
    }
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    // Close drawer before navigation
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  // Handle Logout or Login
  void _handleLogoutOrLogin(BuildContext context) async {
    // Removed early drawer close, handled below.
    // if (Navigator.canPop(context)) {
    //   Navigator.pop(context);
    // }

    if (_isGuest) {
      // Direct Guest to AuthScreen
      if (context.mounted) {
        try {
          // Close drawer
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthScreen()),
            (Route<dynamic> route) => false, // Clear all routes
          );
        } catch (_) {
          // Navigation error
        }
      }
    } else {
      // Show confirmation dialog for registered user
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final dialogBg = isDark ? const Color(0xFF1E4D3E) : Colors.white;
      final dialogText = isDark ? Colors.white : Colors.black87;

      final bool? confirm = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: dialogBg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(AppLocaleKeys.logoutConfirmTitle.tr,
              style: TextStyle(color: dialogText, fontWeight: FontWeight.bold)),
          content: Text(AppLocaleKeys.logoutConfirmMessage.tr,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
              )),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppLocaleKeys.commonCancel.tr,
                    style: TextStyle(
                      color: Colors.cyanAccent,
                    ))),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(AppLocaleKeys.logoutAction.tr,
                    style: TextStyle(
                      color: Colors.redAccent,
                    ))),
          ],
        ),
      );

      // Execute logout
      if (confirm == true && context.mounted) {
        // Close drawer
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        // 1. Show loading indicator
        final NavigatorState dialogNavigator = Navigator.of(context);
        dialogNavigator.push(
          PageRouteBuilder(
            opaque: false,
            barrierDismissible: false,
            pageBuilder: (context, animation, secondaryAnimation) {
              return Center(
                child: AlertDialog(
                  content: Row(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(width: 20),
                      Text(AppLocaleKeys.loggingOut.tr,
                          style: const TextStyle()),
                    ],
                  ),
                ),
              );
            },
          ),
        );

        try {
          // 2. Logout action
          await AuthService.logout(context);

          // 3. Navigate to AuthScreen
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const AuthScreen()),
              (Route<dynamic> route) => false,
            );
          }
        } catch (_) {
          // Logout error
        } finally {
          // 4. Dismiss loading dialog
          if (dialogNavigator.mounted && dialogNavigator.canPop()) {
            dialogNavigator.pop();
          }
        }
      } else {
        // Logout cancelled
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final iconColor =
        isDark ? const Color(0xFF79D8C4) : const Color(0xFF0F6A5C);
    final dividerColor = isDark ? Colors.white24 : Colors.grey.shade300;
    final drawerSurface =
        isDark ? const Color(0xFF0D211C) : const Color(0xFFF3FBF8);
    final drawerCard =
        isDark ? const Color(0xFF16312B) : Colors.white.withValues(alpha: 0.94);

    final String displayName = _isGuest
        ? AppLocaleKeys.drawerWelcomeGuest.tr
        : (_userData?['name'] ?? AppLocaleKeys.drawerUser.tr);
    final String displayEmail = _isGuest
        ? AppLocaleKeys.drawerLoginPrompt.tr
        : (_userData?['email'] ?? "");

    String? imageUrl = _userData?['image_url'];
    if (imageUrl != null && imageUrl.contains('localhost')) {
      // Fix localhost image for emulator
      imageUrl = imageUrl
          .replaceFirst('localhost', 'mihrab-app.alwaysdata.net')
          .replaceFirst('http://', 'https://');
    }

    final Color buttonBgColor =
        _isGuest ? const Color(0xFF157C6D) : const Color(0xFFAA3A46);
    final Color buttonFgColor = Colors.white;
    final String buttonText =
        _isGuest ? AppLocaleKeys.drawerLogin.tr : AppLocaleKeys.drawerLogout.tr;
    final IconData buttonIcon = _isGuest ? Icons.login : Icons.logout;

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        children: [
          Container(color: drawerSurface),
          if (isDark)
            Opacity(
              opacity: 0.08,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/background.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

          // 1. Drawer Structure
          SafeArea(
            top: true,
            bottom: false,
            child: Column(
              children: [
                // --- Header ---
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: drawerCard,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : const Color(0xFFDDEDE7),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0A5448).withValues(
                          alpha: isDark ? 0.16 : 0.08,
                        ),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: isDark
                            ? Colors.white.withOpacity(0.1)
                            : const Color(0xFFE8F6F1),
                        backgroundImage: (!_isGuest &&
                                imageUrl != null &&
                                imageUrl.isNotEmpty)
                            ? NetworkImage(imageUrl)
                            : null,
                        child:
                            (_isGuest || imageUrl == null || imageUrl.isEmpty)
                                ? Icon(Icons.person, size: 34, color: iconColor)
                                : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              displayEmail,
                              style: TextStyle(color: subTextColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(color: dividerColor, height: 1),

                // 2. Scrollable List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(top: 10),
                    children: [
                      // Profile item for registered users only
                      if (!_isGuest)
                        _DrawerItem(
                          icon: Icons.person_outline,
                          title: AppLocaleKeys.drawerProfile.tr,
                          textColor: textColor,
                          iconColor: iconColor,
                          isDark: isDark,
                          onTap: () =>
                              _navigateToScreen(context, const ProfileScreen()),
                        ),

                      _DrawerItem(
                          icon: Icons.favorite_border,
                          title: AppLocaleKeys.drawerFavorites.tr,
                          textColor: textColor,
                          iconColor: iconColor,
                          isDark: isDark,
                          onTap: () => _navigateToScreen(
                              context, const FavoritesScreen())),
                      _DrawerItem(
                          icon: Icons.download_done_rounded,
                          title: AppLocaleKeys.drawerDownloads.tr,
                          textColor: textColor,
                          iconColor: iconColor,
                          isDark: isDark,
                          onTap: () => _navigateToScreen(
                              context, const DownloadsScreen())),
                      // Used FontAwesomeIcons.kaaba as alternative
                      _DrawerItem(
                          icon: FontAwesomeIcons.kaaba,
                          title: AppLocaleKeys.drawerQibla.tr,
                          textColor: textColor,
                          iconColor: iconColor,
                          isDark: isDark,
                          onTap: () =>
                              _navigateToScreen(context, const QiblaScreen())),

                      Divider(
                          color: dividerColor,
                          indent: 20,
                          endIndent: 20,
                          height: 30),

                      _DrawerItem(
                          icon: Icons.settings_outlined,
                          title: AppLocaleKeys.drawerSettings.tr,
                          textColor: textColor,
                          iconColor: iconColor,
                          isDark: isDark,
                          onTap: () => _navigateToScreen(
                              context, const SettingsScreen())),
                      _DrawerItem(
                          icon: Icons.feedback_outlined,
                          title: AppLocaleKeys.drawerFeedback.tr,
                          textColor: textColor,
                          iconColor: iconColor,
                          isDark: isDark,
                          onTap: () => _navigateToScreen(
                              context, const FeedbackScreen())),

                      _DrawerItem(
                          icon: FontAwesomeIcons.facebook,
                          title: AppLocaleKeys.drawerFollowFacebook.tr,
                          textColor: textColor,
                          iconColor: const Color(0xFF1877F2),
                          isDark: isDark,
                          onTap: () async {
                            final Uri url = Uri.parse(
                                'https://www.facebook.com/Qabas.App.Official/');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url,
                                  mode: LaunchMode.externalApplication);
                            }
                          }),

                      // Login/Logout Button
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 20.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () => _handleLogoutOrLogin(context),
                            icon: Icon(buttonIcon, size: 24),
                            label: Text(
                              buttonText,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonBgColor,
                              foregroundColor: buttonFgColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper Widget for Drawer Items
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color textColor;
  final Color iconColor;
  final bool isDark;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.textColor,
    required this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF14302A).withOpacity(0.72)
            : const Color(0xFFF8FCFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE1EFEA),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E5148).withOpacity(0.45)
                : const Color(0xFFE4F5EF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
              color: textColor, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: isDark ? Colors.white38 : const Color(0xFF7A928A),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        hoverColor:
            isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
        tileColor: Colors.transparent,
      ),
    );
  }
}
