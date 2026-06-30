import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ad_config.dart';
import 'consent_service.dart';

class AdService extends ChangeNotifier {
  AdService();

  bool initialized = false;
  InterstitialAd? _interstitial;
  bool _loadingInterstitial = false;

  /// İki tam ekran reklam arası minimum süre.
  static const _minInterval = Duration(minutes: 3);

  /// Kaç tamamlanan maçta bir reklam gösterilsin.
  static const _matchesPerAd = 2;

  DateTime? _lastShownAt;
  int _matchesSinceAd = 0;

  Future<void> init() async {
    if (!AdConfig.supported || initialized) return;
    try {
      if (!await ConsentService.canRequestAds()) {
        debugPrint('AdMob: rıza bekleniyor veya reklam isteği kapalı');
        return;
      }
      await MobileAds.instance.initialize();
      initialized = true;
      notifyListeners();
      preloadInterstitial();
    } catch (e) {
      debugPrint('AdMob init failed: $e');
    }
  }

  void preloadInterstitial() {
    if (!AdConfig.supported || !initialized) return;
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

  bool _canShowNow() {
    if (_lastShownAt == null) return true;
    return DateTime.now().difference(_lastShownAt!) >= _minInterval;
  }

  /// Yalnızca maç bittiğinde; antrenman modunda ve sık aralıklarla değil.
  Future<void> maybeShowInterstitial({
    required bool matchFinished,
    bool skip = false,
  }) async {
    if (skip || !matchFinished) return;
    if (!AdConfig.supported || !initialized) return;

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

  /// Menüye dönüşte reklam gösterme — çok sık rahatsız ediyordu.
  Future<void> showInterstitialOnMenuReturn() async {}

  @override
  void dispose() {
    _interstitial?.dispose();
    super.dispose();
  }
}
