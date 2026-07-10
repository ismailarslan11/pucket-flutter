import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../services/player_meta_service.dart';
import '../services/purchase_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/yesa_background.dart';
import '../widgets/yesa_effects.dart';

/// Premium mağaza — VIP paketi, reklam kaldırma ve jeton paketleri.
class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final purchases = context.watch<PurchaseService>();
    final settings = context.watch<SettingsService>();
    final metaSvc = context.watch<PlayerMetaService>();

    final vipProduct = purchases.productFor(ProductIds.vip);
    final removeAdsProduct = purchases.productFor(ProductIds.removeAds);

    return Scaffold(
      body: YesaBackground(
        warm: true,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 16, 4),
                child: Row(
                  children: [
                    ScalePress(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppGradients.neonPurple,
                          border: Border.all(color: AppColors.beyaz.withValues(alpha: 0.3)),
                          boxShadow: AppShadows.depth(AppColors.morDahaKoyu),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: AppColors.beyaz, size: 20),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        l10n.menuPremium.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.glow(AppColors.sariAna).copyWith(fontSize: 18, letterSpacing: 2),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    StaggerIn(
                      index: 0,
                      child: _VipCard(
                        owned: metaSvc.vip,
                        price: vipProduct?.price,
                        onBuy: vipProduct == null ? null : () => purchases.buy(ProductIds.vip),
                      ),
                    ),
                    const SizedBox(height: 14),
                    StaggerIn(
                      index: 1,
                      child: _RemoveAdsCard(
                        owned: settings.adsRemoved,
                        price: removeAdsProduct?.price,
                        onBuy: removeAdsProduct == null
                            ? null
                            : () => purchases.buy(ProductIds.removeAds),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      l10n.tokenPacksTitle.toUpperCase(),
                      style: AppTextStyles.glow(AppColors.sariAna)
                          .copyWith(fontSize: 13, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 10),
                    StaggerIn(
                      index: 2,
                      child: Row(
                        children: [
                          Expanded(
                            child: _TokenPack(
                              amount: 100,
                              price: purchases.productFor(ProductIds.tokens100)?.price,
                              onBuy: () => purchases.buy(ProductIds.tokens100),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _TokenPack(
                              amount: 550,
                              price: purchases.productFor(ProductIds.tokens500)?.price,
                              onBuy: () => purchases.buy(ProductIds.tokens500),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _TokenPack(
                              amount: 1200,
                              badge: l10n.bestValue,
                              price: purchases.productFor(ProductIds.tokens1200)?.price,
                              onBuy: () => purchases.buy(ProductIds.tokens1200),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (!purchases.available)
                      Text(
                        l10n.iapUnavailable,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      )
                    else if (purchases.products.isEmpty)
                      Text(
                        l10n.premiumPending,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    Center(
                      child: TextButton(
                        onPressed: () => purchases.restore(),
                        child: Text(
                          l10n.restorePurchases,
                          style: const TextStyle(
                            color: AppColors.sariAna,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VipCard extends StatelessWidget {
  const _VipCard({required this.owned, required this.price, required this.onBuy});

  final bool owned;
  final String? price;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GlowPulse(
      color: AppColors.sariAna,
      min: 0.25,
      max: 0.55,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3A2E08), Color(0xFF201505)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.sariAna.withValues(alpha: 0.7), width: 1.6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      center: Alignment(-0.35, -0.42),
                      radius: 1.2,
                      colors: [Color(0xFFFFE9A0), Color(0xFFF6C444), Color(0xFF8A6410)],
                      stops: [0.0, 0.55, 1.0],
                    ),
                    border: Border.all(color: Colors.white24, width: 1.5),
                  ),
                  child: const Text('👑', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.vipTitle,
                        style: AppTextStyles.glow(AppColors.sariAna)
                            .copyWith(fontSize: 17, letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.vipSubtitle,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _perk(l10n.vipPerkNoAds),
            _perk(l10n.vipPerkDisc),
            _perk(l10n.vipPerkTokens),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: owned
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.sariAna.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.sariAna),
                      ),
                      child: Text(
                        l10n.vipActive,
                        style: const TextStyle(
                          color: AppColors.sariAna,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    )
                  : ScalePress(
                      onTap: onBuy ?? () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD75E), Color(0xFFF0A818)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppShadows.neon(AppColors.sariAna, blur: 10),
                        ),
                        child: Text(
                          price == null ? l10n.buyVip : '${l10n.buyVip} — $price',
                          style: const TextStyle(
                            color: Color(0xFF201505),
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _perk(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.sariAna, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.beyaz,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}

class _RemoveAdsCard extends StatelessWidget {
  const _RemoveAdsCard({required this.owned, required this.price, required this.onBuy});

  final bool owned;
  final String? price;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.morDahaKoyu.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.beyaz.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.block_rounded, color: AppColors.turuncuAna, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              owned ? l10n.adsAlreadyRemoved : l10n.removeAds,
              style: const TextStyle(
                color: AppColors.beyaz,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          if (!owned)
            ScalePress(
              onTap: onBuy ?? () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: AppGradients.heroPlay,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  price ?? '—',
                  style: const TextStyle(
                    color: AppColors.morDahaKoyu,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else
            const Icon(Icons.check_circle_rounded, color: AppColors.neonYesil, size: 20),
        ],
      ),
    );
  }
}

class _TokenPack extends StatelessWidget {
  const _TokenPack({
    required this.amount,
    required this.price,
    required this.onBuy,
    this.badge,
  });

  final int amount;
  final String? price;
  final String? badge;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return ScalePress(
      onTap: onBuy,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.morDahaKoyu.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: badge != null
                ? AppColors.sariAna.withValues(alpha: 0.8)
                : AppColors.beyaz.withValues(alpha: 0.12),
            width: badge != null ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.sariAna,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Color(0xFF201505),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ] else
              const SizedBox(height: 20),
            const Icon(Icons.monetization_on_rounded, color: AppColors.sariAna, size: 26),
            const SizedBox(height: 4),
            Text(
              '$amount',
              style: const TextStyle(
                color: AppColors.beyaz,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price ?? '—',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
