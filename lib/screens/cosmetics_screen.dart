import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../config/ad_config.dart';
import '../l10n/l10n_extension.dart';
import '../models/cosmetic_catalog.dart';
import '../services/ad_service.dart';
import '../services/auth_service.dart';
import '../services/player_meta_service.dart';
import '../theme/cosmetics_theme.dart';
import '../theme/app_theme.dart';
import '../widgets/pucket_button.dart';
import '../widgets/yesa_background.dart';
import '../widgets/yesa_menu_tile.dart';
import '../widgets/yesa_effects.dart';
import 'app_router.dart';

class CosmeticsScreen extends StatefulWidget {
  const CosmeticsScreen({super.key});

  @override
  State<CosmeticsScreen> createState() => _CosmeticsScreenState();
}

class _CosmeticsScreenState extends State<CosmeticsScreen> {
  String _disc = 'green';
  String _board = 'classic';
  String _winFx = 'classic';
  bool _saving = false;
  bool _watchingAd = false;
  Timer? _cooldownTimer;

  static const _freeDiscs = CosmeticsTheme.discColors;
  static const _allBoards = ['classic', 'neon', 'wood', 'lava', 'ocean', 'royal'];

  @override
  void initState() {
    super.initState();
    final meta = context.read<PlayerMetaService>().meta;
    _disc = meta?.cosmetics['discColor'] ?? 'green';
    _board = meta?.cosmetics['boardTheme'] ?? 'classic';
    _winFx = meta?.cosmetics['winFx'] ?? 'classic';
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ads = context.read<AdService>();
      final auth = context.read<AuthService>();
      final metaSvc = context.read<PlayerMetaService>();
      await metaSvc.load(auth.getUid(), name: auth.getName());
      await ads.refreshAfterConsent();
      ads.preloadRewarded();
      _startCooldownTicker();
    });
  }

  void _startCooldownTicker() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final metaSvc = context.read<PlayerMetaService>();
      if (metaSvc.adCooldownRemainingMs > 0 || _watchingAd) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _watchAdForTokens() async {
    if (_watchingAd) return;
    final auth = context.read<AuthService>();
    final metaSvc = context.read<PlayerMetaService>();
    final ads = context.read<AdService>();
    final l10n = context.l10nRead;

    if (!AdConfig.supported) {
      _snack(l10n.tokensAdUnavailable);
      return;
    }

    if (!metaSvc.canWatchAdForTokens) {
      final sec = (metaSvc.adCooldownRemainingMs / 1000).ceil();
      _snack(l10n.tokensAdWaitSeconds(sec));
      return;
    }

    if (!ads.initialized || !ads.canLoadAds) {
      await ads.refreshAfterConsent();
    }
    if (!ads.canLoadAds) {
      _snack(l10n.tokensAdConsentRequired);
      return;
    }

    setState(() => _watchingAd = true);

    final outcome = await ads.showRewardedForTokens();
    if (!mounted) return;

    if (outcome == RewardedAdOutcome.notReady) {
      setState(() => _watchingAd = false);
      final detail = ads.lastRewardedError;
      _snack(detail.isNotEmpty ? detail : l10n.tokensAdNotReady);
      return;
    }

    if (outcome == RewardedAdOutcome.dismissedEarly) {
      setState(() => _watchingAd = false);
      _snack(l10n.tokensAdWatchFull);
      return;
    }

    if (outcome == RewardedAdOutcome.showFailed) {
      setState(() => _watchingAd = false);
      _snack(ads.lastRewardedError.isNotEmpty ? ads.lastRewardedError : l10n.tokensAdNotReady);
      return;
    }

    final gain = await metaSvc.rewardAdTokens(auth.getUid());
    if (!mounted) return;
    setState(() => _watchingAd = false);
    if (gain != null && gain > 0) {
      _snack(l10n.tokensEarned(gain));
    } else {
      _snack(metaSvc.lastMessage ?? l10n.tokensAdServerError);
    }
  }

  Future<void> _purchase(String type, String id, int price) async {
    final auth = context.read<AuthService>();
    final metaSvc = context.read<PlayerMetaService>();
    final l10n = context.l10nRead;

    if (metaSvc.tokens < price) {
      // Yerel sayaç sunucudan sapmış olabilir; taze değerle tekrar dene.
      await metaSvc.load(auth.getUid());
      if (!mounted) return;
      if (metaSvc.tokens < price) {
        _showNeedTokensSheet(price);
        return;
      }
    }

    final ok = await metaSvc.purchaseCosmetic(
      auth.getUid(),
      itemType: type,
      itemId: id,
    );
    if (!mounted) return;
    // Sunucu "yetersiz" derse de satış panelini aç (yarış durumu).
    if (!ok && (metaSvc.lastMessage ?? '').contains('Yetersiz')) {
      _showNeedTokensSheet(price);
      return;
    }
    if (ok) {
      final newDisc = type == 'disc' ? id : _disc;
      final newBoard = type == 'board' ? id : _board;
      final newWinFx = type == 'winfx' ? id : _winFx;
      setState(() {
        _disc = newDisc;
        _board = newBoard;
        _winFx = newWinFx;
      });
      await metaSvc.setCosmetics(auth.getUid(), {
        'discColor': newDisc,
        'boardTheme': newBoard,
        'winFx': newWinFx,
      });
      if (!mounted) return;
      _snack(l10n.tokensPurchased);
    } else {
      _snack(metaSvc.lastMessage ?? l10n.tokensNotEnough);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Jeton yetmeyince: eksiği göster + Jeton Al (Premium) / Reklam İzle sun.
  void _showNeedTokensSheet(int price) {
    final l10n = context.l10nRead;
    final metaSvc = context.read<PlayerMetaService>();
    final elo = context.read<AuthService>().user?.elo ?? 1000;
    final adGain = metaSvc.previewAdTokens(elo);
    final have = metaSvc.tokens;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.15),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
              ),
              child: const Icon(Icons.monetization_on_rounded, color: AppColors.gold, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.needTokensTitle,
              style: AppTextStyles.glow(AppColors.gold).copyWith(fontSize: 17, letterSpacing: 1),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.needTokensBody(price, have),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5, height: 1.5),
            ),
            const SizedBox(height: 18),
            // Ana aksiyon: gerçek parayla jeton — Premium ekranına götürür.
            SizedBox(
              width: double.infinity,
              child: ScalePress(
                onTap: () {
                  Navigator.pop(ctx);
                  AppRouter.goPremium(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD75E), Color(0xFFF0A818)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppShadows.neon(AppColors.gold, blur: 10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_bag_rounded, color: Color(0xFF201505), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        l10n.needTokensBuy,
                        style: const TextStyle(
                          color: Color(0xFF201505),
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (AdConfig.supported) ...[
              const SizedBox(height: 10),
              // İkincil: reklam izle, bedava jeton kazan.
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _watchAdForTokens();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.neonYesil,
                    side: BorderSide(color: AppColors.neonYesil.withValues(alpha: 0.55)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.ondemand_video_rounded, size: 18),
                  label: Text(
                    l10n.needTokensAd(adGain),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = context.read<AuthService>();
    final metaSvc = context.watch<PlayerMetaService>();
    final elo = auth.user?.elo ?? 1000;
    final winPreview = metaSvc.previewWinTokens(elo);
    final adPreview = metaSvc.previewAdTokens(elo);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.menuCosmetics),
        backgroundColor: AppColors.bgDeep,
      ),
      body: YesaBackground(
        child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _TokenHeader(
            tokens: metaSvc.tokens,
            winPreview: winPreview,
            adPreview: adPreview,
            showWatchButton: AdConfig.supported,
            onWatchAd: _watchAdForTokens,
            watchingAd: _watchingAd,
            cooldownSec: metaSvc.canWatchAdForTokens
                ? 0
                : (metaSvc.adCooldownRemainingMs / 1000).ceil(),
          ),
          const SizedBox(height: 24),
          YesaSectionLabel(l10n.cosmeticsDiscFree),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _freeDiscs.entries.map((e) {
              return _DiscChip(
                selected: _disc == e.key,
                locked: false,
                price: 0,
                color: e.value,
                onTap: () => setState(() => _disc = e.key),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          YesaSectionLabel(l10n.cosmeticsDiscPremium),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.68,
            ),
            itemCount: CosmeticCatalog.premiumDiscs.length,
            itemBuilder: (context, i) {
              final item = CosmeticCatalog.premiumDiscs[i];
              final unlocked = metaSvc.isDiscUnlocked(item.id);
              final selected = _disc == item.id;
              return _PremiumDiscTile(
                item: item,
                name: l10n.discName(item.id),
                selected: selected,
                unlocked: unlocked,
                onSelect: unlocked ? () => setState(() => _disc = item.id) : null,
                onBuy: unlocked ? null : () => _purchase('disc', item.id, item.price),
              );
            },
          ),
          const SizedBox(height: 24),
          YesaSectionLabel(l10n.cosmeticsDiscEmoji),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 10,
              childAspectRatio: 0.66,
            ),
            // VIP pulu yalnızca (IAP ile) açıldıysa listede görünür.
            itemCount: CosmeticCatalog.emojiDiscs.length +
                (metaSvc.isDiscUnlocked(CosmeticCatalog.vipDisc.id) ? 1 : 0),
            itemBuilder: (context, i) {
              final item = i < CosmeticCatalog.emojiDiscs.length
                  ? CosmeticCatalog.emojiDiscs[i]
                  : CosmeticCatalog.vipDisc;
              final unlocked = metaSvc.isDiscUnlocked(item.id);
              final selected = _disc == item.id;
              return _EmojiDiscTile(
                item: item,
                name: l10n.discName(item.id),
                selected: selected,
                unlocked: unlocked,
                onSelect: unlocked ? () => setState(() => _disc = item.id) : null,
                onBuy: unlocked ? null : () => _purchase('disc', item.id, item.price),
              );
            },
          ),
          const SizedBox(height: 24),
          YesaSectionLabel(l10n.cosmeticsBoard),
          const SizedBox(height: 10),
          ..._allBoards.map((t) {
            final price = CosmeticCatalog.boardPrice(t) ?? 0;
            final unlocked = metaSvc.isBoardUnlocked(t);
            final selected = _board == t;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.boardThemeName(t)),
              subtitle: unlocked
                  ? null
                  : Text(
                      l10n.tokensPrice(price),
                      style: const TextStyle(color: AppColors.gold, fontSize: 12),
                    ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!unlocked)
                    TextButton(
                      onPressed: () => _purchase('board', t, price),
                      child: Text(l10n.tokensBuy),
                    ),
                  if (selected)
                    const Icon(Icons.check_circle, color: AppColors.green)
                  else if (unlocked)
                    IconButton(
                      icon: const Icon(Icons.circle_outlined, color: AppColors.textMuted),
                      onPressed: () => setState(() => _board = t),
                    ),
                ],
              ),
              onTap: unlocked ? () => setState(() => _board = t) : null,
            );
          }),
          const SizedBox(height: 24),
          // ── Maç içi emote'lar — rakip de görür.
          YesaSectionLabel(l10n.cosmeticsEmotes),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: CosmeticCatalog.premiumEmotes.map((e) {
              final unlocked = metaSvc.isEmoteUnlocked(e.id);
              return _EmoteChip(
                emoji: e.emoji,
                price: e.price,
                unlocked: unlocked,
                onBuy: unlocked ? null : () => _purchase('emote', e.id, e.price),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          // ── Zafer efekti — maç sonu konfeti stili.
          YesaSectionLabel(l10n.cosmeticsWinFx),
          const SizedBox(height: 10),
          ...CosmeticCatalog.winFxItems.map((fx) {
            final price = fx.price;
            final unlocked = metaSvc.isWinFxUnlocked(fx.id);
            final selected = _winFx == fx.id;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(fx.emoji, style: const TextStyle(fontSize: 22)),
              title: Text(l10n.winFxName(fx.id)),
              subtitle: unlocked || price == 0
                  ? null
                  : Text(
                      l10n.tokensPrice(price),
                      style: const TextStyle(color: AppColors.gold, fontSize: 12),
                    ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!unlocked)
                    TextButton(
                      onPressed: () => _purchase('winfx', fx.id, price),
                      child: Text(l10n.tokensBuy),
                    ),
                  if (selected)
                    const Icon(Icons.check_circle, color: AppColors.green)
                  else if (unlocked)
                    IconButton(
                      icon: const Icon(Icons.circle_outlined, color: AppColors.textMuted),
                      onPressed: () => setState(() => _winFx = fx.id),
                    ),
                ],
              ),
              onTap: unlocked ? () => setState(() => _winFx = fx.id) : null,
            );
          }),
          const SizedBox(height: 20),
          PucketButton(
            label: _saving ? '...' : l10n.save,
            onPressed: _saving
                ? () {}
                : () async {
                    if (!metaSvc.isDiscUnlocked(_disc) ||
                        !metaSvc.isBoardUnlocked(_board) ||
                        !metaSvc.isWinFxUnlocked(_winFx)) {
                      _snack(l10n.tokensLocked);
                      return;
                    }
                    setState(() => _saving = true);
                    await metaSvc.setCosmetics(auth.getUid(), {
                      'discColor': _disc,
                      'boardTheme': _board,
                      'winFx': _winFx,
                    });
                    if (mounted) {
                      setState(() => _saving = false);
                      Navigator.pop(this.context);
                    }
                  },
          ),
        ],
        ),
      ),
    );
  }

}

