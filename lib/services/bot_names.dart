import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

/// Gizli bot rakiplerine gerçek isim vermek için kayıtlı kullanıcı adlarını
/// (sıralama listesinden) çeker ve önbelleğe alır. Sunucu değişikliği gerekmez;
/// mevcut `/leaderboard` uç noktası isim + elo döndürür.
class BotNames {
  static List<String> _pool = const [];

  /// Çekilmiş gerçek kullanıcı adları (boşsa çağıran yedek listeye düşer).
  static List<String> get pool => _pool;

  static Future<void> refresh({String? excludeName}) async {
    try {
      final res = await http
          .get(Uri.parse('$apiBaseUrl/leaderboard'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode != 200) return;
      final list = jsonDecode(res.body) as List;
      final ex = (excludeName ?? '').trim().toLowerCase();
      final seen = <String>{};
      final names = <String>[];
      for (final e in list) {
        if (e is! Map) continue;
        final n = (e['name'] ?? '').toString().trim();
        if (n.isEmpty) continue;
        final low = n.toLowerCase();
        if (low == 'oyuncu' || low == 'player') continue; // varsayılan ad
        if (low == ex) continue; // oyuncunun kendi adı
        if (!seen.add(low)) continue; // tekrarları ele
        names.add(n);
      }
      if (names.isNotEmpty) _pool = names;
    } catch (_) {
      // Sessizce yut — çağıran, yerleşik yedek isim listesine düşer.
    }
  }
}
