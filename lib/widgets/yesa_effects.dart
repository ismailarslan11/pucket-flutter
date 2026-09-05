import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Dokununca hafif küçülme — oyun hissi.
class ScalePress extends StatefulWidget {
  const ScalePress({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.94,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<ScalePress> createState() => _ScalePressState();
}

class _ScalePressState extends State<ScalePress> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 90));
    _anim = Tween<double>(begin: 1, end: widget.scale).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _anim, child: widget.child),
    );
  }
}

/// Menü öğeleri için kademeli giriş animasyonu.
class StaggerIn extends StatefulWidget {
  const StaggerIn({
    super.key,
    required this.index,
    required this.child,
    this.delayMs = 45,
    this.bounce = false,
  });

  final int index;
  final Widget child;
  final int delayMs;

  /// Elastik yaylanma: kahraman öğelerin girişinde kullanılır. Kayarak
  /// belirmek sakin, yaylanarak belirmek oyunsu okunuyor.
  final bool bounce;

  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.bounce ? 720 : 420),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(widget.bounce
            ? CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut)
            : _fade);
    _scale = Tween<double>(begin: widget.bounce ? 0.82 : 1.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _ctrl,
            curve: widget.bounce ? Curves.elasticOut : Curves.linear));
    Future.delayed(Duration(milliseconds: widget.index * widget.delayMs), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(scale: _scale, child: widget.child),
      ),
    );
  }
}

/// Neon parıltı — öne çıkan öğeler için.
class GlowPulse extends StatefulWidget {
  const GlowPulse({
    super.key,
    required this.child,
    required this.color,
    this.min = 0.35,
    this.max = 0.85,
  });

  final Widget child;
  final Color color;
  final double min;
  final double max;

  @override
  State<GlowPulse> createState() => _GlowPulseState();
}

class _GlowPulseState extends State<GlowPulse> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = widget.min + (widget.max - widget.min) * _ctrl.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(color: widget.color.withValues(alpha: t * 0.55), blurRadius: 18, spreadRadius: 1),
              BoxShadow(color: widget.color.withValues(alpha: t * 0.25), blurRadius: 32, spreadRadius: 2),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Yumuşak aşağı-yukarı süzülme — logo ve madalyonlar için.
class FloatY extends StatefulWidget {
  const FloatY({super.key, required this.child, this.amplitude = 4, this.durationMs = 2600});

  final Widget child;
  final double amplitude;
  final int durationMs;

  @override
  State<FloatY> createState() => _FloatYState();
}

class _FloatYState extends State<FloatY> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: Duration(milliseconds: widget.durationMs))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, math.sin(_ctrl.value * 2 * math.pi) * widget.amplitude),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Parıldayan yıldız — faz kaydırmalı opaklık nabzı.
class Twinkle extends StatefulWidget {
  const Twinkle({super.key, this.size = 12, this.phase = 0, this.color});

  final double size;
  final double phase;
  final Color? color;

  @override
  State<Twinkle> createState() => _TwinkleState();
}

class _TwinkleState extends State<Twinkle> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final t = (_ctrl.value + widget.phase) % 1.0;
        final a = 0.25 + 0.75 * (0.5 + 0.5 * math.sin(t * 2 * math.pi));
        return Opacity(
          opacity: a,
          child: Icon(Icons.auto_awesome, color: widget.color ?? AppColors.sariAna, size: widget.size),
        );
      },
    );
  }
}

/// Radar dalgası — merkezden dışa yayılan halkalar (eşleşme aranıyor hissi).
class RadarPulse extends StatefulWidget {
  const RadarPulse({super.key, required this.child, this.size = 120, this.color, this.active = true});

  final Widget child;
  final double size;
  final Color? color;
  final bool active;

  @override
  State<RadarPulse> createState() => _RadarPulseState();
}

class _RadarPulseState extends State<RadarPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.gokAcik;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.active)
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, _) => CustomPaint(
                size: Size.square(widget.size),
                painter: _RadarPainter(t: _ctrl.value, color: color),
              ),
            ),
          widget.child,
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.t, required this.color});

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;
    for (var i = 0; i < 3; i++) {
      final p = (t + i / 3) % 1.0;
      final r = maxR * (0.35 + 0.65 * p);
      final a = (1 - p) * 0.5;
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: a),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) => old.t != t;
}

