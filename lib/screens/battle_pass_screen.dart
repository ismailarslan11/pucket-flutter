import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n_extension.dart';
import '../models/cosmetic_catalog.dart';
import '../services/auth_service.dart';
import '../services/battle_pass_api.dart';
import '../services/player_meta_service.dart';
import '../services/purchase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/yesa_background.dart';
import '../widgets/yesa_effects.dart';

class BattlePassScreen extends StatefulWidget {
  const BattlePassScreen({super.key});

  @override
  State<BattlePassScreen> createState() => _BattlePassScreenState();
}

class _BattlePassScreenState extends State<BattlePassScreen> {
  BattlePassState? _bp;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = context.read<AuthService>().getUid();
    final bp = await BattlePassApi.fetch(uid);
    if (!mounted) return;
    setState(() {
      _bp = bp;
      _loading = false;
    });
  }

  Future<void> _claim(int tier, bool premium) async {
    final uid = context.read<AuthService>().getUid();
    final err = await BattlePassApi.claim(uid, tier, premium: premium);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    // Jeton/kozmetik güncellensin.
    await context.read<PlayerMetaService>().load(uid);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bp = _bp;
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
                        l10n.battlePass,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.glow(AppColors.sariAna).copyWith(fontSize: 18, letterSpacing: 2),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              if (bp != null) _header(bp, l10n),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.sariAna))
                    : bp == null
                        ? const Center(child: Text('—', style: TextStyle(color: AppColors.textMuted)))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: bp.tiers.length,
                            itemBuilder: (_, i) => StaggerIn(
                              index: i % 8,
                              delayMs: 25,
                              child: _tierRow(bp, i, l10n),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BattlePassState bp, l10n) {
    final inTier = bp.xp % bp.xpPerTier;
    final progress = bp.xpPerTier == 0 ? 0.0 : inTier / bp.xpPerTier;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: YesaDecor.card(radius: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${bp.tier}/${bp.tiers.length}',
                    style: AppTextStyles.label.copyWith(color: AppColors.lavanta, letterSpacing: 1.2)),
                Text('${bp.xp} XP',
                    style: const TextStyle(color: AppColors.sariAna, fontWeight: FontWeight.w900, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 10,
                backgroundColor: AppColors.borderSubtle,
                valueColor: const AlwaysStoppedAnimation(AppColors.sariAna),
              ),
            ),
            if (!bp.premium) ...[
              const SizedBox(height: 10),
              _premiumUnlockButton(l10n),
            ],
          ],
        ),
      ),
    );
  }

  Widget _premiumUnlockButton(AppLocalizations l10n) {
    final purchases = context.watch<PurchaseService>();
    final product = purchases.productFor(ProductIds.battlePassPremium);
    if (!purchases.available || product == null) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      child: ScalePress(
        onTap: () => purchases.buy(ProductIds.battlePassPremium),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppGradients.heroPlay,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppShadows.neon(AppColors.sariAna, blur: 8),
          ),
          child: Text('${l10n.battlePassPremium} — ${product.price}',
              style: const TextStyle(
                  color: AppColors.morDahaKoyu, fontWeight: FontWeight.w900, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _tierRow(BattlePassState bp, int i, l10n) {
    final reached = bp.tier > i;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: AppGradients.glassCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: reached ? AppColors.sariAna.withValues(alpha: 0.5) : AppColors.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: reached ? AppGradients.heroPlay : null,
              color: reached ? null : AppColors.card,
              border: Border.all(color: AppColors.beyaz.withValues(alpha: 0.2)),
            ),
            child: Text('${i + 1}',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: reached ? AppColors.morDahaKoyu : AppColors.textMuted)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _rewardCell(bp, i, bp.tiers[i].free, false, reached, l10n),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _rewardCell(bp, i, bp.tiers[i].premium, true, reached, l10n),
          ),
        ],
      ),
    );
  }

  Widget _rewardCell(BattlePassState bp, int tier, BpReward r, bool premium, bool reached, l10n) {
    final claimed = (premium ? bp.claimedPremium : bp.claimedFree).contains(tier);
    final canClaim = reached && !claimed && (!premium || bp.premium);
    final label = premium ? l10n.battlePassPremium : l10n.battlePassFree;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: premium ? AppColors.sariAna.withValues(alpha: 0.08) : AppColors.bgDeep.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: premium ? AppColors.sariAna.withValues(alpha: 0.35) : AppColors.borderSubtle,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontSize: 7,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w800,
                  color: premium ? AppColors.sariAna : AppColors.textMuted)),
          const SizedBox(height: 4),
          _rewardIcon(r),
          const SizedBox(height: 2),
          Text(_rewardLabel(r),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, color: AppColors.textDim, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          SizedBox(
            height: 26,
            child: canClaim
                ? ScalePress(
                    onTap: () => _claim(tier, premium),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppGradients.heroPlay,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(l10n.battlePassClaim,
                          style: const TextStyle(
                              color: AppColors.morDahaKoyu, fontWeight: FontWeight.w900, fontSize: 10)),
                    ),
                  )
                : Center(
                    child: Text(
                      claimed
                          ? l10n.battlePassClaimed
                          : (premium && !bp.premium)
                              ? l10n.battlePassLocked
                              : l10n.battlePassLocked,
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: claimed ? AppColors.neonYesil : AppColors.textFaint),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _rewardIcon(BpReward r) {
    if (r.type == 'tokens') {
      return const Icon(Icons.monetization_on_rounded, color: AppColors.sariAna, size: 26);
    }
    if (r.type == 'disc') {
      final asset = CosmeticCatalog.discAsset(r.id);
      if (asset != null) {
        return SizedBox(width: 28, height: 28, child: Image.asset(asset, fit: BoxFit.cover));
      }
      return const Icon(Icons.album_rounded, color: AppColors.acikMor, size: 26);
    }
    return const Icon(Icons.grid_view_rounded, color: AppColors.camgobegi, size: 26);
  }

  String _rewardLabel(BpReward r) {
    if (r.type == 'tokens') return '${r.amount}';
    if (r.type == 'disc') return context.l10n.discName(r.id);
    return r.id;
  }
}
