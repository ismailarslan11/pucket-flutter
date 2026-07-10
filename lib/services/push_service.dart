import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import 'deep_link_service.dart';
import 'firebase_init.dart';
import 'meta_api.dart';
import '../theme/app_theme.dart';

/// FCM push bildirimleri.
class PushService {
  PushService._();

  static const channelId = 'pucket_high_importance';
  static const channelName = 'PUCKET';
  static const topic = 'pucket';

  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static String? _cachedToken;
  static String? _cachedUid;
  static bool _setupDone = false;
  static bool _listenersRegistered = false;
  static bool topicSubscribed = false;
  static Future<void>? _setupFuture;

  static String statusMessage = 'Henüz başlatılmadı';
  static bool permissionGranted = false;

  static const _androidLargeIcon = DrawableResourceAndroidBitmap('@mipmap/ic_launcher');

  static const AndroidNotificationDetails _androidDetails = AndroidNotificationDetails(
    channelId,
    channelName,
    importance: Importance.max,
    priority: Priority.high,
    icon: '@drawable/ic_stat_notify',
    largeIcon: _androidLargeIcon,
      color: AppColors.brandBlue,
  );

  static String? get fcmToken => _cachedToken;

  static Future<void> setup({bool force = false}) async {
    if (kIsWeb || !firebaseEnabled) {
      statusMessage = 'Firebase kapalı';
      return;
    }
    if (_setupDone && _cachedToken != null && !force) return;
    if (!Platform.isAndroid && !Platform.isIOS) {
      statusMessage = 'Bu platform desteklenmiyor';
      return;
    }

    _setupFuture ??= _setupImpl();
    await _setupFuture;
    _setupFuture = null;
  }

  static Future<void> _setupImpl() async {
    try {
      await _initLocalNotifications();

      if (Platform.isAndroid) {
        final android = _local.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final androidOk = await android?.requestNotificationsPermission();
        if (androidOk == true) permissionGranted = true;
      }

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
              settings.authorizationStatus == AuthorizationStatus.provisional ||
              permissionGranted;

      if (!permissionGranted && Platform.isAndroid) {
        statusMessage = 'Bildirim izni kapalı — Android ayarlarından PUCKET için açın';
        debugPrint('Push: bildirim izni reddedildi');
      }

      _registerListenersOnce();

      _cachedToken = await _fetchTokenWithRetry();
      if (_cachedToken == null) {
        statusMessage = Platform.isIOS
            ? 'FCM token alınamadı. Gerçek iPhone + bildirim izni + Firebase APNs anahtarı gerekir.'
            : 'FCM token alınamadı. Bildirim iznini açın ve Google Play Services güncel olsun.';
        debugPrint('Push: $statusMessage');
        unawaited(_delayedTokenAndTopicRetry());
      } else {
        statusMessage = 'Token alındı (${_cachedToken!.substring(0, 12)}…)';
        debugPrint('FCM token: $_cachedToken');
        await _subscribeTopic();
      }

      _setupDone = true;
    } catch (e) {
      statusMessage = 'Push hata: $e';
      debugPrint('Push setup failed: $e');
    }
  }

  static void _registerListenersOnce() {
    if (_listenersRegistered) return;
    _listenersRegistered = true;

    final messaging = FirebaseMessaging.instance;
    messaging.onTokenRefresh.listen((token) async {
      _cachedToken = token;
      statusMessage = 'Token yenilendi';
      debugPrint('FCM token yenilendi: $token');
      await _subscribeTopic();
      if (_cachedUid != null) {
        await MetaApi.saveFcmToken(_cachedUid!, token);
      }
    });

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpened);

