import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import '../theme/app_theme.dart';

const _androidLargeIcon = DrawableResourceAndroidBitmap('@mipmap/ic_launcher');

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final n = message.notification;
  final title = n?.title ?? message.data['title'] as String? ?? 'PUCKET';
  final body = n?.body ?? message.data['body'] as String? ?? '';
  if (title.isEmpty && body.isEmpty) return;

  final plugin = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@drawable/ic_stat_notify');
  const iosInit = DarwinInitializationSettings();
  await plugin.initialize(const InitializationSettings(android: androidInit, iOS: iosInit));

  const iosDetails = DarwinNotificationDetails();
  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      'pucket_high_importance',
      'PUCKET',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@drawable/ic_stat_notify',
      largeIcon: _androidLargeIcon,
      color: AppColors.brandBlue,
    ),
    iOS: iosDetails,
  );

  if (Platform.isAndroid) {
    const channel = AndroidNotificationChannel(
      'pucket_high_importance',
      'PUCKET',
      description: 'PUCKET oyun bildirimleri',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    await plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  await plugin.show(message.hashCode, title, body, details);
}
