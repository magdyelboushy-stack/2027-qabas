import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/translations/app_locale_keys.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mihrab/features/auth/ui/widgets/auth_background.dart';

class UpdateScreen extends StatelessWidget {
  final bool isForceUpdate;
  final String storeUrl;

  const UpdateScreen({
    super.key,
    required this.isForceUpdate,
    required this.storeUrl,
  });

  Future<void> _launchStore() async {
    final Uri url = Uri.parse(storeUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AuthBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green.withOpacity(0.5), width: 2),
                  ),
                  child: const Icon(Icons.system_update_rounded, size: 80, color: Colors.green),
                ),
                
                const SizedBox(height: 40),
                
                Text(
                  AppLocaleKeys.updateAvailableTitle.tr,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  AppLocaleKeys.updateAvailableDescription.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                
                const SizedBox(height: 50),
                
                // Update Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _launchStore,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      AppLocaleKeys.updateNow.tr,
                      style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                // Skip Button (Only if not forced)
                if (!isForceUpdate) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushReplacementNamed('/home'), 
                    // Note: You might need to adjust navigation logic based on your routes
                    child: Text(
                      AppLocaleKeys.skipForLater.tr,
                      style: TextStyle(color: Colors.white.withOpacity(0.6)),
                    ),
                  )
                ] else ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => SystemNavigator.pop(),
                    child: Text(
                      AppLocaleKeys.closeApp.tr,
                      style: TextStyle(color: Colors.white.withOpacity(0.6)),
                    ),
                  )
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
