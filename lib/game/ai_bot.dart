import 'dart:math' as math;

import '../models/cosmetic_catalog.dart';
import '../models/disc.dart';
import '../models/rank_tier.dart';
import 'game_constants.dart';

enum AiLevel { easy, medium, hard }

class AiConfig {
  final int intervalMin;
  final int intervalMax;
  final double accuracy;
  final double powerMin;
  final double powerMax;
  final String strategy;

  const AiConfig({
    required this.intervalMin,
    required this.intervalMax,
    required this.accuracy,
    required this.powerMin,
    required this.powerMax,
    required this.strategy,
  });
}

/// Nişan sapmasının ölçeği. Pulun geçitten geçebilmesi için atış çizgisinin
/// duvar hattını geçit merkezinin ~14 birim yakınından kesmesi gerekir
/// (gapW / 2 - discRadius). Sapma bu pencereye göre ölçeklenir: accuracy 0.97
/// → ±3 birim (neredeyse hep girer), 0.86 → ±14 (yarı yarıya), 0.55 → ±45.
const double _aimMissScale = 100;

/// Doğrudan atışın hâlâ geçitten geçebildiği en yatık açı (dikeyden sapma,
/// tanjant cinsinden). Duvar bandı 2 * wallHalfH kalınlığında; pul bandı
/// geçerken yana `bant * tan` kadar kayar, bu kayma geçit penceresini aşarsa
/// pul köşeye çarpar. Emniyet payıyla 1.15 alındı.
const double _maxDirectTan = 1.15;

const aiConfigs = {
  AiLevel.easy: AiConfig(
    intervalMin: 1500,
    intervalMax: 2600,
    accuracy: 0.55,
    powerMin: 0.45,
    powerMax: 0.7,
    strategy: 'random',
  ),
  AiLevel.medium: AiConfig(
    intervalMin: 620,
    intervalMax: 1150,
    accuracy: 0.86,
    powerMin: 0.7,
    powerMax: 0.92,
    strategy: 'smart',
  ),
  AiLevel.hard: AiConfig(
    // Hızlı ve agresif ama makineli tüfek değil: seri atış frenlemesi ve
    // ara sıra gelen "acemi" atış insan ritmini korur.
    intervalMin: 360,
    intervalMax: 720,
    accuracy: 0.975,
    powerMin: 0.94,
    powerMax: 1.0,
    strategy: 'optimal',
  ),
};

class AiBot {
  final math.Random _rng = math.Random();
  double _nextShot = 0;
  int _burst = 0;

  /// Round başında insan gibi biraz "hazırlanır" — geri sayım biter bitmez
  /// atmaz (anında atış botu ele veriyor).
  void reset() {
    _nextShot = 500 + _rng.nextDouble() * 500;
    _burst = 0;
  }

  bool shouldThink(double nowMs, AiLevel level) {
    if (nowMs < _nextShot) return false;
    final cfg = aiConfigs[level]!;
    var wait = cfg.intervalMin +
        (cfg.intervalMax - cfg.intervalMin) * _rng.nextDouble();

    // Seri atış frenlemesi: art arda 2 hızlı atıştan sonra insan gibi bir
    // "nefes alma" molası ver — üst üste 3 pulu saniyede sokması engellensin.
    _burst++;
    if (_burst >= 2) {
      _burst = 0;
      wait += 550 + _rng.nextDouble() * 650;
    } else if (_rng.nextDouble() < 0.15) {
      // Ara sıra kısa duraksama — makine ritmini kırar.
      wait += 250 + _rng.nextDouble() * 450;
    }

    _nextShot = nowMs + wait;
    return true;
  }

  /// Geçidin merkezi ve pulun içinden geçebileceği yanal yarı-pencere.
  /// Duvarın açıklığı gapW ama pul merkezinin köşelere `discRadius` kalması
  /// gerektiği için gerçek pencere çok daha dar.
  static const double _gapCX = GameConstants.gapX + GameConstants.gapW / 2;
  static const double _gateHalfWindow =
      GameConstants.gapW / 2 - GameConstants.discRadius;

  /// Pul ile geçit ağzı arasındaki çizgi başka bir pulla kapalı mı?
  bool _pathBlocked(List<Disc> discs, Disc shooter, double aimX) {
    final dx = aimX - shooter.vx;
    final dy = GameConstants.vHalf - shooter.vy;
    final len2 = dx * dx + dy * dy;
    if (len2 < 1) return false;
    const clearance = GameConstants.discRadius * 1.8;
    for (final d in discs) {
      if (identical(d, shooter)) continue;
      final t = ((d.vx - shooter.vx) * dx + (d.vy - shooter.vy) * dy) / len2;
      if (t <= 0.05 || t >= 1) continue;
      final ox = d.vx - (shooter.vx + dx * t);
      final oy = d.vy - (shooter.vy + dy * t);
      if (ox * ox + oy * oy < clearance * clearance) return true;
    }
    return false;
  }