/// Konfeti yağmuru — zafer anları için döngülü, hafif parçacıklar.
class ConfettiRain extends StatefulWidget {
  const ConfettiRain({super.key, this.count = 42, this.colors});

  final int count;

  /// Özel renk paleti (zafer efekti kozmetiği); null = klasik karışım.
  final List<Color>? colors;

  @override
  State<ConfettiRain> createState() => _ConfettiRainState();
}

class _ConfettiRainState extends State<ConfettiRain> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(t: _ctrl.value, count: widget.count, colors: widget.colors),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.t, required this.count, this.colors});

  final double t;
  final int count;
  final List<Color>? colors;

  static const _colors = [
    AppColors.sariAna,
    AppColors.acikMavi,
    AppColors.gokAcik,
    AppColors.parlakMavi,
    AppColors.neonYesil,
    AppColors.turuncuAna,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(23);
    final paint = Paint();
    for (var i = 0; i < count; i++) {
      final x0 = rng.nextDouble();
      final phase = rng.nextDouble();
      final speed = 0.5 + rng.nextDouble() * 0.7;
      final sway = 0.02 + rng.nextDouble() * 0.04;
      final w = 4.0 + rng.nextDouble() * 4;
      final h = 6.0 + rng.nextDouble() * 5;
      final palette = colors ?? _colors;
      final color = palette[i % palette.length];
      final spin = rng.nextDouble() * math.pi * 2;

      final p = (t * speed + phase) % 1.15;
      final y = p * (size.height + 40) - 20;
      final x = (x0 + math.sin((t * 2 + phase) * math.pi * 2) * sway) * size.width;
      final fadeIn = (p * 8).clamp(0.0, 1.0);
      final fadeOut = ((1.15 - p) * 4).clamp(0.0, 1.0);

      paint.color = color.withValues(alpha: 0.85 * fadeIn * fadeOut);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(spin + t * math.pi * 4 * (i.isEven ? 1 : -1));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}

/// Önemli butonlar için yumuşak nabız (büyüyüp küçülme) animasyonu.
class PulseScale extends StatefulWidget {
  const PulseScale({
    super.key,
    required this.child,
    this.min = 1.0,
    this.max = 1.035,
    this.durationMs = 1300,
    this.enabled = true,
  });

  final Widget child;
  final double min;
  final double max;
  final int durationMs;
  final bool enabled;

  @override
  State<PulseScale> createState() => _PulseScaleState();
}

class _PulseScaleState extends State<PulseScale> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final t = Curves.easeInOut.transform(_ctrl.value);
        return Transform.scale(
          scale: widget.min + (widget.max - widget.min) * t,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Kartın üzerinden periyodik geçen çapraz ışık bandı (vitrin parlaması).
/// Bir Stack içine `Positioned.fill` yerine doğrudan eklenir; kendi kendini
/// konumlandırır ve dokunuşları engellemez.
class ShineOverlay extends StatefulWidget {
  const ShineOverlay({super.key, this.periodMs = 3200, this.opacity = 0.22});

  final int periodMs;
  final double opacity;

  @override
  State<ShineOverlay> createState() => _ShineOverlayState();
}

class _ShineOverlayState extends State<ShineOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.periodMs),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, _) => CustomPaint(
            painter: _ShinePainter(t: _ctrl.value, opacity: widget.opacity),
          ),
        ),
      ),
    );
  }
}

class _ShinePainter extends CustomPainter {
  _ShinePainter({required this.t, required this.opacity});

  final double t;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    // Bandın hızlı geçip uzun beklemesi: sadece döngünün ilk %45'inde görünür.
    final phase = t / 0.45;
    if (phase > 1) return;
    final x = size.width * (phase * 1.8 - 0.4);
    final band = size.width * 0.22;
    canvas.save();
    canvas.translate(x, 0);
    canvas.skew(-0.35, 0);
    canvas.drawRect(
      Rect.fromLTWH(0, -size.height, band, size.height * 3),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: opacity),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, band, size.height)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ShinePainter old) => old.t != t;
}
