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
  /// IAP ile reklamlar kaldırıldıysa banner/interstitial gösterilmez.
  /// (Ödüllü reklam jeton kazanmak için isteğe bağlı kalır.)
  bool adsRemoved = false;
  String statusMessage = 'Başlatılıyor…';
  String lastBannerError = '';
  String lastRewardedError = '';
  String consentDebug = '';

  InterstitialAd? _interstitial;
  bool _loadingInterstitial = false;
  RewardedInterstitialAd? _rewardedInterstitial;
  RewardedAd? _rewardedClassic;
  bool _loadingRewarded = false;
  int _rewardedFailCount = 0;
  DateTime? _rewardedRetryAfter;
  int _initRetries = 0;

  static const _minInterval = Duration(minutes: 3);
  static const _matchesPerAd = 2;

  DateTime? _lastShownAt;
  int _matchesSinceAd = 0;

  bool get _rewardedLoaded =>
      AdConfig.useClassicRewardedAd ? _rewardedClassic != null : _rewardedInterstitial != null;

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
    if (!ConsentService.updateFinished) {
      await ConsentService.ensureConsent();
    }
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
    if (adsRemoved) return;
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

  String _friendlyRewardedError(LoadAdError error) {
    switch (error.code) {
      case 0:
        return 'Dahili hata — biraz sonra tekrar dene';
      case 1:
        return 'Çok sık deneme — 1-2 dakika bekle';
      case 2:
        return 'Ağ hatası — internet bağlantını kontrol et';
      case 3:
        if (AdConfig.useTestAds) {
          return 'Test reklam yüklenemedi — uygulamayı kapatıp tekrar aç';
        }
        return 'AdMob henüz reklam göndermiyor — yeni hesapta 24-48 saat sürebilir';
      default:
        return error.message;
    }
  }

  int _rewardedRetrySeconds(int code) {
    return switch (code) {
      1 => 90 + (_rewardedFailCount.clamp(0, 4) * 30),
      3 => AdConfig.useTestAds ? 15 : 120,
      2 => 25,
      _ => 35,
    };
  }

  void _onRewardedLoaded() {
    _loadingRewarded = false;
    _rewardedFailCount = 0;
    _rewardedRetryAfter = null;
    lastRewardedError = '';
    debugPrint('Rewarded loaded: ${AdConfig.rewardedUnitId}');
    notifyListeners();
  }

  void _onRewardedFailed(LoadAdError error) {
    _rewardedFailCount++;
    final waitSec = _rewardedRetrySeconds(error.code);
    _rewardedRetryAfter = DateTime.now().add(Duration(seconds: waitSec));
    lastRewardedError = '${_friendlyRewardedError(error)} (kod ${error.code})';
    debugPrint(
      'Rewarded load failed: ${error.message} '
      'code=${error.code} unit=${AdConfig.rewardedUnitId} retryIn=${waitSec}s',
    );
    _loadingRewarded = false;
    notifyListeners();
    Future.delayed(Duration(seconds: waitSec), () => preloadRewarded());
  }

  void preloadRewarded({bool force = false}) {
    if (!AdConfig.supported || !initialized || !canLoadAds) return;
    if (_loadingRewarded || _rewardedLoaded) return;
    if (!force &&
        _rewardedRetryAfter != null &&
        DateTime.now().isBefore(_rewardedRetryAfter!)) {
      return;
    }
    final unitId = AdConfig.rewardedUnitId;
    if (unitId.isEmpty) return;

    _loadingRewarded = true;
    if (AdConfig.useClassicRewardedAd) {
      RewardedAd.load(
        adUnitId: unitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedClassic = ad;
            _onRewardedLoaded();
          },
          onAdFailedToLoad: _onRewardedFailed,
        ),
      );
      return;
    }

    RewardedInterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitial = ad;
          _onRewardedLoaded();
        },
        onAdFailedToLoad: _onRewardedFailed,
      ),
    );
  }

  Future<bool> ensureRewardedReady({
    Duration timeout = const Duration(seconds: 25),
  }) async {
    if (!AdConfig.supported || !initialized) return false;
    if (!canLoadAds) {
      await refreshAfterConsent();
      if (!canLoadAds) return false;
    }
    if (_rewardedLoaded) return true;

    preloadRewarded();
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (_rewardedLoaded) return true;
      final inBackoff = _rewardedRetryAfter != null &&
          DateTime.now().isBefore(_rewardedRetryAfter!);
      if (!inBackoff && !_loadingRewarded && !_rewardedLoaded) {
        preloadRewarded();
      }
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
    return _rewardedLoaded;
  }

  Future<RewardedAdOutcome> showRewardedForTokens() async {
    if (!AdConfig.supported || !initialized || !canLoadAds) {
      return RewardedAdOutcome.notReady;
    }

    final ready = await ensureRewardedReady();
    if (!ready) {
      final err = lastRewardedError;
      lastRewardedError = err.isNotEmpty
          ? err
          : 'Reklam henüz dolmadı — yeni AdMob hesabında 24-48 saat sürebilir';
      return RewardedAdOutcome.notReady;
    }

    if (AdConfig.useClassicRewardedAd) {
      final ad = _rewardedClassic!;
      _rewardedClassic = null;
      return _showClassicRewarded(ad);
    }

    final interstitial = _rewardedInterstitial!;
    _rewardedInterstitial = null;
    return _showInterstitialRewarded(interstitial);
  }

  Future<RewardedAdOutcome> _showClassicRewarded(RewardedAd ad) async {
    final completer = Completer<RewardedAdOutcome>();
    var earned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preloadRewarded();
        if (completer.isCompleted) return;
        Future<void>.delayed(const Duration(milliseconds: 800), () {
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
          if (!completer.isCompleted) {
            completer.complete(RewardedAdOutcome.earned);
          }
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

  Future<RewardedAdOutcome> _showInterstitialRewarded(RewardedInterstitialAd ad) async {
    final completer = Completer<RewardedAdOutcome>();
    var earned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preloadRewarded();
        if (completer.isCompleted) return;
        Future<void>.delayed(const Duration(milliseconds: 800), () {
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
          if (!completer.isCompleted) {
            completer.complete(RewardedAdOutcome.earned);
          }
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

  bool get rewardedReady => _rewardedLoaded;

  @override
  void dispose() {
    _interstitial?.dispose();
    _rewardedInterstitial?.dispose();
    _rewardedClassic?.dispose();
    super.dispose();
  }
}
