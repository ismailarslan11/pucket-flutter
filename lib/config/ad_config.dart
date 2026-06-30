import 'package:flutter/foundation.dart';

/// AdMob birim ID'leri.
///
/// Release build varsayılan: prod birimler.
/// Test reklam yalnızca debug veya --dart-define=ADMOB_USE_TEST_ADS=true ile.
class AdConfig {
  AdConfig._();

  static const _bannerFromEnv = String.fromEnvironment('ADMOB_BANNER_ID');
  static const _interstitialFromEnv = String.fromEnvironment('ADMOB_INTERSTITIAL_ID');
  static const _useTestAdsFromEnv = bool.fromEnvironment('ADMOB_USE_TEST_ADS');

  /// PUCKET Android — com.pucket.pucket_flutter (AdMob Console)
  static const _prodBannerAndroid = 'ca-app-pub-2558408055462441/2963997268';
  static const _prodInterstitialAndroid = 'ca-app-pub-2558408055462441/8581331624';

  static const _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';
  static const _testInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const _testInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';

  static bool get useTestAds => _useTestAdsFromEnv || kDebugMode;

  static String get bannerUnitId {
    if (_bannerFromEnv.isNotEmpty) return _bannerFromEnv;
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return useTestAds ? _testBannerAndroid : _prodBannerAndroid;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return useTestAds ? _testBannerIos : _testBannerIos;
    }
    return '';
  }

  static String get interstitialUnitId {
    if (_interstitialFromEnv.isNotEmpty) return _interstitialFromEnv;
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return useTestAds ? _testInterstitialAndroid : _prodInterstitialAndroid;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return useTestAds ? _testInterstitialIos : _testInterstitialIos;
    }
    return '';
  }

  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
}
