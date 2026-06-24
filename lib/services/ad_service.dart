import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ad_config.dart';
import 'settings_service.dart';

class AdService extends ChangeNotifier {
  AdService(this.settings);

  final SettingsService settings;

  bool initialized = false;
  InterstitialAd? _interstitial;
  bool _loadingInterstitial = false;
  int _roundsSinceInterstitial = 0;

  Future<void> init() async {
    if (!AdConfig.supported || initialized) return;
    try {
      await MobileAds.instance.initialize();
      initialized = true;
      preloadInterstitial();
    } catch (e) {
      debugPrint('AdMob init failed: $e');
    }
  }

  void preloadInterstitial() {
    if (!AdConfig.supported || !settings.adsOn) return;
    if (_loadingInterstitial || _interstitial != null) return;
    final unitId = AdConfig.interstitialUnitId;
    if (unitId.isEmpty) return;

    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _loadingInterstitial = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitial = null;
              preloadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _interstitial = null;
              preloadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (_) {
          _loadingInterstitial = false;
          Future.delayed(const Duration(seconds: 30), preloadInterstitial);
        },
      ),
    );
  }

  /// Maç bitince veya her 2 round sonrası tam ekran reklam.
  Future<void> maybeShowInterstitial({required bool matchFinished}) async {
    if (!AdConfig.supported || !settings.adsOn || !initialized) return;

    _roundsSinceInterstitial++;
    final shouldShow = matchFinished || _roundsSinceInterstitial >= 2;
    if (!shouldShow) return;

    final ad = _interstitial;
    if (ad == null) {
      preloadInterstitial();
      return;
    }

    _roundsSinceInterstitial = 0;
    _interstitial = null;
    await ad.show();
    preloadInterstitial();
  }

  Future<void> showInterstitialOnMenuReturn() async {
    if (!AdConfig.supported || !settings.adsOn || !initialized) return;
    final ad = _interstitial;
    if (ad == null) {
      preloadInterstitial();
      return;
    }
    _interstitial = null;
    await ad.show();
    preloadInterstitial();
  }

  void onAdsSettingChanged() {
    if (!settings.adsOn) {
      _interstitial?.dispose();
      _interstitial = null;
    } else {
      preloadInterstitial();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _interstitial?.dispose();
    super.dispose();
  }
}
