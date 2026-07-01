import 'dart:math' as math;

import '../models/disc.dart';
import 'game_constants.dart';
import 'training_layout.dart';

class PhysicsEngine {
  static const _solverPasses = 3;

  static double clamp(double v, double a, double b) =>
      math.max(a, math.min(b, v));

  static List<Disc> initDiscs() => _buildFromPositions(_standardRed, _standardBlue);

  static List<Disc> initTrainingDiscs(TrainingLayout layout) {
    switch (layout) {
      case TrainingLayout.shooting:
        return _buildFromPositions(
          const [
            [0.35, 0.58],
            [0.50, 0.62],
            [0.65, 0.58],
          ],
          const [
            [0.50, 0.22],
          ],
        );
      case TrainingLayout.defense:
        return _buildFromPositions(
          const [
            [0.30, 0.72],
            [0.70, 0.72],
          ],
          const [
            [0.25, 0.56],
            [0.50, 0.54],
            [0.75, 0.56],
            [0.50, 0.48],
          ],
        );
      case TrainingLayout.full:
        return initDiscs();
    }
  }

  static const _standardRed = [
    [0.2, 0.62],
    [0.8, 0.62],
    [0.5, 0.70],
    [0.28, 0.82],
    [0.72, 0.82],
  ];

  static const _standardBlue = [
    [0.2, 0.38],
    [0.8, 0.38],
    [0.5, 0.30],
    [0.28, 0.18],
    [0.72, 0.18],
  ];

  static List<Disc> _buildFromPositions(List<List<double>> red, List<List<double>> blue) {
    final m = GameConstants.discRadius + 8;
    final discs = <Disc>[];

    for (final p in red) {
      discs.add(Disc(
        vx: clamp(GameConstants.vw * p[0], m, GameConstants.vw - m),
        vy: clamp(GameConstants.vh * p[1], GameConstants.vHalf + m, GameConstants.vh - m),
        owner: 0,
      ));
    }

    for (final p in blue) {
      discs.add(Disc(
        vx: clamp(GameConstants.vw * p[0], m, GameConstants.vw - m),
        vy: clamp(GameConstants.vh * p[1], m, GameConstants.vHalf - m),
        owner: 1,
      ));
    }

    return discs;
  }

  static void stepPhysics(List<Disc> discs) {
    final dr = GameConstants.discRadius;

    for (final d in discs) {
      d.vx += d.vvx;
      d.vy += d.vvy;
      d.vvx *= GameConstants.friction;
      d.vvy *= GameConstants.friction;
      if (d.vvx.abs() < 0.03) d.vvx = 0;
      if (d.vvy.abs() < 0.03) d.vvy = 0;
    }

    for (var pass = 0; pass < _solverPasses; pass++) {
      for (var i = 0; i < discs.length; i++) {
        for (var j = i + 1; j < discs.length; j++) {
          _resolveDiscPair(discs[i], discs[j], dr);
        }
      }
      for (final d in discs) {
        _resolveMidWall(d, dr);
        _resolveOuterBounds(d, dr);
      }
    }
  }

  static void _resolveOuterBounds(Disc d, double dr) {
    if (d.vx < dr) {
      d.vx = dr;
      d.vvx = d.vvx.abs() * GameConstants.restitution;
    }
    if (d.vx > GameConstants.vw - dr) {
      d.vx = GameConstants.vw - dr;
      d.vvx = -d.vvx.abs() * GameConstants.restitution;
    }
    if (d.vy < dr) {
      d.vy = dr;
      d.vvy = d.vvy.abs() * GameConstants.restitution;
    }
    if (d.vy > GameConstants.vh - dr) {
      d.vy = GameConstants.vh - dr;
      d.vvy = -d.vvy.abs() * GameConstants.restitution;
    }
  }

  /// Sol/sağ duvar blokları — görsel hitbox ile aynı dikdörtgenler.
  static void _resolveMidWall(Disc d, double dr) {
    _resolveCircleWallBar(
      d,
      dr,
      left: 0,
      top: GameConstants.wallTop,
      right: GameConstants.gapX,
      bottom: GameConstants.wallBottom,
      pushRight: true,
    );
    _resolveCircleWallBar(
      d,
      dr,
      left: GameConstants.gapX + GameConstants.gapW,
      top: GameConstants.wallTop,
      right: GameConstants.vw,
      bottom: GameConstants.wallBottom,
      pushRight: false,
    );
  }

