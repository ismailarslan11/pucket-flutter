import 'package:flutter/foundation.dart';

import 'meta_api.dart';

class PlayerMetaService extends ChangeNotifier {
  PlayerMeta? meta;
  SeasonInfo? season;
  List<TournamentEntry> tournament = [];
  bool loading = false;
  String? lastMessage;

  static const achievementLabels = {
    'first_win': '🏆 İlk Galibiyet',
    'ten_wins': '🔥 10 Galibiyet',
    'career_start': '🎯 Kariyer Başlangıcı',
    'training_done': '🏋️ Antrenman',
    'streak_3': '📅 3 Gün Seri',
    'streak_7': '⭐ 7 Gün Seri',
    'tournament_join': '🏅 Turnuva',
  };

  Future<void> load(String uid, {String name = ''}) async {
    loading = true;
    notifyListeners();
    await MetaApi.registerPlayer(uid, name.isNotEmpty ? name : 'Oyuncu');
    meta = await MetaApi.fetchMeta(uid, name: name);
    season = await MetaApi.fetchSeason();
    tournament = await MetaApi.fetchTournament();
    loading = false;
    notifyListeners();
  }

  Future<void> onMatchPlayed(String uid, {required bool won, required bool ranked}) async {
    // Görev ilerlemesi sunucuda matchEnd ile güncellenir
    await load(uid);
  }

  Future<void> onCareerWin(String uid) async {
    await load(uid);
  }

  Future<bool> claimDailyReward(String uid) async {
    final reward = await MetaApi.claimQuests(uid);
    if (reward == null) {
      lastMessage = 'Görevler tamamlanmadı veya ödül alındı';
      notifyListeners();
      return false;
    }
    lastMessage = '+$reward KP ödülü alındı!';
    await load(uid);
    return true;
  }

  Future<void> setCosmetics(String uid, Map<String, String> cosmetics) async {
    await MetaApi.saveCosmetics(uid, cosmetics);
    await load(uid);
  }

  Future<bool> joinTournament(String uid, String name) async {
    final ok = await MetaApi.joinTournament(uid, name);
    if (ok) await load(uid);
    return ok;
  }

  Future<void> saveFcmToken(String uid, String token) async {
    await MetaApi.saveFcmToken(uid, token);
  }

  String discColor(String uid) => meta?.cosmetics['discColor'] ?? 'green';
  String boardTheme(String uid) => meta?.cosmetics['boardTheme'] ?? 'classic';
}
