import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Canlı gradient arka plan — yüzen neon blob'lar + parıltılar.
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
    final baseTop = warm ? AppColors.geceLacivert : AppColors.morDahaKoyu;
    final baseMid = warm ? AppColors.morKoyu : AppColors.koyuMor;
    final baseBottom = AppColors.morDahaKoyu;

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
    _blob(canvas, size, Offset(0.1 + math.sin(t * math.pi * 2) * 0.04, 0.08), 130,
        AppColors.anaMor.withValues(alpha: 0.22 + pulse * 0.08));
    _blob(canvas, size, Offset(0.9 + math.cos(t * math.pi * 2) * 0.03, 0.12), 100,
        AppColors.pembe.withValues(alpha: 0.16 + pulse * 0.06));
    _blob(canvas, size, Offset(0.75 + math.sin(t * math.pi * 2 + 1) * 0.05, 0.82), 150,
        AppColors.sariAna.withValues(alpha: 0.14 + pulse * 0.05));
    _blob(canvas, size, Offset(0.06, 0.65 + math.cos(t * math.pi * 2) * 0.04), 110,
        AppColors.camgobegi.withValues(alpha: 0.18 + pulse * 0.06));
    _blob(canvas, size, const Offset(0.5, 0.45), 180,
        AppColors.vurguMoru.withValues(alpha: 0.06 + pulse * 0.04));

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
              ? AppColors.anaMor.withValues(alpha: 0.07)
              : AppColors.morDahaKoyu.withValues(alpha: 0.12),
      );
    }
    canvas.restore();

    // Üst kenar neon çizgi
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 2),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.acikMor.withValues(alpha: 0.6),
            AppColors.sariAna.withValues(alpha: 0.5),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, 2)),
    );
  }

  void _blob(Canvas canvas, Size size, Offset anchor, double r, Color color) {
    canvas.drawCircle(
      Offset(size.width * anchor.dx, size.height * anchor.dy),
      r,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _YesaStripePainter old) => old.warm != warm || old.t != t;
}
