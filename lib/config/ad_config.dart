import 'package:flutter/foundation.dart';

/// AdMob birim ID'leri.
///
/// Test ID'leri varsayılan — gerçek gelir için AdMob Console'dan alıp
/// build sırasında dart-define ile ver:
///
///   --dart-define=ADMOB_BANNER_ID=ca-app-pub-XXXX/YYYY
///   --dart-define=ADMOB_INTERSTITIAL_ID=ca-app-pub-XXXX/YYYY
///
/// AndroidManifest + Info.plist içindeki APPLICATION_ID'yi de güncelle.
class AdConfig {
  AdConfig._();

  static const _bannerFromEnv = String.fromEnvironment('ADMOB_BANNER_ID');
  static const _interstitialFromEnv = String.fromEnvironment('ADMOB_INTERSTITIAL_ID');

  /// Google test banner
  static const _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';

  /// Google test interstitial
  static const _testInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const _testInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';

  static String get bannerUnitId {
    if (_bannerFromEnv.isNotEmpty) return _bannerFromEnv;
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.iOS) return _testBannerIos;
    if (defaultTargetPlatform == TargetPlatform.android) return _testBannerAndroid;
    return '';
  }

  static String get interstitialUnitId {
    if (_interstitialFromEnv.isNotEmpty) return _interstitialFromEnv;
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.iOS) return _testInterstitialIos;
    if (defaultTargetPlatform == TargetPlatform.android) return _testInterstitialAndroid;
    return '';
  }

  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
}