class _TokenHeader extends StatelessWidget {
  const _TokenHeader({
    required this.tokens,
    required this.winPreview,
    required this.adPreview,
    required this.showWatchButton,
    required this.onWatchAd,
    required this.watchingAd,
    required this.cooldownSec,
  });

  final int tokens;
  final int winPreview;
  final int adPreview;
  final bool showWatchButton;
  final VoidCallback onWatchAd;
  final bool watchingAd;
  final int cooldownSec;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: YesaDecor.highlightBanner(radius: 18).copyWith(
        border: Border.all(color: AppColors.accentYellow.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monetization_on, color: AppColors.brandPurpleDeep.withValues(alpha: 0.85), size: 28),
              const SizedBox(width: 8),
              Text(
                l10n.tokensBalance(tokens),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: AppColors.brandPurpleDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tokensEarnHint(winPreview, adPreview),
            style: TextStyle(
              color: AppColors.brandPurpleDeep.withValues(alpha: 0.75),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          if (showWatchButton)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: watchingAd || cooldownSec > 0 ? null : onWatchAd,
                icon: watchingAd
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                      )
                    : const Icon(Icons.play_circle_outline, color: AppColors.gold),
                label: Text(
                  watchingAd
                      ? l10n.tokensAdLoading
                      : cooldownSec > 0
                          ? l10n.tokensAdWaitSeconds(cooldownSec)
                          : l10n.tokensWatchAd(adPreview),
                  style: TextStyle(
                    color: AppColors.gold.withValues(alpha: watchingAd || cooldownSec > 0 ? 0.7 : 1),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppColors.gold.withValues(alpha: watchingAd || cooldownSec > 0 ? 0.5 : 1),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DiscChip extends StatelessWidget {
  const _DiscChip({
    required this.selected,
    required this.locked,
    required this.price,
    required this.onTap,
    this.color,
  });

  final bool selected;
  final bool locked;
  final int price;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = color ?? AppColors.neonYesil;
    final light = Color.lerp(base, Colors.white, 0.42)!;
    final dark = Color.lerp(base, Colors.black, 0.38)!;
    final rim = Color.lerp(base, Colors.black, 0.52)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Oyundaki 3D pul görünümüyle aynı: üst-soldan ışık.
          gradient: RadialGradient(
            center: const Alignment(-0.35, -0.42),
            radius: 1.25,
            colors: [light, base, dark],
            stops: const [0.0, 0.55, 1.0],
          ),
          border: Border.all(
            color: selected ? AppColors.gold : Colors.white24,
            width: selected ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: dark.withValues(alpha: 0.6),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Jant + iç oluk halkası.
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: rim.withValues(alpha: 0.85), width: 3),
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: dark.withValues(alpha: 0.55), width: 1.6),
              ),
            ),
            // Cam parlaması.
            Align(
              alignment: const Alignment(-0.45, -0.5),
              child: Container(
                width: 20,
                height: 20,
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
            if (locked)
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.55),
                ),
                child: const Icon(Icons.lock, color: Colors.white70, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}

class _PremiumDiscTile extends StatelessWidget {
  const _PremiumDiscTile({
    required this.item,
    required this.name,
    required this.selected,
    required this.unlocked,
    required this.onSelect,
    required this.onBuy,
  });

  final CosmeticItem item;
  final String name;
  final bool selected;
  final bool unlocked;
  final VoidCallback? onSelect;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        GestureDetector(
          onTap: onSelect ?? onBuy,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage(item.asset),
                    fit: BoxFit.cover,
                  ),
                  border: Border.all(
                    color: selected ? AppColors.gold : Colors.white24,
                    width: selected ? 3 : 1.5,
                  ),
                ),
              ),
              if (!unlocked)
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                  child: const Icon(Icons.lock, color: Colors.white70),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, height: 1.1),
        ),
        if (!unlocked)
          TextButton(
            onPressed: onBuy,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.tokensPrice(item.price),
              style: const TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ),
      ],
    );
  }
}

