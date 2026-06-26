import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../services/auth_service.dart';
import '../services/player_meta_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pucket_button.dart';

class TournamentScreen extends StatefulWidget {
  const TournamentScreen({super.key});

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  bool _joining = false;

  @override
  Widget build(BuildContext context) {
    final meta = context.watch<PlayerMetaService>();
    final auth = context.watch<AuthService>();
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.menuTournament),
        backgroundColor: AppColors.bg,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l10n.tournamentDesc,
            style: const TextStyle(color: Color(0xFF888888), height: 1.5),
          ),
          const SizedBox(height: 16),
          PucketButton(
            label: _joining ? '...' : l10n.tournamentJoin,
            onPressed: _joining
                ? () {}
                : () async {
                    setState(() => _joining = true);
                    await meta.joinTournament(auth.getUid(), auth.getName());
                    if (mounted) setState(() => _joining = false);
                  },
          ),
          const SizedBox(height: 20),
          Text(l10n.tournamentLeaderboard, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 12)),
          const SizedBox(height: 10),
          if (meta.tournament.isEmpty)
            Text(l10n.tournamentEmpty, style: const TextStyle(color: Color(0xFF666666)))
          else
            ...meta.tournament.asMap().entries.map((e) {
              final i = e.key;
              final t = e.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Text('${i + 1}.', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                    Text('${t.points} ${l10n.points}', style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w800)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
