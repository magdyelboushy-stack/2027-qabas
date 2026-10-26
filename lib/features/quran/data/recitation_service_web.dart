import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../config/api_endpoints.dart';
import 'models/recitation.dart';

class RecitationService {
  static Future<List<Recitation>> getRecitationsForShaykh(
    String shaykhId, {
    String? mushafId,
  }) async {
    List<Recitation> allRecitations = [];

    try {
      final url = ApiEndpoints.buildUrl(
        ApiEndpoints.recitationsRead,
        {
          'reciter_id': shaykhId,
          if (mushafId != null) 'mushaf_id': mushafId,
        },
      );

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          final List<dynamic> jsonList = data['data'];
          allRecitations =
              jsonList.map((jsonItem) => Recitation.fromJson(jsonItem)).toList();
        }
      }
    } catch (_) {
      allRecitations = [];
    }

    if (mushafId != null) {
      allRecitations =
          allRecitations.where((r) => r.mushafId == mushafId).toList();
    }

    return allRecitations;
  }
}
