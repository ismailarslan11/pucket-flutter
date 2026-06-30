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
}
