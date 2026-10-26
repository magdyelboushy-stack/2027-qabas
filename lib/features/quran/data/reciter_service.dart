// This service seems redundant as ApiService already handles fetching Shaykhs.
// You might want to consolidate this into ApiService or keep it if it will have distinct logic.
// For now, I'll redirect it to use ApiService to avoid duplication.

import '../../../core/services/api_service.dart';
import 'models/shaykh.dart';

class ReciterService {
  static Future<List<Shaykh>> getAllReciters() async {
    return await ApiService.getShaykhs();
  }
}