  /// Atış kalitesi — küçük olan daha iyi. Dikey yaklaşan, geçide yakın ve
  /// çizgisi kapalı olmayan pul tercih edilir. Çok yatay bir açıdan gelen pul
  /// duvar bandını geçerken köşeye sürtüp geri döner, bu yüzden açı cezası
  /// baskın terim.
  double _shotCost(List<Disc> discs, Disc d) {
    final dy = GameConstants.vHalf - d.vy;
    if (dy <= 1) return 1e6;
    final tan = (d.vx - _gapCX).abs() / dy; // 0 = tam dikey çizgi
    var cost = tan * 120 + dy * 0.12;
    if (_pathBlocked(discs, d, _gapCX)) cost += 400;
    cost += math.sqrt(d.vvx * d.vvx + d.vvy * d.vvy) * 40;
    return cost;
  }

  bool think(List<Disc> discs, AiLevel level) {
    final cfg = aiConfigs[level]!;

    final botDiscs = <({Disc d, int i})>[];
    for (var i = 0; i < discs.length; i++) {
      if (discs[i].vy < GameConstants.vHalf) botDiscs.add((d: discs[i], i: i));
    }
    if (botDiscs.isEmpty) return false;

    ({Disc d, int i})? chosen;

    if (cfg.strategy == 'random') {
      chosen = botDiscs[_rng.nextInt(botDiscs.length)];
    } else {
      // Duran pullar önce; hepsi hareketliyse yine de en iyisini dene.
      final still = botDiscs
          .where((e) => math.sqrt(e.d.vvx * e.d.vvx + e.d.vvy * e.d.vvy) < 0.5)
          .toList();
      final pool = still.isNotEmpty ? still : botDiscs;
      pool.sort((a, b) =>
          _shotCost(discs, a.d).compareTo(_shotCost(discs, b.d)));
      // 'smart' (orta) her zaman en iyi pulu seçmez — insan gibi ikinci en
      // iyiyi de oynar. 'optimal' hep en iyisini seçer.
      chosen = (cfg.strategy == 'smart' &&
              pool.length > 1 &&
              _rng.nextDouble() < 0.3)
          ? pool[1]
          : pool.first;
    }

    final tgt = chosen.d;

    if (math.sqrt(tgt.vvx * tgt.vvx + tgt.vvy * tgt.vvy) > 2.5) return false;

    // Nişan noktası DUVAR HATTININ ÜZERİNDE olmalı: pul düz bir çizgide gittiği
    // için duvarı tam olarak `aimX`'te keser. Hedef geçidin ötesine alınırsa
    // (eski davranış) çizgi duvarı geçidin berisinde kesip duvara çarpar —
    // botun kenardaki pulları bir türlü sokamamasının sebebi buydu.
    var aimX = _gapCX;

    if (cfg.strategy == 'optimal') {
      // Karşı yarıda geçidin önünü tutan pullar varsa ağzın boş tarafına yanaş
      // — ama pul köşeye sürtmesin diye pencerenin içinde kal.
      final blockers = discs.where((d) =>
          d.vy >= GameConstants.vHalf &&
          d.vy < GameConstants.vHalf + 90 &&
          d.vx > GameConstants.gapX - 20 &&
          d.vx < GameConstants.gapX + GameConstants.gapW + 20);
      if (blockers.isNotEmpty) {
        final avgX =
            blockers.map((d) => d.vx).reduce((a, b) => a + b) / blockers.length;
        aimX += avgX < _gapCX ? _gateHalfWindow * 0.6 : -_gateHalfWindow * 0.6;
      }
    }

    var missX = (1 - cfg.accuracy) * _aimMissScale;
    // İnsan payı: keskin nişancı bot bile ara sıra çuvallasın, aksi halde
    // kusursuz ritmi makine gibi hissettiriyor.
    if (_rng.nextDouble() < 0.12) missX *= 3.5;
    aimX += (_rng.nextDouble() - 0.5) * 2 * missX;

    var aimY = GameConstants.vHalf;
    var powerScale = 1.0;

    // Kurulum atışı. Pul duvara yakın ve geçidin çok yanındaysa doğrudan atış
    // matematiksel olarak imkânsız: pul 16 birim kalınlığındaki duvar bandını
    // geçerken yana `bandKalınlığı * tan` kadar kayar ve köşeye çarpar. İyi bir
    // oyuncu bu durumda pulu zorlamaz, önce koridora çeker. Bot da öyle yapar.
    final dyWall = GameConstants.vHalf - tgt.vy;
    if (cfg.strategy != 'random' &&
        dyWall > 1 &&
        (aimX - tgt.vx).abs() / dyWall > _maxDirectTan) {
      aimY = tgt.vy - 70; // yukarı-içeri: bir sonraki atış için temiz çizgi
      powerScale = 0.5; // nazik dokunuş, pul karşı duvara sekmesin
    }

    final dx = aimX - tgt.vx;
    final dy = aimY - tgt.vy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 1) return false;

