import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class MatchRecord {
  final bool won;
  final String opponent;
  final int eloChange;
  final int timestamp;
  final bool ranked;

  MatchRecord({
    required this.won,
    required this.opponent,
    required this.eloChange,
    required this.timestamp,
    required this.ranked,
  });

  factory MatchRecord.fromJson(Map<String, dynamic> j) => MatchRecord(
        won: j['won'] as bool? ?? false,
        opponent: j['opponent'] as String? ?? 'Oyuncu',
        eloChange: (j['eloChange'] as num?)?.toInt() ?? 0,
        timestamp: (j['timestamp'] as num?)?.toInt() ?? 0,
        ranked: j['ranked'] as bool? ?? false,
      );
}

class MatchApi {
  static Future<List<MatchRecord>> fetchHistory(String uid) async {
    try {
      final res = await http
          .get(Uri.parse('${apiBaseUrl}/match-history/$uid'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return [];
      final list = jsonDecode(res.body) as List;
      return list.map((e) => MatchRecord.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> fetchPlayer(String uid) async {
    try {
      final res = await http
          .get(Uri.parse('${apiBaseUrl}/player/$uid'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
