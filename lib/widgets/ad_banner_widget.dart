import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../config/ad_config.dart';
import '../services/ad_service.dart';

class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _banner;
  AdService? _ads;
  bool _loaded = false;
  bool _loading = false;
  int _failCount = 0;
  Timer? _retryTimer;
  bool _kicked = false;

  @override
  void initState() {
    super.initState();
    AdBannerController.registerReload(reload);
    WidgetsBinding.instance.addPostFrameCallback((_) => _kickOnce());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ads ??= context.read<AdService>();
    _ads!.addListener(_onAdsChanged);
  }

  void _kickOnce() {
    if (_kicked || !mounted) return;
    _kicked = true;
    context.read<AdService>().refreshAfterConsent();
  }

  void _onAdsChanged() {
    if (!mounted || _loaded || _loading) return;
    _maybeLoad();
  }

  Future<void> _maybeLoad() async {
    if (_loading || _loaded) return;
    final ads = _ads;
    if (ads == null || !AdConfig.supported) return;
    if (!ads.initialized || !ads.canLoadAds) return;

    final unitId = AdConfig.bannerUnitId;
    if (unitId.isEmpty) return;

    _loading = true;
    AdSize size = AdSize.banner;
    try {
      final width = MediaQuery.sizeOf(context).width.truncate();
      if (width > 0) {
        final adaptive = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
        size = adaptive ?? AdSize.banner;
      }
    } catch (_) {
      size = AdSize.banner;
    }

    final banner = BannerAd(
      adUnitId: unitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          ads.reportBannerLoaded();
          setState(() {
            _loaded = true;
            _loading = false;
            _failCount = 0;
          });
        },
        onAdFailedToLoad: (ad, error) {
          final msg = _friendlyError(error);
          debugPrint('Banner load failed: ${error.code}: ${error.message}');
          ad.dispose();
          if (!mounted) return;
          ads.reportBannerError(msg);
          setState(() {
            _banner = null;
            _loaded = false;
            _loading = false;
            _failCount++;
          });
          _scheduleRetry(error.code);
        },
      ),
    );

    _banner?.dispose();
    _banner = banner;
    banner.load();
  }

  String _friendlyError(LoadAdError error) {
    switch (error.code) {
      case 0:
        return 'Dahili hata — biraz sonra tekrar dene';
      case 1:
        return 'Çok sık istek — 2 dk bekle veya uygulamayı yeniden aç';
      case 2:
        return 'Ağ hatası — internet bağlantını kontrol et';
      case 3:
        return 'Reklam yok (No fill) — AdMob henüz doldurmuyor, normal';
      default:
        return '${error.code}: ${error.message}';
    }
  }

  void _scheduleRetry(int code) {
    _retryTimer?.cancel();
    if (_failCount >= 5) return;

    // Google rate-limit (kod 1): en az 90 sn bekle
    final seconds = switch (code) {
      1 => 90,
      3 => 45,
      2 => 20,
      _ => 30,
    };
    _retryTimer = Timer(Duration(seconds: seconds), () {
      if (mounted) _maybeLoad();
    });
  }

  /// Ayarlar → "Reklamı yenile" için dışarıdan çağrılır.
  void reload() {
    _retryTimer?.cancel();
    _banner?.dispose();
    _banner = null;
    _loaded = false;
    _loading = false;
    _failCount = 0;
    _maybeLoad();
  }

  @override
  void dispose() {
    AdBannerController.unregisterReload(reload);
    _retryTimer?.cancel();
    _ads?.removeListener(_onAdsChanged);
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdConfig.supported) return const SizedBox.shrink();

    if (!_loaded || _banner == null) {
      return const SizedBox(width: double.infinity, height: 50);
    }

    return Container(
      width: double.infinity,
      height: _banner!.size.height.toDouble(),
      alignment: Alignment.center,
      color: const Color(0xFF111111),
      child: AdWidget(ad: _banner!),
    );
  }
}

/// Menü banner'ını Ayarlar'dan yenilemek için.
class AdBannerController {
  static void Function()? _reload;

  static void registerReload(void Function() reload) => _reload = reload;

  static void unregisterReload(void Function() reload) {
    if (_reload == reload) _reload = null;
  }

  static void reload() => _reload?.call();
}