    // Uygulama kapalıyken push'a dokunularak açıldıysa.
    FirebaseMessaging.instance.getInitialMessage().then((initial) {
      if (initial != null) _handleOpened(initial);
    });
  }

  /// Arkadaş meydan okuma push'una dokununca ilgili odaya katıl.
  static void _handleOpened(RemoteMessage msg) {
    debugPrint('Push açıldı: ${msg.notification?.title}');
    final data = msg.data;
    if (data['type'] == 'challenge') {
      final room = (data['room'] ?? '').toString();
      if (room.isNotEmpty) {
        // Menü açılınca DeepLinkService.consumePending tarafından kullanılır.
        DeepLinkService.pendingJoinCode = room.toUpperCase();
      }
    }
  }

  static Future<void> _subscribeTopic() async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      topicSubscribed = true;
      statusMessage = 'Topic abone: $topic';
      debugPrint('FCM topic abone: $topic');
    } catch (e) {
      topicSubscribed = false;
      debugPrint('FCM topic abonelik hatası: $e');
    }
  }

  static Future<void> _delayedTokenAndTopicRetry() async {
    for (final waitSec in [5, 15, 30, 60]) {
      await Future<void>.delayed(Duration(seconds: waitSec));
      if (_cachedToken != null && topicSubscribed) return;
      final token = await _fetchTokenWithRetry();
      if (token != null && token.isNotEmpty) {
        _cachedToken = token;
        debugPrint('FCM token (gecikmeli): $token');
        await _subscribeTopic();
        if (_cachedUid != null) {
          await MetaApi.saveFcmToken(_cachedUid!, token);
        }
        return;
      }
    }
  }

  static Future<void> initAndRegister(String uid) async {
    if (kIsWeb || !firebaseEnabled) return;
    _cachedUid = uid;
    await setup(force: _cachedToken == null);

    final token = _cachedToken ?? await _fetchTokenWithRetry();
    if (token != null && token.isNotEmpty) {
      _cachedToken = token;
      await _subscribeTopic();
      await MetaApi.saveFcmToken(uid, token);
      statusMessage = 'Sunucuya kaydedildi (topic: $topic)';
      debugPrint('FCM token sunucuya kaydedildi');
    } else {
      unawaited(_delayedTokenAndTopicRetry());
    }
  }

  static Future<String?> refreshToken() async {
    await setup();
    _cachedToken = await _fetchTokenWithRetry();
    if (_cachedToken != null) {
      await _subscribeTopic();
      statusMessage = 'Token alındı (${_cachedToken!.substring(0, 12)}…)';
    }
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
      const iosDetails = DarwinNotificationDetails();
      await _local.show(
        999,
        'PUCKET test',
        'Bildirimler çalışıyor!',
        const NotificationDetails(android: _androidDetails, iOS: iosDetails),
      );
      return true;
    } catch (e) {
      statusMessage = 'Test bildirimi hatası: $e';
      return false;
    }
  }

  static Future<void> showRemoteNotification(RemoteMessage message) async {
    await _showForegroundNotification(message);
  }

  static Future<String?> _fetchTokenWithRetry() async {
    if (Platform.isIOS) {
      await _ensureApnsToken();
    }

    final maxAttempts = Platform.isAndroid ? 10 : 12;
    for (var i = 0; i < maxAttempts; i++) {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.isNotEmpty) return token;
      } catch (e) {
        final msg = e.toString();
        debugPrint('getToken deneme ${i + 1}: $e');
        if (Platform.isIOS && msg.contains('apns-token-not-set')) {
          statusMessage = 'APNs token bekleniyor… (simülatörde push çalışmaz)';
        }
      }
      if (i < maxAttempts - 1) {
        await Future<void>.delayed(Duration(seconds: 1 + (i ~/ 2)));
      }
    }
    if (Platform.isIOS) {
      statusMessage =
          'iOS push token alınamadı. Xcode Push Notifications + Firebase APNs (.p8) kontrol edin.';
    }
    return null;
  }

  static Future<void> _ensureApnsToken() async {
    for (var i = 0; i < 12; i++) {
      final apns = await FirebaseMessaging.instance.getAPNSToken();
      if (apns != null && apns.isNotEmpty) return;
      await Future<void>.delayed(Duration(seconds: 1 + (i ~/ 3)));
    }
  }

  static Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@drawable/ic_stat_notify');
    const ios = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    if (Platform.isIOS) {
      await _local
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        channelId,
        channelName,
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

    // Resimli bildirim: FCM image alanı veya data.image.
    final imageUrl = n?.android?.imageUrl ??
        n?.apple?.imageUrl ??
        (message.data['image'] as String?);

    AndroidNotificationDetails androidDetails = _androidDetails;
    DarwinNotificationDetails iosDetails = const DarwinNotificationDetails();

    if (imageUrl != null && imageUrl.isNotEmpty) {
      final path = await _downloadImage(imageUrl);
      if (path != null) {
        androidDetails = AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@drawable/ic_stat_notify',
          largeIcon: _androidLargeIcon,
          color: AppColors.brandBlue,
          styleInformation: BigPictureStyleInformation(FilePathAndroidBitmap(path)),
        );
        iosDetails = DarwinNotificationDetails(
          attachments: [DarwinNotificationAttachment(path)],
        );
      }
    }

    await _local.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  /// Push resmi geçici dosyaya indirilir (bildirim eki dosya yolu ister).
  static Future<String?> _downloadImage(String url) async {
    try {
      final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return null;
      final ext = url.toLowerCase().contains('.png') ? 'png' : 'jpg';
      final file = File(
        '${Directory.systemTemp.path}/push_${DateTime.now().millisecondsSinceEpoch}.$ext',
      );
      await file.writeAsBytes(resp.bodyBytes);
      return file.path;
    } catch (_) {
      return null;
    }
  }
}
