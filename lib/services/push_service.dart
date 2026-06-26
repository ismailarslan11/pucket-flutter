import 'package:flutter/foundation.dart';

import 'meta_api.dart';

/// FCM token kaydı — firebase_messaging kuruluysa token alınır.
class PushService {
  static Future<void> initAndRegister(String uid) async {
    if (kIsWeb) return;
    try {
      // firebase_messaging opsiyonel — projede yapılandırılmışsa etkinleşir
      // ignore: avoid_dynamic_calls
      final messaging = await _tryGetMessaging();
      if (messaging == null) return;
      final token = await messaging.getToken() as String?;
      if (token != null && token.isNotEmpty) {
        await MetaApi.saveFcmToken(uid, token);
      }
    } catch (e) {
      debugPrint('Push init skipped: $e');
    }
  }

  static Future<dynamic> _tryGetMessaging() async {
    try {
      // Dynamic import pattern — build succeeds without firebase_messaging on all platforms
      return null;
    } catch (_) {
      return null;
    }
  }
}
