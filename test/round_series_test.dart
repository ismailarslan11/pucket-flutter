import 'package:flutter_test/flutter_test.dart';
import 'package:pucket_flutter/game/game_controller.dart';
import 'package:pucket_flutter/services/settings_service.dart';

/// Maç serisi kuralı: en fazla 3 raunt, 2 raunt kazanan maçı alır.
/// Beraberlikle biten raunt kimseye puan yazmaz.
void main() {
  late GameController game;

  setUp(() {
    game = GameController(
      SettingsService()..vibrationOn = false,
      wsUrl: 'ws://localhost:8080',
    );
    game.resetMatch();
  });

  group('maç serisi (3 raunt / 2 galibiyet)', () {
    test('başlangıç durumu', () {
      expect(game.currentRound, 1);
      expect(game.roundWins, [0, 0]);
      expect(game.matchFinished, isFalse);
      expect(GameController.maxRounds, 3);
      expect(GameController.roundsToWin, 2);
    });

    test('ilk raunt maçı bitirmez', () {
      game.scoreRound(0);
      expect(game.roundWins, [1, 0]);
      expect(game.currentRound, 2);
      expect(game.matchFinished, isFalse,
          reason: 'tek raunt kazanmak yetmemeli');
    });

    test('üst üste iki raunt kazanan maçı alır', () {
      game.scoreRound(0);
      game.scoreRound(0);
      expect(game.roundWins, [2, 0]);
      expect(game.matchFinished, isTrue);
    });

    test('1-1 sonrası üçüncü raunt maçı belirler', () {
      game.scoreRound(0);
      game.scoreRound(1);
      expect(game.matchFinished, isFalse, reason: '1-1 iken maç sürmeli');
      expect(game.currentRound, 3);

      game.scoreRound(1);
      expect(game.roundWins, [1, 2]);
      expect(game.matchFinished, isTrue);
    });

    test('beraberlikle biten raunt puan yazmaz ve maçı bitirmez', () {
      game.scoreRound(null);
      expect(game.roundWins, [0, 0]);
      expect(game.currentRound, 2);
      expect(game.matchFinished, isFalse);
    });

    test('raunt hakkı biterse maçı daha çok raunt kazanan alır', () {
      // Beraberlik, galibiyet, beraberlik → kimse 2'ye ulaşamaz.
      game.scoreRound(null);
      game.scoreRound(0);
      expect(game.matchFinished, isFalse);
      game.scoreRound(null);

      expect(game.matchFinished, isTrue, reason: '3 raunt doldu');
      expect(game.lastWinner, 0, reason: '1-0 önde bitiren maçı almalı');
      expect(game.isDraw, isFalse);
    });

    test('üç raunt da berabere biterse maç berabere', () {
      game.scoreRound(null);
      game.scoreRound(null);
      game.scoreRound(null);
      expect(game.matchFinished, isTrue);
      expect(game.isDraw, isTrue);
      expect(game.lastWinner, isNull);
    });

    test('maç dörde çıkmaz', () {
      game.scoreRound(null);
      game.scoreRound(null);
      game.scoreRound(0);
      expect(game.matchFinished, isTrue,
          reason: '3. rauntta 1-0 öne geçen maçı almalı');
      expect(game.lastWinner, 0);
    });

    test('uzatma varsayılan olarak kapalı ve raunt süresi normaldir', () {
      game.matchDurationSec = 60;
      expect(game.inExtraTime, isFalse);
      expect(game.roundDurationSec, 60);
    });

    test('uzatmaya girilince raunt süresi 10 saniye uzar', () {
      game.matchDurationSec = 60;
      game.inExtraTime = true;
      expect(game.roundDurationSec, 70);
      expect(GameController.extraTimeSec, 10);
    });

    test('resetRound uzatmayı sıfırlar', () {
      game.matchDurationSec = 60;
      game.inExtraTime = true;
      game.resetRound();
      expect(game.inExtraTime, isFalse);
      expect(game.roundDurationSec, 60);
    });

    test('resetMatch seriyi sıfırlar', () {
      game.scoreRound(0);
      game.scoreRound(0);
      game.resetMatch();
      expect(game.currentRound, 1);
      expect(game.roundWins, [0, 0]);
      expect(game.matchFinished, isFalse);
    });
  });
}
