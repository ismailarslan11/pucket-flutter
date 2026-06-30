import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ad_config.dart';
import 'consent_service.dart';

class AdService extends ChangeNotifier {
  AdService();

  bool initialized = false;
  bool canLoadAds = false;
  String statusMessage = 'Başlatılıyor…';
  String lastBannerError = '';
  String consentDebug = '';

  InterstitialAd? _interstitial;
  bool _loadingInterstitial = false;
  int _initRetries = 0;

  static const _minInterval = Duration(minutes: 3);
  static const _matchesPerAd = 2;

  DateTime? _lastShownAt;
  int _matchesSinceAd = 0;

  Future<void> init() async {
    if (!AdConfig.supported || initialized) return;
    try {
      await MobileAds.instance.initialize();
      initialized = true;
      notifyListeners();
      await _refreshLoadPermission();
    } catch (e) {
      statusMessage = 'AdMob başlatılamadı: $e';
      debugPrint('AdMob init failed: $e');
      _scheduleRetry();
    }
  }

  Future<void> _refreshLoadPermission() async {
    if (!initialized) return;

    consentDebug = await ConsentService.debugSummary();
    canLoadAds = await ConsentService.shouldRequestAds();

    if (canLoadAds) {
      final mode = AdConfig.useTestAds ? ' (test reklam)' : '';
      statusMessage = 'Reklamlar aktif$mode · ${AdConfig.bannerUnitId.split('/').last}';
      _initRetries = 0;
      preloadInterstitial();
    } else {
      statusMessage = 'Rıza gerekli — Ayarlar → Reklam gizlilik tercihleri';
      _scheduleRetry();
    }
    notifyListeners();
  }

  void reportBannerError(String message) {
    lastBannerError = message;
    statusMessage = 'Banner yüklenemedi: $message';
    notifyListeners();
  }

  void reportBannerLoaded() {
    lastBannerError = '';
    final mode = AdConfig.useTestAds ? ' (test)' : '';
    statusMessage = 'Banner görünüyor$mode';
    notifyListeners();
  }

  void _scheduleRetry() {
    if (_initRetries >= 3 || !AdConfig.supported) return;
    _initRetries++;
    final delay = Duration(seconds: 15 * _initRetries);
    Future.delayed(delay, () async {
      if (!initialized) {
        await init();
        return;
      }
      await _refreshLoadPermission();
    });
  }

  Future<void> refreshAfterConsent() async {
    if (!AdConfig.supported) return;
    if (!initialized) {
      await init();
      return;
    }
    _initRetries = 0;
    await _refreshLoadPermission();
  }

  void preloadInterstitial() {
    if (!AdConfig.supported || !initialized || !canLoadAds) return;
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
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial load failed: ${error.message}');
          _loadingInterstitial = false;
          Future.delayed(const Duration(seconds: 30), preloadInterstitial);
        },
      ),
    );
  }

  bool _canShowNow() {
    if (_lastShownAt == null) return true;
    return DateTime.now().difference(_lastShownAt!) >= _minInterval;
  }

  Future<void> maybeShowInterstitial({
    required bool matchFinished,
    bool skip = false,
  }) async {
    if (skip || !matchFinished) return;
    if (!AdConfig.supported || !initialized || !canLoadAds) return;

    _matchesSinceAd++;
    if (_matchesSinceAd < _matchesPerAd) return;
    if (!_canShowNow()) return;

    final ad = _interstitial;
    if (ad == null) {
      preloadInterstitial();
      return;
    }

    _matchesSinceAd = 0;
    _lastShownAt = DateTime.now();
    _interstitial = null;
    await ad.show();
    preloadInterstitial();
  }

  Future<void> showInterstitialOnMenuReturn() async {}

  @override
  void dispose() {
    _interstitial?.dispose();
    super.dispose();
  }
}
