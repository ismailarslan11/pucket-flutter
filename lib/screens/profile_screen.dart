import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/rank_tier.dart';
import '../services/auth_service.dart';
import '../services/match_api.dart';
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
  String? _error;

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
      _error = history.isEmpty ? null : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;
    final tier = user != null ? RankTier.forElo(user.elo) : RankTier.tiers.first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PROFİL'),
        backgroundColor: AppColors.bg,
      ),
      body: user == null
          ? const Center(child: Text('Profil yok'))
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
                            Text('${tier.emoji} ${tier.name} • ${user.elo} ELO',
                                style: TextStyle(color: tier.color, fontSize: 12)),
                            Text('${user.wins}G / ${user.losses}M • ${user.matches} maç',
                                style: const TextStyle(color: Color(0xFF666666), fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('SON MAÇLAR', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 12)),
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
                    child: Text(
                      _error ?? 'Henüz maç geçmişi yok.\nRanked oyna veya sunucuya bağlan.',
                      style: const TextStyle(color: Color(0xFF666666), height: 1.4),
                    ),
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
                                    m.ranked ? 'Ranked' : 'Casual',
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
                  label: 'YENİLE',
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
