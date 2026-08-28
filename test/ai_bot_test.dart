import 'package:flutter_test/flutter_test.dart';
import 'package:pucket_flutter/game/ai_bot.dart';
import 'package:pucket_flutter/game/game_constants.dart';
import 'package:pucket_flutter/game/physics_engine.dart';
import 'package:pucket_flutter/models/disc.dart';

/// Botun tek bir pulu, tahtanın her yerinden, en fazla [shots] atışta karşı
/// yarıya geçirebilme oranı. Bot rastgelelik içerdiği için eşikler geniş
/// tutulmuştur — ölçülen gerçek değerler bu eşiklerin epey üstünde.
double _clearRate(AiLevel level, {required int shots}) {
  final bot = AiBot();
  var cleared = 0;
  var total = 0;
  for (var gx = 40.0; gx <= 360.0; gx += 20) {
    for (var gy = 60.0; gy <= 300.0; gy += 30) {
      for (var repeat = 0; repeat < 4; repeat++) {
        final disc = Disc(vx: gx, vy: gy, owner: 1);
        final discs = [disc];
        total++;
        for (var s = 0; s < shots; s++) {
          if (disc.vy > GameConstants.vHalf) break;
          if (!bot.think(discs, level)) break;
          for (var i = 0; i < 900; i++) {
            PhysicsEngine.stepPhysics(discs);
            if (PhysicsEngine.allStopped(discs)) break;
          }
        }
        if (disc.vy > GameConstants.vHalf) cleared++;
      }
    }
  }
  return cleared / total;
}

void main() {
  group('ai bot gate accuracy', () {
    test('hard bot almost always clears a disc within three shots', () {
      expect(_clearRate(AiLevel.hard, shots: 3), greaterThan(0.95));
    });

    test('hard bot lands most single shots', () {
      // Tek atışta %100 beklenmiyor: kenardaki pullarda bot önce kurulum
      // atışı yapar, bu ölçümde ıskalanmış sayılır.
      expect(_clearRate(AiLevel.hard, shots: 1), greaterThan(0.6));
    });

    test('medium bot clears reliably but easy bot does not', () {
      final medium = _clearRate(AiLevel.medium, shots: 3);
      final easy = _clearRate(AiLevel.easy, shots: 3);
      expect(medium, greaterThan(0.9));
      expect(easy, lessThan(medium));
    });

    test('difficulty ordering holds on single shots', () {
      final easy = _clearRate(AiLevel.easy, shots: 1);
      final hard = _clearRate(AiLevel.hard, shots: 1);
      expect(easy, lessThan(hard));
    });
  });

  group('ai bot shot geometry', () {
    test('a disc at a hopeless angle gets a gentle setup shot, not a wild one',
        () {
      // Duvarın hemen üstünde, geçidin çok solunda: doğrudan atış imkânsız.
      final disc = Disc(vx: 40, vy: 300, owner: 1);
      expect(AiBot().think([disc], AiLevel.hard), isTrue);
      // Kurulum atışı pulu duvardan uzaklaştırır (yukarı) ve koridora çeker.
      expect(disc.vvy, lessThan(0));
      expect(disc.vvx, greaterThan(0));
      final speed = disc.vvx.abs() + disc.vvy.abs();
      expect(speed, lessThan(GameConstants.slingMax * GameConstants.slingPower));
    });

    test('a well placed disc is shot straight at the gate', () {
      final disc = Disc(vx: 200, vy: 120, owner: 1);
      expect(AiBot().think([disc], AiLevel.hard), isTrue);
      expect(disc.vvy, greaterThan(0)); // duvara doğru
      expect(disc.vvx.abs(), lessThan(1)); // neredeyse dikey
    });
  });
}
