import 'package:flutter/material.dart';

/// Uygulama açılışında gösterilen animasyonlu Yesa Studio marka ekranı.
class BrandSplash extends StatefulWidget {
  const BrandSplash({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<BrandSplash> createState() => _BrandSplashState();
}

class _BrandSplashState extends State<BrandSplash> with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final AnimationController _outCtrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _outCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _fade = CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.5, curve: Curves.easeOut));
    _scale = Tween<double>(begin: 0.86, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _glow = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);

    _ctrl.forward();
    // Giriş + bekleme sonrası çıkış.
    Future.delayed(const Duration(milliseconds: 2200), () async {
      if (!mounted) return;
      await _outCtrl.forward();
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _outCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_ctrl, _outCtrl]),
      builder: (context, _) {
        final outFade = 1.0 - _outCtrl.value;
        return Opacity(
          opacity: outFade,
          child: Container(
            color: Colors.white,
            alignment: Alignment.center,
            child: FadeTransition(
              opacity: _fade,
              child: Transform.scale(
                scale: _scale.value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Çok yumuşak, dağınık marka parıltısı (belirgin daire değil).
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2DE1C2).withValues(alpha: 0.06 * _glow.value),
                            blurRadius: 120,
                            spreadRadius: 8,
                          ),
                          BoxShadow(
                            color: const Color(0xFF9B6BFF).withValues(alpha: 0.06 * _glow.value),
                            blurRadius: 120,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Image.asset(
                        'assets/images/yesa_studio_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
