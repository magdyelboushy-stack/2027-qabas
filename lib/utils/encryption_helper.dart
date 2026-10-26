import 'dart:convert';
import 'package:crypto/crypto.dart';

class EncryptionHelper {
  // Simple XOR encryption for additional obfuscation
  static String xorEncrypt(String input, String key) {
    final keyBytes = utf8.encode(key);
    final inputBytes = utf8.encode(input);
    final output = <int>[];

    for (int i = 0; i < inputBytes.length; i++) {
      output.add(inputBytes[i] ^ keyBytes[i % keyBytes.length]);
    }

    return base64.encode(output);
  }

  static String xorDecrypt(String encrypted, String key) {
    final keyBytes = utf8.encode(key);
    final encryptedBytes = base64.decode(encrypted);
    final output = <int>[];

    for (int i = 0; i < encryptedBytes.length; i++) {
      output.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
    }

    return utf8.decode(output);
  }

  // Hash sensitive data (one-way)
  static String hashSha256(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Generate request signature for API verification
  static String generateSignature(String data, String secret) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final message = '$data:$timestamp:$secret';
    return hashSha256(message);
  }

  // Obfuscate string using Base64 + reverse
  static String obfuscate(String input) {
    final reversed = input.split('').reversed.join('');
    return base64.encode(utf8.encode(reversed));
  }

  static String deobfuscate(String obfuscated) {
    try {
      final decoded = utf8.decode(base64.decode(obfuscated));
      return decoded.split('').reversed.join('');
    } catch (e) {
      return '';
    }
  }
}
