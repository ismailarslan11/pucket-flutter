import 'dart:math' as math;

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
  /// Botun kendi yarısını temizlemesi kaç saniye sürüyor? shouldThink ile
  /// sanal saat ilerletildiği için tempo (bekleme, nişan duraklaması, seri
  /// atış freni) ölçüme dahildir — yani "karşısında oynarken ne kadar zorlu".
  double secondsToClear(AiLevel level, {int trials = 12}) {
    final bot = AiBot();
    var total = 0.0;
    for (var t = 0; t < trials; t++) {
      bot.reset();
      final discs = PhysicsEngine.initDiscs();
      var clock = 0.0;
      var shots = 0;
      while (discs.any(PhysicsEngine.occupiesTop) &&
          clock < 120000 &&
          shots < 60) {
        clock += 16.7;
        if (!bot.shouldThink(clock, level)) continue;
        if (!bot.think(discs, level)) continue;
        shots++;
        for (var i = 0; i < 1200; i++) {
          PhysicsEngine.stepPhysics(discs);
          if (PhysicsEngine.allStopped(discs)) break;
        }
      }
      total += clock / 1000;
    }
    return total / trials;
  }

  group('ai bot difficulty ladder', () {
    test('each level clears its half faster than the one below', () {
      final easy = secondsToClear(AiLevel.easy);
      final medium = secondsToClear(AiLevel.medium);
      final hard = secondsToClear(AiLevel.hard);
      expect(hard, lessThan(medium));
      expect(medium, lessThan(easy));
    });

    test('hard bot clears its half in well under ten seconds', () {
      // Ölçülen ~5.3 sn; eşik rastgeleliğe pay bırakacak kadar gevşek.
      expect(secondsToClear(AiLevel.hard), lessThan(9));
    });
  });

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
    test('a disc at a hopeless angle gets a measured setup shot', () {
      // Duvarın hemen üstünde, geçidin çok solunda: doğrudan atış imkânsız.
      final disc = Disc(vx: 40, vy: 300, owner: 1);
      expect(AiBot().think([disc], AiLevel.hard), isTrue);
      // Kurulum atışı pulu duvardan uzaklaştırır (yukarı) ve koridora çeker.
      expect(disc.vvy, lessThan(0));
      expect(disc.vvx, greaterThan(0));

      // Gücü mesafeden hesaplanır: pul hedeflenen noktada durmalı, tahtayı
      // baştan sona geçmemeli. Sürtünmeli menzil = v0 / (1 - friction).
      final v0 = math.sqrt(disc.vvx * disc.vvx + disc.vvy * disc.vvy);
      final range = v0 / (1 - GameConstants.friction);
      expect(range, greaterThan(80));
      expect(range, lessThan(360), reason: 'kurulum atışı tahtayı aşmamalı');
    });

    test('a tight-angle shot is aimed more carefully than an open one', () {
      // Aynı yatay sapma, farklı mesafe → farklı yaklaşma açısı. Dar açılı
      // atışta hata payı daraldığı için bot sapmasını küçültür.
      double spread(double vy, int samples) {
        final bot = AiBot();
        var min = double.infinity, max = -double.infinity;
        for (var i = 0; i < samples; i++) {
          final d = Disc(vx: 130, vy: vy, owner: 1);
          if (!bot.think([d], AiLevel.hard)) continue;
          final t = (GameConstants.vHalf - d.vy) / d.vvy;
          final entry = d.vx + d.vvx * t; // duvar hattını kestiği x
          if (entry < min) min = entry;
          if (entry > max) max = entry;
        }
        return max - min;
      }

      final open = spread(120, 60); // uzaktan, dik yaklaşma
      final tight = spread(300, 60); // duvara yakın, yatık yaklaşma
      expect(tight, lessThan(open),
          reason: 'zor atışta nişan sapması daha küçük olmalı');
    });

    test('a well placed disc is shot straight at the gate', () {
      final disc = Disc(vx: 200, vy: 120, owner: 1);
      expect(AiBot().think([disc], AiLevel.hard), isTrue);
      expect(disc.vvy, greaterThan(0)); // duvara doğru
      expect(disc.vvx.abs(), lessThan(1)); // neredeyse dikey
    });
  });
}
