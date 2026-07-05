import 'package:flutter/material.dart';

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
  });

  final int index;
  final Widget child;
  final int delayMs;

  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(_fade);
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
      child: SlideTransition(position: _slide, child: widget.child),
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
