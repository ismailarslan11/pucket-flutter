import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../models/rank_tier.dart';
import '../services/auth_service.dart';
import '../services/match_api.dart';
import '../services/player_meta_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pucket_button.dart';

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
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        backgroundColor: AppColors.bg,
      ),
      body: user == null
          ? Center(child: Text(l10n.profileEmpty))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.green.withValues(alpha: 0.2),
                        backgroundImage:
                            user.photoUrl != null && user.photoUrl!.isNotEmpty
                                ? NetworkImage(user.photoUrl!)
                                : null,
                        child: user.photoUrl == null || user.photoUrl!.isEmpty
                            ? Text(
                                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                  color: AppColors.green,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                            Text('${tier.emoji} ${l10n.tierName(tier)} • ${user.elo} ELO',
                                style: TextStyle(color: tier.color, fontSize: 12)),
                            Text('${user.wins}${l10n.winsLosses} ${user.losses}M • ${user.matches}',
                                style: const TextStyle(color: Color(0xFF666666), fontSize: 11)),
                            if (meta.season != null)
                              Text(
                                '${l10n.seasonLabel(meta.season!.name)} · ${meta.meta?.seasonWins ?? 0} ${l10n.seasonWins}',
                                style: const TextStyle(color: AppColors.gold, fontSize: 10),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(l10n.achievements, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (meta.meta?.achievements ?? []).isEmpty
                      ? [
                          Chip(
                            label: Text(l10n.questInProgress, style: const TextStyle(fontSize: 11)),
                            backgroundColor: AppColors.card,
                          ),
                        ]
                      : meta.meta!.achievements.map((id) {
                          final label = PlayerMetaService.achievementLabels[id] ?? id;
                          return Chip(
                            label: Text(label, style: const TextStyle(fontSize: 11)),
                            backgroundColor: AppColors.card,
                            side: const BorderSide(color: AppColors.green),
                          );
                        }).toList(),
                ),
                const SizedBox(height: 20),
                Text(l10n.matchHistory, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 12)),
                const SizedBox(height: 10),
                if (_loading)
                  const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                else if (_history.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(l10n.noHistory, style: const TextStyle(color: Color(0xFF666666), height: 1.4)),
                  )
                else
                  ..._history.map((m) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Text(m.won ? '✅' : '❌', style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('vs ${m.opponent}',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                  Text(
                                    '${m.ranked ? l10n.rankedLabel : l10n.casualLabel}${m.timestamp > 0 ? ' · ${_formatTime(m.timestamp)}' : ''}',
                                    style: const TextStyle(color: Color(0xFF555555), fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${m.eloChange >= 0 ? '+' : ''}${m.eloChange}',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: m.eloChange >= 0 ? AppColors.green : AppColors.red,
                              ),
                            ),
                          ],
                        ),
                      )),
                const SizedBox(height: 16),
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
    );
  }
}
