import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print('Handling background message: ${message.messageId}');
  }
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final Dio _dio = Dio(BaseOptions(baseUrl: AuthService.baseUrl));

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 1. Initialize Firebase
      await Firebase.initializeApp();

      // 2. Set Background Message Handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Setup Local Notifications for Foreground Banners
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(initSettings);

      // 4. Request Permissions
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (kDebugMode) {
          print('User granted notification permissions');
        }

        // 5. Get and Sync FCM Token
        String? token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await syncFcmTokenWithBackend(token);
        }

        // Token Refresh Listener
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
          syncFcmTokenWithBackend(newToken);
        });

        // 6. Listen for Foreground Messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          _showForegroundNotification(message);
        });
      }

      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('PushNotificationService initialization warning: $e');
      }
    }
  }

  Future<void> syncFcmTokenWithBackend(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwt_token');

      if (jwtToken == null) {
        if (kDebugMode) {
          print('User not logged in yet. Skipping FCM token upload.');
        }
        return;
      }

      final response = await _dio.post(
        '/api/v1/users/fcm-token',
        data: {'fcmToken': token},
        options: Options(
          headers: {
            'Authorization': 'Bearer $jwtToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (kDebugMode) {
        print('FCM Token synced successfully: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing FCM token with backend: $e');
      }
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'moi_high_importance_channel',
            'MoI Notifications',
            channelDescription: 'Notifications for MoI Reports and Messages',
            importance: Importance.max,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }
  }
}
