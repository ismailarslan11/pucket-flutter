import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class Friend {
  final String uid;
  final String name;
  final int elo;
  final String league;
  final bool online;

  Friend({
    required this.uid,
    required this.name,
    this.elo = 1000,
    this.league = 'Bronz',
    this.online = false,
  });

  factory Friend.fromJson(Map<String, dynamic> j) => Friend(
        uid: j['uid'] as String? ?? '',
        name: j['name'] as String? ?? 'Oyuncu',
        elo: (j['elo'] as num?)?.toInt() ?? 1000,
        league: j['league'] as String? ?? 'Bronz',
        online: j['online'] as bool? ?? false,
      );
}

class FriendsApi {
  static Future<List<Friend>> list(String uid) async {
    try {
      final res = await http
          .get(Uri.parse('$apiBaseUrl/friends/$uid'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as List;
      return data.map((e) => Friend.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Kullanıcı adıyla arkadaş ekler. Hata varsa mesaj döner, başarıda null.
  static Future<String?> add(String uid, String username) async {
    try {
      final res = await http
          .post(
            Uri.parse('$apiBaseUrl/friend/add'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'uid': uid, 'username': username}),
          )
          .timeout(const Duration(seconds: 8));
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && j['ok'] == true) return null;
      return j['error'] as String? ?? 'Eklenemedi';
    } catch (_) {
      return 'Bağlantı hatası';
    }
  }

  /// Maç sonu: rakibin uid'si ile doğrudan ekler.
  static Future<String?> addByUid(String uid, String friendUid) async {
    try {
      final res = await http
          .post(
            Uri.parse('$apiBaseUrl/friend/add'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'uid': uid, 'friendUid': friendUid}),
          )
          .timeout(const Duration(seconds: 8));
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && j['ok'] == true) return null;
      return j['error'] as String? ?? 'Eklenemedi';
    } catch (_) {
      return 'Bağlantı hatası';
    }
  }

  static Future<bool> remove(String uid, String friendUid) async {
    try {
      final res = await http
          .post(
            Uri.parse('$apiBaseUrl/friend/remove'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'uid': uid, 'friendUid': friendUid}),
          )
          .timeout(const Duration(seconds: 8));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
