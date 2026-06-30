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
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      l10n.rankTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.gold, letterSpacing: 2),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  _filterBtn(l10n.rankAll, null),
                  _filterBtn(l10n.tierBronze, 'Bronz', AppColors.darkOrange),
                  _filterBtn(l10n.tierSilver, 'Gümüş', AppColors.silver),
                  _filterBtn(l10n.tierGold, 'Altın', AppColors.gold),
                  _filterBtn(l10n.tierDiamond, 'Elmas', AppColors.fieldBlue),
                  _filterBtn(l10n.tierMaster, 'Usta', AppColors.brandBlue),
                  _filterBtn(l10n.tierLegend, 'Efsane', AppColors.red),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.green))
                  : list.isEmpty
                      ? Center(
                          child: Text(
                            _loadError ?? 'Bu ligde oyuncu yok',
                            style: const TextStyle(color: AppColors.textMuted),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (_, i) {
                            final p = list[i];
                            final tier = RankTier.forElo(p.elo);
                            final isMe = p.uid == myUid;
                            return Container(
                              color: isMe ? AppColors.green.withValues(alpha: 0.06) : null,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 26,
                                    child: Text(
                                      i == 0 ? '1' : i == 1 ? '2' : i == 2 ? '3' : '${i + 1}',
                                      style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textFaint),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(width: 9),
                                  Expanded(
                                    child: Text(
                                      '${p.name}${isMe ? ' (SEN)' : ''}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: isMe ? AppColors.green : AppColors.silver,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text('${p.wins}G ${p.losses}M', style: const TextStyle(fontSize: 10, color: AppColors.textFaint)),
                                  const SizedBox(width: 10),
                                  Text('${p.elo}', style: TextStyle(fontWeight: FontWeight.w900, color: tier.color, fontSize: 13)),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterBtn(String label, String? league, [Color? color]) {
    final on = _filter == league;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() => _filter = league),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: on ? AppColors.cardElevated : AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: on ? AppColors.textFaint : AppColors.cardElevated),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color ?? (on ? Colors.white : AppColors.textMuted),
            ),
          ),
        ),
      ),
    );
  }
}
