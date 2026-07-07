import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../services/auth_service.dart';
import '../services/meta_api.dart';
import '../theme/app_theme.dart';
import '../widgets/yesa_background.dart';
import '../widgets/yesa_effects.dart';

class TournamentScreen extends StatefulWidget {
  const TournamentScreen({super.key});

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  List<TournamentEntry> _board = [];
  bool _loading = true;
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final board = await MetaApi.fetchTournament();
    if (!mounted) return;
    setState(() {
      _board = board;
      _loading = false;
    });
  }

  Future<void> _join() async {
    if (_joining) return;
    setState(() => _joining = true);
    final auth = context.read<AuthService>();
    final l10n = context.l10n;
    await MetaApi.joinTournament(auth.getUid(), auth.getName());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.tournamentJoined)));
    setState(() => _joining = false);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const prizes = [300, 150, 75];
    final medalColors = [AppColors.sariAna, AppColors.pusluBeyaz, AppColors.turuncuAna];
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
                        l10n.tournament,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.glow(AppColors.sariAna).copyWith(fontSize: 18, letterSpacing: 2),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: YesaDecor.card(radius: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.tournamentPrizes.toUpperCase(),
                          style: AppTextStyles.label.copyWith(color: AppColors.lavanta, letterSpacing: 1.2)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (var i = 0; i < prizes.length; i++) ...[
                            Icon(Icons.emoji_events_rounded, color: medalColors[i], size: 18),
                            const SizedBox(width: 3),
                            Text('${prizes[i]}',
                                style: const TextStyle(
                                    color: AppColors.beyaz, fontWeight: FontWeight.w900, fontSize: 13)),
                            const SizedBox(width: 14),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.tournamentDesc,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.4)),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ScalePress(
                          onTap: _join,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: AppGradients.heroPlay,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: AppShadows.neon(AppColors.sariAna, blur: 10),
                            ),
                            child: Text(_joining ? '...' : l10n.tournamentJoin,
                                style: const TextStyle(
                                    color: AppColors.morDahaKoyu, fontWeight: FontWeight.w900, fontSize: 14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.sariAna))
                    : _board.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(l10n.tournamentEmpty,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppColors.textMuted, height: 1.5)),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                            itemCount: _board.length,
                            itemBuilder: (_, i) {
                              final e = _board[i];
                              final podium = i < 3;
                              return StaggerIn(
                                index: i % 8,
                                delayMs: 30,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                  decoration: BoxDecoration(
                                    gradient: AppGradients.glassCard,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: podium ? medalColors[i].withValues(alpha: 0.6) : AppColors.borderSubtle,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 30,
                                        child: podium
                                            ? Icon(Icons.emoji_events_rounded, color: medalColors[i], size: 20)
                                            : Text('${i + 1}',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w900, color: AppColors.textFaint)),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(e.name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.beyaz),
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                      Text('${e.points}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w900, color: AppColors.sariAna, fontSize: 14)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
