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
  bool _tried = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ads ??= context.read<AdService>();
    _loadBanner();
  }

  void _loadBanner() {
    if (_tried) return;
    final ads = _ads;
    if (ads == null || !AdConfig.supported) return;

    if (!ads.initialized) {
      ads.addListener(_onAdsChanged);
      return;
    }

    _tryLoad(ads);
  }

  void _onAdsChanged() {
    if (!mounted) return;
    final ads = context.read<AdService>();
    if (ads.initialized) {
      ads.removeListener(_onAdsChanged);
      _tryLoad(ads);
    }
  }

  void _tryLoad(AdService ads) {
    if (_tried) return;
    final unitId = AdConfig.bannerUnitId;
    if (unitId.isEmpty) return;
    _tried = true;

    final banner = BannerAd(
      adUnitId: unitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          _banner = null;
          _tried = false;
        },
      ),
    );
    _banner = banner;
    banner.load();
  }

  @override
  void dispose() {
    _ads?.removeListener(_onAdsChanged);
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdConfig.supported || !_loaded || _banner == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: _banner!.size.width.toDouble(),
      height: _banner!.size.height.toDouble(),
      alignment: Alignment.center,
      color: const Color(0xFF111111),
      child: AdWidget(ad: _banner!),
    );
  }
}
