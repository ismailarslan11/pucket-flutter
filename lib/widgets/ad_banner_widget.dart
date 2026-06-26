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
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadBanner();
  }

  void _loadBanner() {
    final ads = context.read<AdService>();
    if (!AdConfig.supported || !ads.initialized) return;

    final unitId = AdConfig.bannerUnitId;
    if (unitId.isEmpty || _banner != null) return;

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
        },
      ),
    );
    _banner = banner;
    banner.load();
  }

  @override
  void dispose() {
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
