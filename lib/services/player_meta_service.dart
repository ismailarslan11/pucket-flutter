import 'package:flutter/foundation.dart';

import '../models/cosmetic_catalog.dart';
import 'meta_api.dart';

class PlayerMetaService extends ChangeNotifier {
  PlayerMeta? meta;
  SeasonInfo? season;
  bool loading = false;
  String? lastMessage;

  static const achievementLabels = {
    'first_win': 'İlk Galibiyet',
    'ten_wins': '10 Galibiyet',
    'career_start': 'Kariyer Başlangıcı',
    'training_done': 'Antrenman',
    'streak_3': '3 Gün Seri',
    'streak_7': '7 Gün Seri',
  };

  int get tokens => meta?.tokens ?? 0;
  List<String> get unlockedDiscs => meta?.unlockedDiscs ?? const [];
  List<String> get unlockedBoards => meta?.unlockedBoards ?? const [];

  Future<void> load(String uid, {String name = ''}) async {
    loading = true;
    notifyListeners();
    await MetaApi.registerPlayer(uid, name.isNotEmpty ? name : 'Oyuncu');
    meta = await MetaApi.fetchMeta(uid, name: name);
    season = await MetaApi.fetchSeason();
    loading = false;
    notifyListeners();
  }

  bool isDiscUnlocked(String id) =>
      CosmeticCatalog.freeDiscs.contains(id) || unlockedDiscs.contains(id);

  bool isBoardUnlocked(String id) =>
      CosmeticCatalog.freeBoards.contains(id) || unlockedBoards.contains(id);

  Future<void> onMatchPlayed(String uid, {required bool won, required bool ranked}) async {
    await load(uid);
  }

  Future<int?> earnWinTokens(String uid) async {
    final r = await MetaApi.earnWinTokens(uid);
    if (r.meta != null) {
      meta = r.meta;
      if (r.tokenGain != null) {
        lastMessage = '+${r.tokenGain} jeton';
      }
      notifyListeners();
      return r.tokenGain;
    }
    lastMessage = r.error;
    notifyListeners();
    return null;
  }

  Future<int?> rewardAdTokens(String uid) async {
    final r = await MetaApi.rewardAdTokens(uid);
    if (r.meta != null) {
      meta = r.meta;
      if (r.tokenGain != null) {
        lastMessage = '+${r.tokenGain} jeton';
      }
      notifyListeners();
      return r.tokenGain;
    }
    lastMessage = r.error;
    notifyListeners();
    return null;
  }

  Future<bool> purchaseCosmetic(
    String uid, {
    required String itemType,
    required String itemId,
  }) async {
    final r = await MetaApi.purchaseCosmetic(uid, itemType: itemType, itemId: itemId);
    if (r.meta != null) {
      meta = r.meta;
      lastMessage = 'Satın alındı';
      notifyListeners();
      return true;
    }
    lastMessage = r.error ?? 'Satın alınamadı';
    notifyListeners();
    return false;
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

  Future<void> saveFcmToken(String uid, String token) async {
    await MetaApi.saveFcmToken(uid, token);
  }

  String discColor(String uid) => meta?.cosmetics['discColor'] ?? 'green';
  String boardTheme(String uid) => meta?.cosmetics['boardTheme'] ?? 'classic';

  int previewWinTokens(int elo) => CosmeticCatalog.winTokenReward(elo);
  int previewAdTokens(int elo) => CosmeticCatalog.adTokenReward(elo);

  static const adCooldownMs = 30000;

  int get adCooldownRemainingMs {
    final last = meta?.lastAdReward ?? 0;
    if (last <= 0) return 0;
    final left = adCooldownMs - (DateTime.now().millisecondsSinceEpoch - last);
    return left > 0 ? left : 0;
  }

  bool get canWatchAdForTokens => adCooldownRemainingMs <= 0;
}
