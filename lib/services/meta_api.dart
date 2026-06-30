import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class PlayerMeta {
  final Map<String, dynamic> quests;
  final int streak;
  final List<String> achievements;
  final Map<String, String> cosmetics;
  final int seasonWins;
  final int tokens;
  final List<String> unlockedDiscs;
  final List<String> unlockedBoards;

  PlayerMeta({
    required this.quests,
    required this.streak,
    required this.achievements,
    required this.cosmetics,
    required this.seasonWins,
    required this.tokens,
    required this.unlockedDiscs,
    required this.unlockedBoards,
  });

  factory PlayerMeta.fromJson(Map<String, dynamic> j) => PlayerMeta(
        quests: Map<String, dynamic>.from(j['quests'] as Map? ?? {}),
        streak: (j['streak'] as num?)?.toInt() ?? 0,
        achievements: (j['achievements'] as List?)?.map((e) => e.toString()).toList() ?? [],
        cosmetics: Map<String, String>.from(
          (j['cosmetics'] as Map?)?.map((k, v) => MapEntry(k.toString(), v.toString())) ?? {},
        ),
        seasonWins: (j['seasonWins'] as num?)?.toInt() ?? 0,
        tokens: (j['tokens'] as num?)?.toInt() ?? 0,
        unlockedDiscs: (j['unlockedDiscs'] as List?)?.map((e) => e.toString()).toList() ?? [],
        unlockedBoards: (j['unlockedBoards'] as List?)?.map((e) => e.toString()).toList() ?? [],
      );

  bool get questsComplete =>
      (quests['play'] as num? ?? 0) >= 3 &&
      (quests['win'] as num? ?? 0) >= 1 &&
      (quests['career'] as num? ?? 0) >= 1;

  bool get questsClaimed => quests['claimed'] == true;
}

class SeasonInfo {
  final int id;
  final String name;

  SeasonInfo({required this.id, required this.name});

  factory SeasonInfo.fromJson(Map<String, dynamic> j) => SeasonInfo(
        id: (j['id'] as num?)?.toInt() ?? 1,
        name: j['name'] as String? ?? 'Sezon 1',
      );
}

class TournamentEntry {
  final String uid;
  final String name;
  final int points;

  TournamentEntry({required this.uid, required this.name, required this.points});

  factory TournamentEntry.fromJson(Map<String, dynamic> j) => TournamentEntry(
        uid: j['uid'] as String? ?? '',
        name: j['name'] as String? ?? 'Oyuncu',
        points: (j['points'] as num?)?.toInt() ?? 0,
      );
}

class MetaApi {
  static Future<bool> registerPlayer(String uid, String name) async {
    try {
      final res = await http
          .post(
            Uri.parse('${apiBaseUrl}/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'uid': uid, 'name': name}),
          )
          .timeout(const Duration(seconds: 8));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<PlayerMeta?> fetchMeta(String uid, {String name = ''}) async {
    try {
      final q = name.isNotEmpty ? '?name=${Uri.encodeComponent(name)}' : '';
      final res = await http
          .get(Uri.parse('${apiBaseUrl}/meta/$uid$q'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      return PlayerMeta.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<PlayerMeta?> postMeta(String uid, Map<String, dynamic> body) async {
    try {
      final res = await http
          .post(
            Uri.parse('${apiBaseUrl}/meta/$uid'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      final meta = j['meta'];
      if (meta is Map<String, dynamic>) return PlayerMeta.fromJson(meta);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<int?> claimQuests(String uid) async {
    try {
      final res = await http
          .post(
            Uri.parse('${apiBaseUrl}/meta/$uid'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'action': 'claim_quests'}),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      return (j['reward'] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  static Future<void> bumpQuest(String uid, String field) async {
    await postMeta(uid, {'questBump': field});
  }

  static Future<void> saveCosmetics(String uid, Map<String, String> cosmetics) async {
    await postMeta(uid, {'cosmetics': cosmetics});
  }

  static Future<({PlayerMeta? meta, int? tokenGain, String? error})> earnWinTokens(String uid) async {
    try {
      final res = await http
          .post(
            Uri.parse('${apiBaseUrl}/meta/$uid'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'action': 'earn_win'}),
          )
          .timeout(const Duration(seconds: 8));
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200) {
        return (meta: null, tokenGain: null, error: j['error'] as String? ?? 'Hata');
      }
      final meta = j['meta'];
      return (
        meta: meta is Map<String, dynamic> ? PlayerMeta.fromJson(meta) : null,
        tokenGain: (j['tokenGain'] as num?)?.toInt(),
        error: null,
      );
    } catch (_) {
      return (meta: null, tokenGain: null, error: 'Bağlantı hatası');
    }
  }

  static Future<({PlayerMeta? meta, int? tokenGain, String? error})> rewardAdTokens(String uid) async {
    try {
      final res = await http
          .post(
            Uri.parse('${apiBaseUrl}/meta/$uid'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'action': 'reward_ad'}),
          )
          .timeout(const Duration(seconds: 8));
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200) {
        return (meta: null, tokenGain: null, error: j['error'] as String? ?? 'Hata');
      }
      final meta = j['meta'];
      return (
        meta: meta is Map<String, dynamic> ? PlayerMeta.fromJson(meta) : null,
        tokenGain: (j['tokenGain'] as num?)?.toInt(),
        error: null,
      );
    } catch (_) {
      return (meta: null, tokenGain: null, error: 'Bağlantı hatası');
    }
  }

  static Future<({PlayerMeta? meta, String? error})> purchaseCosmetic(
    String uid, {
    required String itemType,
    required String itemId,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('${apiBaseUrl}/meta/$uid'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'action': 'purchase', 'itemType': itemType, 'itemId': itemId}),
          )
          .timeout(const Duration(seconds: 8));
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200) {
        return (meta: null, error: j['error'] as String? ?? 'Satın alınamadı');
      }
      final meta = j['meta'];
      return (
        meta: meta is Map<String, dynamic> ? PlayerMeta.fromJson(meta) : null,
        error: null,
      );
    } catch (_) {
      return (meta: null, error: 'Bağlantı hatası');
    }
  }

  static Future<void> saveFcmToken(String uid, String token) async {
    await postMeta(uid, {'fcmToken': token});
  }

  static Future<SeasonInfo?> fetchSeason() async {
    try {
      final res = await http.get(Uri.parse('${apiBaseUrl}/season')).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      return SeasonInfo.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<List<TournamentEntry>> fetchTournament() async {
    try {
      final res = await http.get(Uri.parse('${apiBaseUrl}/tournament')).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return [];
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      final list = j['leaderboard'] as List? ?? [];
      return list.map((e) => TournamentEntry.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> joinTournament(String uid, String name) async {
    try {
      final res = await http
          .post(
            Uri.parse('${apiBaseUrl}/tournament/join'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'uid': uid, 'name': name}),
          )
          .timeout(const Duration(seconds: 8));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> reportPlayer({
    required String reporter,
    required String reported,
    required String reason,
    String room = '',
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('${apiBaseUrl}/report'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'reporter': reporter,
              'reported': reported,
              'reason': reason,
              'room': room,
            }),
          )
          .timeout(const Duration(seconds: 8));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> fetchCareer(String uid) async {
    try {
      final res = await http.get(Uri.parse('${apiBaseUrl}/career/$uid')).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveCareer(String uid, Map<String, dynamic> data) async {
    try {
      await http
          .post(
            Uri.parse('${apiBaseUrl}/career/$uid'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {}
  }
}
