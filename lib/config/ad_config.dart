import 'package:flutter/foundation.dart';

/// AdMob birim ID'leri.
///
/// Release build varsayılan: prod birimler.
/// Test reklam yalnızca debug veya --dart-define=ADMOB_USE_TEST_ADS=true ile.
class AdConfig {
  AdConfig._();

  static const _bannerFromEnv = String.fromEnvironment('ADMOB_BANNER_ID');
  static const _interstitialFromEnv = String.fromEnvironment('ADMOB_INTERSTITIAL_ID');
  static const _bannerIosFromEnv = String.fromEnvironment('ADMOB_IOS_BANNER_ID');
  static const _interstitialIosFromEnv = String.fromEnvironment('ADMOB_IOS_INTERSTITIAL_ID');
  static const _useTestAdsFromEnv = bool.fromEnvironment('ADMOB_USE_TEST_ADS');

  /// PUCKET Android — com.pucket.pucket_flutter (AdMob Console)
  static const _prodBannerAndroid = 'ca-app-pub-2558408055462441/2963997268';
  static const _prodInterstitialAndroid = 'ca-app-pub-2558408055462441/8581331624';

  /// PUCKET iOS — com.pucket.pucketFlutter (AdMob Console)
  static const _prodBannerIos = 'ca-app-pub-2558408055462441/8708525371';
  static const _prodInterstitialIos = 'ca-app-pub-2558408055462441/9043567292';

  static const _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';
  static const _testInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const _testInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';
  static const _testRewardedAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const _testRewardedIos = 'ca-app-pub-3940256099942544/1712485313';

  static bool get useTestAds => _useTestAdsFromEnv || kDebugMode;

  static String get bannerUnitId {
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      if (_bannerFromEnv.isNotEmpty) return _bannerFromEnv;
      return useTestAds ? _testBannerAndroid : _prodBannerAndroid;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (_bannerIosFromEnv.isNotEmpty) return _bannerIosFromEnv;
      if (useTestAds) return _testBannerIos;
      if (_prodBannerIos.isNotEmpty) return _prodBannerIos;
      return '';
    }
    return '';
  }

  static String get interstitialUnitId {
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      if (_interstitialFromEnv.isNotEmpty) return _interstitialFromEnv;
      return useTestAds ? _testInterstitialAndroid : _prodInterstitialAndroid;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (_interstitialIosFromEnv.isNotEmpty) return _interstitialIosFromEnv;
      if (useTestAds) return _testInterstitialIos;
      if (_prodInterstitialIos.isNotEmpty) return _prodInterstitialIos;
      return '';
    }
    return '';
  }

  static String get rewardedUnitId {
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return useTestAds ? _testRewardedAndroid : _prodInterstitialAndroid;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return useTestAds ? _testRewardedIos : _prodInterstitialIos;
    }
    return '';
  }

  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
}
