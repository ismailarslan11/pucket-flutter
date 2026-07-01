import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/ad_config.dart';
import '../l10n/l10n_extension.dart';
import '../models/cosmetic_catalog.dart';
import '../services/ad_service.dart';
import '../services/auth_service.dart';
import '../services/player_meta_service.dart';
import '../theme/cosmetics_theme.dart';
import '../theme/app_theme.dart';
import '../widgets/pucket_button.dart';

class CosmeticsScreen extends StatefulWidget {
  const CosmeticsScreen({super.key});

  @override
  State<CosmeticsScreen> createState() => _CosmeticsScreenState();
}

class _CosmeticsScreenState extends State<CosmeticsScreen> {
  String _disc = 'green';
  String _board = 'classic';
  bool _saving = false;
  bool _watchingAd = false;

  static const _freeDiscs = CosmeticsTheme.discColors;
  static const _allBoards = ['classic', 'neon', 'wood'];

  @override
  void initState() {
    super.initState();
    final meta = context.read<PlayerMetaService>().meta;
    _disc = meta?.cosmetics['discColor'] ?? 'green';
    _board = meta?.cosmetics['boardTheme'] ?? 'classic';
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ads = context.read<AdService>();
      final auth = context.read<AuthService>();
      final metaSvc = context.read<PlayerMetaService>();
      await metaSvc.load(auth.getUid(), name: auth.getName());
      await ads.refreshAfterConsent();
      ads.preloadRewarded();
    });
  }

  Future<void> _watchAdForTokens() async {
    if (_watchingAd) return;
    final auth = context.read<AuthService>();
    final metaSvc = context.read<PlayerMetaService>();
    final ads = context.read<AdService>();
    final l10n = context.l10n;

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
      _snack(detail.isNotEmpty ? '${l10n.tokensAdNotReady}\n$detail' : l10n.tokensAdNotReady);
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
    final l10n = context.l10n;

    if (metaSvc.tokens < price) {
      _snack(l10n.tokensNotEnough);
      return;
    }

    final ok = await metaSvc.purchaseCosmetic(
      auth.getUid(),
      itemType: type,
      itemId: id,
    );
    if (!mounted) return;
    if (ok) {
      final newDisc = type == 'disc' ? id : _disc;
      final newBoard = type == 'board' ? id : _board;
      setState(() {
        _disc = newDisc;
        _board = newBoard;
      });
      await metaSvc.setCosmetics(auth.getUid(), {
        'discColor': newDisc,
        'boardTheme': newBoard,
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
        backgroundColor: AppColors.bg,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _TokenHeader(
            tokens: metaSvc.tokens,
            winPreview: winPreview,
            adPreview: adPreview,
            onWatchAd: _watchingAd ? null : _watchAdForTokens,
            watchingAd: _watchingAd,
          ),
          const SizedBox(height: 24),
          Text(l10n.cosmeticsDiscFree, style: _sectionStyle),
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
          Text(l10n.cosmeticsDiscPremium, style: _sectionStyle),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.82,
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
          Text(l10n.cosmeticsBoard, style: _sectionStyle),
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
          const SizedBox(height: 20),
          PucketButton(
            label: _saving ? '...' : l10n.save,
            onPressed: _saving
                ? () {}
                : () async {
                    if (!metaSvc.isDiscUnlocked(_disc) || !metaSvc.isBoardUnlocked(_board)) {
                      _snack(l10n.tokensLocked);
                      return;
                    }
                    setState(() => _saving = true);
                    await metaSvc.setCosmetics(auth.getUid(), {
                      'discColor': _disc,
                      'boardTheme': _board,
                    });
                    if (mounted) {
                      setState(() => _saving = false);
                      Navigator.pop(context);
                    }
                  },
          ),
        ],
      ),
    );
  }

  TextStyle get _sectionStyle => const TextStyle(fontWeight: FontWeight.w800, fontSize: 15);
}

class _TokenHeader extends StatelessWidget {
  const _TokenHeader({
    required this.tokens,
    required this.winPreview,
    required this.adPreview,
    required this.onWatchAd,
    required this.watchingAd,
  });

  final int tokens;
  final int winPreview;
  final int adPreview;
  final VoidCallback? onWatchAd;
  final bool watchingAd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppGradients.ranked,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monetization_on, color: AppColors.gold, size: 28),
              const SizedBox(width: 8),
              Text(
                l10n.tokensBalance(tokens),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tokensEarnHint(winPreview, adPreview),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),
          if (onWatchAd != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onWatchAd,
                icon: watchingAd
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                      )
                    : const Icon(Icons.play_circle_outline, color: AppColors.gold),
                label: Text(
                  watchingAd ? '...' : l10n.tokensWatchAd(adPreview),
                  style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.gold),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: selected ? AppColors.gold : Colors.white24,
            width: selected ? 3 : 1.5,
          ),
        ),
        child: locked
            ? Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.55),
                ),
                child: const Icon(Icons.lock, color: Colors.white70, size: 18),
              )
            : null,
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
          maxLines: 2,
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
