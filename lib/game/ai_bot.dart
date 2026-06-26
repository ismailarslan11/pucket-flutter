import 'dart:math' as math;

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

const aiConfigs = {
  AiLevel.easy: AiConfig(
    intervalMin: 1600,
    intervalMax: 2800,
    accuracy: 0.5,
    powerMin: 0.4,
    powerMax: 0.65,
    strategy: 'random',
  ),
  AiLevel.medium: AiConfig(
    intervalMin: 700,
    intervalMax: 1300,
    accuracy: 0.82,
    powerMin: 0.65,
    powerMax: 0.88,
    strategy: 'smart',
  ),
  AiLevel.hard: AiConfig(
    intervalMin: 200,
    intervalMax: 500,
    accuracy: 0.96,
    powerMin: 0.85,
    powerMax: 1.0,
    strategy: 'optimal',
  ),
};

class AiBot {
  final math.Random _rng = math.Random();
  double _nextShot = 0;

  void reset() => _nextShot = 0;

  bool shouldThink(double nowMs, AiLevel level) {
    if (nowMs < _nextShot) return false;
    final cfg = aiConfigs[level]!;
    _nextShot = nowMs +
        cfg.intervalMin +
        (cfg.intervalMax - cfg.intervalMin) * _rng.nextDouble();
    return true;
  }

  bool think(List<Disc> discs, AiLevel level) {
    final cfg = aiConfigs[level]!;
    final gapCX = GameConstants.gapX + GameConstants.gapW / 2;

    final botDiscs = <({Disc d, int i})>[];
    for (var i = 0; i < discs.length; i++) {
      if (discs[i].vy < GameConstants.vHalf) botDiscs.add((d: discs[i], i: i));
    }
    if (botDiscs.isEmpty) return false;

    ({Disc d, int i})? chosen;

    if (cfg.strategy == 'random') {
      chosen = botDiscs[_rng.nextInt(botDiscs.length)];
    } else if (cfg.strategy == 'smart') {
      botDiscs.sort((a, b) {
        final scoreA = (GameConstants.vHalf - a.d.vy) * 0.6 +
            (a.d.vx - gapCX).abs() * 0.4 -
            math.sqrt(a.d.vvx * a.d.vvx + a.d.vvy * a.d.vvy) * 8;
        final scoreB = (GameConstants.vHalf - b.d.vy) * 0.6 +
            (b.d.vx - gapCX).abs() * 0.4 -
            math.sqrt(b.d.vvx * b.d.vvx + b.d.vvy * b.d.vvy) * 8;
        return scoreA.compareTo(scoreB);
      });
      chosen = botDiscs.first;
    } else {
      final danger = botDiscs.where((e) => e.d.owner == 0).toList();
      if (danger.isNotEmpty && _rng.nextDouble() < 0.7) {
        chosen = danger.first;
      } else {
        final still =
            botDiscs.where((e) => math.sqrt(e.d.vvx * e.d.vvx + e.d.vvy * e.d.vvy) < 0.5).toList();
        final pool = still.isNotEmpty ? still : botDiscs;
        pool.sort((a, b) {
          final sa = (GameConstants.vHalf - a.d.vy) * 0.5 + (a.d.vx - gapCX).abs() * 0.5;
          final sb = (GameConstants.vHalf - b.d.vy) * 0.5 + (b.d.vx - gapCX).abs() * 0.5;
          return sa.compareTo(sb);
        });
        chosen = pool.first;
      }
    }

    final tgt = chosen.d;

    if (math.sqrt(tgt.vvx * tgt.vvx + tgt.vvy * tgt.vvy) > 2.5) return false;

    var aimX = gapCX;
    var aimY = GameConstants.vHalf + 60;

    if (cfg.strategy == 'optimal') {
      final redDiscs = discs.where((d) => d.vy >= GameConstants.vHalf).toList();
      if (redDiscs.isNotEmpty) {
        final avgX = redDiscs.map((d) => d.vx).reduce((a, b) => a + b) / redDiscs.length;
        aimX = avgX < GameConstants.vw / 2
            ? GameConstants.gapX + GameConstants.gapW * 0.75
            : GameConstants.gapX + GameConstants.gapW * 0.25;
      }
    }

    final missX = (1 - cfg.accuracy) * GameConstants.gapW * 2.5;
    aimX += (_rng.nextDouble() - 0.5) * 2 * missX;
    aimY += (_rng.nextDouble() - 0.5) * 20;

    final dx = aimX - tgt.vx;
    final dy = aimY - tgt.vy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 1) return false;

    final power = GameConstants.slingMax *
        (cfg.powerMin + (cfg.powerMax - cfg.powerMin) * _rng.nextDouble());
    tgt.vvx = (dx / dist) * power * GameConstants.slingPower;
    tgt.vvy = (dy / dist) * power * GameConstants.slingPower;
    return true;
  }
}

/// Hızlı eşleşmede rakip bulunamazsa gerçek oyuncu gibi görünen profil.
class BotFallbackProfile {
  final String name;
  final int elo;
  final String league;
  final String roomCode;

  const BotFallbackProfile({
    required this.name,
    required this.elo,
    required this.league,
    required this.roomCode,
  });

  static const _names = [
    'Arda', 'Zeynep', 'Marcus', 'Elena', 'Can', 'Mira', 'Leo', 'Aylin',
    'Kaan', 'Sofia', 'Emre', 'Luna', 'Deniz', 'Nova', 'Berk', 'Yuki',
    'Selin', 'Omar', 'Defne', 'Alex', 'Ece', 'Ryan', 'Melis', 'Luca',
  ];

  factory BotFallbackProfile.generate({int playerElo = 1000}) {
    final rng = math.Random();
    final name = _names[rng.nextInt(_names.length)];
    final delta = rng.nextInt(130) + 20;
    final elo = (playerElo + (rng.nextBool() ? delta : -delta)).clamp(850, 1750);
    final league = RankTier.forElo(elo).name;
    const hex = '0123456789ABCDEF';
    final roomCode = List.generate(6, (_) => hex[rng.nextInt(16)]).join();
    return BotFallbackProfile(name: name, elo: elo, league: league, roomCode: roomCode);
  }
}