  static void _resolveCircleWallBar(
    Disc d,
    double r, {
    required double left,
    required double top,
    required double right,
    required double bottom,
    required bool pushRight,
  }) {
    if (d.vy + r <= top || d.vy - r >= bottom) return;

    final closestX = clamp(d.vx, left, right);
    final closestY = clamp(d.vy, top, bottom);
    var dx = d.vx - closestX;
    var dy = d.vy - closestY;
    final distSq = dx * dx + dy * dy;
    final rSq = r * r;
    if (distSq >= rSq) return;

    double nx;
    double ny;
    double penetration;

    if (distSq < 1e-8) {
      nx = pushRight ? 1 : -1;
      ny = 0;
      penetration = pushRight ? (left + (right - left) + r - d.vx) : (d.vx - left + r);
      if (penetration < 0) penetration = r;
    } else {
      final dist = math.sqrt(distSq);
      nx = dx / dist;
      ny = dy / dist;
      penetration = r - dist;
      if (pushRight && nx < 0) {
        nx = 1;
        ny = 0;
      } else if (!pushRight && nx > 0) {
        nx = -1;
        ny = 0;
      }
    }

    d.vx += nx * penetration;
    d.vy += ny * penetration;

    final vDot = d.vvx * nx + d.vvy * ny;
    if (vDot < 0) {
      final bounce = (1 + GameConstants.restitution) * vDot;
      d.vvx -= bounce * nx;
      d.vvy -= bounce * ny;
    }
  }

  static void _resolveDiscPair(Disc a, Disc b, double dr) {
    var dx = b.vx - a.vx;
    var dy = b.vy - a.vy;
    var dist = math.sqrt(dx * dx + dy * dy);
    if (dist >= dr * 2) return;

    if (dist < 1e-6) {
      dx = 0;
      dy = 1;
      dist = 1;
    }

    final nx = dx / dist;
    final ny = dy / dist;
    final overlap = dr * 2 - dist;
    a.vx -= nx * overlap / 2;
    a.vy -= ny * overlap / 2;
    b.vx += nx * overlap / 2;
    b.vy += ny * overlap / 2;

    final dot = (b.vvx - a.vvx) * nx + (b.vvy - a.vvy) * ny;
    if (dot < 0) {
      a.vvx += dot * GameConstants.restitution * nx;
      a.vvy += dot * GameConstants.restitution * ny;
      b.vvx -= dot * GameConstants.restitution * nx;
      b.vvy -= dot * GameConstants.restitution * ny;
    }
  }

  static const int discsPerPlayer = 5;

  static bool overlapsLeftWall(Disc d) => _overlapsWallBar(
        d,
        left: 0,
        right: GameConstants.gapX,
      );

  static bool overlapsRightWall(Disc d) => _overlapsWallBar(
        d,
        left: GameConstants.gapX + GameConstants.gapW,
        right: GameConstants.vw,
      );

  static bool _overlapsWallBar(
    Disc d, {
    required double left,
    required double right,
  }) {
    return _circleOverlapsRect(
      d.vx,
      d.vy,
      GameConstants.discRadius,
      left,
      GameConstants.wallTop,
      right,
      GameConstants.wallBottom,
    );
  }

  static bool discsOverlap(Disc a, Disc b) {
    final dr = GameConstants.discRadius;
    final dx = b.vx - a.vx;
    final dy = b.vy - a.vy;
    return dx * dx + dy * dy < (dr * 2 - 0.5) * (dr * 2 - 0.5);
  }

  static bool _circleOverlapsRect(
    double cx,
    double cy,
    double r,
    double left,
    double top,
    double right,
    double bottom,
  ) {
    final closestX = clamp(cx, left, right);
    final closestY = clamp(cy, top, bottom);
    final dx = cx - closestX;
    final dy = cy - closestY;
    return dx * dx + dy * dy < r * r;
  }

