import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_init.dart';
import 'meta_api.dart';

/// FCM push bildirimleri.
class PushService {
  PushService._();

  static const _channelId = 'pucket_high_importance';
  static const _channelName = 'PUCKET';
  static const _topic = 'pucket';

  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static String? _cachedToken;
  static String? _cachedUid;
  static bool _setupDone = false;

  static String statusMessage = 'Henüz başlatılmadı';
  static bool permissionGranted = false;

  static String? get token => _cachedToken;

  static Future<void> setup() async {
    if (kIsWeb || !firebaseEnabled) {
      statusMessage = 'Firebase kapalı';
      return;
    }
    if (_setupDone) return;
    if (!Platform.isAndroid && !Platform.isIOS) {
      statusMessage = 'Bu platform desteklenmiyor';
      return;
    }

    try {
      await _initLocalNotifications();

      final messaging = FirebaseMessaging.instance;
      await messaging.setAutoInitEnabled(true);
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      permissionGranted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;

      if (Platform.isAndroid) {
        final android = _local.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final androidOk = await android?.requestNotificationsPermission();
        if (androidOk == true) permissionGranted = true;
      }

      _cachedToken = await _fetchTokenWithRetry();
      if (_cachedToken == null) {
        statusMessage =
            'FCM token alınamadı. Google Play Services güncel mi? (BlueStacks\'ta sık sorun)';
        debugPrint('Push: $statusMessage');
        return;
      }

      statusMessage = 'Token alındı (${_cachedToken!.substring(0, 12)}…)';
      debugPrint('FCM token: $_cachedToken');

      try {
        await messaging.subscribeToTopic(_topic);
        debugPrint('FCM topic abone: $_topic');
      } catch (e) {
        debugPrint('FCM topic abonelik hatası: $e');
      }

      messaging.onTokenRefresh.listen((token) async {
        _cachedToken = token;
        statusMessage = 'Token yenilendi';
        if (_cachedUid != null) {
          await MetaApi.saveFcmToken(_cachedUid!, token);
        }
      });

      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      FirebaseMessaging.onMessageOpenedApp.listen((msg) {
        debugPrint('Push açıldı: ${msg.notification?.title}');
      });

      _setupDone = true;
    } catch (e) {
      statusMessage = 'Push hata: $e';
      debugPrint('Push setup failed: $e');
    }
  }

  static Future<void> initAndRegister(String uid) async {
    if (kIsWeb || !firebaseEnabled) return;
    _cachedUid = uid;
    await setup();

    final token = _cachedToken ?? await _fetchTokenWithRetry();
    if (token != null && token.isNotEmpty) {
      await MetaApi.saveFcmToken(uid, token);
      statusMessage = 'Sunucuya kaydedildi';
      debugPrint('FCM token sunucuya kaydedildi');
    }
  }

  static Future<String?> refreshToken() async {
    await setup();
    _cachedToken = await _fetchTokenWithRetry();
    if (_cachedUid != null && _cachedToken != null) {
      await MetaApi.saveFcmToken(_cachedUid!, _cachedToken!);
    }
    return _cachedToken;
  }

  static Future<void> copyTokenToClipboard() async {
    final t = _cachedToken ?? await refreshToken();
    if (t != null) {
      await Clipboard.setData(ClipboardData(text: t));
      statusMessage = 'Token panoya kopyalandı — Firebase Test mesajına yapıştır';
    } else {
      statusMessage = 'Kopyalanacak token yok';
    }
  }

  static Future<bool> showTestNotification() async {
    try {
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@drawable/ic_stat_notify',
      );
      const iosDetails = DarwinNotificationDetails();
      await _local.show(
        999,
        'PUCKET test',
        'Bildirimler çalışıyor!',
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
      );
      return true;
    } catch (e) {
      statusMessage = 'Test bildirimi hatası: $e';
      return false;
    }
  }

  static Future<String?> _fetchTokenWithRetry() async {
    const maxAttempts = 5;
    for (var i = 0; i < maxAttempts; i++) {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.isNotEmpty) return token;
      } catch (e) {
        final msg = e.toString();
        debugPrint('getToken deneme ${i + 1}: $e');
        // iOS simülatörde APNS yok; gereksiz beklemeyi kes.
        if (Platform.isIOS && msg.contains('apns-token-not-set')) {
          statusMessage = 'Simülatörde push token alınamaz (gerçek cihaz gerekir)';
          return null;
        }
      }
      if (i < maxAttempts - 1) {
        await Future<void>.delayed(Duration(seconds: 1 + i));
      }
    }
    return null;
  }

  static Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@drawable/ic_stat_notify');
    const ios = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'PUCKET oyun bildirimleri',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final n = message.notification;
    final title = n?.title ?? message.data['title'] as String? ?? 'PUCKET';
    final body = n?.body ?? message.data['body'] as String? ?? '';

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@drawable/ic_stat_notify',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _local.show(message.hashCode, title, body, details);
  }
}
