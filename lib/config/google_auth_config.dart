import 'google_auth_config.generated.dart';

/// Google OAuth client IDs — `tool/setup_firebase.sh` ile otomatik dolar
/// veya `--dart-define` ile geçilebilir.
class GoogleAuthConfig {
  /// Web client ID (Firebase Console → Project settings → Web app).
  /// iOS/Android'de Firebase Auth için idToken almak için gerekli.
  static String get webClientId {
    const fromEnv = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;
    return GoogleAuthConfigGenerated.webClientId;
  }

  /// iOS client ID (GoogleService-Info.plist → CLIENT_ID).
  static String get iosClientId {
    const fromEnv = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;
    return GoogleAuthConfigGenerated.iosClientId;
  }

  static bool get hasWebClientId => webClientId.isNotEmpty;
  static bool get hasIosClientId => iosClientId.isNotEmpty;
}
