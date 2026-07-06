import 'dart:math' as math;
import 'dart:ui';

/// Tahta koordinatlarında (vw/vh) yaşayan hafif parçacık.
class FxParticle {
  double x, y, vx, vy, life, maxLife, size;
  final Color color;
  FxParticle(this.x, this.y, this.vx, this.vy, this.life, this.size, this.color)
      : maxLife = life;
}

/// Oyun hissi (juice) yöneticisi: parçacıklar + ekran sarsıntısı.
/// Fizik adımıyla aynı hızda güncellenir; render tahta ölçeğiyle yapılır.
class GameFx {
  final List<FxParticle> particles = [];
  final _rng = math.Random();

  double _shake = 0;
  double shakeX = 0;
  double shakeY = 0;

  bool get active => particles.isNotEmpty || _shake > 0.05;

  void addShake(double amount) {
    _shake = math.min(_shake + amount, 14);
  }

  /// Bir noktada kıvılcım/patlama.
  void burst(
    double x,
    double y, {
    required int count,
    required Color color,
    double speed = 3,
    double size = 2.5,
  }) {
    for (var i = 0; i < count; i++) {
      final ang = _rng.nextDouble() * math.pi * 2;
      final sp = speed * (0.4 + _rng.nextDouble());
      particles.add(FxParticle(
        x,
        y,
        math.cos(ang) * sp,
        math.sin(ang) * sp,
        18 + _rng.nextDouble() * 14,
        size * (0.6 + _rng.nextDouble() * 0.8),
        color,
      ));
    }
    // Aşırı birikmeyi önle
    if (particles.length > 220) {
      particles.removeRange(0, particles.length - 220);
    }
  }

  /// Her fizik adımında çağrılır.
  void step() {
    if (_shake > 0.05) {
      _shake *= 0.86;
      shakeX = (_rng.nextDouble() * 2 - 1) * _shake;
      shakeY = (_rng.nextDouble() * 2 - 1) * _shake;
    } else {
      _shake = 0;
      shakeX = 0;
      shakeY = 0;
    }
    for (var i = particles.length - 1; i >= 0; i--) {
      final p = particles[i];
      p.x += p.vx;
      p.y += p.vy;
      p.vx *= 0.92;
      p.vy *= 0.92;
      p.life -= 1;
      if (p.life <= 0) particles.removeAt(i);
    }
  }

  void clear() {
    particles.clear();
    _shake = 0;
    shakeX = 0;
    shakeY = 0;
  }
}
