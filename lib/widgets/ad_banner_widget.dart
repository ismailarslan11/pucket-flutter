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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ads ??= context.read<AdService>();
    _ads!.addListener(_onAdsChanged);
    _maybeLoad();
  }

  void _onAdsChanged() {
    if (!mounted) return;
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
    final width = MediaQuery.sizeOf(context).width.truncate();
    final adaptive = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    final size = adaptive ?? AdSize.banner;

    final banner = BannerAd(
      adUnitId: unitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() {
            _loaded = true;
            _loading = false;
            _failCount = 0;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner load failed: ${error.message}');
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _banner = null;
            _loaded = false;
            _loading = false;
            _failCount++;
          });
          _scheduleRetry();
        },
      ),
    );

    _banner?.dispose();
    _banner = banner;
    banner.load();
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    if (_failCount >= 6) return;
    final delay = Duration(seconds: 5 * _failCount.clamp(1, 6));
    _retryTimer = Timer(delay, () {
      if (mounted) _maybeLoad();
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _ads?.removeListener(_onAdsChanged);
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdConfig.supported) {
      return const SizedBox.shrink();
    }

    if (!_loaded || _banner == null) {
      // Yer tutucu — layout zıplamasın, reklam yüklenince görünsün
      return const SizedBox(
        width: double.infinity,
        height: 50,
      );
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
