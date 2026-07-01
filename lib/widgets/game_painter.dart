import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../game/game_constants.dart';
import '../game/game_controller.dart';
import '../models/cosmetic_catalog.dart';
import '../models/disc.dart';
import '../services/disc_image_cache.dart';
import '../theme/app_theme.dart';
import '../theme/cosmetics_theme.dart';

/// Tahta çizimi — [repaint] ile widget rebuild olmadan yenilenir.
class GamePainter extends CustomPainter {
  GamePainter({
    required this.game,
    required this.sx,
    required this.sy,
    required this.discColor,
    required this.boardTheme,
  }) : super(repaint: game.boardRepaint);

  final GameController game;
  final double sx;
  final double sy;
  final String discColor;
  final String boardTheme;

  static const _fieldVersion = 6;
  static ui.Picture? _fieldPicture;
  static Size? _fieldSize;
  static int? _fieldSeat;
  static String? _fieldBoardTheme;
  static int? _fieldVersionCached;

  static final _redFill = Paint()..color = AppColors.red;
  static final _blueFill = Paint()..color = AppColors.blue;
  static final _premiumPaint = Paint()..filterQuality = FilterQuality.none;
  static final _slingLow = Paint()
    ..color = AppColors.fieldBlue
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  static final _slingHigh = Paint()
    ..color = AppColors.brandOrange
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;
  static final _slingArc = Paint()
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;

  Offset _s2c(double vx, double vy) => Offset(vx * sx, vy * sy);

