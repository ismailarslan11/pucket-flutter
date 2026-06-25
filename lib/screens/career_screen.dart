import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n_extension.dart';
import '../models/career_opponent.dart';
import '../models/rank_tier.dart';
import '../services/career_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pucket_button.dart';
import 'app_router.dart';

class CareerScreen extends StatelessWidget {
  const CareerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final career = context.watch<CareerService>();
    final l10n = context.l10n;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3),
            radius: 1.3,
            colors: [Color(0xFF2A1A4A), AppColors.bg],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _header(context, career, l10n),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: RankTier.tiers.length,
                  itemBuilder: (context, i) => _LeagueSection(
                    leagueIndex: i,
                    career: career,
                    l10n: l10n,
                    onFight: (o) => AppRouter.startCareer(context, o),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, CareerService career, AppLocalizations l10n) {
    final tier = career.currentLeague;
    final next = career.nextOpponent();
    final tierLabel = l10n.tierName(tier);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    AppRouter.goMenu(context);
                  }
                },
                icon: const Icon(Icons.arrow_back, color: Color(0xFF888888)),
              ),
              Expanded(
                child: Text(
                  l10n.careerTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statChip('⭐', '${career.careerPoints}', 'KP'),
              const SizedBox(width: 12),
              _statChip('✓', '${career.careerWins}G', '${career.careerLosses}M'),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tier.color),
                  color: tier.color.withValues(alpha: 0.12),
                ),
                child: Text(
                  '${tier.emoji} $tierLabel',
                  style: TextStyle(color: tier.color, fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
            ],
          ),
          if (career.careerComplete)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                l10n.careerComplete,
                style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            )
          else if (next != null) ...[
            const SizedBox(height: 10),
            Text(
              l10n.nextOpponent(next.name, l10n.tierName(next.league)),
              style: const TextStyle(color: Color(0xFF777777), fontSize: 11),
            ),
            const SizedBox(height: 8),
            PucketButton(
              label: l10n.playWith(next.name),
              width: 280,
              gradient: LinearGradient(colors: [tier.color, AppColors.green]),
              onPressed: () => AppRouter.startCareer(context, next),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statChip(String icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
          const SizedBox(width: 3),
          Text(label, style: const TextStyle(color: Color(0xFF555555), fontSize: 9)),
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
  });

  final int leagueIndex;
  final CareerService career;
  final AppLocalizations l10n;
  final void Function(CareerOpponent) onFight;

  @override
  Widget build(BuildContext context) {
    final tier = RankTier.tiers[leagueIndex];
    final tierLabel = l10n.tierName(tier);
    final opponents = opponentsInLeague(leagueIndex);
    final progress = career.leagueProgress(leagueIndex);
    final locked = leagueIndex > career.currentLeagueIndex;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(tier.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                tierLabel.toUpperCase(),
                style: TextStyle(
                  color: locked ? const Color(0xFF444444) : tier.color,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                locked ? '🔒' : '$progress/${opponents.length}',
                style: TextStyle(
                  color: locked ? const Color(0xFF444444) : const Color(0xFF666666),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...opponents.map((o) => _OpponentCard(
                opponent: o,
                l10n: l10n,
                locked: locked || !career.isUnlocked(o),
                defeated: career.isDefeated(o.id),
                isNext: career.nextOpponent()?.id == o.id,
                onFight: () => onFight(o),
              )),
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
  });

  final CareerOpponent opponent;
  final AppLocalizations l10n;
  final bool locked;
  final bool defeated;
  final bool isNext;
  final VoidCallback onFight;

  @override
  Widget build(BuildContext context) {
    final tier = opponent.league;
    final canPlay = !locked;

    return Opacity(
      opacity: locked ? 0.35 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isNext
                ? AppColors.green
                : defeated
                    ? tier.color.withValues(alpha: 0.5)
                    : AppColors.border,
            width: isNext ? 2 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: canPlay ? onFight : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tier.color.withValues(alpha: 0.15),
                      border: Border.all(color: tier.color.withValues(alpha: 0.6)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      defeated ? '✓' : opponent.name[0],
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: defeated ? AppColors.green : tier.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          opponent.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        Text(
                          '${l10n.difficultyLabel(opponent.aiLevel.name)} · ${opponent.displayElo} ELO · +${opponent.pointsReward} KP',
                          style: const TextStyle(color: Color(0xFF666666), fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  if (locked)
                    const Icon(Icons.lock, color: Color(0xFF444444), size: 18)
                  else if (defeated)
                    Text(l10n.replay, style: const TextStyle(color: Color(0xFF555555), fontSize: 10))
                  else
                    Icon(Icons.chevron_right, color: isNext ? AppColors.green : const Color(0xFF555555)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
