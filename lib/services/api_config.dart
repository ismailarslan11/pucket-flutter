import 'package:flutter/foundation.dart';

/// Canlı sunucu (Render). Yerel test için:
/// flutter run --dart-define=WS_URL=ws://localhost:8080 --dart-define=API_URL=http://localhost:8080
const kProductionServer = 'https://pucket-flutter-2.onrender.com';
const kLocalServerHttp = 'http://localhost:8080';
const kLocalServerWs = 'ws://localhost:8080';

/// macOS/Windows/Linux debug: yerel sunucu. Telefon release: Render.
bool get useLocalDevServer {
  if (kIsWeb) return true;
  if (!kDebugMode) return false;
  switch (defaultTargetPlatform) {
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
    case TargetPlatform.linux:
      return true;
    default:
      return false;
  }
}

String get kWsServerUrl {
  const fromEnv = String.fromEnvironment('WS_URL');
  if (fromEnv.isNotEmpty) return fromEnv;

  if (useLocalDevServer) return kLocalServerWs;

  return 'wss://pucket-flutter-2.onrender.com';
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

  const ws = String.fromEnvironment('WS_URL');
  if (ws.isNotEmpty) return httpBaseFromWs(ws);

  if (useLocalDevServer) return kLocalServerHttp;

  return kProductionServer;
}

bool get apiUsesProductionServer =>
    !useLocalDevServer && apiBaseUrl.contains('onrender.com');
