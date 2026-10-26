import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mihrab/core/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/desktop_utils.dart';

// ✅ Top-level function for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // debugPrint("Handling background message: ${message.messageId}");
}

class FCMService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Initialize FCM
  static Future<void> initialize() async {
    // ✅ Skip FCM on desktop platforms (not supported)
    if (DesktopUtils.isDesktop) return;

    // 1. Request Permission
    await _requestPermission();

    // 2. Setup Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Setup Local Notifications (for Foreground)
    await _setupLocalNotifications();

    // 4. Get & Save Token
    await _getToken();

    // 4.5 Subscribe to general topic
    await _firebaseMessaging.subscribeToTopic('all_users');

    // 5. Foreground Message Listener
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 6. Message Opened App Listener
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 7. Check if app opened from terminated state
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  static Future<void> _requestPermission() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  static Future<void> _getToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        // debugPrint("🔥 FCM Token: $token");
        await _saveTokenToBackend(token);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen(_saveTokenToBackend);
    } catch (e) {
      // debugPrint("Error getting FCM token: $e");
    }
  }

  static Future<void> _saveTokenToBackend(String token) async {
    // Save locally to avoid redundant API calls
    final prefs = await SharedPreferences.getInstance();
    final String? savedToken = prefs.getString('fcm_token');

    if (savedToken != token) {
      // Send to API
      // debugPrint("🚀 Sending new FCM token to backend...");
      await ApiService.updateFCMToken(token);
      await prefs.setString('fcm_token', token);
    }
  }

  static Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle local notification tap
        // debugPrint("Local notification tapped payload: ${response.payload}");
      },
    );

    // Create high importance channel for Android
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            'high_importance_channel', // id
            'High Importance Notifications', // title
            description: 'This channel is used for important notifications.',
            importance: Importance.high,
          ));
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    // debugPrint("📩 Foreground Message received: ${message.notification?.title}");

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    // Show local notification
    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            icon: '@mipmap/launcher_icon',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    // debugPrint("📖 Notification caused app to open: ${message.messageId}");
    // Navigate to specific screen if needed
    // navigatorKey.currentState?.pushNamed('/notifications');
  }
}
