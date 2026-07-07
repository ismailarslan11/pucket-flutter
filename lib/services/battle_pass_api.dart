import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class BpReward {
  final String type; // tokens | disc | board
  final int amount;
  final String id;
  BpReward({required this.type, this.amount = 0, this.id = ''});
  factory BpReward.fromJson(Map<String, dynamic> j) => BpReward(
        type: j['t'] as String? ?? 'tokens',
        amount: (j['n'] as num?)?.toInt() ?? 0,
        id: j['id'] as String? ?? '',
      );
}

class BpTier {
  final BpReward free;
  final BpReward premium;
  BpTier({required this.free, required this.premium});
  factory BpTier.fromJson(Map<String, dynamic> j) => BpTier(
        free: BpReward.fromJson(j['free'] as Map<String, dynamic>),
        premium: BpReward.fromJson(j['premium'] as Map<String, dynamic>),
      );
}

class BattlePassState {
  final int xp;
  final int xpPerTier;
  final int tier;
  final bool premium;
  final List<int> claimedFree;
  final List<int> claimedPremium;
  final List<BpTier> tiers;

  BattlePassState({
    required this.xp,
    required this.xpPerTier,
    required this.tier,
    required this.premium,
    required this.claimedFree,
    required this.claimedPremium,
    required this.tiers,
  });

  factory BattlePassState.fromJson(Map<String, dynamic> j) => BattlePassState(
        xp: (j['xp'] as num?)?.toInt() ?? 0,
        xpPerTier: (j['xpPerTier'] as num?)?.toInt() ?? 150,
        tier: (j['tier'] as num?)?.toInt() ?? 0,
        premium: j['premium'] as bool? ?? false,
        claimedFree: (j['claimedFree'] as List?)?.map((e) => (e as num).toInt()).toList() ?? [],
        claimedPremium: (j['claimedPremium'] as List?)?.map((e) => (e as num).toInt()).toList() ?? [],
        tiers: (j['tiers'] as List?)
                ?.map((e) => BpTier.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class BattlePassApi {
  static Future<BattlePassState?> fetch(String uid) async {
    try {
      final res = await http
          .get(Uri.parse('$apiBaseUrl/battlepass/$uid'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      return BattlePassState.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> addXp(String uid, int amount) async {
    try {
      await http
          .post(
            Uri.parse('$apiBaseUrl/battlepass/xp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'uid': uid, 'amount': amount}),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  /// IAP sonrası premium yolu açar (satın alma mağazada doğrulanır).
  static Future<bool> unlockPremium(String uid) async {
    try {
      final res = await http
          .post(
            Uri.parse('$apiBaseUrl/battlepass/unlock'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'uid': uid, 'receipt': 'iap'}),
          )
          .timeout(const Duration(seconds: 8));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Ödül talep eder. Hata varsa mesaj, başarıda null döner.
  static Future<String?> claim(String uid, int tier, {required bool premium}) async {
    try {
      final res = await http
          .post(
            Uri.parse('$apiBaseUrl/battlepass/claim'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'uid': uid, 'tier': tier, 'track': premium ? 'premium' : 'free'}),
          )
          .timeout(const Duration(seconds: 8));
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && j['ok'] == true) return null;
      return j['error'] as String? ?? 'Alınamadı';
    } catch (_) {
      return 'Bağlantı hatası';
    }
  }
}
