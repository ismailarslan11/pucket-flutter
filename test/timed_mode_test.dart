import 'package:flutter_test/flutter_test.dart';
import 'package:pucket_flutter/game/game_constants.dart';
import 'package:pucket_flutter/game/game_controller.dart';
import 'package:pucket_flutter/game/physics_engine.dart';
import 'package:pucket_flutter/models/disc.dart';
import 'package:pucket_flutter/services/settings_service.dart';

/// Süreli modda oynanan bir maçı fizik döngüsüyle ileri sarar.
GameController _timedMatch(List<Disc> discs) {
  final settings = SettingsService()..vibrationOn = false;
  final game = GameController(settings, wsUrl: 'ws://localhost:8080')
    ..aiMode = true
    ..timedMode = true
    ..matchDurationSec = 300
    ..discs = discs
    ..phase = GamePhase.playing;
  return game;
}

void _run(GameController game, {int frames = 12}) {
  for (var i = 0; i <= frames; i++) {
    game.tick(i * 20.0);
  }
}

/// Tüm pulları [top] true ise üst yarıya, değilse alt yarıya taşır.
List<Disc> _allOnOneSide({required bool top}) {
  final discs = PhysicsEngine.initDiscs();
  for (var i = 0; i < discs.length; i++) {
    discs[i].vx = 60.0 + (i % 5) * 60.0;
    discs[i].vy = top ? 90.0 + (i ~/ 5) * 70.0 : 500.0 + (i ~/ 5) * 70.0;
    discs[i].vvx = 0;
    discs[i].vvy = 0;
  }
  return discs;
}

void main() {
  group('timed mode early finish', () {
    test('bottom half cleared before time is up wins the round for seat 0', () {
      final game = _timedMatch(_allOnOneSide(top: true));

      _run(game);

      expect(game.phase, GamePhase.gameover);
      expect(game.isDraw, isFalse);
      expect(game.lastWinner, 0);
      expect(game.roundWins, [1, 0]);
      // Maç 3 rauntluk seri: tek raunt kazanmak maçı bitirmez.
      expect(game.matchFinished, isFalse);
      expect(game.currentRound, 2);
      game.dispose();
    });

    test('top half cleared before time is up wins the round for seat 1', () {
      final game = _timedMatch(_allOnOneSide(top: false));

      _run(game);

      expect(game.phase, GamePhase.gameover);
      expect(game.isDraw, isFalse);
      expect(game.lastWinner, 1);
      expect(game.roundWins, [0, 1]);
      expect(game.matchFinished, isFalse);
      game.dispose();
    });

    test('second round win finishes the match', () {
      final game = _timedMatch(_allOnOneSide(top: true));
      _run(game);
      expect(game.matchFinished, isFalse);

      // İkinci raunt: tahtayı yeniden kur, aynı taraf yine boşaltsın.
      game
        ..discs = _allOnOneSide(top: true)
        ..phase = GamePhase.playing;
      _run(game);

      expect(game.roundWins, [2, 0]);
      expect(game.matchFinished, isTrue);
      expect(game.lastWinner, 0);
      game.dispose();
    });

    test('match keeps running while both halves still hold discs', () {
      final discs = PhysicsEngine.initDiscs();
      expect(discs.any(PhysicsEngine.occupiesTop), isTrue);
      expect(discs.any(PhysicsEngine.occupiesBottom), isTrue);
      final game = _timedMatch(discs);

      _run(game);

      expect(game.phase, GamePhase.playing);
      expect(game.matchFinished, isFalse);
      game.dispose();
    });

    test('cleared side wins even when it holds the fewer discs by count', () {
      // Alt yarı boş ama üst yarıdaki pul sayısı fazla: erken bitişte sayım
      // değil, "alanı boşalan taraf kazanır" kuralı geçerli olmalı.
      final discs = _allOnOneSide(top: true);
      final game = _timedMatch(discs);

      _run(game);

      expect(game.discs.where((d) => d.vy < GameConstants.vHalf).length,
          greaterThan(0));
      expect(game.lastWinner, 0);
      game.dispose();
    });
  });
}
