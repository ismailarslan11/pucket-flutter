import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class UsernameClaimResult {
  final bool ok;
  final String? error;
  final Map<String, dynamic>? player;

  UsernameClaimResult({required this.ok, this.error, this.player});

  factory UsernameClaimResult.fromJson(Map<String, dynamic> j) => UsernameClaimResult(
        ok: j['ok'] as bool? ?? false,
        error: j['error'] as String?,
        player: j['player'] as Map<String, dynamic>?,
      );
}

class UsernameApi {
  static Future<bool> checkAvailable(String username, {required String uid}) async {
    try {
      final uri = Uri.parse('${apiBaseUrl}/username/check').replace(
        queryParameters: {'name': username, 'uid': uid},
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return false;
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      return j['available'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<UsernameClaimResult> claim({
    required String uid,
    required String username,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('${apiBaseUrl}/username/claim'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'uid': uid, 'username': username}),
          )
          .timeout(const Duration(seconds: 10));
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      return UsernameClaimResult.fromJson(j);
    } catch (_) {
      return UsernameClaimResult(ok: false, error: 'Sunucuya bağlanılamadı');
    }
  }
}
