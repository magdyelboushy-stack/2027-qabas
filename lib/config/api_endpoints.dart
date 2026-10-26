import 'app_config.dart';

class ApiEndpoints {
  // Base URL from config
  static String get _baseUrl => AppConfig.apiBaseUrl;

  // Auth endpoints
  static String get login => '$_baseUrl/app_auth/login.php';
  static String get register => '$_baseUrl/app_auth/register.php';
  static String get googleLogin => '$_baseUrl/app_auth/google_login.php';
  static String get refreshToken => '$_baseUrl/app_auth/refresh_token.php';
  static String get updateProfile => '$_baseUrl/app_auth/update_profile.php';
  static String get deleteAccount => '$_baseUrl/app_auth/delete_account.php';
  static String get checkStatus => '$_baseUrl/app_auth/check_status.php';
  static String get logout => '$_baseUrl/app_auth/logout.php';
  static String get updateFCMToken => '$_baseUrl/app_auth/update_fcm_token.php';

  // Settings endpoints
  static String get settingsRead => '$_baseUrl/settings/read.php';

  // Reciters endpoints
  static String get recitersRead => '$_baseUrl/reciters/read.php';
  static String get recitersCreate => '$_baseUrl/reciters/create.php';
  static String get recitersUpdate => '$_baseUrl/reciters/update.php';
  static String get recitersDelete => '$_baseUrl/reciters/delete.php';

  // Recitations endpoints
  static String get recitationsRead => '$_baseUrl/recitations/read.php';
  static String recitationsByReciter(int reciterId) =>
      '$_baseUrl/recitations/read_by_reciter.php?reciter_id=$reciterId';
  static String recitationSingle(int id) =>
      '$_baseUrl/recitations/read_single.php?id=$id';
  static String get recitationsCreate => '$_baseUrl/recitations/create.php';
  static String get recitationsUpdate => '$_baseUrl/recitations/update.php';
  static String get recitationsDelete => '$_baseUrl/recitations/delete.php';
  static String get recitationsIncreaseViews =>
      '$_baseUrl/recitations/increase_views.php';

  // Mushafs endpoints
  static String get mushafsRead => '$_baseUrl/mushafs/read.php';
  static String mushafsByReciter(int reciterId) =>
      '$_baseUrl/mushafs/read_by_reciter.php?reciter_id=$reciterId';
  static String get mushafsCreate => '$_baseUrl/mushafs/create.php';
  static String get mushafsUpdate => '$_baseUrl/mushafs/update.php';
  static String get mushafsDelete => '$_baseUrl/mushafs/delete.php';

  // Adhans endpoints
  static String get adhansRead => '$_baseUrl/adhans/read.php';
  static String get adhansCreate => '$_baseUrl/adhans/create.php';
  static String get adhansUpdate => '$_baseUrl/adhans/update.php';
  static String get adhansDelete => '$_baseUrl/adhans/delete.php';

  // Slider endpoints
  static String get sliderRead => '$_baseUrl/slider/read.php';
  static String sliderSingle(int id) =>
      '$_baseUrl/slider/read_single.php?id=$id';
  static String get sliderCreate => '$_baseUrl/slider/create.php';
  static String get sliderUpdate => '$_baseUrl/slider/update.php';
  static String get sliderDelete => '$_baseUrl/slider/delete.php';

  // Users endpoints
  static String get usersRead => '$_baseUrl/users/read.php';
  static String get usersBan => '$_baseUrl/users/ban.php';

  // Chat endpoints
  static String get chatRead => '$_baseUrl/chat/read.php';
  static String get chatSend => '$_baseUrl/chat/send.php';

  // Notifications endpoints
  static String get notificationsRead => '$_baseUrl/notifications/read.php';
  static String get notificationsCreate => '$_baseUrl/notifications/create.php';
  static String get notificationsDelete => '$_baseUrl/notifications/delete.php';

  // Contact / Feedback endpoints
  static String get contactSend => '$_baseUrl/contact/send.php';
  static String get contactRead => '$_baseUrl/contact/read.php';

  // Ramadan endpoints
  static String get ramadanSync => '$_baseUrl/ramadan/sync.php';
  static String get ramadanLeaderboard => '$_baseUrl/ramadan/leaderboard.php';
  static String get ramadanSetupDb => '$_baseUrl/ramadan/setup_db.php';

  // Helper method to build URL with query params
  static String buildUrl(String endpoint, Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) return endpoint;

    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');

    return '$endpoint?$queryString';
  }
}
