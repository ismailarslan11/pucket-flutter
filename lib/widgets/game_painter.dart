import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../game/game_constants.dart';
import '../game/game_controller.dart';
import '../models/disc.dart';
import '../theme/app_theme.dart';
import '../theme/cosmetics_theme.dart';

class GamePainter extends CustomPainter {
  GamePainter({
    required this.discs,
    required this.mySeat,
    required this.drag,
    required this.visualGeneration,
    required this.sx,
    required this.sy,
    this.myDiscColor = 'green',
    this.boardTheme = 'classic',
  });

  final List<Disc> discs;
  final int mySeat;
  final DragState? drag;
  final int visualGeneration;
  final double sx;
  final double sy;
  final String myDiscColor;
  final String boardTheme;

  static ui.Picture? _fieldPicture;
  static Size? _fieldSize;
  static int? _fieldSeat;
  static String? _fieldBoardTheme;

  Offset _s2c(double vx, double vy) => Offset(vx * sx, vy * sy);

  ui.Picture _fieldPictureFor(Size size) {
    if (_fieldPicture != null &&
        _fieldSize == size &&
        _fieldSeat == mySeat &&
        _fieldBoardTheme == boardTheme) {
      return _fieldPicture!;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    _drawFieldStatic(canvas, size);
    _fieldPicture = recorder.endRecording();
    _fieldSize = size;
    _fieldSeat = mySeat;
    _fieldBoardTheme = boardTheme;
    return _fieldPicture!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (mySeat == 1) {
      canvas.translate(size.width, size.height);
      canvas.rotate(math.pi);
    }

    canvas.drawPicture(_fieldPictureFor(size));
    for (final d in discs) {
      _drawDisc(canvas, d);
    }
    if (drag != null && drag!.discIndex < discs.length) {
      _drawSling(canvas, discs[drag!.discIndex], drag!);
    }
    canvas.restore();
  }

  void _drawFieldStatic(Canvas canvas, Size size) {
    final palette = CosmeticsTheme.boardPalette(boardTheme);
    final gap = _s2c(GameConstants.gapX, GameConstants.vHalf - 5);
    final gw = GameConstants.gapW * sx;
    final gh = 10 * sy;
    final hw = size.width;
    final hh = size.height / 2;

    canvas.drawRect(Rect.fromLTWH(0, 0, hw, hh), Paint()..color = palette.topGrass);
    canvas.drawRect(Rect.fromLTWH(0, hh, hw, hh), Paint()..color = palette.bottomGrass);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, hw, hh),
      Paint()..color = AppColors.blue.withValues(alpha: 0.07),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, hh, hw, hh),
      Paint()..color = AppColors.red.withValues(alpha: 0.07),
    );

    final linePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(hw / 2, hh / 2), hw * 0.12, linePaint);
    canvas.drawCircle(Offset(hw / 2, hh + hh / 2), hw * 0.12, linePaint);
    final pb = math.min(hh * 0.15, 55.0);
    canvas.drawRect(Rect.fromLTWH(hw * 0.28, 4, hw * 0.44, pb), linePaint);
    canvas.drawRect(Rect.fromLTWH(hw * 0.28, size.height - 4 - pb, hw * 0.44, pb), linePaint);

    final wallPaint = Paint()..color = palette.wall;
    canvas.drawRect(Rect.fromLTWH(0, hh - 7, gap.dx - 2, 14), wallPaint);
    canvas.drawRect(Rect.fromLTWH(gap.dx + gw + 2, hh - 7, hw, 14), wallPaint);

    final gapPaint = Paint()..color = palette.gateFill;
    canvas.drawRect(Rect.fromLTWH(gap.dx, gap.dy, gw, gh), gapPaint);
    final gapStroke = Paint()
      ..color = palette.gateStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(Rect.fromLTWH(gap.dx, gap.dy, gw, gh), gapStroke);

    canvas.save();
    if (mySeat == 1) {
      canvas.translate(size.width, size.height);
      canvas.rotate(math.pi);
    }
    final tp = TextPainter(
      text: TextSpan(
        text: mySeat == 0 ? 'MAVİ SAHA' : 'KIRMIZI SAHA',
        style: TextStyle(
          color: Colors.black.withValues(alpha: 0.2),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width / 2 - tp.width / 2, 16));

    final tp2 = TextPainter(
      text: TextSpan(
        text: mySeat == 0 ? 'KIRMIZI SAHA' : 'MAVİ SAHA',
        style: TextStyle(
          color: Colors.black.withValues(alpha: 0.2),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp2.paint(canvas, Offset(size.width / 2 - tp2.width / 2, size.height - 20));

    final tp3 = TextPainter(
      text: TextSpan(
        text: '▲ SEN ▲',
        style: TextStyle(
          color: (mySeat == 0 ? AppColors.red : AppColors.blue).withValues(alpha: 0.35),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp3.paint(canvas, Offset(size.width / 2 - tp3.width / 2, size.height / 2 + 15));
    canvas.restore();
  }

  void _drawDisc(Canvas canvas, Disc d) {
    final pos = _s2c(d.vx, d.vy);
    final r = GameConstants.discRadius * sx;

    canvas.drawCircle(
      Offset(pos.dx + 1, pos.dy + 2),
      r,
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );

    final defaultColor = d.owner == 0 ? AppColors.red : AppColors.blue;
    final color = d.owner == mySeat ? CosmeticsTheme.discColor(myDiscColor) : defaultColor;
    canvas.drawCircle(pos, r, Paint()..color = color);
    canvas.drawCircle(
      pos,
      r,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(
      pos,
      r * 0.44,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final spokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var k = 0; k < 5; k++) {
      final a = (k / 5) * math.pi * 2 - math.pi / 2;
      canvas.drawLine(
        Offset(pos.dx + math.cos(a) * r * 0.44, pos.dy + math.sin(a) * r * 0.44),
        Offset(pos.dx + math.cos(a) * r * 0.87, pos.dy + math.sin(a) * r * 0.87),
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

    final dashPaint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.85)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(discPos, pullPos, dashPaint);

    final col = pow > 0.7 ? const Color(0xFFFF4444) : const Color(0xFFFFCC00);
    final arrowPaint = Paint()
      ..color = col
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      discPos,
      Offset(discPos.dx + nx * lim * sx * 0.55, discPos.dy + ny * lim * sy * 0.55),
      arrowPaint,
    );

    final arcPaint = Paint()
      ..color = col
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final r = GameConstants.discRadius * sx;
    canvas.drawArc(
      Rect.fromCircle(center: discPos, radius: r + 4),
      -math.pi / 2,
      math.pi * 2 * pow,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant GamePainter old) {
    return old.visualGeneration != visualGeneration ||
        old.mySeat != mySeat ||
        old.sx != sx ||
        old.sy != sy ||
        old.drag != drag ||
        old.myDiscColor != myDiscColor ||
        old.boardTheme != boardTheme;
  }
}
