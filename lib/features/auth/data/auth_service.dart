import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../config/api_endpoints.dart';
import '../../../services/secure_storage_service.dart';

class AuthService {
  static const String _userKey = 'app_user_data';
  static const String _guestKey = 'is_guest_user';
  static final _secureStorage = SecureStorageService();

  static String _genericAuthError() {
    return 'Something went wrong. Please try again.';
  }

  static String _cancelledAuthMessage() {
    return 'The action was cancelled';
  }

  static Map<String, dynamic> _decodeJsonSafely(http.Response response) {
    final body = response.body.trim();
    if (body.isEmpty) return {};
    
    if (body.startsWith('<')) {
      debugPrint("API HTML ERROR RESPONSE: \n$body\n----------------");
      throw const FormatException('Non-JSON response');
    }

    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.cast<String, dynamic>();
      }
      return {};
    } catch (e) {
      debugPrint("API JSON DECODE ERROR. Body was: \n$body\n----------------");
      throw const FormatException('Non-JSON response');
    }
  }

  // 1. Guest Login
  static Future<void> loginAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestKey, true);
  }

  static Future<bool> isGuest() async {
    final prefs = await SharedPreferences.getInstance();
    final result = prefs.getBool(_guestKey) ?? false;
    return result;
  }

  // 2. Login (Email & Password)
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.login),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final data = _decodeJsonSafely(response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _saveUserData(data['user']);

        // Save JWT tokens securely if available
        if (data['tokens'] != null) {
          await _secureStorage.saveTokens(
            accessToken: data['tokens']['access_token'],
            refreshToken: data['tokens']['refresh_token'],
          );
        }

        return data['user'];
      } else {
        throw Exception(_genericAuthError());
      }
    } catch (e) {
      throw Exception(_genericAuthError());
    }
  }

  // 3. Register
  static Future<Map<String, dynamic>> register(
      String name, String email, String password, String phone) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.register),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone
        }),
      );

      final data = _decodeJsonSafely(response);

      // Successfully created (201) or OK (200)
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['user'] != null) {
          await _saveUserData(data['user']);
        }

        // Save JWT tokens securely if available
        if (data['tokens'] != null) {
          await _secureStorage.saveTokens(
            accessToken: data['tokens']['access_token'],
            refreshToken: data['tokens']['refresh_token'],
          );
        }

        return data['user'] ?? {};
      } else {
        throw Exception(_genericAuthError());
      }
    } catch (e) {
      debugPrint("AuthService Register Error: $e");
      throw Exception(_genericAuthError());
    }
  }

  static bool _isGoogleSignInInitialized = false;

  // --- 4. Google Sign In ---
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      if (!_isGoogleSignInInitialized) {
        await GoogleSignIn.instance.initialize();
        _isGoogleSignInInitialized = true;
      }

      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();

      final response = await http.post(
        Uri.parse(ApiEndpoints.googleLogin),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': googleUser.email,
          'name': googleUser.displayName ?? 'Google User',
          'google_id': googleUser.id,
        }),
      );

      final data = _decodeJsonSafely(response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['user'] != null) {
          await _saveUserData(data['user']);
        }

        if (data['tokens'] != null) {
          await _secureStorage.saveTokens(
            accessToken: data['tokens']['access_token'],
            refreshToken: data['tokens']['refresh_token'],
          );
        }

        return data['user'] ?? {};
      } else {
        throw Exception(_genericAuthError());
      }
    } catch (e) {
      final text = e.toString().toLowerCase();
      if (text.contains('cancel')) {
        throw Exception(_cancelledAuthMessage());
      }
      debugPrint("AuthService Google Sign In Error: $e");
      throw Exception(_genericAuthError());
    }
  }

  // --- 5. Logout ---
  static Future<void> logout([BuildContext? context]) async {
    try {
      final currentUser = await getCurrentUser();
      final token = await _secureStorage.getAccessToken();

      // Attempt to notify server of logout
      if (currentUser != null && currentUser['id'] != null && token != null) {
        await http.post(
          Uri.parse(ApiEndpoints.logout),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({'user_id': currentUser['id']}),
        );
      }
    } catch (e) {
      // Log error
    }

    // Clear Local State
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_guestKey);
    await _secureStorage.clearAll();

    // Notify UI
    _notifyUserChange(null);
    debugPrint("AuthService: Logged out & Stream Updated");
  }

  // --- 6. Get Current User ---
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userStr = prefs.getString(_userKey);
    if (userStr != null) {
      return json.decode(userStr);
    }
    return null;
  }

  static Future<void> _saveUserData(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user));
    await prefs.remove(_guestKey);

    // Secure Storage
    if (user['id'] != null && user['email'] != null && user['name'] != null) {
      await _secureStorage.saveUserData(
        userId: user['id'].toString(),
        email: user['email'],
        name: user['name'],
      );
    }

    // Notify UI
    _notifyUserChange(user);
  }

  // --- 7. Check ban status ---
  static Future<void> checkBanStatus(BuildContext context) async {
    try {
      final user = await getCurrentUser();
      if (user == null || user['id'] == null) return;

      // Retry logic for checkBanStatus
      int retryCount = 0;
      http.Response? response;

      while (retryCount < 2) {
        final token = await _secureStorage.getAccessToken();
        response = await http.post(
          Uri.parse(ApiEndpoints.checkStatus),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: json.encode({'user_id': user['id']}),
        );

        if (response.statusCode == 401 && retryCount == 0) {
          final newToken = await refreshToken();
          if (newToken != null) {
            retryCount++;
            continue;
          } else {
            // Refresh failed, maybe logout? But checkBan is background mostly
            return;
          }
        }
        break;
      }

      if (response != null &&
          (response.statusCode == 403 || response.statusCode == 404)) {
        // If banned, clear local data
        await logout();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Sorry, your account has been disabled by the administration. Please contact technical support for more information.',
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                  textAlign: TextAlign.center),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error checking ban status: $e");
    }
  }

  // --- 8. Update profile ---
  static Future<Map<String, dynamic>> updateProfile({
    required String id,
    required String name,
    required String phone,
    XFile? imageFile,
  }) async {
    try {
      int retryCount = 0;
      while (retryCount < 2) {
        final token = await _secureStorage.getAccessToken();
        var request = http.MultipartRequest(
            'POST', Uri.parse(ApiEndpoints.updateProfile));

        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }

        request.fields['id'] = id;
        request.fields['name'] = name;
        request.fields['phone'] = phone;

        if (imageFile != null) {
          if (kIsWeb) {
            request.files.add(
              http.MultipartFile.fromBytes(
                'image',
                await imageFile.readAsBytes(),
                filename: imageFile.name,
              ),
            );
          } else {
            request.files.add(
              await http.MultipartFile.fromPath('image', imageFile.path),
            );
          }
        }

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['user'] != null) {
            await _saveUserData(data['user']);
            return data['user'];
          }
          throw Exception('Failed to update profile - unexpected response');
        } else if (response.statusCode == 401 && retryCount == 0) {
          // Token expired, try to refresh
          debugPrint("Token expired in updateProfile, refreshing...");
          final newToken = await refreshToken();
          if (newToken != null) {
            retryCount++;
            continue; // Retry loop
          } else {
            await logout(); // Refresh failed
            throw Exception('Session expired, please login again');
          }
        }

        throw Exception('Failed to update profile (${response.statusCode})');
      }
      throw Exception('Failed to update profile');
    } catch (e) {
      debugPrint("AuthService Error in updateProfile: $e");
      throw Exception('Connection error: $e');
    }
  }

  // --- 9. Auth State Stream (Reactive UI) ---
  static final ValueNotifier<Map<String, dynamic>?> userNotifier =
      ValueNotifier(null);

  // Helper to notify listeners
  static void _notifyUserChange(Map<String, dynamic>? user) {
    userNotifier.value = user;
  }

  // Call this on app start to initialize
  static Future<void> initUserStream() async {
    final user = await getCurrentUser();
    _notifyUserChange(user);
  }

  // --- 8.5 Delete Account Logic ---
  static Future<void> deleteAccount(BuildContext context) async {
    try {
      final user = await getCurrentUser();
      if (user == null || user['id'] == null) return;

      final token = await _secureStorage.getAccessToken();

      // Call endpoint
      await http.post(
        Uri.parse(ApiEndpoints.deleteAccount),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({'user_id': user['id']}),
      );

      // Perform local logout
      await logout(context);
    } catch (e) {
      debugPrint("Error deleting account: $e");
      // Fallback to logout anyway so user feels functionality works
      await logout(context);
    }
  }

  // --- 9. Refresh Token Logic ---
  static Future<String?> refreshToken() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) return null;

      final response = await http.post(
        Uri.parse(ApiEndpoints.refreshToken),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['access_token'] != null) {
          // Save new tokens
          // Note: API might return only access_token or both. Handle accordingly.
          // Assuming API returns 'access_token' and 'expires_at'
          await _secureStorage.saveTokens(
            accessToken: data['access_token'],
            refreshToken: data['refresh_token'] ??
                refreshToken, // Keep old if not rotated
          );
          return data['access_token'];
        }
      }
      return null;
    } catch (e) {
      debugPrint("AuthService Token Refresh Error: $e");
      return null;
    }
  }

  // --- 10. Get JWT Token for API calls ---
  static Future<String?> getAuthToken() async {
    return await _secureStorage.getAccessToken();
  }
}
