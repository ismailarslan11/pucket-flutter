import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../l10n/app_localizations.dart';
import '../models/rank_tier.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/career_service.dart';
import '../services/player_meta_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/daily_quests_panel.dart';
import '../widgets/ranked_login_dialog.dart';
import '../widgets/yesa_background.dart';
import '../widgets/yesa_effects.dart';
import '../widgets/yesa_menu_tile.dart';
import 'app_router.dart';
import 'rank_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final career = context.watch<CareerService>();
    final meta = context.watch<PlayerMetaService>();
    final l10n = context.l10n;
    final user = auth.user;
    final tier = user != null ? RankTier.forElo(user.elo) : null;

    return Scaffold(
      body: YesaBackground(
        child: SafeArea(
          child: Column(
            children: [
              if (user != null && tier != null)
                _ProfileCard(user: user, tier: tier, tokens: meta.tokens, l10n: l10n),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      StaggerIn(index: 2, child: const DailyQuestsPanel()),
                      const SizedBox(height: 16),
                      YesaSectionLabel('Oyna'),
                      // Amiral gemisi: tam genişlik RANKED afişi.
                      StaggerIn(
                        index: 3,
                        child: PulseScale(
                          max: 1.015,
                          durationMs: 1600,
                          child: _HeroPlayCard(
                            title: l10n.menuRanked,
                            subtitle: l10n.menuRankedSub,
                            onPressed: () => _goRanked(context, auth),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // İki orta kart: hızlı eşleşme + kariyer.
                      Row(
                        children: [
                          Expanded(
                            child: StaggerIn(
                              index: 4,
                              child: _MediumPlayCard(
                                label: l10n.menuQuick,
                                icon: Icons.bolt_rounded,
                                color: AppColors.acikMor,
                                onPressed: () =>
                                    AppRouter.goLobby(context, quickMatch: true),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: StaggerIn(
                              index: 5,
                              child: _MediumPlayCard(
                                label: l10n.menuCareer,
                                icon: Icons.military_tech_rounded,
                                color: AppColors.pembe,
                                badge: '${career.careerPoints}p',
                                onPressed: () => AppRouter.goCareer(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Beş mini kutu: oda / katıl / antrenman / bot / 2 kişilik.
                      StaggerIn(
                        index: 6,
                        child: Row(
                          children: [
                            Expanded(
                              child: _MiniPlayTile(
                                label: l10n.menuCreateRoom,
                                icon: Icons.add_box_rounded,
                                onPressed: () =>
                                    AppRouter.goLobby(context, createRoom: true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MiniPlayTile(
                                label: l10n.menuJoinRoom,
                                icon: Icons.login_rounded,
                                onPressed: () => AppRouter.goJoin(context),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MiniPlayTile(
                                label: l10n.menuTraining,
                                icon: Icons.fitness_center_rounded,
                                onPressed: () => AppRouter.goTraining(context),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MiniPlayTile(
                                label: l10n.menuVsBot,
                                icon: Icons.smart_toy_rounded,
                                onPressed: () => AppRouter.goDifficulty(context),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MiniPlayTile(
                                label: l10n.menuLocalDuo,
                                icon: Icons.people_alt_rounded,
                                onPressed: () => AppRouter.goLocalDuo(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      YesaSectionLabel(l10n.more),
                      YesaMenuGrid(
                        columns: 4,
                        spacing: 10,
                        children: [
                          YesaMenuTile(
                            label: l10n.menuLeaderboard,
                            icon: Icons.leaderboard_rounded,
                            staggerIndex: 11,
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RankScreen()),
                            ),
                          ),
                          YesaMenuTile(
                            label: l10n.battlePass,
                            icon: Icons.military_tech_rounded,
                            accent: true,
                            staggerIndex: 12,
                            onPressed: () => AppRouter.goBattlePass(context),
                          ),
                          YesaMenuTile(
                            label: l10n.friends,
                            icon: Icons.group_rounded,
                            staggerIndex: 14,
                            onPressed: () => AppRouter.goFriends(context),
                          ),
                          YesaMenuTile(
                            label: l10n.menuTutorial,
                            icon: Icons.school_rounded,
                            staggerIndex: 15,
                            onPressed: () => AppRouter.goTutorial(context),
                          ),
                          YesaMenuTile(
                            label: l10n.menuProfile,
                            icon: Icons.person_rounded,
                            staggerIndex: 14,
                            onPressed: () => AppRouter.goProfile(context),
                          ),
                          YesaMenuTile(
                            label: l10n.menuCosmetics,
                            icon: Icons.storefront_rounded,
                            staggerIndex: 15,
                            onPressed: () => AppRouter.goCosmetics(context),
                          ),
                          YesaMenuTile(
                            label: l10n.menuPremium,
                            icon: Icons.workspace_premium_rounded,
                            accent: true,
                            staggerIndex: 16,
                            onPressed: () => AppRouter.goPremium(context),
                          ),
                          YesaMenuTile(
                            label: l10n.menuSettings,
                            icon: Icons.settings_rounded,
                            staggerIndex: 17,
                            onPressed: () => AppRouter.goSettings(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const AdBannerWidget(),
            ],
          ),
        ),
      ),
    );
  }

  void _goRanked(BuildContext context, AuthService auth) {
    if (!auth.canPlayRanked) {
      showRankedLoginDialog(context);
      return;
    }
    AppRouter.goQueue(context);
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.user,
    required this.tier,
    required this.tokens,
    required this.l10n,
  });

  final UserProfile user;
  final RankTier tier;
  final int tokens;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: StaggerIn(
        index: 0,
        child: GlowPulse(
          color: AppColors.anaMor,
          min: 0.2,
          max: 0.5,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: YesaDecor.card(radius: 22),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (!auth.canPlayRanked) {
                      showRankedLoginDialog(context);
                    } else {
                      AppRouter.goProfile(context);
                    }
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppGradients.heroPlay,
                      border: Border.all(color: AppColors.beyaz.withValues(alpha: 0.55), width: 2),
                      boxShadow: AppShadows.neon(AppColors.sariAna, blur: 10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.morDahaKoyu,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: AppTextStyles.title.copyWith(fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n.tierName(tier).toUpperCase(),
                        style: AppTextStyles.glow(tier.color).copyWith(fontSize: 10, letterSpacing: 0.8),
                      ),
                      Text(
                        '${user.elo} ELO · ${user.wins}${l10n.winsLosses}${user.losses}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 5),
                      _TierProgress(elo: user.elo, tier: tier),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StatPill(
                      icon: Icons.monetization_on_rounded,
                      value: '$tokens',
                      gradient: AppGradients.heroPlay,
                      onTap: () => AppRouter.goCosmetics(context),
                    ),
                    const SizedBox(height: 6),
                    _StatPill(
                      icon: Icons.emoji_events_outlined,
                      value: '${user.elo}',
                      gradient: AppGradients.neonPurple,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RankScreen()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tam genişlik RANKED afişi — turuncu gradyan, süzülen kupa, ok ucu.
class _HeroPlayCard extends StatelessWidget {
  const _HeroPlayCard({
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GlowPulse(
      color: AppColors.sariAna,
      min: 0.25,
      max: 0.55,
      child: ScalePress(
        onTap: onPressed,
        child: Container(
          height: 78,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: AppGradients.heroPlay,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.beyaz.withValues(alpha: 0.55), width: 2),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Cam parlaması.
              Positioned(
                top: -26,
                left: -20,
                right: -20,
                height: 52,
                child: IgnorePointer(
                  child: Transform.rotate(
                    angle: -0.10,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.beyaz.withValues(alpha: 0.30),
                            AppColors.beyaz.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Sağda kocaman soluk kupa — derinlik.
              Positioned(
                right: -6,
                top: -10,
                child: Icon(
                  Icons.emoji_events_rounded,
                  size: 96,
                  color: AppColors.morDahaKoyu.withValues(alpha: 0.15),
                ),
              ),
              const ShineOverlay(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    FloatY(
                      amplitude: 3,
                      child: Container(
                        width: 46,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.beyaz.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.beyaz.withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.emoji_events_rounded,
                            size: 26, color: AppColors.morDahaKoyu),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.morDahaKoyu,
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.morDahaKoyu.withValues(alpha: 0.75),
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 18, color: AppColors.morDahaKoyu),
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

/// Orta boy yatay oyun kartı — renkli ikon rozeti + etiket.
class _MediumPlayCard extends StatelessWidget {
  const _MediumPlayCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.badge,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return ScalePress(
      onTap: onPressed,
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          gradient: AppGradients.tileSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.55), width: 1.3),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                label.toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.beyaz,
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                  height: 1.15,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 9,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Mini kare oyun kutusu — ikon üstte, kısa etiket altta.
class _MiniPlayTile extends StatelessWidget {
  const _MiniPlayTile({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ScalePress(
      onTap: onPressed,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.morDahaKoyu.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.lavanta.withValues(alpha: 0.28)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.sariAna),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.pusluBeyaz,
                fontWeight: FontWeight.w700,
                fontSize: 7.5,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bir sonraki lige ilerleme çubuğu — ince, tier renkli, parlayan uç.
class _TierProgress extends StatelessWidget {
  const _TierProgress({required this.elo, required this.tier});

  final int elo;
  final RankTier tier;

  @override
  Widget build(BuildContext context) {
    // Mevcut ve sonraki ligin ELO eşiği.
    final idx = RankTier.tiers.indexOf(tier);
    final isMax = idx >= RankTier.tiers.length - 1;
    final start = tier.minElo;
    final end = isMax ? (elo < start + 300 ? start + 300 : elo) : RankTier.tiers[idx + 1].minElo;
    final p = ((elo - start) / (end - start)).clamp(0.0, 1.0);

    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 5,
              child: Stack(
                children: [
                  Container(color: AppColors.morDahaKoyu.withValues(alpha: 0.8)),
                  FractionallySizedBox(
                    widthFactor: p == 0 ? 0.02 : p,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [tier.color.withValues(alpha: 0.7), tier.color],
                        ),
                        boxShadow: [
                          BoxShadow(color: tier.color.withValues(alpha: 0.7), blurRadius: 6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isMax ? '★ MAX' : '${RankTier.tiers[idx + 1].minElo - elo} ELO → ${RankTier.tiers[idx + 1].name}',
            style: TextStyle(
              color: tier.color.withValues(alpha: 0.9),
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.value,
    required this.onTap,
    required this.gradient,
  });

  final IconData icon;
  final String value;
  final VoidCallback onTap;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ScalePress(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.beyaz.withValues(alpha: 0.3)),
          boxShadow: AppShadows.neon(AppColors.anaMor, blur: 6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColors.morDahaKoyu),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.morDahaKoyu,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
