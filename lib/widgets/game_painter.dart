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

class GamePainter extends CustomPainter {
  GamePainter({
    required this.discs,
    required this.mySeat,
    required this.drags,
    required this.visualGeneration,
    required this.sx,
    required this.sy,
    this.localDuoMode = false,
    this.myDiscColor = 'green',
    this.boardTheme = 'classic',
  });

  final List<Disc> discs;
  final int mySeat;
  final List<DragState> drags;
  final int visualGeneration;
  final double sx;
  final double sy;
  final bool localDuoMode;
  final String myDiscColor;
  final String boardTheme;

  static const _fieldVersion = 4;
  static ui.Picture? _fieldPicture;
  static Size? _fieldSize;
  static int? _fieldSeat;
  static String? _fieldBoardTheme;
  static int? _fieldVersionCached;

  Offset _s2c(double vx, double vy) => Offset(vx * sx, vy * sy);

  ui.Picture _fieldPictureFor(Size size) {
    if (_fieldPicture != null &&
        _fieldSize == size &&
        _fieldSeat == mySeat &&
        _fieldBoardTheme == boardTheme &&
        _fieldVersionCached == _fieldVersion) {
      return _fieldPicture!;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    _drawFieldStatic(canvas, size);
    _fieldPicture = recorder.endRecording();
    _fieldSize = size;
    _fieldSeat = mySeat;
    _fieldBoardTheme = boardTheme;
    _fieldVersionCached = _fieldVersion;
    return _fieldPicture!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (mySeat == 1 && !localDuoMode) {
      canvas.translate(size.width, size.height);
      canvas.rotate(math.pi);
    }

    canvas.drawPicture(_fieldPictureFor(size));
    for (final d in discs) {
      _drawDisc(canvas, d);
    }
    for (final drag in drags) {
      if (drag.discIndex < discs.length) {
        _drawSling(canvas, discs[drag.discIndex], drag);
      }
    }
    canvas.restore();
  }

  void _drawFieldStatic(Canvas canvas, Size size) {
    final palette = CosmeticsTheme.boardPalette(boardTheme);
    final gap = _s2c(GameConstants.gapX, GameConstants.gapY);
    final gw = GameConstants.gapW * sx;
    final gh = GameConstants.gapH * sy;
    final hw = size.width;
    final hh = size.height / 2;

    _drawSpaceHalf(canvas, Rect.fromLTWH(0, 0, hw, hh), palette.topGrass, palette.topTint, palette);
    _drawSpaceHalf(canvas, Rect.fromLTWH(0, hh, hw, hh), palette.bottomGrass, palette.bottomTint, palette);
    _drawStarfield(canvas, size, palette);
    _drawNeonGrid(canvas, size, palette);

    _neonLine(canvas, Offset(0, hh), Offset(hw, hh), palette.neonPrimary, width: 1.5);
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

  void _drawSpaceHalf(Canvas canvas, Rect rect, Color base, Color tint, BoardPalette palette) {
    final mid = Color.lerp(base, palette.neonPrimary, 0.08)!;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(base, Colors.white, 0.04)!, mid, base],
        ).createShader(rect),
    );
    if (tint.a > 0) canvas.drawRect(rect, Paint()..color = tint);
  }

  void _drawStarfield(Canvas canvas, Size size, BoardPalette palette) {
    final rng = math.Random(42);
    for (var i = 0; i < 55; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 1.2 + 0.3;
      final alpha = rng.nextDouble() * 0.35 + 0.08;
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );
    }
  }

  void _drawNeonGrid(Canvas canvas, Size size, BoardPalette palette) {
    final gridPaint = Paint()
      ..color = palette.gridColor
      ..strokeWidth = 0.6;
    const step = 24.0;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _neonLine(Canvas canvas, Offset a, Offset b, Color color, {double width = 1.5}) {
    canvas.drawLine(
      a,
      b,
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..strokeWidth = width + 5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawLine(a, b, Paint()..color = color..strokeWidth = width);
  }

  void _neonCircle(Canvas canvas, Offset c, double r, Color color) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = color.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _neonRect(Canvas canvas, RRect rrect, Color color) {
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
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
      Paint()
        ..shader = LinearGradient(
          colors: [
            palette.wall,
            Color.lerp(palette.wall, palette.neonPrimary, 0.35)!,
            palette.wall,
          ],
        ).createShader(rect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()
        ..color = palette.neonPrimary.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawPortalGoal(Canvas canvas, Rect rect, BoardPalette palette) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.gateFill,
            palette.neonSecondary.withValues(alpha: 0.35),
          ],
        ).createShader(rect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      Paint()
        ..color = palette.gateStroke.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      Paint()
        ..color = palette.gateStroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawDisc(Canvas canvas, Disc d) {
    final pos = _s2c(d.vx, d.vy);
    final r = GameConstants.discRadius * sx;
    final moving = d.vvx.abs() + d.vvy.abs() > 0.35;

    final defaultColor = d.owner == 0 ? AppColors.red : AppColors.blue;
    final isMine = d.owner == mySeat;
    final usePremium = isMine && CosmeticCatalog.isPremiumDisc(myDiscColor);
    final img = usePremium ? DiscImageCache.imageFor(myDiscColor) : null;

    if (img != null) {
      if (!moving) {
        canvas.drawCircle(
          pos,
          r + 4,
          Paint()..color = Colors.white.withValues(alpha: 0.1),
        );
      }
      final dst = Rect.fromCircle(center: pos, radius: r);
      canvas.save();
      canvas.clipRRect(RRect.fromRectAndRadius(dst, Radius.circular(r)));
      paintImage(
        canvas: canvas,
        rect: dst,
        image: img,
        fit: BoxFit.cover,
        filterQuality: moving ? FilterQuality.low : FilterQuality.medium,
      );
      canvas.restore();
      canvas.drawCircle(
        pos,
        r,
        Paint()
          ..color = Colors.white.withValues(alpha: moving ? 0.35 : 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      return;
    }

    final color = localDuoMode
        ? defaultColor
        : (isMine ? CosmeticsTheme.discColor(myDiscColor) : defaultColor);

    if (!moving) {
      canvas.drawCircle(
        pos,
        r + 4,
        Paint()..color = color.withValues(alpha: 0.15),
      );
    }

    final discPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [
          Color.lerp(color, Colors.white, 0.5)!,
          color,
          Color.lerp(color, Colors.black, 0.35)!,
        ],
      ).createShader(Rect.fromCircle(center: pos, radius: r));
    canvas.drawCircle(pos, r, discPaint);

    canvas.drawCircle(
      pos,
      r,
      Paint()
        ..color = color.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    if (moving) return;

    canvas.drawCircle(
      pos,
      r * 0.38,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    final spokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (var k = 0; k < 5; k++) {
      final a = (k / 5) * math.pi * 2 - math.pi / 2;
      canvas.drawLine(
        Offset(pos.dx + math.cos(a) * r * 0.38, pos.dy + math.sin(a) * r * 0.38),
        Offset(pos.dx + math.cos(a) * r * 0.88, pos.dy + math.sin(a) * r * 0.88),
        spokePaint,
      );
    }
    canvas.drawCircle(pos, 2.5, Paint()..color = Colors.white);
  }

  void _drawSling(Canvas canvas, Disc d, DragState drag) {
    final discPos = _s2c(d.vx, d.vy);
    final pullPos = _s2c(drag.currentVx, drag.currentVy);
    final ddx = drag.currentVx - drag.startVx;
    final ddy = drag.currentVy - drag.startVy;
    final dist = math.sqrt(ddx * ddx + ddy * ddy);
    if (dist < 3) return;

    final lim = math.min(dist, GameConstants.slingMax);
    final pow = lim / GameConstants.slingMax;
    final nx = -ddx / dist;
    final ny = -ddy / dist;

    _neonLine(canvas, discPos, pullPos, AppColors.fieldBlue, width: 1.5);

    final col = pow > 0.7 ? AppColors.brandOrange : AppColors.fieldBlue;
    final tip = Offset(discPos.dx + nx * lim * sx * 0.55, discPos.dy + ny * lim * sy * 0.55);
    _neonLine(canvas, discPos, tip, col, width: 2.5);

    final r = GameConstants.discRadius * sx;
    canvas.drawArc(
      Rect.fromCircle(center: discPos, radius: r + 5),
      -math.pi / 2,
      math.pi * 2 * pow,
      false,
      Paint()
        ..color = col.withValues(alpha: 0.35)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
    canvas.drawArc(
      Rect.fromCircle(center: discPos, radius: r + 5),
      -math.pi / 2,
      math.pi * 2 * pow,
      false,
      Paint()
        ..color = col
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant GamePainter old) {
    return old.visualGeneration != visualGeneration ||
        old.mySeat != mySeat ||
        old.localDuoMode != localDuoMode ||
        old.sx != sx ||
        old.sy != sy ||
        old.drags.length != drags.length ||
        old.myDiscColor != myDiscColor ||
        old.boardTheme != boardTheme;
  }
}
