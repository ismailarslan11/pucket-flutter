import 'dart:math' as math;

import '../models/disc.dart';
import 'game_constants.dart';
import 'training_layout.dart';

class PhysicsEngine {
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
    final wallTop = GameConstants.vHalf - 6;
    final wallBot = GameConstants.vHalf + 6;

    for (final d in discs) {
      d.vx += d.vvx;
      d.vy += d.vvy;
      d.vvx *= GameConstants.friction;
      d.vvy *= GameConstants.friction;
      if (d.vvx.abs() < 0.03) d.vvx = 0;
      if (d.vvy.abs() < 0.03) d.vvy = 0;

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

      final inGap = d.vx > GameConstants.gapX && d.vx < GameConstants.gapX + GameConstants.gapW;
      if (!inGap) {
        if (d.vy + dr > wallTop && d.vy - dr < wallBot) {
          if (d.vvy > 0 && d.vy < GameConstants.vHalf) {
            d.vy = wallTop - dr;
            d.vvy = -d.vvy.abs() * GameConstants.restitution;
          } else if (d.vvy < 0 && d.vy > GameConstants.vHalf) {
            d.vy = wallBot + dr;
            d.vvy = d.vvy.abs() * GameConstants.restitution;
          }
        }
      }
    }

    for (var i = 0; i < discs.length; i++) {
      for (var j = i + 1; j < discs.length; j++) {
        final a = discs[i];
        final b = discs[j];
        final dx = b.vx - a.vx;
        final dy = b.vy - a.vy;
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist < dr * 2 && dist > 0) {
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
      }
    }
  }

  static const int discsPerPlayer = 5;

  static bool inGateZone(Disc d) {
    final inGapX = d.vx > GameConstants.gapX && d.vx < GameConstants.gapX + GameConstants.gapW;
    final nearMid = (d.vy - GameConstants.vHalf).abs() < GameConstants.discRadius + 10;
    return inGapX && nearMid;
  }

  static bool isStopped(Disc d) =>
      d.vvx.abs() < 0.12 && d.vvy.abs() < 0.12;

  /// Pul üst yarıyı işgal ediyor mu?
  static bool occupiesTop(Disc d) {
    final dr = GameConstants.discRadius;
    if (inGateZone(d)) {
      // Kapıdan geçerken durmayı bekleme — merkez çizgisine göre yarı ata
      return d.vy <= GameConstants.vHalf;
    }
    return d.vy - dr < GameConstants.vHalf;
  }

  /// Pul alt yarıyı işgal ediyor mu?
  static bool occupiesBottom(Disc d) {
    final dr = GameConstants.discRadius;
    if (inGateZone(d)) {
      return d.vy > GameConstants.vHalf;
    }
    return d.vy + dr > GameConstants.vHalf;
  }

  static bool allStopped(List<Disc> discs) => discs.every(isStopped);

  static void settleGateDiscs(List<Disc> discs) {
    for (final d in discs) {
      if (!inGateZone(d) || !isStopped(d)) continue;
      // Kapıda takılı pulları hafifçe geçir — yarım boş kalabilsin
      if (d.vy < GameConstants.vHalf) {
        d.vy = GameConstants.vHalf - GameConstants.discRadius - 2;
      } else {
        d.vy = GameConstants.vHalf + GameConstants.discRadius + 2;
      }
      d.vvx = 0;
      d.vvy = 0;
    }
  }

  static int? checkWinner(List<Disc> discs) {
    if (discs.length < discsPerPlayer * 2) return null;

    final topEmpty = !discs.any(occupiesTop);
    final bottomEmpty = !discs.any(occupiesBottom);

    // Alt yarı tamamen boş → kırmızı kazandı
    if (bottomEmpty) return 0;
    // Üst yarı tamamen boş → mavi kazandı
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
}
