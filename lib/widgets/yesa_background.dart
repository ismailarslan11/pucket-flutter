import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Canlı gradient arka plan — yumuşak neon ışımalar, süzülen pul halkaları,
/// parıltılar ve kenar vinyeti.
class YesaBackground extends StatefulWidget {
  const YesaBackground({
    super.key,
    required this.child,
    this.warm = false,
  });

  final Widget child;
  final bool warm;

  @override
  State<YesaBackground> createState() => _YesaBackgroundState();
}

class _YesaBackgroundState extends State<YesaBackground> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) => CustomPaint(
            painter: _YesaStripePainter(warm: widget.warm, t: _ctrl.value),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _YesaStripePainter extends CustomPainter {
  _YesaStripePainter({this.warm = false, required this.t});

  final bool warm;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final baseTop = warm ? AppColors.geceLacivert : AppColors.laciDerin;
    final baseMid = warm ? AppColors.laciOrta : AppColors.koyuMavi;
    final baseBottom = AppColors.laciDerin;

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [baseTop, baseMid, baseBottom],
          stops: const [0, 0.45, 1],
        ).createShader(Offset.zero & size),
    );

    final pulse = math.sin(t * math.pi * 2) * 0.5 + 0.5;
    _glow(canvas, size, Offset(0.1 + math.sin(t * math.pi * 2) * 0.04, 0.08), 150,
        AppColors.anaMavi.withValues(alpha: 0.30 + pulse * 0.10));
    _glow(canvas, size, Offset(0.9 + math.cos(t * math.pi * 2) * 0.03, 0.12), 120,
        AppColors.parlakMavi.withValues(alpha: 0.22 + pulse * 0.08));
    _glow(canvas, size, Offset(0.75 + math.sin(t * math.pi * 2 + 1) * 0.05, 0.82), 170,
        AppColors.sariAna.withValues(alpha: 0.18 + pulse * 0.06));
    _glow(canvas, size, Offset(0.06, 0.65 + math.cos(t * math.pi * 2) * 0.04), 130,
        AppColors.gokAcik.withValues(alpha: 0.24 + pulse * 0.08));
    _glow(canvas, size, const Offset(0.5, 0.45), 200,
        AppColors.vurguMavi.withValues(alpha: 0.10 + pulse * 0.05));

    // Yukarı süzülen pul halkaları — oyun teması.
    final ringPaint = Paint()..style = PaintingStyle.stroke;
    final rng0 = math.Random(11);
    for (var i = 0; i < 6; i++) {
      final speed = 0.35 + rng0.nextDouble() * 0.5;
      final x = rng0.nextDouble();
      final phase = rng0.nextDouble();
      final y = 1.15 - ((t * speed + phase) % 1.3);
      final r = 7.0 + rng0.nextDouble() * 9;
      final fade = (1.15 - y).clamp(0.0, 1.0) * (y + 0.15).clamp(0.0, 1.0);
      final col = i.isEven ? AppColors.acikMavi : AppColors.gokAcik;
      ringPaint
        ..color = col.withValues(alpha: 0.10 * fade)
        ..strokeWidth = 2.2;
      final c = Offset(size.width * x, size.height * y);
      canvas.drawCircle(c, r, ringPaint);
      // İç oluk — dama pulu hissi.
      ringPaint
        ..color = col.withValues(alpha: 0.05 * fade)
        ..strokeWidth = 1;
      canvas.drawCircle(c, r * 0.55, ringPaint);
    }

    // Parıltı noktaları
    final rng = math.Random(7);
    for (var i = 0; i < 24; i++) {
      final bx = rng.nextDouble() * size.width;
      final by = rng.nextDouble() * size.height;
      final flicker = (math.sin(t * math.pi * 2 + i * 1.7) * 0.5 + 0.5);
      canvas.drawCircle(
        Offset(bx, by),
        0.8 + rng.nextDouble() * 1.2,
        Paint()..color = AppColors.beyaz.withValues(alpha: 0.04 + flicker * 0.12),
      );
    }

    const stripeW = 38.0;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-math.pi / 4 + t * 0.02);
    canvas.translate(-size.width, -size.height);
    final diag = size.width + size.height;
    for (var x = -diag; x < diag * 2; x += stripeW) {
      final i = ((x + diag) / stripeW).floor();
      canvas.drawRect(
        Rect.fromLTWH(x, -diag, stripeW / 2, diag * 3),
        Paint()
          ..color = i.isEven
              ? AppColors.anaMavi.withValues(alpha: 0.07)
              : AppColors.laciDerin.withValues(alpha: 0.12),
      );
    }
    canvas.restore();

    // Kenar vinyeti — içeriğe derinlik katar.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.15,
          colors: [
            Colors.transparent,
            Colors.transparent,
            AppColors.laciDerin.withValues(alpha: 0.55),
          ],
          stops: const [0.0, 0.62, 1.0],
        ).createShader(Offset.zero & size),
    );

    // Üst kenar neon çizgi
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 2),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.acikMavi.withValues(alpha: 0.6),
            AppColors.sariAna.withValues(alpha: 0.5),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, 2)),
    );
  }

  /// Yumuşak kenarlı neon ışıma — merkezden dışa eriyen radyal geçiş.
  void _glow(Canvas canvas, Size size, Offset anchor, double r, Color color) {
    final c = Offset(size.width * anchor.dx, size.height * anchor.dy);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0.0)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  @override
  bool shouldRepaint(covariant _YesaStripePainter old) => old.warm != warm || old.t != t;
}
