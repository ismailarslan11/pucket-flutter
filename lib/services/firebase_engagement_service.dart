import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firebase_init.dart';

/// Firebase Analytics + In-App Messaging.
class FirebaseEngagementService {
  FirebaseEngagementService._();

  static FirebaseAnalytics? _analytics;
  static FirebaseInAppMessaging? _inAppMessaging;
  static String? installationId;
  static String statusMessage = 'Henüz başlatılmadı';

  static FirebaseAnalytics? get analytics => _analytics;

  static Future<void> init() async {
    if (kIsWeb || !firebaseEnabled) {
      statusMessage = 'Firebase kapalı';
      return;
    }

    try {
      _analytics = FirebaseAnalytics.instance;
      _inAppMessaging = FirebaseInAppMessaging.instance;

      await _inAppMessaging!.setAutomaticDataCollectionEnabled(true);
      await _inAppMessaging!.setMessagesSuppressed(false);

      await _analytics!.logAppOpen();
      installationId = await FirebaseInstallations.instance.getId();
      statusMessage = 'Analytics + In-App Messaging aktif';
      debugPrint('Firebase IAM FID: $installationId');
    } catch (e) {
      statusMessage = 'Engagement hata: $e';
      debugPrint('FirebaseEngagementService init failed: $e');
    }
  }

  static Future<void> setUser(String uid) async {
    if (_analytics == null) return;
    try {
      await _analytics!.setUserId(id: uid);
    } catch (e) {
      debugPrint('Analytics setUserId failed: $e');
    }
  }

  static Future<void> logScreen(String name) async {
    if (_analytics == null) return;
    try {
      await _analytics!.logScreenView(screenName: name);
    } catch (e) {
      debugPrint('Analytics logScreenView failed: $e');
    }
  }

  static Future<void> logEvent(String name, {Map<String, Object>? params}) async {
    if (_analytics == null) return;
    try {
      await _analytics!.logEvent(name: name, parameters: params);
    } catch (e) {
      debugPrint('Analytics logEvent failed: $e');
    }
  }

  static Future<String?> refreshInstallationId() async {
    if (kIsWeb || !firebaseEnabled) return null;
    try {
      installationId = await FirebaseInstallations.instance.getId();
      return installationId;
    } catch (e) {
      debugPrint('getInstallationId failed: $e');
      return null;
    }
  }
}
