import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../models/rank_tier.dart';
import '../services/auth_service.dart';
import '../services/career_service.dart';
import '../services/share_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/daily_quests_panel.dart';
import '../widgets/pucket_button.dart';
import '../widgets/pucket_logo.dart';
import '../widgets/ranked_login_dialog.dart';
import 'app_router.dart';
import 'rank_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final career = context.watch<CareerService>();
    final l10n = context.l10n;
    final user = auth.user;
    final tier = user != null ? RankTier.forElo(user.elo) : null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.screenBg),
        child: SafeArea(
          child: Column(
            children: [
              if (user != null && tier != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Color(0x0AFFFFFF),
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _profileTap(context, auth),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.green.withValues(alpha: 0.15),
                            border: Border.all(color: AppColors.green, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppColors.green,
                              fontSize: 17,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${user.elo} ELO  •  ${user.wins}${l10n.winsLosses} ${user.losses}M',
                              style: const TextStyle(color: Color(0xFF666666), fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RankScreen()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: tier.color),
                          ),
                          child: Text(
                            '${tier.emoji} ${l10n.tierName(tier)}',
                            style: TextStyle(color: tier.color, fontWeight: FontWeight.w700, fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      const PucketLogo(height: 130, showTagline: true),
                      const SizedBox(height: 8),
                      Text(
                        l10n.onlineMultiplayer,
                        style: const TextStyle(color: AppColors.cyan, fontSize: 10, letterSpacing: 4),
                      ),
                      const SizedBox(height: 28),
                      const DailyQuestsPanel(),
                      const SizedBox(height: 16),
                      PucketButton(
                        label: l10n.menuRanked,
                        gradient: AppGradients.ranked,
                        shadowColor: AppColors.purpleDark,
                        onPressed: () => _goRanked(context, auth),
                      ),
                      const SizedBox(height: 14),
                      PucketButton(
                        label: l10n.menuQuick,
                        onPressed: () => AppRouter.goLobby(context, quickMatch: true),
                      ),
                      const SizedBox(height: 14),
                      PucketButton(
                        label: l10n.menuCreateRoom,
                        onPressed: () => AppRouter.goLobby(context, createRoom: true),
                      ),
                      const SizedBox(height: 14),
                      PucketButton(
                        label: l10n.menuJoinRoom,
                        onPressed: () => AppRouter.goJoin(context),
                      ),
                      const SizedBox(height: 14),
                      PucketButton(
                        label: l10n.menuCareer,
                        subtitle: l10n.careerSubtitle(
                          career.careerPoints,
                          '${career.currentLeague.emoji} ${l10n.tierName(career.currentLeague)}',
                        ),
                        gradient: const LinearGradient(colors: [Color(0xFF6A3093), Color(0xFF2A1A4A)]),
                        shadowColor: const Color(0xFF1A0A2A),
                        onPressed: () => AppRouter.goCareer(context),
                      ),
                      const SizedBox(height: 14),
                      PucketButton(
                        label: l10n.menuTraining,
                        onPressed: () => AppRouter.goTraining(context),
                      ),
                      const SizedBox(height: 14),
                      PucketButton(
                        label: l10n.menuTournament,
                        onPressed: () => AppRouter.goTournament(context),
                      ),
                      const SizedBox(height: 14),
                      PucketButton(
                        label: l10n.menuVsBot,
                        color: const Color(0xFF252525),
                        shadowColor: const Color(0xFF111111),
                        onPressed: () => AppRouter.goDifficulty(context),
                      ),
                      const SizedBox(height: 20),
                      _DividerRow(label: l10n.more),
                      const SizedBox(height: 10),
                      PucketButton(
                        label: l10n.menuLeaderboard,
                        secondary: true,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RankScreen()),
                        ),
                      ),
                      const SizedBox(height: 14),
                      PucketButton(
                        label: l10n.menuTutorial,
                        secondary: true,
                        onPressed: () => AppRouter.goTutorial(context),
                      ),
                      const SizedBox(height: 14),
                      PucketButton(
                        label: l10n.menuProfile,
                        secondary: true,
                        onPressed: () => AppRouter.goProfile(context),
                      ),
                      const SizedBox(height: 14),
                      PucketButton(
                        label: l10n.menuCosmetics,
                        secondary: true,
                        onPressed: () => AppRouter.goCosmetics(context),
                      ),
                      const SizedBox(height: 14),
                      PucketButton(
                        label: l10n.menuInvite,
                        secondary: true,
                        onPressed: () => ShareService.shareInviteLink(),
                      ),
                      const SizedBox(height: 14),
                      PucketButton(
                        label: l10n.menuSettings,
                        secondary: true,
                        onPressed: () => AppRouter.goSettings(context),
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

  void _profileTap(BuildContext context, AuthService auth) {
    if (!auth.canPlayRanked) {
      showRankedLoginDialog(context);
    } else {
      AppRouter.goProfile(context);
    }
  }

  void _goRanked(BuildContext context, AuthService auth) {
    if (!auth.canPlayRanked) {
      showRankedLoginDialog(context);
      return;
    }
    AppRouter.goQueue(context);
  }
}

class _DividerRow extends StatelessWidget {
  const _DividerRow({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(label, style: const TextStyle(color: Color(0xFF444444), fontSize: 11)),
        ),
        Expanded(child: Container(height: 1, color: AppColors.border)),
      ],
    );
  }
}
