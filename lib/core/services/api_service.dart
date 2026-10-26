import 'dart:convert';
import 'package:flutter/foundation.dart'; // ✅ For compute
// ✅ For debugPrint
import 'package:flutter/material.dart'; // ✅ For SnackBar
import '../utils/keys.dart'; // ✅ For navigatorKey
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_endpoints.dart';
import '../../features/quran/data/models/shaykh.dart';
import '../../features/quran/data/models/mushaf_category.dart'; // ✅ Import MushafCategory
import 'download_manager.dart';

class ApiService {
  static const String _cacheKeyShaykhs = 'cached_shaykhs';

  /// Fetches the list of Shaykhs.
  /// If [refresh] is true, tries network first, then cache.
  /// If [refresh] is false, tries cache first, then network.
  static Future<List<Shaykh>> getShaykhs({bool refresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. If refresh requested, try Network first
    if (refresh) {
      try {
        final netList = await fetchShaykhsFromApi();
        if (netList.isNotEmpty) return netList;
      } catch (e) {
        debugPrint("⚠️ Network refresh failed, falling back to cache: $e");
        // Fallthrough to cache
      }
    }

    // 2. Try Cache
    if (prefs.containsKey(_cacheKeyShaykhs)) {
      final String? cachedData = prefs.getString(_cacheKeyShaykhs);
      if (cachedData != null && cachedData.isNotEmpty) {
        try {
          final List<dynamic> decodedData = json.decode(cachedData);
          final list = decodedData.map((json) => Shaykh.fromJson(json)).toList();
          if (list.isNotEmpty) {
            return list;
          }
        } catch (e) {
          debugPrint("⚠️ Cache corrupted: $e");
        }
      }
    }

    // 3. If cache missing/failed and not refresh, try network
    if (!refresh) {
      try {
        final netList = await fetchShaykhsFromApi();
        if (netList.isNotEmpty) return netList;
      } catch (e) {
        debugPrint("⚠️ Network fetch failed: $e");
      }
    }

    // 4. Offline Fallback: Extract Shaykhs from downloaded audio files
    try {
      final downloads = await DownloadManager.getAllDownloads();
      if (downloads.isNotEmpty) {
        final Map<String, Shaykh> offlineShaykhs = {};
        for (final item in downloads) {
          final id = item['shaykhId']?.toString() ?? '';
          final name = item['reciterName']?.toString() ?? '';
          if (id.isNotEmpty && name.isNotEmpty && !offlineShaykhs.containsKey(id)) {
            offlineShaykhs[id] = Shaykh(
              id: id,
              name: name,
              bio: 'قارئ القرآن الكريم',
              imageUrl: item['imageUrl']?.toString() ?? '',
              category: 'all',
            );
          }
        }
        if (offlineShaykhs.isNotEmpty) {
          debugPrint("✅ Loaded ${offlineShaykhs.length} Shaykhs from downloaded files fallback.");
          return offlineShaykhs.values.toList();
        }
      }
    } catch (e) {
      debugPrint("⚠️ Offline downloads fallback error: $e");
    }

    return [];
  }

  static Future<List<Shaykh>> fetchShaykhsFromApi() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      debugPrint('📥 Fetching Shaykhs from: ${ApiEndpoints.recitersRead}');
      final response = await http
          .get(Uri.parse(ApiEndpoints.recitersRead))
          .timeout(const Duration(seconds: 4));
      
      debugPrint('📥 Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        // ✅ Offload parsing AND encoding to Isolate
        final result = await compute(_parseShaykhs, response.body);
        
        // Save to cache
        if (result.jsonString.isNotEmpty) {
           await prefs.setString(_cacheKeyShaykhs, result.jsonString);
        }
        return result.shaykhs;
      } else {
        debugPrint('❌ Server Error: ${response.body}');
        if (response.statusCode == 429 || response.statusCode == 502 || response.statusCode == 503 || response.statusCode == 504) {
          _showOverloadMessage();
        }
        // Fallback to cache if available
        if (prefs.containsKey(_cacheKeyShaykhs)) {
          final String? cachedData = prefs.getString(_cacheKeyShaykhs);
          if (cachedData != null && cachedData.isNotEmpty) {
            final List<dynamic> decoded = json.decode(cachedData);
            return decoded.map((j) => Shaykh.fromJson(j)).toList();
          }
        }
        throw Exception("Server Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      debugPrint('❌ ApiService Exception: $e');
      
      if (e.toString().contains('TimeoutException') || e.toString().contains('Connection refused')) {
        _showOverloadMessage();
      }

      // If we have cache, return it instead of throwing!
      if (prefs.containsKey(_cacheKeyShaykhs)) {
        final String? cachedData = prefs.getString(_cacheKeyShaykhs);
        if (cachedData != null && cachedData.isNotEmpty) {
          try {
            final List<dynamic> decoded = json.decode(cachedData);
            final cachedList = decoded.map((j) => Shaykh.fromJson(j)).toList();
            if (cachedList.isNotEmpty) {
              return cachedList;
            }
          } catch (_) {}
        }
      }

      throw Exception("Connection Failed: $e");
    }
  }

  // ✅ Function used with compute()
  static Future<_ShaykhParseResult> _parseShaykhs(String responseBody) async {
    final Map<String, dynamic> map = json.decode(responseBody);
    if (map['data'] != null) {
      final List<dynamic> data = map['data'];
      try {
        final List<Shaykh> shaykhs = data.map((json) => Shaykh.fromJson(json)).toList();
        // Re-encode valid data for caching (expensive, so do it here)
        final String jsonString = json.encode(data);
        return _ShaykhParseResult(shaykhs, jsonString);
      } catch (e) {
        debugPrint('❌ Parsing Error in Shaykh.fromJson: $e');
        throw Exception("Parsing Error: $e");
      }
    }
    return _ShaykhParseResult([], "");
  }

  // ✅ Show friendly message when server is busy
  static void _showOverloadMessage() {
    // Check if context is available
    if (navigatorKey.currentState?.context == null) return;
    
    // Run on UI thread
    if (navigatorKey.currentState?.mounted ?? false) {
       ScaffoldMessenger.of(navigatorKey.currentState!.context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.wifi_off_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sorry, the server is currently busy due to high traffic. Please try again later.',
                  style: TextStyle( color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Fetches the list of notifications from the API.
  static Future<List<dynamic>> getNotifications() async {
    try {
      final response = await http.get(Uri.parse(ApiEndpoints.notificationsRead));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching notifications: $e');
      return [];
    }
  }

  /// Deletes a notification from the API.
  static Future<bool> deleteNotification(int id) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiEndpoints.notificationsDelete),
        body: json.encode({'id': id}),
        headers: {'Content-Type': 'application/json'}
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error deleting notification: $e');
      return false;
    }
  }

  /// Fetches the list of Adhans from the API.
  static Future<List<dynamic>> getAdhans() async {
    try {
      final response = await http.get(Uri.parse(ApiEndpoints.adhansRead));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) { return []; }
  }

  /// Forces a refresh of the Shaykhs list from the server.
  static Future<List<Shaykh>> refreshShaykhs() async {
    try {
      final response = await http.get(Uri.parse(ApiEndpoints.recitersRead));

      if (response.statusCode == 200) {
        final Map<String, dynamic> map = json.decode(response.body);

        if (map['data'] != null) {
          final List<dynamic> data = map['data'];
          final List<Shaykh> shaykhs = data.map((json) => Shaykh.fromJson(json)).toList();

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_cacheKeyShaykhs, json.encode(data));

          return shaykhs;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Fetches the active advertisement image URL.
  static Future<String?> getAdImageUrl() async {
    try {
      final response = await http.get(Uri.parse(ApiEndpoints.sliderRead));

      if (response.statusCode == 200) {
        final Map<String, dynamic> map = json.decode(response.body);

        if (map['data'] != null && map['data'].isNotEmpty) {
          final adData = map['data'][0];
          final String imageUrl = adData['image_url'] ?? '';

          if (imageUrl.isNotEmpty) {
            return imageUrl;
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Fetches nested content (sub-mushafs/series) by parent ID
  static Future<List<MushafCategory>> getSeriesContent(String reciterId, String parentId) async {
    try {
      final uri = Uri.parse('${ApiEndpoints.mushafsByReciter(int.parse(reciterId))}&parent_id=$parentId');
      debugPrint('📥 Fetching Series Content: $uri');
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> map = json.decode(response.body);
        if (map['data'] != null) {
          final List<dynamic> data = map['data'];
          return data.map((json) => MushafCategory.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
       debugPrint('❌ Error fetching series content: $e');
       return [];
    }
  }

  /// Clears the cached Shaykhs data (use when API structure changes)
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKeyShaykhs);
  }
  // ✅ Update FCM Token
  static Future<void> updateFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userStr = prefs.getString('app_user_data');
      
      if (userStr != null) {
        final user = jsonDecode(userStr);
        final userId = user['id'];
        
        if (userId != null) {
          await http.post(
            Uri.parse(ApiEndpoints.updateFCMToken),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'fcm_token': token,
            }),
          );
        }
      }
    } catch (e) {
       debugPrint("Error updating FCM token: $e");
    }
  }

  // ✅ Get App Settings (Maintenance, Version, etc.)
  static Future<Map<String, String>> getAppSettings() async {
    try {
      final response = await http.get(Uri.parse(ApiEndpoints.settingsRead)).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          // Return a fake response to trigger the catch block or handle empty return
          return http.Response('Error', 408); 
        },
      );
      final Map<String, String> settingsMap = {};
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data.containsKey('data')) {
          final settings = data['data'] as List;
          for (var setting in settings) {
            settingsMap[setting['key']] = setting['value'].toString();
          }
        }
      }
      return settingsMap;
    } catch (e) {
      debugPrint("Error fetching app settings: $e");
      return {};
    }
  }
}

// Helper class for Isolate result
class _ShaykhParseResult {
  final List<Shaykh> shaykhs;
  final String jsonString;
  _ShaykhParseResult(this.shaykhs, this.jsonString);
}