    final power = GameConstants.slingMax *
        powerScale *
        (cfg.powerMin + (cfg.powerMax - cfg.powerMin) * _rng.nextDouble());
    tgt.vvx = (dx / dist) * power * GameConstants.slingPower;
    tgt.vvy = (dy / dist) * power * GameConstants.slingPower;
    return true;
  }
}

/// Gizli bot zorluk seçimi sonucu: kullanılacak seviye + yeni sayaç değeri.
class HiddenBotPick {
  const HiddenBotPick(this.level, this.nextCounter);
  final AiLevel level;
  final int nextCounter;
}

/// Gizli botun zorluğunu seçer. Rakipler genelde zorludur, ama her 5-6 maçta
/// bir kolay rakip düşer — oyuncu üst üste kaybedip oyunu bırakmasın diye.
/// Kullanıcı bunu fark etmez; sadece "bu rakip daha zayıfmış" hisseder.
HiddenBotPick pickHiddenBotLevel(int matchesSinceEasy) {
  final rng = math.Random();
  // 6-8 maç zorlu geçtiyse sıradaki maç kolay olur. Merhamet aralığı geniş
  // tutuldu: kazanmak kolay olmamalı, ama üst üste kayıp da oyuncuyu kaçırır.
  final threshold = 6 + rng.nextInt(3);
  if (matchesSinceEasy >= threshold) {
    return const HiddenBotPick(AiLevel.easy, 0);
  }
  // Ara sıra "orta" rakip de çıksın — hep aynı güçte olmasın (insan hissi).
  final level = rng.nextDouble() < 0.18 ? AiLevel.medium : AiLevel.hard;
  return HiddenBotPick(level, matchesSinceEasy + 1);
}

/// Hızlı eşleşmede rakip bulunamazsa gerçek oyuncu gibi görünen profil.
class BotFallbackProfile {
  final String name;
  final int elo;
  final String league;
  final String roomCode;

  /// Rakibin pul kozmetiği — gerçek oyuncular gibi bazen premium pul kullanır.
  final String discId;

  const BotFallbackProfile({
    required this.name,
    required this.elo,
    required this.league,
    required this.roomCode,
    required this.discId,
  });

  static const _names = [
    'Arda', 'Zeynep', 'Marcus', 'Elena', 'Can', 'Mira', 'Leo', 'Aylin',
    'Kaan', 'Sofia', 'Emre', 'Luna', 'Deniz', 'Nova', 'Berk', 'Yuki',
    'Selin', 'Omar', 'Defne', 'Alex', 'Ece', 'Ryan', 'Melis', 'Luca',
  ];

  static const _freeColors = ['green', 'blue', 'red', 'purple', 'gold'];

  /// Rakip için pul seç: ~%30 premium görsel, ~%15 emoji, kalanı ücretsiz renk.
  static String _pickDisc(math.Random rng) {
    final r = rng.nextDouble();
    if (r < 0.30) {
      final list = CosmeticCatalog.premiumDiscs;
      return list[rng.nextInt(list.length)].id;
    } else if (r < 0.45) {
      final list = CosmeticCatalog.emojiDiscs;
      return list[rng.nextInt(list.length)].id;
    }
    return _freeColors[rng.nextInt(_freeColors.length)];
  }

  factory BotFallbackProfile.generate({
    int playerElo = 1000,
    List<String> namePool = const [],
  }) {
    final rng = math.Random();
    // Öncelik: uygulamaya kayıtlı gerçek kullanıcı adları; yoksa yerleşik liste.
    final pool = namePool.isNotEmpty ? namePool : _names;
    final name = pool[rng.nextInt(pool.length)];
    final delta = rng.nextInt(130) + 20;
    final elo = (playerElo + (rng.nextBool() ? delta : -delta)).clamp(850, 1750);
    final league = RankTier.forElo(elo).name;
    const hex = '0123456789ABCDEF';
    final roomCode = List.generate(6, (_) => hex[rng.nextInt(16)]).join();
    return BotFallbackProfile(
      name: name,
      elo: elo,
      league: league,
      roomCode: roomCode,
      discId: _pickDisc(rng),
    );
  }
}