  ui.Picture _fieldPictureFor(Size size, int mySeat) {
    if (_fieldPicture != null &&
        _fieldSize == size &&
        _fieldSeat == mySeat &&
        _fieldBoardTheme == boardTheme &&
        _fieldVersionCached == _fieldVersion) {
      return _fieldPicture!;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    _drawFieldStatic(canvas, size, mySeat);
    _fieldPicture = recorder.endRecording();
    _fieldSize = size;
    _fieldSeat = mySeat;
    _fieldBoardTheme = boardTheme;
    _fieldVersionCached = _fieldVersion;
    return _fieldPicture!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final mySeat = game.mySeat;
    final localDuo = game.localDuoMode;
    final discs = game.discs;
    final drags = game.activeDrags;
    final fastDraw = game.phase == GamePhase.playing;

    canvas.save();
    if (mySeat == 1 && !localDuo) {
      canvas.translate(size.width, size.height);
      canvas.rotate(math.pi);
    }

    canvas.drawPicture(_fieldPictureFor(size, mySeat));

    for (final d in discs) {
      _drawDisc(canvas, d, mySeat: mySeat, localDuo: localDuo, fast: fastDraw);
    }
    for (final drag in drags) {
      if (drag.discIndex < discs.length) {
        _drawSling(canvas, discs[drag.discIndex], drag);
      }
    }
    canvas.restore();
  }

  void _drawFieldStatic(Canvas canvas, Size size, int mySeat) {
    final palette = CosmeticsTheme.boardPalette(boardTheme);
    final gap = _s2c(GameConstants.gapX, GameConstants.gapY);
    final gw = GameConstants.gapW * sx;
    final gh = GameConstants.gapH * sy;
    final hw = size.width;
    final hh = size.height / 2;
    final isClassic = boardTheme == 'classic';

    _drawSpaceHalf(canvas, Rect.fromLTWH(0, 0, hw, hh), palette.topGrass, palette.topTint);
    _drawSpaceHalf(canvas, Rect.fromLTWH(0, hh, hw, hh), palette.bottomGrass, palette.bottomTint);
    if (!isClassic) {
      _drawStarfield(canvas, size);
      _drawNeonGrid(canvas, size, palette);
    }

    _neonLine(canvas, Offset(0, hh), Offset(hw, hh), palette.neonPrimary);
    _neonCircle(canvas, Offset(hw / 2, hh / 2), hw * 0.11, palette.neonPrimary);
    _neonCircle(canvas, Offset(hw / 2, hh + hh / 2), hw * 0.11, palette.neonSecondary);

    final pb = math.min(hh * 0.14, 52.0);
    final boxW = hw * 0.42;
    final boxLeft = (hw - boxW) / 2;
    _neonRect(
      canvas,
      RRect.fromRectAndRadius(Rect.fromLTWH(boxLeft, 8, boxW, pb), const Radius.circular(4)),
      palette.neonPrimary.withValues(alpha: 0.5),
    );
    _neonRect(
      canvas,
      RRect.fromRectAndRadius(
        Rect.fromLTWH(boxLeft, size.height - 8 - pb, boxW, pb),
        const Radius.circular(4),
      ),
      palette.neonSecondary.withValues(alpha: 0.5),
    );

    _drawNeonWall(canvas, Rect.fromLTWH(0, gap.dy, gap.dx, gh), palette);
    _drawNeonWall(canvas, Rect.fromLTWH(gap.dx + gw, gap.dy, hw - gap.dx - gw, gh), palette);
    _drawPortalGoal(canvas, Rect.fromLTWH(gap.dx, gap.dy, gw, gh), palette);
  }

  void _drawSpaceHalf(Canvas canvas, Rect rect, Color base, Color tint) {
    canvas.drawRect(rect, Paint()..color = base);
    if (tint.a > 0) canvas.drawRect(rect, Paint()..color = tint);
  }

  void _drawStarfield(Canvas canvas, Size size) {
    final rng = math.Random(42);
    for (var i = 0; i < 14; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawCircle(
        Offset(x, y),
        rng.nextDouble() * 0.9 + 0.4,
        Paint()..color = Colors.white.withValues(alpha: rng.nextDouble() * 0.25 + 0.08),
      );
    }
  }

  void _drawNeonGrid(Canvas canvas, Size size, BoardPalette palette) {
    if (palette.gridColor.a < 0.05) return;
    final gridPaint = Paint()
      ..color = palette.gridColor
      ..strokeWidth = 0.5;
    const step = 40.0;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _neonLine(Canvas canvas, Offset a, Offset b, Color color) {
    canvas.drawLine(a, b, Paint()..color = color..strokeWidth = 1.2);
  }

  void _neonCircle(Canvas canvas, Offset c, double r, Color color) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = color.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _neonRect(Canvas canvas, RRect rrect, Color color) {
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawNeonWall(Canvas canvas, Rect rect, BoardPalette palette) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()..color = palette.wall,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()
        ..color = palette.neonPrimary.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawPortalGoal(Canvas canvas, Rect rect, BoardPalette palette) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      Paint()..color = palette.gateFill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      Paint()
        ..color = palette.gateStroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawDisc(Canvas canvas, Disc d, {required int mySeat, required bool localDuo, required bool fast}) {
    final pos = _s2c(d.vx, d.vy);
    final r = GameConstants.discRadius * sx;
    final isMine = d.owner == mySeat;
    final usePremium = isMine && CosmeticCatalog.isPremiumDisc(discColor);
    final img = usePremium ? DiscImageCache.imageFor(discColor) : null;

    if (img != null) {
      final dst = Rect.fromCircle(center: pos, radius: r);
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        dst,
        _premiumPaint,
      );
      return;
    }

    if (fast) {
      canvas.drawCircle(pos, r, d.owner == 0 ? _redFill : _blueFill);
      return;
    }

    final defaultColor = d.owner == 0 ? AppColors.red : AppColors.blue;
    final color = localDuo
        ? defaultColor
        : (isMine ? CosmeticsTheme.discColor(discColor) : defaultColor);

    canvas.drawCircle(pos, r, Paint()..color = color);
    canvas.drawCircle(
      pos,
      r,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _drawSling(Canvas canvas, Disc d, DragState drag) {
    final discPos = _s2c(d.vx, d.vy);
    final pullPos = _s2c(drag.currentVx, drag.currentVy);
    final ddx = drag.currentVx - drag.startVx;
    final ddy = drag.currentVy - drag.startVy;
    final distSq = ddx * ddx + ddy * ddy;
    if (distSq < 9) return;

    final dist = math.sqrt(distSq);
    final lim = math.min(dist, GameConstants.slingMax);
    final pow = lim / GameConstants.slingMax;
    final nx = -ddx / dist;
    final ny = -ddy / dist;

    canvas.drawLine(discPos, pullPos, _slingLow);

    final col = pow > 0.7 ? _slingHigh : _slingLow;
    final tip = Offset(discPos.dx + nx * lim * sx * 0.55, discPos.dy + ny * lim * sy * 0.55);
    canvas.drawLine(discPos, tip, col);

    _slingArc.color = (pow > 0.7 ? AppColors.brandOrange : AppColors.fieldBlue).withValues(alpha: 0.5);
    canvas.drawArc(
      Rect.fromCircle(center: discPos, radius: GameConstants.discRadius * sx + 4),
      -math.pi / 2,
      math.pi * 2 * pow,
      false,
      _slingArc,
    );
  }

  @override
  bool shouldRepaint(covariant GamePainter old) {
    return old.sx != sx ||
        old.sy != sy ||
        old.discColor != discColor ||
        old.boardTheme != boardTheme ||
        old.game.mySeat != game.mySeat ||
        old.game.localDuoMode != game.localDuoMode;
  }
}
