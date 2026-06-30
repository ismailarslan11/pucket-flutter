import 'package:flutter/foundation.dart';

/// AdMob birim ID'leri.
///
/// Release Android build'de gerçek banner kullanılır.
/// Interstitial için AdMob birim ID'si [ _prodInterstitialAndroid ] içinde tanımlı.
/// İsteğe bağlı override: --dart-define=ADMOB_INTERSTITIAL_ID=...
class AdConfig {
  AdConfig._();

  static const _bannerFromEnv = String.fromEnvironment('ADMOB_BANNER_ID');
  static const _interstitialFromEnv = String.fromEnvironment('ADMOB_INTERSTITIAL_ID');

  /// PUCKET Android — AdMob Console
  static const _prodBannerAndroid = 'ca-app-pub-2558408055462441/2240385603';
  static const _prodInterstitialAndroid = 'ca-app-pub-2558408055462441/3263078842';

  /// Google test banner
  static const _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';

  /// Google test interstitial
  static const _testInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const _testInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';

  static String get bannerUnitId {
    if (_bannerFromEnv.isNotEmpty) return _bannerFromEnv;
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return kDebugMode ? _testBannerAndroid : _prodBannerAndroid;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) return _testBannerIos;
    return '';
  }

  static String get interstitialUnitId {
    if (_interstitialFromEnv.isNotEmpty) return _interstitialFromEnv;
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      if (kDebugMode) return _testInterstitialAndroid;
      if (_prodInterstitialAndroid.isNotEmpty) return _prodInterstitialAndroid;
      return _testInterstitialAndroid;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) return _testInterstitialIos;
    return '';
  }

  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
}
