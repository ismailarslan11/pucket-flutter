import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Arka planda data-only mesajlar için yerel bildirim göster.
  final n = message.notification;
  final title = n?.title ?? message.data['title'] as String? ?? 'PUCKET';
  final body = n?.body ?? message.data['body'] as String? ?? '';
  if (title.isEmpty && body.isEmpty) return;

  const channel = AndroidNotificationChannel(
    'pucket_high_importance',
    'PUCKET',
    description: 'PUCKET oyun bildirimleri',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  final plugin = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@drawable/ic_stat_notify');
  await plugin.initialize(const InitializationSettings(android: androidInit));
  await plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  const androidDetails = AndroidNotificationDetails(
    'pucket_high_importance',
    'PUCKET',
    importance: Importance.max,
    priority: Priority.high,
    icon: '@drawable/ic_stat_notify',
  );
  await plugin.show(
    message.hashCode,
    title,
    body,
    const NotificationDetails(android: androidDetails),
  );
}
