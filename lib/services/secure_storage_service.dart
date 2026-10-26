import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Keys for storage
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';
  static const String _keyTokenExpiry = 'token_expiry';

  // Save JWT tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
  }) async {
    await Future.wait([
      _storage.write(key: _keyAccessToken, value: accessToken),
      _storage.write(key: _keyRefreshToken, value: refreshToken),
      if (expiresAt != null)
        _storage.write(
          key: _keyTokenExpiry,
          value: expiresAt.millisecondsSinceEpoch.toString(),
        ),
    ]);
  }

  // Get access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  // Get refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  // Check if token is expired
  Future<bool> isTokenExpired() async {
    final expiryStr = await _storage.read(key: _keyTokenExpiry);
    if (expiryStr == null) return true;

    final expiry = DateTime.fromMillisecondsSinceEpoch(int.parse(expiryStr));
    return DateTime.now().isAfter(expiry);
  }

  // Save user data
  Future<void> saveUserData({
    required String userId,
    required String email,
    required String name,
  }) async {
    await Future.wait([
      _storage.write(key: _keyUserId, value: userId),
      _storage.write(key: _keyUserEmail, value: email),
      _storage.write(key: _keyUserName, value: name),
    ]);
  }

  // Get user data
  Future<Map<String, String?>> getUserData() async {
    final results = await Future.wait([
      _storage.read(key: _keyUserId),
      _storage.read(key: _keyUserEmail),
      _storage.read(key: _keyUserName),
    ]);

    return {
      'userId': results[0],
      'email': results[1],
      'name': results[2],
    };
  }

  // Clear all data (logout)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Generic secure write
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  // Generic secure read
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  // Delete specific key
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }
}
