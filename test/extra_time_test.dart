import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pucket_flutter/game/game_constants.dart';
import 'package:pucket_flutter/game/game_controller.dart';
import 'package:pucket_flutter/models/disc.dart';
import 'package:pucket_flutter/services/settings_service.dart';

/// İki yarıda eşit sayıda pul: süre dolunca beraberlik.
List<Disc> _tiedBoard() => [
      for (var i = 0; i < 3; i++)
        Disc(vx: 80.0 + i * 40, vy: GameConstants.vHalf - 90, owner: 1),
      for (var i = 0; i < 3; i++)
        Disc(vx: 80.0 + i * 40, vy: GameConstants.vHalf + 90, owner: 0),
    ];

GameController _game() => GameController(
      SettingsService()..vibrationOn = false,
      wsUrl: 'ws://localhost:8080',
    );

void main() {
  group('süreli rauntta uzatma', () {
    test('süre eşitlikle dolunca raunt bitmez, uzatmaya geçer', () {
      fakeAsync((async) {
        final game = _game()
          ..aiMode = true
          ..timedMode = true
          ..matchDurationSec = 30
          ..discs = _tiedBoard();
        game.startCountdown();

        // 3 sn geri sayım + 30 sn maç süresi.
        async.elapse(const Duration(seconds: 34));

        expect(game.inExtraTime, isTrue, reason: 'beraberlikte uzatma verilmeli');
        expect(game.phase, GamePhase.playing, reason: 'raunt sürmeli');
        expect(game.roundDurationSec, 40, reason: '30 + 10 sn');
        game.dispose();
      });
    });

    test('uzatma da eşit biterse raunt berabere kapanır', () {
      fakeAsync((async) {
        final game = _game()
          ..aiMode = true
          ..timedMode = true
          ..matchDurationSec = 30
          ..discs = _tiedBoard();
        game.startCountdown();

        async.elapse(const Duration(seconds: 34));
        expect(game.inExtraTime, isTrue);

        // Uzatmanın 10 saniyesi de dolsun.
        async.elapse(const Duration(seconds: 11));

        expect(game.phase, GamePhase.gameover);
        expect(game.isDraw, isTrue);
        expect(game.roundWins, [0, 0], reason: 'berabere raunt puan yazmaz');
        expect(game.matchFinished, isFalse, reason: 'seri sürmeli');
        game.dispose();
      });
    });

    test('uzatma yalnızca bir kez verilir', () {
      fakeAsync((async) {
        final game = _game()
          ..aiMode = true
          ..timedMode = true
          ..matchDurationSec = 30
          ..discs = _tiedBoard();
        game.startCountdown();

        async.elapse(const Duration(seconds: 60));

        // İkinci bir uzatma verilseydi oyun hâlâ sürüyor olurdu.
        expect(game.phase, GamePhase.gameover);
        expect(game.isDraw, isTrue);
        game.dispose();
      });
    });
  });
}
