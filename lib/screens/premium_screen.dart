import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n_extension.dart';
import '../services/player_meta_service.dart';
import '../services/purchase_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/yesa_background.dart';
import '../widgets/yesa_effects.dart';
import 'app_router.dart';

/// Premium mağaza — vitrin, VIP paketi, karşılaştırma, reklam kaldırma,
/// jeton paketleri ve Battle Pass premium.
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
    final bpProduct = purchases.productFor(ProductIds.battlePassPremium);

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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    StaggerIn(index: 0, child: _PremiumHero(l10n: l10n)),
                    const SizedBox(height: 6),
                    StaggerIn(
                      index: 1,
                      child: _VipCard(
                        owned: metaSvc.vip,
                        price: vipProduct?.price,
                        onBuy: vipProduct == null ? null : () => purchases.buy(ProductIds.vip),
                      ),
                    ),
                    const SizedBox(height: 14),
                    StaggerIn(index: 2, child: _CompareTable(l10n: l10n)),
                    const SizedBox(height: 14),
                    StaggerIn(
                      index: 3,
                      child: _RemoveAdsCard(
                        owned: settings.adsRemoved,
                        price: removeAdsProduct?.price,
                        onBuy: removeAdsProduct == null
                            ? null
                            : () => purchases.buy(ProductIds.removeAds),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _SectionHeader(
                      icon: Icons.monetization_on_rounded,
                      label: l10n.tokenPacksTitle.toUpperCase(),
                    ),
                    const SizedBox(height: 12),
                    StaggerIn(
                      index: 4,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _TokenPack(
                              amount: 100,
                              coins: 1,
                              price: purchases.productFor(ProductIds.tokens100)?.price,
                              onBuy: () => purchases.buy(ProductIds.tokens100),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _TokenPack(
                              amount: 550,
                              coins: 2,
                              bonusBadge: l10n.bonus10,
                              price: purchases.productFor(ProductIds.tokens500)?.price,
                              onBuy: () => purchases.buy(ProductIds.tokens500),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _TokenPack(
                              amount: 1200,
                              coins: 3,
                              bonusBadge: l10n.bonus20,
                              highlight: l10n.bestValue,
                              price: purchases.productFor(ProductIds.tokens1200)?.price,
                              onBuy: () => purchases.buy(ProductIds.tokens1200),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: AppColors.textMuted, size: 13),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            l10n.tokenGuide,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _SectionHeader(
                      icon: Icons.military_tech_rounded,
                      label: l10n.battlePass.toUpperCase(),
                      color: AppColors.vurguMoru,
                    ),
                    const SizedBox(height: 12),
                    StaggerIn(
                      index: 5,
                      child: _BattlePassCard(
                        price: bpProduct?.price,
                        onBuy: bpProduct == null
                            ? null
                            : () => purchases.buy(ProductIds.battlePassPremium),
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
                      child: TextButton.icon(
                        onPressed: () => purchases.restore(),
                        icon: const Icon(Icons.restore_rounded, color: AppColors.sariAna, size: 16),
                        label: Text(
                          l10n.restorePurchases,
                          style: const TextStyle(
                            color: AppColors.sariAna,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    // Güven satırı — ödemeler mağaza üzerinden.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_rounded, color: AppColors.textMuted, size: 12),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            l10n.securePayments,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        l10n.premiumNotes,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10.5,
                          height: 1.5,
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

// ── Vitrin (hero) ──────────────────────────────────────────────────────

class _PremiumHero extends StatelessWidget {
  const _PremiumHero({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Arka plan altın ışıma.
          Container(
            width: 240,
            height: 140,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppColors.sariAna.withValues(alpha: 0.16),
                  AppColors.sariAna.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          // Parıldayan yıldızlar.
          const Positioned(left: 42, top: 22, child: Twinkle(size: 13, phase: 0.0)),
          const Positioned(right: 52, top: 14, child: Twinkle(size: 10, phase: 0.35)),
          const Positioned(right: 30, bottom: 38, child: Twinkle(size: 15, phase: 0.6)),
          const Positioned(left: 60, bottom: 26, child: Twinkle(size: 9, phase: 0.85)),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatY(
                amplitude: 5,
                child: Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      center: Alignment(-0.35, -0.42),
                      radius: 1.2,
                      colors: [Color(0xFFFFE9A0), Color(0xFFF6C444), Color(0xFF8A6410)],
                      stops: [0.0, 0.55, 1.0],
                    ),
                    border: Border.all(color: Colors.white30, width: 1.5),
                    boxShadow: AppShadows.neon(AppColors.sariAna, blur: 18),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded,
                      color: Color(0xFF3A2A05), size: 34),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.premiumHeroSub,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Bölüm başlığı ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label, this.color = AppColors.sariAna});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 7),
        Text(
          label,
          style: AppTextStyles.glow(color).copyWith(fontSize: 13, letterSpacing: 1.5),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1.2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.55), color.withValues(alpha: 0.0)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── VIP kartı ──────────────────────────────────────────────────────────

class _VipCard extends StatelessWidget {
  const _VipCard({required this.owned, required this.price, required this.onBuy});

  final bool owned;
  final String? price;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GlowPulse(
          color: AppColors.sariAna,
          min: 0.25,
          max: 0.55,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
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
                    // VIP taç pulu önizlemesi — oyundaki 3D pul görünümüyle aynı.
                    FloatY(amplitude: 3, child: const _CrownDiscPreview(size: 64)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.vipTitle,
                            style: AppTextStyles.glow(AppColors.sariAna)
                                .copyWith(fontSize: 18, letterSpacing: 1.5),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            l10n.vipSubtitle,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _perk(l10n.vipPerkNoAds, l10n.vipPerkNoAdsSub, Icons.block_rounded),
                _perk(l10n.vipPerkDisc, l10n.vipPerkDiscSub, Icons.workspace_premium_rounded),
                _perk(l10n.vipPerkTokens, l10n.vipPerkTokensSub, Icons.monetization_on_rounded),
                const SizedBox(height: 14),
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
        ),
        // "EN İYİ TEKLİF" kurdelesi — kartın üstüne biner.
        if (!owned)
          Positioned(
            top: -9,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD75E), Color(0xFFF0A818)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppShadows.neon(AppColors.sariAna, blur: 8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFF201505), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      l10n.bestOffer,
                      style: const TextStyle(
                        color: Color(0xFF201505),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _perk(String title, String sub, IconData icon) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.sariAna.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.sariAna, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.beyaz,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    sub,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

/// Oyundaki 3D pul stiliyle altın taç pulu önizlemesi.
class _CrownDiscPreview extends StatelessWidget {
  const _CrownDiscPreview({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    const base = Color(0xFFF6C444);
    final light = Color.lerp(base, Colors.white, 0.42)!;
    final dark = Color.lerp(base, Colors.black, 0.38)!;
    final rim = Color.lerp(base, Colors.black, 0.52)!;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.42),
          radius: 1.25,
          colors: [light, base, dark],
          stops: const [0.0, 0.55, 1.0],
        ),
        border: Border.all(color: Colors.white24, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: dark.withValues(alpha: 0.7),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.84,
            height: size * 0.84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: rim.withValues(alpha: 0.85), width: size * 0.06),
            ),
          ),
          Text('👑', style: TextStyle(fontSize: size * 0.42)),
          Align(
            alignment: const Alignment(-0.45, -0.5),
            child: Container(
              width: size * 0.38,
              height: size * 0.38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.45),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ücretsiz vs VIP karşılaştırma tablosu ──────────────────────────────

class _CompareTable extends StatelessWidget {
  const _CompareTable({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      decoration: BoxDecoration(
        color: AppColors.morDahaKoyu.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.beyaz.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  l10n.compareTitle,
                  style: const TextStyle(
                    color: AppColors.beyaz,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  l10n.compareFree,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  l10n.compareVip,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.sariAna,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 0.5,
                    shadows: [Shadow(color: AppColors.sariAna.withValues(alpha: 0.6), blurRadius: 6)],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _row(l10n.compareAds, l10n.compareAdsFree, l10n.compareAdsVip, goodVip: true, badFree: true),
          _row(l10n.compareWinTokens, 'x1', 'x1.5', goodVip: true),
          _row(l10n.compareFirstWin, '2x', '3x', goodVip: true),
          _row(l10n.compareCrown, '—', '✓', goodVip: true),
        ],
      ),
    );
  }

  Widget _row(String label, String free, String vip, {bool goodVip = false, bool badFree = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.beyaz, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              free,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: badFree ? AppColors.turuncuAna : AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              vip,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: goodVip ? AppColors.neonYesil : AppColors.beyaz,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reklamları Kaldır ──────────────────────────────────────────────────

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
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.turuncuAna.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.block_rounded, color: AppColors.turuncuAna, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  owned ? l10n.adsAlreadyRemoved : l10n.removeAds,
                  style: const TextStyle(
                    color: AppColors.beyaz,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.removeAdsSub,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
            const Icon(Icons.check_circle_rounded, color: AppColors.neonYesil, size: 22),
        ],
      ),
    );
  }
}

// ── Jeton paketi kartı ─────────────────────────────────────────────────

class _TokenPack extends StatelessWidget {
  const _TokenPack({
    required this.amount,
    required this.coins,
    required this.price,
    required this.onBuy,
    this.bonusBadge,
    this.highlight,
  });

  final int amount;
  final int coins; // görsel yığın boyutu (1-3)
  final String? price;
  final String? bonusBadge;
  final String? highlight;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final highlighted = highlight != null;
    return ScalePress(
      onTap: onBuy,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          gradient: highlighted
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF3A2E08), Color(0xFF251A05)],
                )
              : null,
          color: highlighted ? null : AppColors.morDahaKoyu.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlighted
                ? AppColors.sariAna.withValues(alpha: 0.85)
                : AppColors.beyaz.withValues(alpha: 0.12),
            width: highlighted ? 1.6 : 1,
          ),
          boxShadow: highlighted ? AppShadows.neon(AppColors.sariAna, blur: 8) : null,
        ),
        child: Column(
          children: [
            SizedBox(
              height: 16,
              child: highlight != null
                  ? _chip(highlight!, AppColors.sariAna, const Color(0xFF201505))
                  : (bonusBadge != null
                      ? _chip(bonusBadge!, AppColors.neonYesil.withValues(alpha: 0.2), AppColors.neonYesil)
                      : null),
            ),
            const SizedBox(height: 8),
            // Paket büyüdükçe büyüyen jeton yığını.
            SizedBox(
              height: 34,
              width: 14.0 * coins + 22,
              child: Stack(
                children: [
                  for (var i = 0; i < coins; i++)
                    Positioned(
                      left: 14.0 * i,
                      top: coins == 1 ? 3 : (i.isEven ? 6 : 0),
                      child: Icon(
                        Icons.monetization_on_rounded,
                        color: i == coins - 1
                            ? AppColors.sariAna
                            : AppColors.sariAna.withValues(alpha: 0.55),
                        size: 28,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$amount',
              style: const TextStyle(
                color: AppColors.beyaz,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
            if (bonusBadge != null)
              Text(
                bonusBadge!,
                style: const TextStyle(
                  color: AppColors.neonYesil,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: highlighted
                    ? AppColors.sariAna
                    : AppColors.beyaz.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                price ?? '—',
                style: TextStyle(
                  color: highlighted ? const Color(0xFF201505) : AppColors.beyaz,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Text(
          text,
          style: TextStyle(color: fg, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.4),
        ),
      );
}

// ── Battle Pass premium kartı ──────────────────────────────────────────

class _BattlePassCard extends StatelessWidget {
  const _BattlePassCard({required this.price, required this.onBuy});

  final String? price;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.vurguMoru.withValues(alpha: 0.25),
            AppColors.morDahaKoyu.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.vurguMoru.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.vurguMoru.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.military_tech_rounded, color: AppColors.vurguMoru, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.battlePass} — ${l10n.battlePassPremium}',
                  style: const TextStyle(
                    color: AppColors.beyaz,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.bpCardSub,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ScalePress(
            onTap: () => AppRouter.goBattlePass(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppGradients.neonPurple,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                price ?? l10n.openLabel,
                style: const TextStyle(
                  color: AppColors.beyaz,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
