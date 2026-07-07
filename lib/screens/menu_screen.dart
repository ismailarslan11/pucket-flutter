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
                      StaggerIn(index: 1, child: YesaRibbon(text: l10n.onlineMultiplayer, icon: Icons.wifi_tethering_rounded)),
                      const SizedBox(height: 14),
                      StaggerIn(index: 2, child: const DailyQuestsPanel()),
                      const SizedBox(height: 16),
                      YesaSectionLabel('Oyna'),
                      YesaMenuGrid(
                        columns: 3,
                        spacing: 10,
                        children: [
                          YesaMenuTile(
                            label: l10n.menuRanked,
                            icon: Icons.emoji_events_rounded,
                            featured: true,
                            staggerIndex: 3,
                            onPressed: () => _goRanked(context, auth),
                          ),
                          YesaMenuTile(
                            label: l10n.menuQuick,
                            icon: Icons.bolt_rounded,
                            staggerIndex: 4,
                            onPressed: () => AppRouter.goLobby(context, quickMatch: true),
                          ),
                          YesaMenuTile(
                            label: l10n.menuCreateRoom,
                            icon: Icons.add_box_rounded,
                            staggerIndex: 5,
                            onPressed: () => AppRouter.goLobby(context, createRoom: true),
                          ),
                          YesaMenuTile(
                            label: l10n.menuJoinRoom,
                            icon: Icons.login_rounded,
                            staggerIndex: 6,
                            onPressed: () => AppRouter.goJoin(context),
                          ),
                          YesaMenuTile(
                            label: l10n.menuCareer,
                            icon: Icons.military_tech_rounded,
                            accent: true,
                            subtitle: '${career.careerPoints}p',
                            staggerIndex: 7,
                            onPressed: () => AppRouter.goCareer(context),
                          ),
                          YesaMenuTile(
                            label: l10n.menuTraining,
                            icon: Icons.fitness_center_rounded,
                            staggerIndex: 8,
                            onPressed: () => AppRouter.goTraining(context),
                          ),
                          YesaMenuTile(
                            label: l10n.menuVsBot,
                            icon: Icons.smart_toy_rounded,
                            staggerIndex: 9,
                            onPressed: () => AppRouter.goDifficulty(context),
                          ),
                          YesaMenuTile(
                            label: l10n.menuLocalDuo,
                            icon: Icons.people_alt_rounded,
                            staggerIndex: 10,
                            onPressed: () => AppRouter.goLocalDuo(context),
                          ),
                        ],
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
                            label: l10n.menuTutorial,
                            icon: Icons.school_rounded,
                            staggerIndex: 12,
                            onPressed: () => AppRouter.goTutorial(context),
                          ),
                          YesaMenuTile(
                            label: l10n.friends,
                            icon: Icons.group_rounded,
                            staggerIndex: 13,
                            onPressed: () => AppRouter.goFriends(context),
                          ),
                          YesaMenuTile(
                            label: l10n.menuProfile,
                            icon: Icons.person_rounded,
                            staggerIndex: 14,
                            onPressed: () => AppRouter.goProfile(context),
                          ),
                          YesaMenuTile(
                            label: l10n.menuCosmetics,
                            icon: Icons.palette_rounded,
                            staggerIndex: 15,
                            onPressed: () => AppRouter.goCosmetics(context),
                          ),
                          YesaMenuTile(
                            label: l10n.menuSettings,
                            icon: Icons.settings_rounded,
                            staggerIndex: 16,
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
