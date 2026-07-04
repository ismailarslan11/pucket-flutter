import 'package:flutter/foundation.dart';

import 'ad_config.generated.dart';

/// AdMob birim ID'leri.
///
/// Release build varsayılan: `tool/setup_admob.sh` ile doldurulan prod birimler.
/// Test reklam yalnızca debug veya `--dart-define=ADMOB_USE_TEST_ADS=true` ile.
class AdConfig {
  AdConfig._();

  static const _bannerFromEnv = String.fromEnvironment('ADMOB_BANNER_ID');
  static const _interstitialFromEnv = String.fromEnvironment('ADMOB_INTERSTITIAL_ID');
  static const _rewardedFromEnv = String.fromEnvironment('ADMOB_REWARDED_ID');
  static const _bannerIosFromEnv = String.fromEnvironment('ADMOB_IOS_BANNER_ID');
  static const _interstitialIosFromEnv = String.fromEnvironment('ADMOB_IOS_INTERSTITIAL_ID');
  static const _rewardedIosFromEnv = String.fromEnvironment('ADMOB_IOS_REWARDED_ID');
  static const _useTestAdsFromEnv = bool.fromEnvironment('ADMOB_USE_TEST_ADS');

  static const _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';
  static const _testInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const _testInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';
  // Test: klasik ödüllü (emülatörde daha güvenilir). Prod: ödüllü geçiş birimi.
  static const _testRewardedInterstitialAndroid = 'ca-app-pub-3940256099942544/5354046379';
  static const _testRewardedInterstitialIos = 'ca-app-pub-3940256099942544/6978759866';
  static const _testRewardedClassicAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const _testRewardedClassicIos = 'ca-app-pub-3940256099942544/1712485313';

  static bool get useTestAds => _useTestAdsFromEnv || kDebugMode;

  /// Test build'de RewardedAd; prod'da RewardedInterstitialAd (AdMob birim türüne uygun).
  static bool get useClassicRewardedAd => useTestAds;

  static String get bannerUnitId {
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      if (_bannerFromEnv.isNotEmpty) return _bannerFromEnv;
      if (useTestAds) return _testBannerAndroid;
      return AdConfigGenerated.androidBanner;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (_bannerIosFromEnv.isNotEmpty) return _bannerIosFromEnv;
      if (useTestAds) return _testBannerIos;
      return AdConfigGenerated.iosBanner;
    }
    return '';
  }

  static String get interstitialUnitId {
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      if (_interstitialFromEnv.isNotEmpty) return _interstitialFromEnv;
      if (useTestAds) return _testInterstitialAndroid;
      return AdConfigGenerated.androidInterstitial;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (_interstitialIosFromEnv.isNotEmpty) return _interstitialIosFromEnv;
      if (useTestAds) return _testInterstitialIos;
      return AdConfigGenerated.iosInterstitial;
    }
    return '';
  }

  /// Ödüllü geçiş birimi (prod) veya klasik ödüllü test birimi.
  static String get rewardedUnitId {
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      if (_rewardedFromEnv.isNotEmpty) return _rewardedFromEnv;
      if (useTestAds) {
        return useClassicRewardedAd
            ? _testRewardedClassicAndroid
            : _testRewardedInterstitialAndroid;
      }
      return AdConfigGenerated.androidRewarded;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (_rewardedIosFromEnv.isNotEmpty) return _rewardedIosFromEnv;
      if (useTestAds) {
        return useClassicRewardedAd
            ? _testRewardedClassicIos
            : _testRewardedInterstitialIos;
      }
      return AdConfigGenerated.iosRewarded;
    }
    return '';
  }

  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
}
