import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/ad_service.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/translations/app_locale_keys.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  bool get _isArabic => Get.locale?.languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    AdService.showInterstitialAd();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getNotifications();
    if (!mounted) return;
    setState(() {
      _notifications = data;
      _isLoading = false;
    });
  }

  String _formatDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return '';
    try {
      final date = DateTime.parse(value.toString());
      return DateFormat(
        _isArabic ? 'yyyy/MM/dd - hh:mm a' : 'yyyy/MM/dd - hh:mm a',
      ).format(date);
    } catch (_) {
      return value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark;
    final bgTop = isDark ? const Color(0xFF081713) : const Color(0xFFF7FBF8);
    final bgBottom = isDark ? const Color(0xFF0E241E) : const Color(0xFFE7F2EC);
    final titleColor = isDark ? Colors.white : const Color(0xFF17352E);
    final subColor =
        isDark ? Colors.white.withOpacity(0.68) : const Color(0xFF6A8479);
    final cardColor = isDark ? const Color(0xFF132D26) : Colors.white;
    final borderColor =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFD9E9E0);
    final accent = const Color(0xFF2A8B68);

    return Directionality(
      textDirection: _isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bgBottom,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [bgTop, bgBottom],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          _isArabic
                              ? Icons.arrow_back_ios_new_rounded
                              : Icons.arrow_forward_ios_rounded,
                          color: titleColor,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          AppLocaleKeys.notificationsTitle.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.10),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.withOpacity(0.12),
                          ),
                          child: Icon(
                            Icons.notifications_active_rounded,
                            color: accent,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _isArabic
                                ? AppLocaleKeys.latestAlertsDesc.tr
                                : 'Your latest alerts and important updates',
                            style: TextStyle(
                              color: subColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AdService.nativeAdWidget(),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(color: accent),
                        )
                      : _notifications.isEmpty
                          ? _buildEmptyState(titleColor, subColor, accent)
                          : RefreshIndicator(
                              onRefresh: _loadNotifications,
                              color: accent,
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 8, 20, 24),
                                itemCount: _notifications.length,
                                itemBuilder: (context, index) {
                                  final notif = _notifications[index];
                                  return _buildNotificationCard(
                                    notif: notif,
                                    titleColor: titleColor,
                                    subColor: subColor,
                                    cardColor: cardColor,
                                    borderColor: borderColor,
                                    accent: accent,
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required dynamic notif,
    required Color titleColor,
    required Color subColor,
    required Color cardColor,
    required Color borderColor,
    required Color accent,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withOpacity(0.12),
                ),
                child: Icon(
                  Icons.notifications_rounded,
                  color: accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  (notif['title'] ?? '').toString(),
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            (notif['message'] ?? '').toString(),
            style: TextStyle(
              color: subColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: _isArabic ? Alignment.centerLeft : Alignment.centerRight,
            child: Text(
              _formatDate(notif['created_at']),
              style: TextStyle(
                color: subColor.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color titleColor, Color subColor, Color accent) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(0.12),
              ),
              child: Icon(
                Icons.notifications_off_rounded,
                color: accent,
                size: 44,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              AppLocaleKeys.noNotificationsYet.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: titleColor,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isArabic
                  ? AppLocaleKeys.emptyNotificationsDesc.tr
                  : 'When new notifications arrive, they will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
