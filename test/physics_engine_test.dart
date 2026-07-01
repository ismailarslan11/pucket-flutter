import 'package:flutter_test/flutter_test.dart';
import 'package:pucket_flutter/game/game_constants.dart';
import 'package:pucket_flutter/game/physics_engine.dart';
import 'package:pucket_flutter/models/disc.dart';

void main() {
  group('mid wall collisions', () {
    test('disc in gate column passes upward through wall band', () {
      final d = Disc(vx: 200, vy: 380, vvx: 0, vvy: -12, owner: 0);
      final discs = [d];

      for (var i = 0; i < 30; i++) {
        PhysicsEngine.stepPhysics(discs);
      }

      expect(d.vy, lessThan(GameConstants.vHalf));
      expect(PhysicsEngine.overlapsLeftWall(d), isFalse);
      expect(PhysicsEngine.overlapsRightWall(d), isFalse);
    });

    test('disc cannot pass through left wall', () {
      final d = Disc(vx: 120, vy: GameConstants.vHalf, vvx: 18, vvy: 0, owner: 0);
      final discs = [d];

      for (var i = 0; i < 20; i++) {
        PhysicsEngine.stepPhysics(discs);
      }

      expect(PhysicsEngine.overlapsLeftWall(d), isFalse);
    });

    test('disc cannot pass through right wall', () {
      final d = Disc(
        vx: 280,
        vy: GameConstants.vHalf,
        vvx: -18,
        vvy: 0,
        owner: 0,
      );
      final discs = [d];

      for (var i = 0; i < 20; i++) {
        PhysicsEngine.stepPhysics(discs);
      }

      expect(PhysicsEngine.overlapsRightWall(d), isFalse);
    });

    test('fast shot through gate does not tunnel side walls', () {
      final d = Disc(vx: 200, vy: 420, vvx: 0, vvy: -25, owner: 0);
      final discs = [d];

      for (var i = 0; i < 40; i++) {
        PhysicsEngine.stepPhysics(discs);
      }

      expect(d.vy, lessThan(GameConstants.vHalf));
      expect(PhysicsEngine.overlapsLeftWall(d), isFalse);
      expect(PhysicsEngine.overlapsRightWall(d), isFalse);
    });

    test('two discs at gate stay separated after physics', () {
      final a = Disc(vx: 200, vy: 400, vvx: 0, vvy: -10, owner: 0);
      final b = Disc(vx: 200, vy: 420, vvx: 0, vvy: -10, owner: 0);
      final discs = [a, b];

      for (var i = 0; i < 50; i++) {
        PhysicsEngine.stepPhysics(discs);
      }

      expect(PhysicsEngine.discsOverlap(a, b), isFalse);
      expect(PhysicsEngine.overlapsLeftWall(a), isFalse);
      expect(PhysicsEngine.overlapsRightWall(b), isFalse);
    });
  });

  group('local duo disc pick', () {
    test('invading opponent disc in bottom half is directly selectable', () {
      final invader = Disc(vx: 200, vy: 520, owner: 1); // blue in red half
      final discs = [invader];

      final idx = PhysicsEngine.findDiscAtLocalDuo(discs, 200, 520);
      expect(idx, 0);
    });

    test('invading opponent disc in top half is directly selectable', () {
      final invader = Disc(vx: 200, vy: 180, owner: 0); // red in blue half
      final discs = [invader];

      final idx = PhysicsEngine.findDiscAtLocalDuo(discs, 200, 180);
      expect(idx, 0);
    });

    test('opponent disc on home half is not selectable from other half touch', () {
      final homeBlue = Disc(vx: 200, vy: 180, owner: 1);
      final discs = [homeBlue];

      final idx = PhysicsEngine.findDiscAtLocalDuo(discs, 200, 520);
      expect(idx, -1);
    });

    test('own disc still selectable in home half', () {
      final own = Disc(vx: 200, vy: 520, owner: 0);
      final discs = [own];

      final idx = PhysicsEngine.findDiscAtLocalDuo(discs, 200, 520);
      expect(idx, 0);
    });

    test('topmost overlapping disc wins', () {
      final bottom = Disc(vx: 200, vy: 520, owner: 0);
      final top = Disc(vx: 200, vy: 520, owner: 1);
      final discs = [bottom, top];

      final idx = PhysicsEngine.findDiscAtLocalDuo(discs, 200, 520);
      expect(idx, 1);
    });
  });
}