class _EmojiDiscTile extends StatelessWidget {
  const _EmojiDiscTile({
    required this.item,
    required this.name,
    required this.selected,
    required this.unlocked,
    required this.onSelect,
    required this.onBuy,
  });

  final CosmeticItem item;
  final String name;
  final bool selected;
  final bool unlocked;
  final VoidCallback? onSelect;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        GestureDetector(
          onTap: onSelect ?? onBuy,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.bgColor,
                  border: Border.all(
                    color: selected ? AppColors.gold : Colors.white24,
                    width: selected ? 3 : 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(item.emoji, style: const TextStyle(fontSize: 28, height: 1)),
              ),
              if (!unlocked)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                  child: const Icon(Icons.lock, color: Colors.white70, size: 18),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, height: 1.1),
        ),
        if (!unlocked)
          TextButton(
            onPressed: onBuy,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.tokensPrice(item.price),
              style: const TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ),
      ],
    );
  }
}


/// Satın alınabilir emote çipi — kilitliyken fiyat gösterir.
class _EmoteChip extends StatelessWidget {
  const _EmoteChip({
    required this.emoji,
    required this.price,
    required this.unlocked,
    required this.onBuy,
  });

  final String emoji;
  final int price;
  final bool unlocked;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onBuy,
      child: Container(
        width: 74,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.morDahaKoyu.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: unlocked
                ? AppColors.neonYesil.withValues(alpha: 0.6)
                : AppColors.beyaz.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: unlocked ? 1 : 0.75,
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(height: 4),
            if (unlocked)
              const Icon(Icons.check_circle, color: AppColors.neonYesil, size: 14)
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.monetization_on_rounded, color: AppColors.gold, size: 12),
                  const SizedBox(width: 2),
                  Text(
                    '$price',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