  static bool inGateZone(Disc d) {
    final dr = GameConstants.discRadius;
    final inGapX = d.vx > GameConstants.gapX && d.vx < GameConstants.gapX + GameConstants.gapW;
    final inGapY = d.vy + dr > GameConstants.gapY && d.vy - dr < GameConstants.gapY + GameConstants.gapH;
    return inGapX && inGapY;
  }

  static bool isStopped(Disc d) =>
      d.vvx.abs() < 0.12 && d.vvy.abs() < 0.12;

  static bool occupiesTop(Disc d) {
    final dr = GameConstants.discRadius;
    if (inGateZone(d)) {
      return d.vy <= GameConstants.vHalf;
    }
    return d.vy - dr < GameConstants.vHalf;
  }

  static bool occupiesBottom(Disc d) {
    final dr = GameConstants.discRadius;
    if (inGateZone(d)) {
      return d.vy > GameConstants.vHalf;
    }
    return d.vy + dr > GameConstants.vHalf;
  }

  static bool allStopped(List<Disc> discs) => discs.every(isStopped);

  static void settleGateDiscs(List<Disc> discs) {
    if (!allStopped(discs)) return;

    final dr = GameConstants.discRadius;
    final minSep = dr * 2 + 1;

    for (var pass = 0; pass < 4; pass++) {
      for (var i = 0; i < discs.length; i++) {
        for (var j = i + 1; j < discs.length; j++) {
          _resolveDiscPair(discs[i], discs[j], dr);
        }
      }
      for (final d in discs) {
        _resolveMidWall(d, dr);
      }
    }

    final gateDiscs = discs.where(inGateZone).toList()
      ..sort((a, b) => a.vy.compareTo(b.vy));

    for (var i = 1; i < gateDiscs.length; i++) {
      final prev = gateDiscs[i - 1];
      final cur = gateDiscs[i];
      if (cur.vy - prev.vy < minSep) {
        cur.vy = prev.vy + minSep;
      }
    }

    for (final d in gateDiscs) {
      final target = d.vy < GameConstants.vHalf
          ? GameConstants.vHalf - dr - 2
          : GameConstants.vHalf + dr + 2;
      d.vy += clamp(target - d.vy, -4.0, 4.0);
      d.vvx = 0;
      d.vvy = 0;
      _resolveMidWall(d, dr);
    }
  }

  static int? checkWinner(List<Disc> discs) {
    if (discs.length < discsPerPlayer * 2) return null;

    final topEmpty = !discs.any(occupiesTop);
    final bottomEmpty = !discs.any(occupiesBottom);

    if (bottomEmpty) return 0;
    if (topEmpty) return 1;

    return null;
  }

  static int findDiscAt(List<Disc> discs, double x, double y, int mySeat) {
    for (var i = discs.length - 1; i >= 0; i--) {
      final d = discs[i];
      if (mySeat == 0 && d.vy < GameConstants.vHalf) continue;
      if (mySeat == 1 && d.vy >= GameConstants.vHalf) continue;
      final dx = x - d.vx;
      final dy = y - d.vy;
      if (dx * dx + dy * dy < (GameConstants.discRadius + 14) * (GameConstants.discRadius + 14)) {
        return i;
      }
    }
    return -1;
  }

  /// 2 kişilik mod: üst yarı mavi, alt yarı kırmızı — aynı anda oynanır.
  /// Dokunulan yarıdaki pullar seçilir: kendi pulların + alanına girmiş rakip pullar.
  static int findDiscAtLocalDuo(List<Disc> discs, double x, double y) {
    final blueTerritory = y < GameConstants.vHalf;
    const pickR = GameConstants.discRadius + 18;
    const pickSq = pickR * pickR;

    bool inTouchTerritory(Disc d) =>
        blueTerritory ? occupiesTop(d) : occupiesBottom(d);

    for (var i = discs.length - 1; i >= 0; i--) {
      final d = discs[i];
      if (!inTouchTerritory(d)) continue;
      final dx = x - d.vx;
      final dy = y - d.vy;
      if (dx * dx + dy * dy <= pickSq) return i;
    }
    return -1;
  }
}
