import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../models/rank_tier.dart';
import '../services/auth_service.dart';
import '../services/match_api.dart';
import '../services/player_meta_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pucket_button.dart';
import '../widgets/yesa_background.dart';
import '../widgets/yesa_effects.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<MatchRecord> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = context.read<AuthService>().getUid();
    final history = await MatchApi.fetchHistory(uid);
    if (!mounted) return;
    setState(() {
      _history = history;
      _loading = false;
    });
  }

  String _formatTime(int ts) {
    if (ts <= 0) return '';
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    return '${d.day}.${d.month}.${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final meta = context.watch<PlayerMetaService>();
    final user = auth.user;
    final l10n = context.l10n;
    final tier = user != null ? RankTier.forElo(user.elo) : RankTier.tiers.first;

    return Scaffold(
      body: YesaBackground(
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
                        l10n.profileTitle,
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
              ),
              Expanded(
                child: user == null
                    ? Center(
                        child: Text(l10n.profileEmpty, style: const TextStyle(color: AppColors.textMuted)),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        children: [
                          StaggerIn(
                            index: 0,
                            child: GlowPulse(
                              color: tier.color,
                              min: 0.15,
                              max: 0.4,
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: YesaDecor.card(radius: 24, borderColor: tier.color.withValues(alpha: 0.5)),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 62,
                                      height: 62,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: AppGradients.heroPlay,
                                        border: Border.all(color: AppColors.beyaz.withValues(alpha: 0.55), width: 2),
                                        boxShadow: AppShadows.neon(AppColors.sariAna, blur: 10),
                                      ),
                                      alignment: Alignment.center,
                                      child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                                          ? ClipOval(
                                              child: Image.network(
                                                user.photoUrl!,
                                                width: 58,
                                                height: 58,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Text(
                                              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 24,
                                                color: AppColors.morDahaKoyu,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user.name,
                                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.beyaz),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${l10n.tierName(tier)} · ${user.elo} ELO',
                                            style: AppTextStyles.glow(tier.color).copyWith(fontSize: 12),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${user.wins}${l10n.winsLosses} ${user.losses}M · ${user.matches}',
                                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                                          ),
                                          if (meta.season != null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text(
                                                '${l10n.seasonLabel(meta.season!.name)} · ${meta.meta?.seasonWins ?? 0} ${l10n.seasonWins}',
                                                style: const TextStyle(color: AppColors.sariAna, fontSize: 10, fontWeight: FontWeight.w700),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          StaggerIn(
                            index: 1,
                            child: Text(
                              l10n.achievements.toUpperCase(),
                              style: AppTextStyles.label.copyWith(color: AppColors.lavanta, letterSpacing: 1.4),
                            ),
                          ),
                          const SizedBox(height: 10),
                          StaggerIn(
                            index: 2,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: (meta.meta?.achievements ?? []).isEmpty
                                  ? [_AchievementChip(label: l10n.questInProgress, done: false)]
                                  : meta.meta!.achievements.map((id) {
                                      final label = PlayerMetaService.achievementLabels[id] ?? id;
                                      return _AchievementChip(label: label, done: true);
                                    }).toList(),
                            ),
                          ),
                          const SizedBox(height: 22),
                          StaggerIn(
                            index: 3,
                            child: Text(
                              l10n.matchHistory.toUpperCase(),
                              style: AppTextStyles.label.copyWith(color: AppColors.lavanta, letterSpacing: 1.4),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_loading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: CircularProgressIndicator(color: AppColors.sariAna),
                              ),
                            )
                          else if (_history.isEmpty)
                            StaggerIn(
                              index: 4,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: YesaDecor.card(radius: 16),
                                child: Text(
                                  l10n.noHistory,
                                  style: const TextStyle(color: AppColors.textMuted, height: 1.4),
                                ),
                              ),
                            )
                          else
                            for (var i = 0; i < _history.length; i++)
                              StaggerIn(
                                index: 4 + (i % 8),
                                delayMs: 30,
                                child: _MatchRow(record: _history[i], timeLabel: _formatTime(_history[i].timestamp)),
                              ),
                          const SizedBox(height: 18),
                          PucketButton(
                            label: l10n.refresh,
                            secondary: true,
                            onPressed: () {
                              setState(() => _loading = true);
                              _load();
                            },
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

class _AchievementChip extends StatelessWidget {
  const _AchievementChip({required this.label, required this.done});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: done ? AppGradients.neonPurple : null,
        color: done ? null : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: done ? AppColors.beyaz.withValues(alpha: 0.35) : AppColors.borderSubtle),
        boxShadow: done ? AppShadows.neon(AppColors.acikMor, blur: 6) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (done) const Icon(Icons.emoji_events_rounded, size: 13, color: AppColors.beyaz),
          if (done) const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: done ? AppColors.beyaz : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({required this.record, required this.timeLabel});

  final MatchRecord record;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = record.won ? AppColors.neonYesil : AppColors.kirmizi;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppGradients.glassCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.18),
              border: Border.all(color: color, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              record.won ? 'G' : 'M',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'vs ${record.opponent}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.beyaz),
                ),
                Text(
                  '${record.ranked ? l10n.rankedLabel : l10n.casualLabel}${record.timestamp > 0 ? ' · $timeLabel' : ''}',
                  style: const TextStyle(color: AppColors.textDim, fontSize: 10),
                ),
              ],
            ),
          ),
          Text(
            '${record.eloChange >= 0 ? '+' : ''}${record.eloChange}',
            style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
