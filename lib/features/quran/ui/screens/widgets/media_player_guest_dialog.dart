import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/translations/app_locale_keys.dart';
import '../../../../auth/ui/screens/auth_screen.dart';

void showMediaPlayerGuestDialog(BuildContext context) {
  final isArabic = Get.locale?.languageCode == 'ar';

  showDialog(
    context: context,
    builder: (ctx) => Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF16312B)
            : const Color(0xFFF8FCF9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          AppLocaleKeys.guestAlertTitle.tr,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          AppLocaleKeys.guestAlertMessage.tr,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocaleKeys.commonCancel.tr),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1F7A5E),
            ),
            child: Text(AppLocaleKeys.loginNow.tr),
          ),
        ],
      ),
    ),
  );
}
