import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/career_opponent.dart';
import '../models/career_result.dart';
import '../models/rank_tier.dart';
import 'meta_api.dart';

class CareerService extends ChangeNotifier {
  int careerPoints = 0;
  int careerWins = 0;
  int careerLosses = 0;
  int currentLeagueIndex = 0;
  final Set<String> _defeatedIds = {};

  static const _key = 'pucket_career';

  RankTier get currentLeague =>
      RankTier.tiers[currentLeagueIndex.clamp(0, RankTier.tiers.length - 1)];

  int get defeatedCount => _defeatedIds.length;
  int get totalOpponents => careerOpponents.length;
  bool get careerComplete => _defeatedIds.length >= careerOpponents.length;

  Set<String> get defeatedIds => Set.unmodifiable(_defeatedIds);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      notifyListeners();
      return;
    }
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      careerPoints = (j['points'] as num?)?.toInt() ?? 0;
      careerWins = (j['wins'] as num?)?.toInt() ?? 0;
      careerLosses = (j['losses'] as num?)?.toInt() ?? 0;
      currentLeagueIndex = (j['league'] as num?)?.toInt() ?? 0;
      final ids = j['defeated'] as List?;
      _defeatedIds
        ..clear()
        ..addAll(ids?.map((e) => e.toString()) ?? const []);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'points': careerPoints,
        'wins': careerWins,
        'losses': careerLosses,
        'league': currentLeagueIndex,
        'defeated': _defeatedIds.toList(),
      }),
    );
  }

  bool isDefeated(String id) => _defeatedIds.contains(id);

  bool isUnlocked(CareerOpponent opponent) {
    if (opponent.leagueIndex < currentLeagueIndex) return true;
    if (opponent.leagueIndex > currentLeagueIndex) return false;
    final leagueOps = opponentsInLeague(opponent.leagueIndex);
    final idx = leagueOps.indexWhere((o) => o.id == opponent.id);
    if (idx <= 0) return true;
    return _defeatedIds.contains(leagueOps[idx - 1].id);
  }

  CareerOpponent? nextOpponent() {
    for (final o in careerOpponents) {
      if (!isDefeated(o.id) && isUnlocked(o)) return o;
    }
    return null;
  }

  int leagueProgress(int leagueIndex) {
    final ops = opponentsInLeague(leagueIndex);
    return ops.where((o) => _defeatedIds.contains(o.id)).length;
  }

  Future<CareerMatchResult> recordResult({
    required CareerOpponent opponent,
    required bool won,
    String? uid,
  }) async {
    var pointsEarned = 0;
    var firstTimeWin = false;
    var promoted = false;

    if (won) {
      careerWins++;
      if (!_defeatedIds.contains(opponent.id)) {
        firstTimeWin = true;
        _defeatedIds.add(opponent.id);
        pointsEarned = opponent.pointsReward;
        careerPoints += pointsEarned;

        final leagueOps = opponentsInLeague(opponent.leagueIndex);
        final leagueDone = leagueOps.every((o) => _defeatedIds.contains(o.id));
        if (leagueDone &&
            opponent.leagueIndex == currentLeagueIndex &&
            currentLeagueIndex < RankTier.tiers.length - 1) {
          currentLeagueIndex++;
          promoted = true;
        }
      }
    } else {
      careerLosses++;
    }

    await _save();
    if (uid != null) await syncToCloud(uid);
    notifyListeners();

    return CareerMatchResult(
      won: won,
      pointsEarned: pointsEarned,
      firstTimeWin: firstTimeWin,
      promoted: promoted,
      newLeague: currentLeague,
      opponent: opponent,
      totalCareerPoints: careerPoints,
      careerComplete: careerComplete,
    );
  }

  Future<void> syncFromCloud(String uid) async {
    final remote = await MetaApi.fetchCareer(uid);
    if (remote == null || remote.isEmpty) {
      await syncToCloud(uid);
      return;
    }
    try {
      careerPoints = (remote['points'] as num?)?.toInt() ?? careerPoints;
      careerWins = (remote['wins'] as num?)?.toInt() ?? careerWins;
      careerLosses = (remote['losses'] as num?)?.toInt() ?? careerLosses;
      currentLeagueIndex = (remote['league'] as num?)?.toInt() ?? currentLeagueIndex;
      final ids = remote['defeated'] as List?;
      if (ids != null) {
        _defeatedIds
          ..clear()
          ..addAll(ids.map((e) => e.toString()));
      }
      await _save();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> syncToCloud(String uid) async {
    await MetaApi.saveCareer(uid, {
      'points': careerPoints,
      'wins': careerWins,
      'losses': careerLosses,
      'league': currentLeagueIndex,
      'defeated': _defeatedIds.toList(),
    });
  }

  Map<String, dynamic> toCloudJson() => {
        'points': careerPoints,
        'wins': careerWins,
        'losses': careerLosses,
        'league': currentLeagueIndex,
        'defeated': _defeatedIds.toList(),
      };
}
