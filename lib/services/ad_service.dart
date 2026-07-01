import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ad_config.dart';
import 'consent_service.dart';

enum RewardedAdOutcome {
  notReady,
  dismissedEarly,
  earned,
  showFailed,
}

class AdService extends ChangeNotifier {
  AdService();

  bool initialized = false;
  bool canLoadAds = false;
  String statusMessage = 'Başlatılıyor…';
  String lastBannerError = '';
  String lastRewardedError = '';
  String consentDebug = '';

  InterstitialAd? _interstitial;
  bool _loadingInterstitial = false;
  RewardedAd? _rewarded;
  bool _loadingRewarded = false;
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
      preloadRewarded();
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

  void preloadRewarded() {
    if (!AdConfig.supported || !initialized || !canLoadAds) return;
    if (_loadingRewarded || _rewarded != null) return;
    final unitId = AdConfig.rewardedUnitId;
    if (unitId.isEmpty) return;

    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _loadingRewarded = false;
          debugPrint('Rewarded ad loaded: ${AdConfig.rewardedUnitId}');
        },
        onAdFailedToLoad: (error) {
          lastRewardedError = error.message;
          debugPrint('Rewarded load failed: ${error.message} (${AdConfig.rewardedUnitId})');
          _loadingRewarded = false;
          Future.delayed(const Duration(seconds: 30), preloadRewarded);
        },
      ),
    );
  }

  Future<bool> ensureRewardedReady({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (!AdConfig.supported || !initialized) return false;
    if (!canLoadAds) {
      await refreshAfterConsent();
      if (!canLoadAds) return false;
    }
    if (_rewarded != null) return true;

    preloadRewarded();
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (_rewarded != null) return true;
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!_loadingRewarded && _rewarded == null) {
        preloadRewarded();
      }
    }
    return _rewarded != null;
  }

  /// Ödüllü reklam sonucu. [earned] = kullanıcı ödülü hak etti.
  Future<RewardedAdOutcome> showRewardedForTokens() async {
    if (!AdConfig.supported || !initialized || !canLoadAds) {
      return RewardedAdOutcome.notReady;
    }

    final ready = await ensureRewardedReady();
    if (!ready) {
      lastRewardedError = lastRewardedError.isNotEmpty ? lastRewardedError : 'Reklam yüklenemedi';
      return RewardedAdOutcome.notReady;
    }

    final ad = _rewarded!;
    _rewarded = null;

    final completer = Completer<RewardedAdOutcome>();
    var earned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preloadRewarded();
        // Android'de callback bazen dismiss'ten sonra gelir — kısa bekle.
        Future<void>.delayed(const Duration(milliseconds: 600), () {
          if (completer.isCompleted) return;
          completer.complete(earned ? RewardedAdOutcome.earned : RewardedAdOutcome.dismissedEarly);
        });
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        lastRewardedError = error.message;
        ad.dispose();
        preloadRewarded();
        if (!completer.isCompleted) {
          completer.complete(RewardedAdOutcome.showFailed);
        }
      },
    );

    try {
      ad.show(
        onUserEarnedReward: (ad, reward) {
          earned = true;
          debugPrint('Reward earned: ${reward.amount} ${reward.type}');
        },
      );
    } catch (e) {
      lastRewardedError = '$e';
      ad.dispose();
      preloadRewarded();
      return RewardedAdOutcome.showFailed;
    }

    return completer.future.timeout(
      const Duration(minutes: 3),
      onTimeout: () => earned ? RewardedAdOutcome.earned : RewardedAdOutcome.dismissedEarly,
    );
  }

  bool get rewardedReady => _rewarded != null;

  @override
  void dispose() {
    _interstitial?.dispose();
    _rewarded?.dispose();
    super.dispose();
  }
}
