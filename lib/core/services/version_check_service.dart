import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';

class VersionCheckService {
  static Future<bool> checkVersion(BuildContext context) async {
    try {
      // 1. Get Settings from API
      // Note: getAppSettings returns Map<String, dynamic> where value is String
      // But ApiService.getAppSettings returns Map<String, String>? Wait, let's check ApiService.
      // It returns Map<String, String>. Good.
      
      final settings = await ApiService.getAppSettings();
      
      if (settings.isEmpty) return false;

      final String? latestVersion = settings['latest_version'];
      final bool forceUpdate = settings['force_update'] == '1';
      final String storeUrl = settings['store_url'] ?? '';

      if (latestVersion == null || latestVersion.isEmpty) return false;

      // 2. Get Current App Version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      debugPrint("📊 Version Check: Current=$currentVersion, Latest=$latestVersion, Force=$forceUpdate");

      // 3. Compare
      if (_isUpdateAvailable(currentVersion, latestVersion)) {
        if (forceUpdate) {
            if (context.mounted) {
              _showUpdateDialog(context, storeUrl, true);
            }
            return true; // Block navigation
        } else {
            // Optional update? Maybe later.
        }
      }
      return false;
    } catch (e) {
      debugPrint("❌ Error checking version: $e");
      return false;
    }
  }

  static bool _isUpdateAvailable(String current, String latest) {
    List<int> currentParts = current.split('.').map(int.parse).toList();
    List<int> latestParts = latest.split('.').map(int.parse).toList();

    for (int i = 0; i < latestParts.length; i++) {
      if (i >= currentParts.length) return true; // Latest has more parts (e.g. 1.0.1 > 1.0)
      
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false; // Equal or current is greater (e.g. 1.0.1 vs 1.0.0.1?)
  }

  static void _showUpdateDialog(BuildContext context, String url, bool isForce) {
    showDialog(
      context: context,
      barrierDismissible: !isForce,
      barrierColor: Colors.black87,
      builder: (context) => WillPopScope(
        onWillPop: () async => !isForce,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.system_update, color: Color(0xFFFFD700), size: 30),
              SizedBox(width: 10),
              Text(
                "New Update Available",
                style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            "Please update the app to get the latest features and bug fixes. You cannot use the app without updating.",
            style: TextStyle(fontFamily: 'Cairo', color: Colors.white70),
          ),
          actions: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA000)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextButton(
                onPressed: () {
                   if (url.isNotEmpty) {
                     launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                   }
                },
                child: const Text(
                  "Update Now",
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
