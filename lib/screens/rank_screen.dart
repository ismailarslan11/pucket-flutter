import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../models/rank_tier.dart';
import '../models/user_profile.dart';
import '../services/api_config.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/yesa_background.dart';
import '../widgets/yesa_effects.dart';

class RankScreen extends StatefulWidget {
  const RankScreen({super.key});

  @override
  State<RankScreen> createState() => _RankScreenState();
}

class _RankScreenState extends State<RankScreen> {
  List<UserProfile> _leaderboard = [];
  bool _loading = true;
  String? _filter;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final res = await http
          .get(Uri.parse('$apiBaseUrl/leaderboard'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        _leaderboard = list
            .map((e) => UserProfile.fromServer(e as Map<String, dynamic>))
            .toList();
      } else {
        _loadError = 'Sunucu yanıt vermedi (${res.statusCode})';
      }
    } catch (_) {
      _loadError = 'Sıralama yüklenemedi';
    }
    if (mounted) setState(() => _loading = false);
  }

  List<UserProfile> get _filtered {
    if (_filter == null) return _leaderboard;
    return _leaderboard.where((p) => p.league == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final l10n = context.l10n;
    final myUid = auth.getUid();
    final list = _filtered;

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
                        l10n.rankTitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.glow(AppColors.sariAna).copyWith(fontSize: 18, letterSpacing: 2),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 40,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      _filterBtn(l10n.rankAll, null),
                      _filterBtn(l10n.tierBronze, 'Bronz', AppColors.turuncuKoyu),
                      _filterBtn(l10n.tierSilver, 'Gümüş', AppColors.lavanta),
                      _filterBtn(l10n.tierGold, 'Altın', AppColors.sariAna),
                      _filterBtn(l10n.tierDiamond, 'Elmas', AppColors.acikMor),
                      _filterBtn(l10n.tierMaster, 'Usta', AppColors.vurguMoru),
                      _filterBtn(l10n.tierLegend, 'Efsane', AppColors.turuncuAna),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.sariAna))
                    : list.isEmpty
                        ? Center(
                            child: Text(
                              _loadError ?? 'Bu ligde oyuncu yok',
                              style: const TextStyle(color: AppColors.textMuted),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                            itemCount: list.length,
                            itemBuilder: (_, i) {
                              final p = list[i];
                              final tier = RankTier.forElo(p.elo);
                              final isMe = p.uid == myUid;
                              return StaggerIn(
                                index: i % 8,
                                delayMs: 30,
                                child: _RankRow(rank: i + 1, profile: p, tier: tier, isMe: isMe),
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

  Widget _filterBtn(String label, String? league, [Color? color]) {
    final on = _filter == league;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ScalePress(
        onTap: () => setState(() => _filter = league),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: on ? AppGradients.neonPurple : null,
            color: on ? null : AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: on ? AppColors.beyaz.withValues(alpha: 0.35) : AppColors.borderSubtle),
            boxShadow: on ? AppShadows.neon(AppColors.acikMor, blur: 8) : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color ?? (on ? AppColors.beyaz : AppColors.textMuted),
            ),
          ),
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.rank, required this.profile, required this.tier, required this.isMe});

  final int rank;
  final UserProfile profile;
  final RankTier tier;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final isPodium = rank <= 3;
    final podiumColor = rank == 1
        ? AppColors.sariAna
        : rank == 2
            ? AppColors.pusluBeyaz
            : AppColors.turuncuAna;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        gradient: AppGradients.glassCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe ? AppColors.neonYesil : AppColors.borderSubtle,
          width: isMe ? 2 : 1,
        ),
        boxShadow: isMe ? AppShadows.neon(AppColors.neonYesil, blur: 8) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: isPodium
                ? Icon(Icons.emoji_events_rounded, color: podiumColor, size: 20)
                : Text(
                    '$rank',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textFaint),
                    textAlign: TextAlign.center,
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${profile.name}${isMe ? ' (SEN)' : ''}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isMe ? AppColors.neonYesil : AppColors.beyaz,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${profile.wins}G ${profile.losses}M',
            style: const TextStyle(fontSize: 10, color: AppColors.textFaint, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: tier.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tier.color.withValues(alpha: 0.6)),
            ),
            child: Text(
              '${profile.elo}',
              style: TextStyle(fontWeight: FontWeight.w900, color: tier.color, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
