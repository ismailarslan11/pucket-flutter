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

class UsernameCheckResult {
  /// true = müsait, false = alınmış, null = sunucu/ bağlantı hatası
  final bool? available;
  final String? error;

  UsernameCheckResult({required this.available, this.error});

  bool get isAvailable => available == true;
  bool get isTaken => available == false && error == null;
  bool get isServerError => available == null;
  bool get isInvalid => available == false && error != null;
}

class UsernameApi {
  static Duration get _timeout =>
      apiUsesProductionServer ? const Duration(seconds: 45) : const Duration(seconds: 10);

  /// Render free tier uyur; ilk istekte sunucuyu uyandır.
  static Future<void> _wakeServerIfNeeded() async {
    if (!apiUsesProductionServer) return;
    try {
      await http.get(Uri.parse('$apiBaseUrl/health')).timeout(const Duration(seconds: 60));
    } catch (_) {}
  }

  static Future<UsernameCheckResult> check(String username, {required String uid}) async {
    await _wakeServerIfNeeded();

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final uri = Uri.parse('$apiBaseUrl/username/check').replace(
          queryParameters: {'name': username, 'uid': uid},
        );
        final res = await http.get(uri).timeout(_timeout);
        if (res.statusCode != 200) {
          if (attempt == 0 && apiUsesProductionServer) {
            await _wakeServerIfNeeded();
            continue;
          }
          return UsernameCheckResult(
            available: null,
            error: 'Sunucu yanıt vermedi (${res.statusCode})',
          );
        }
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        if (j['ok'] == false) {
          return UsernameCheckResult(
            available: false,
            error: j['error'] as String? ?? 'Geçersiz kullanıcı adı',
          );
        }
        return UsernameCheckResult(
          available: j['available'] as bool? ?? false,
          error: null,
        );
      } catch (_) {
        if (attempt == 0 && apiUsesProductionServer) {
          await _wakeServerIfNeeded();
          continue;
        }
        return UsernameCheckResult(
          available: null,
          error: apiUsesProductionServer
              ? 'Sunucu uyandırılıyor — biraz bekleyip tekrar dene'
              : 'Sunucuya bağlanılamadı — terminalde: cd server && node server.js',
        );
      }
    }
    return UsernameCheckResult(
      available: null,
      error: 'Sunucuya bağlanılamadı',
    );
  }

  static Future<UsernameClaimResult> claim({
    required String uid,
    required String username,
  }) async {
    await _wakeServerIfNeeded();

    try {
      final res = await http
          .post(
            Uri.parse('$apiBaseUrl/username/claim'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'uid': uid, 'username': username}),
          )
          .timeout(_timeout);
      if (res.statusCode == 404) {
        return UsernameClaimResult(
          ok: false,
          error: 'Sunucu güncel değil — username API yok (server.js yeniden deploy)',
        );
      }
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      return UsernameClaimResult.fromJson(j);
    } catch (_) {
      return UsernameClaimResult(
        ok: false,
        error: apiUsesProductionServer
            ? 'Sunucuya bağlanılamadı — Render uyanması 1 dk sürebilir'
            : 'Sunucuya bağlanılamadı — yerel sunucu çalışıyor mu?',
      );
    }
  }
}
