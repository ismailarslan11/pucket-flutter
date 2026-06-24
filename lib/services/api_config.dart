import 'package:flutter/foundation.dart';

/// WebSocket sunucu adresi.
/// Android emülatör: ws://10.0.2.2:8080
/// Gerçek cihaz: ws://BILGISAYAR_IP:8080
/// Production:
///   flutter build apk --dart-define=WS_URL=wss://SUNUCU --dart-define=API_URL=https://SUNUCU
///   veya: ./tool/build_release.sh apk
String get kWsServerUrl {
  const fromEnv = String.fromEnvironment('WS_URL');
  if (fromEnv.isNotEmpty) return fromEnv;

  assert(() {
    // Debug: localhost uyarısı
    return true;
  }());

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'ws://10.0.2.2:8080';
  }
  return 'ws://localhost:8080';
}

String httpBaseFromWs(String wsUrl) {
  var url = wsUrl;
  if (url.startsWith('wss://')) {
    return url.replaceFirst('wss://', 'https://');
  }
  if (url.startsWith('ws://')) {
    return url.replaceFirst('ws://', 'http://');
  }
  return 'http://$url';
}

const kHttpBaseUrl = String.fromEnvironment('API_URL', defaultValue: '');

String get apiBaseUrl {
  if (kHttpBaseUrl.isNotEmpty) return kHttpBaseUrl;
  return httpBaseFromWs(kWsServerUrl);
}
