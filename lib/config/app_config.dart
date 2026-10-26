import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Environment detection
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'production',
  );

  static bool get isProduction =>
      (dotenv.env['ENVIRONMENT'] ?? environment) == 'production';
  static bool get isLocal =>
      (dotenv.env['ENVIRONMENT'] ?? environment) == 'local';

  // API Base URL
  static String get apiBaseUrl {
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      final decoded = _decodeUrl(envUrl);
      if (decoded.isNotEmpty) return decoded;
    }
    if (isLocal) {
      return 'http://10.0.2.2/MihrabApp_API/api';
    }
    return 'https://mihrab-app.alwaysdata.net/api';
  }

  // Decode obfuscated or plain URL
  static String _decodeUrl(String encoded) {
    try {
      return utf8.decode(base64.decode(encoded));
    } catch (e) {
      return encoded;
    }
  }

  // Encode URL for .env file (helper method)
  static String encodeUrl(String url) {
    return base64.encode(utf8.encode(url));
  }

  // App version
  static const String appVersion = '1.0.2';
  
  // API timeout
  static const Duration apiTimeout = Duration(seconds: 30);
  
  // Enable debug logs
  static bool get enableDebugLogs => !isProduction;
}
