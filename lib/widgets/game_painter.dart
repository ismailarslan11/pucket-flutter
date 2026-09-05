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
    this.oppDiscColor = '',
  }) : super(repaint: game.boardRepaint);

  final GameController game;
  final double sx;
  final double sy;
  final String discColor;
  final String oppDiscColor;
  final String boardTheme;

  static const _fieldVersion = 6;
  static ui.Picture? _fieldPicture;
  static Size? _fieldSize;
  static int? _fieldSeat;
  static String? _fieldBoardTheme;
  static int? _fieldVersionCached;

  static final _discStroke = Paint()
    ..color = Color(0x59FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;
  static final _premiumPaint = Paint()..filterQuality = FilterQuality.low;
  static final _emojiPictureCache = <String, ui.Picture>{};
  static final _fancyDiscCache = <String, ui.Picture>{};
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
    // Ekran sarsıntısı (juice) — tüm tahtayı hafifçe kaydır.
    if (game.fx.shakeX != 0 || game.fx.shakeY != 0) {
      canvas.translate(game.fx.shakeX, game.fx.shakeY);
    }
    if (mySeat == 1 && !localDuo) {
      canvas.translate(size.width, size.height);
      canvas.rotate(math.pi);
    }

    canvas.drawPicture(_fieldPictureFor(size, mySeat));

    // Raunt skoru filigranı: zeminin üstünde, pulların altında. Aynı dönüşüm
    // ikinci kez uygulanınca (180° + 180°) ekran eksenine dönülür, böylece
    // koltuk 1'de rakamlar ters durmaz.
    canvas.save();
    if (mySeat == 1 && !localDuo) {
      canvas.translate(size.width, size.height);
      canvas.rotate(math.pi);
    }
    _drawRoundWins(canvas, size, localDuo ? 0 : mySeat);
    canvas.restore();

    for (var i = 0; i < discs.length; i++) {
      _drawDisc(
        canvas,
        discs[i],
        i,
        mySeat: mySeat,
        localDuo: localDuo,
        fast: fastDraw,
      );
    }
    for (final drag in drags) {
      if (drag.discIndex < discs.length) {
        _drawSling(canvas, discs[drag.discIndex], drag);
      }
    }
    _drawParticles(canvas);
    canvas.restore();
  }

  // Rakamlar her karede yeniden dizilmesin: değer veya ölçü değişmedikçe
  // aynı TextPainter kullanılıyor. Tahta oynanış boyunca 60 fps yenileniyor.
  TextPainter? _winTop;
  TextPainter? _winBottom;
  String _winKey = '';

  /// Her takımın kazandığı raunt sayısı, kendi yarı sahasının ortasında.
  ///
  /// Önce üst şeritte dolan daireler vardı; şerit süre ve duraklat dışında
  /// boşaltılınca skor tahtaya indi. Oyuncu gözünü kendi yarısından ayırmadan
  /// kaçta kaç olduğunu görüyor.
  void _drawRoundWins(Canvas canvas, Size size, int bottomOwner) {
    final topOwner = 1 - bottomOwner;
    final fontSize = size.width * 0.34;
    final key = '${game.roundWins[topOwner]}:${game.roundWins[bottomOwner]}'
        ':$topOwner:${fontSize.toStringAsFixed(1)}';
    if (key != _winKey) {
      TextPainter build(int owner) => TextPainter(
            text: TextSpan(
              text: '${game.roundWins[owner]}',
              style: TextStyle(
                color: (owner == 0 ? AppColors.red : AppColors.blue)
                    .withValues(alpha: 0.14),
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
      _winTop = build(topOwner);
      _winBottom = build(bottomOwner);
      _winKey = key;
    }
    void put(TextPainter? tp, double cy) {
      if (tp == null) return;
      tp.paint(canvas, Offset((size.width - tp.width) / 2, cy - tp.height / 2));
    }
    put(_winTop, size.height * 0.25);
    put(_winBottom, size.height * 0.75);
  }

  void _drawParticles(Canvas canvas) {
    final particles = game.fx.particles;
    if (particles.isEmpty) return;
    final paint = Paint();
    for (final p in particles) {
      final t = (p.life / p.maxLife).clamp(0.0, 1.0);
      paint.color = p.color.withValues(alpha: t);
      canvas.drawCircle(_s2c(p.x, p.y), p.size * (0.4 + t * 0.6), paint);
    }
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

  void _drawDisc(
    Canvas canvas,
    Disc d,
    int index, {
    required int mySeat,
    required bool localDuo,
    required bool fast,
  }) {
    final rx = fast ? game.renderDiscX(index) : d.vx;
    final ry = fast ? game.renderDiscY(index) : d.vy;
    final pos = _s2c(rx, ry);
    final r = GameConstants.discRadius * sx;
    final isMine = d.owner == mySeat;
    // Rakibin premium/emoji skin'i de gösterilir (düz renkler karışmasın diye
    // sadece resim/emoji tabanlı kozmetikler; kırmızı/mavi kimliği korunur).
    final cosmetic = isMine ? discColor : oppDiscColor;

    if (cosmetic.isNotEmpty && CosmeticCatalog.isEmojiDisc(cosmetic)) {
      _drawEmojiDisc(canvas, pos, r, CosmeticCatalog.emojiDisc(cosmetic)!);
      return;
    }

    final usePremium = cosmetic.isNotEmpty && CosmeticCatalog.isImageDisc(cosmetic);
    final img = usePremium ? DiscImageCache.imageFor(cosmetic) : null;

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

    final defaultColor = d.owner == 0 ? AppColors.red : AppColors.blue;
    final color = (localDuo || fast)
        ? defaultColor
        : (isMine ? CosmeticsTheme.discColor(discColor) : defaultColor);

    _drawFancyDisc(canvas, pos, r, color);
  }

  /// Düz renkli pulları 3D görünümle çizer: radyal parlaklık, jant halkası,
  /// iç oluk ve cam parlaması. Sonuç Picture olarak önbelleklenir.
  void _drawFancyDisc(Canvas canvas, Offset pos, double r, Color color) {
    final bucket = (r * 2).round() / 2;
    final key = '${color.toARGB32()}@$bucket';
    final picture = _fancyDiscCache.putIfAbsent(key, () {
      final recorder = ui.PictureRecorder();
      final c = Canvas(recorder);
      const center = Offset.zero;
      final rr = bucket;

      Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;
      final light = mix(color, Colors.white, 0.42);
      final dark = mix(color, Colors.black, 0.38);
      final rim = mix(color, Colors.black, 0.52);

      // Gövde: üst-soldan ışık alan radyal geçiş (3D kubbe hissi).
      c.drawCircle(
        center,
        rr,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(-rr * 0.35, -rr * 0.42),
            rr * 1.9,
            [light, color, dark],
            [0.0, 0.55, 1.0],
          ),
      );

      // Jant: dış kenarda koyu makine halkası.
      c.drawCircle(
        center,
        rr * 0.93,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rr * 0.13
          ..color = rim.withValues(alpha: 0.85),
      );

      // İç oluk: dama pulu oyuğu (koyu ince halka + hemen içinde açık halka).
      c.drawCircle(
        center,
        rr * 0.60,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rr * 0.07
          ..color = dark.withValues(alpha: 0.55),
      );
      c.drawCircle(
        center,
        rr * 0.50,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rr * 0.045
          ..color = light.withValues(alpha: 0.35),
      );

      // Cam parlaması: üst-solda yumuşak beyaz leke.
      c.drawCircle(
        Offset(-rr * 0.34, -rr * 0.40),
        rr * 0.52,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(-rr * 0.34, -rr * 0.40),
            rr * 0.52,
            [Colors.white.withValues(alpha: 0.42), Colors.white.withValues(alpha: 0.0)],
          ),
      );

      // Dış kontur — mevcut ince beyaz çizgi korunur.
      c.drawCircle(center, rr, _discStroke);
      return recorder.endRecording();
    });

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.drawPicture(picture);
    canvas.restore();
  }

  void _drawEmojiDisc(Canvas canvas, Offset pos, double r, CosmeticItem item) {
    final bucket = (r * 2).round() / 2;
    final key = '${item.id}@$bucket';
    final picture = _emojiPictureCache.putIfAbsent(key, () {
      final recorder = ui.PictureRecorder();
      final c = Canvas(recorder);
      const center = Offset.zero;
      c.drawCircle(center, bucket, Paint()..color = item.bgColor);
      c.drawCircle(center, bucket, _discStroke);
      final emojiSize = bucket * 1.35;
      final tp = TextPainter(
        text: TextSpan(text: item.emoji, style: TextStyle(fontSize: emojiSize, height: 1)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, Offset(-tp.width / 2, -tp.height / 2));
      return recorder.endRecording();
    });

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.drawPicture(picture);
    canvas.restore();
  }

  void _drawSling(Canvas canvas, Disc d, DragState drag) {
    final idx = drag.discIndex;
    final rx = game.phase == GamePhase.playing ? game.renderDiscX(idx) : d.vx;
    final ry = game.phase == GamePhase.playing ? game.renderDiscY(idx) : d.vy;
    final discPos = _s2c(rx, ry);
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
        old.oppDiscColor != oppDiscColor ||
        old.boardTheme != boardTheme ||
        old.game.mySeat != game.mySeat ||
        old.game.localDuoMode != game.localDuoMode ||
        old.game.roundWins[0] != game.roundWins[0] ||
        old.game.roundWins[1] != game.roundWins[1];
  }
}
