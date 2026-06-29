import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_init.dart';
import 'meta_api.dart';

/// FCM push bildirimleri — token kaydı + foreground gösterim.
class PushService {
  PushService._();

  static const _channelId = 'pucket_high_importance';
  static const _channelName = 'PUCKET';

  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static String? _cachedToken;
  static String? _cachedUid;
  static bool _setupDone = false;

  static Future<void> setup() async {
    if (kIsWeb || !firebaseEnabled || _setupDone) return;
    _setupDone = true;

    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      await _initLocalNotifications();

      final messaging = FirebaseMessaging.instance;
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      if (Platform.isIOS) {
        await messaging.requestPermission(alert: true, badge: true, sound: true);
      }

      if (Platform.isAndroid) {
        final android = _local.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await android?.requestNotificationsPermission();
      }

      _cachedToken = await messaging.getToken();
      debugPrint('FCM token: ${_cachedToken ?? "(yok)"}');

      messaging.onTokenRefresh.listen((token) async {
        _cachedToken = token;
        debugPrint('FCM token yenilendi');
        if (_cachedUid != null) {
          await MetaApi.saveFcmToken(_cachedUid!, token);
        }
      });

      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    } catch (e) {
      debugPrint('Push setup failed: $e');
    }
  }

  static Future<void> initAndRegister(String uid) async {
    if (kIsWeb || !firebaseEnabled) return;
    _cachedUid = uid;

    await setup();

    try {
      _cachedToken ??= await FirebaseMessaging.instance.getToken();
      final token = _cachedToken;
      if (token != null && token.isNotEmpty) {
        await MetaApi.saveFcmToken(uid, token);
        debugPrint('FCM token sunucuya kaydedildi');
      } else {
        debugPrint('FCM token alınamadı — Play Services / izin kontrol et');
      }
    } catch (e) {
      debugPrint('Push register failed: $e');
    }
  }

  static Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'PUCKET oyun bildirimleri',
        importance: Importance.high,
      );
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _local.show(
      n.hashCode,
      n.title,
      n.body,
      details,
    );
  }
}
