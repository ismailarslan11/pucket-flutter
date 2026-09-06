import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n_extension.dart';
import '../models/career_opponent.dart';
import '../models/rank_tier.dart';
import '../services/career_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pucket_button.dart';
import '../widgets/yesa_background.dart';
import '../widgets/yesa_effects.dart';
import '../widgets/yesa_menu_tile.dart';
import 'app_router.dart';

class CareerScreen extends StatelessWidget {
  const CareerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final career = context.watch<CareerService>();
    final l10n = context.l10n;
    final tier = career.currentLeague;
    final next = career.nextOpponent();
    final leagueTotal = opponentsInLeague(career.currentLeagueIndex).length;
    final leagueDone = career.leagueProgress(career.currentLeagueIndex);

    var staggerCounter = 6;
    final leagueWidgets = <Widget>[];
    for (var i = 0; i < RankTier.tiers.length; i++) {
      leagueWidgets.add(_LeagueSection(
        leagueIndex: i,
        career: career,
        l10n: l10n,
        onFight: (o) => AppRouter.startCareer(context, o),
        staggerStart: staggerCounter,
      ));
      staggerCounter += opponentsInLeague(i).length + 1;
    }

    return Scaffold(
      body: YesaBackground(
        warm: true,
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(l10n: l10n),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    StaggerIn(
                      index: 0,
                      child: _SummaryCard(
                        career: career,
                        tier: tier,
                        leagueDone: leagueDone,
                        leagueTotal: leagueTotal,
                        l10n: l10n,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (career.careerComplete)
                      StaggerIn(
                        index: 1,
                        child: YesaRibbon(text: l10n.careerComplete, icon: Icons.military_tech_rounded),
                      )
                    else if (next != null) ...[
                      StaggerIn(
                        index: 1,
                        child: YesaRibbon(text: l10n.careerNextOpponent, icon: Icons.sports_hockey_rounded),
                      ),
                      const SizedBox(height: 10),
                      StaggerIn(index: 2, child: _NextMatchCard(next: next, l10n: l10n)),
                      const SizedBox(height: 10),
                      StaggerIn(
                        index: 3,
                        child: PucketButton(
                          label: l10n.playWith(next.name),
                          width: double.infinity,
                          gradient: LinearGradient(colors: [tier.color, AppColors.sariAna]),
                          onPressed: () => AppRouter.startCareer(context, next),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    StaggerIn(index: 4, child: _SeasonProgressBar(career: career)),
                    const SizedBox(height: 14),
                    StaggerIn(index: 5, child: _StatRow(career: career)),
                    const SizedBox(height: 20),
                    ...leagueWidgets,
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 16, 4),
      child: Row(
        children: [
          ScalePress(
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                AppRouter.goMenu(context);
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.neonPurple,
                border: Border.all(color: AppColors.beyaz.withValues(alpha: 0.3)),
                boxShadow: AppShadows.depth(AppColors.laciDerin),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: AppColors.beyaz, size: 20),
            ),
          ),
          Expanded(
            child: Text(
              l10n.careerTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: AppColors.beyaz,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.career,
    required this.tier,
    required this.leagueDone,
    required this.leagueTotal,
    required this.l10n,
  });

  final CareerService career;
  final RankTier tier;
  final int leagueDone;
  final int leagueTotal;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final progress = leagueTotal == 0 ? 1.0 : leagueDone / leagueTotal;

    return GlowPulse(
      color: tier.color,
      min: 0.12,
      max: 0.35,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: YesaDecor.card(radius: 24, borderColor: tier.color.withValues(alpha: 0.5)),
        child: Row(
          children: [
            _LeagueRing(progress: progress, done: leagueDone, total: leagueTotal, color: tier.color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.careerTitle,
                    style: AppTextStyles.label.copyWith(color: AppColors.textMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.tierName(tier).toUpperCase(),
                    style: AppTextStyles.glow(tier.color).copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _Badge(
                        icon: Icons.emoji_events_rounded,
                        text: '${career.careerPoints} ${l10n.careerPointsShort}',
                        gradient: AppGradients.heroPlay,
                      ),
                      _Badge(
                        icon: Icons.check_circle_rounded,
                        text: '${career.careerWins}${l10n.winsShort} ${career.careerLosses}${l10n.lossesShort}',
                        gradient: AppGradients.neonPurple,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeagueRing extends StatelessWidget {
  const _LeagueRing({
    required this.progress,
    required this.done,
    required this.total,
    required this.color,
  });

  final double progress;
  final int done;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: CircularProgressIndicator(
              value: progress.clamp(0, 1),
              strokeWidth: 6,
              backgroundColor: AppColors.borderSubtle,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$done',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.beyaz),
              ),
              Text(
                '/$total',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.text, required this.gradient});

  final IconData icon;
  final String text;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.beyaz.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.laciDerin),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(color: AppColors.laciDerin, fontWeight: FontWeight.w900, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _NextMatchCard extends StatelessWidget {
  const _NextMatchCard({required this.next, required this.l10n});

  final CareerOpponent next;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final tier = next.league;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        gradient: AppGradients.glassCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neonYesil.withValues(alpha: 0.75), width: 2),
        boxShadow: AppShadows.neon(AppColors.neonYesil, blur: 14),
      ),
      child: Column(
        children: [
          Text(
            l10n.tierName(tier).toUpperCase(),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _VsSide(label: l10n.youLabel, color: AppColors.sariAna, icon: Icons.person_rounded),
              Text('VS', style: AppTextStyles.glow(AppColors.beyaz).copyWith(fontSize: 20)),
              _VsSide(label: next.name, color: tier.color, icon: Icons.smart_toy_rounded),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${l10n.difficultyLabel(next.aiLevel.name)} · ${next.displayElo} ELO · +${next.pointsReward} KP',
            style: const TextStyle(color: AppColors.textDim, fontSize: 11, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _VsSide extends StatelessWidget {
  const _VsSide({required this.label, required this.color, required this.icon});

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.18),
            border: Border.all(color: color, width: 2),
            boxShadow: AppShadows.neon(color, blur: 10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 84,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.beyaz),
          ),
        ),
      ],
    );
  }
}

class _SeasonProgressBar extends StatelessWidget {
  const _SeasonProgressBar({required this.career});

  final CareerService career;

  @override
  Widget build(BuildContext context) {
    final total = career.totalOpponents;
    final done = career.defeatedCount;
    final progress = total == 0 ? 0.0 : done / total;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: YesaDecor.card(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.careerProgressTitle,
                style: AppTextStyles.label.copyWith(color: AppColors.buzMavi, letterSpacing: 1.2),
              ),
              Text(
                '$done/$total',
                style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 10,
              backgroundColor: AppColors.borderSubtle,
              valueColor: const AlwaysStoppedAnimation(AppColors.sariAna),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.career});

  final CareerService career;

  @override
  Widget build(BuildContext context) {
    final total = career.totalOpponents;
    final wins = career.careerWins;
    final losses = career.careerLosses;
    final played = wins + losses;
    final accuracy = played == 0 ? 0 : ((wins / played) * 100).round();

    return Row(
      children: [
        Expanded(
          child: _StatTile(icon: Icons.flag_rounded, value: '$total', label: context.l10n.careerOpponents, color: AppColors.gokAcik),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.check_circle_rounded,
            value: '$wins',
            label: context.l10n.careerWins,
            color: AppColors.neonYesil,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(icon: Icons.close_rounded, value: '$losses', label: context.l10n.careerLosses, color: AppColors.kirmizi),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(icon: Icons.percent_rounded, value: '$accuracy%', label: context.l10n.careerAccuracy, color: AppColors.sariAna),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.value, required this.label, required this.color});

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: YesaDecor.card(radius: 16, borderColor: color.withValues(alpha: 0.35)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.beyaz)),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _LeagueSection extends StatelessWidget {
  const _LeagueSection({
    required this.leagueIndex,
    required this.career,
    required this.l10n,
    required this.onFight,
    required this.staggerStart,
  });

  final int leagueIndex;
  final CareerService career;
  final AppLocalizations l10n;
  final void Function(CareerOpponent) onFight;
  final int staggerStart;

  @override
  Widget build(BuildContext context) {
    final tier = RankTier.tiers[leagueIndex];
    final tierLabel = l10n.tierName(tier);
    final opponents = opponentsInLeague(leagueIndex);
    final progress = career.leagueProgress(leagueIndex);
    final locked = leagueIndex > career.currentLeagueIndex;
    final nextId = career.nextOpponent()?.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaggerIn(
            index: staggerStart,
            delayMs: 25,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: locked ? AppColors.textFaint : tier.color,
                    boxShadow: locked ? null : AppShadows.neon(tier.color, blur: 6),
                  ),
                ),
                Text(
                  tierLabel.toUpperCase(),
                  style: TextStyle(
                    color: locked ? AppColors.textFaint : tier.color,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Text(
                  locked ? 'Kilitli' : '$progress/${opponents.length}',
                  style: TextStyle(
                    color: locked ? AppColors.textFaint : AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < opponents.length; i++)
            _OpponentCard(
              opponent: opponents[i],
              l10n: l10n,
              locked: locked || !career.isUnlocked(opponents[i]),
              defeated: career.isDefeated(opponents[i].id),
              isNext: nextId == opponents[i].id,
              onFight: () => onFight(opponents[i]),
              staggerIndex: staggerStart + 1 + i,
            ),
        ],
      ),
    );
  }
}

class _OpponentCard extends StatelessWidget {
  const _OpponentCard({
    required this.opponent,
    required this.l10n,
    required this.locked,
    required this.defeated,
    required this.isNext,
    required this.onFight,
    required this.staggerIndex,
  });

  final CareerOpponent opponent;
  final AppLocalizations l10n;
  final bool locked;
  final bool defeated;
  final bool isNext;
  final VoidCallback onFight;
  final int staggerIndex;

  @override
  Widget build(BuildContext context) {
    final tier = opponent.league;
    final canPlay = !locked;

    Widget card = Opacity(
      opacity: locked ? 0.4 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          gradient: defeated
              ? LinearGradient(colors: [tier.color.withValues(alpha: 0.18), AppColors.cardElevated])
              : AppGradients.glassCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isNext
                ? AppColors.neonYesil
                : defeated
                    ? tier.color.withValues(alpha: 0.5)
                    : AppColors.borderSubtle,
            width: isNext ? 2 : 1.2,
          ),
          boxShadow: isNext ? AppShadows.neon(AppColors.neonYesil, blur: 10) : null,
        ),
        child: ScalePress(
          onTap: canPlay ? onFight : null,
          scale: 0.97,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tier.color.withValues(alpha: 0.16),
                    border: Border.all(color: tier.color.withValues(alpha: 0.7), width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: defeated
                      ? const Icon(Icons.check_rounded, color: AppColors.neonYesil, size: 20)
                      : Text(
                          opponent.name.isNotEmpty ? opponent.name[0] : '?',
                          style: TextStyle(fontWeight: FontWeight.w900, color: tier.color),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opponent.name,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.beyaz),
                      ),
                      Text(
                        '${l10n.difficultyLabel(opponent.aiLevel.name)} · ${opponent.displayElo} ELO · +${opponent.pointsReward} KP',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (locked)
                  const Icon(Icons.lock_rounded, color: AppColors.textFaint, size: 18)
                else if (defeated)
                  Text(
                    l10n.replay,
                    style: const TextStyle(color: AppColors.textDim, fontSize: 10, fontWeight: FontWeight.w700),
                  )
                else
                  Icon(Icons.chevron_right_rounded, color: isNext ? AppColors.neonYesil : AppColors.textDim),
              ],
            ),
          ),
        ),
      ),
    );

    if (isNext) {
      card = GlowPulse(color: AppColors.neonYesil, min: 0.15, max: 0.4, child: card);
    }

    return StaggerIn(index: staggerIndex, delayMs: 20, child: card);
  }
}
