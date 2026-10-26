import 'dart:convert';
import 'package:flutter/services.dart';
import 'adhkar_model.dart';

class AdhkarService {
  static Future<List<AdhkarCategory>> getAdhkar() async {
    try {
      final String response = await rootBundle.loadString('assets/data/adhkar.json');
      final List<dynamic> data = json.decode(response);

      return data.map((json) => AdhkarCategory.fromJson(json)).toList();
    } catch (_) {
      // Consider logging this error to a service like Crashlytics
      // Consider logging this error to a service like Crashlytics
      return [];
    }
  }
}
