import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pucket_flutter/game/ai_bot.dart';
import 'package:pucket_flutter/game/game_controller.dart';
import 'package:pucket_flutter/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

GameController _botMatch() => GameController(
      SettingsService()..vibrationOn = false,
      wsUrl: 'ws://localhost:8080',
    )
      ..aiMode = true
      ..timedMode = true
      ..isBotFallback = true
      ..matchDurationSec = 60
      ..opponentName = 'EskiRakip'
      ..opponentElo = 1234
      ..roomCode = 'AAAAAA'
      ..matchFinished = true;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('yeni maç = yeni rakip', () {
    test('gizli bot maçında rakip baştan üretilir', () {
      fakeAsync((async) {
        final game = _botMatch();
        game.rematchLocal();
        async.flushMicrotasks();

        expect(game.opponentName, isNot('EskiRakip'),
            reason: 'aynı rakiple devam etmemeli');
        expect(game.roomCode, isNot('AAAAAA'),
            reason: 'yeni eşleşme yeni oda kodu demek');
        expect(game.opponentName, isNotEmpty);
        expect(game.currentRound, 1);
        expect(game.roundWins, [0, 0]);
        expect(game.matchFinished, isFalse);
        game.dispose();
      });
    });

    test('art arda yeniden maçlar farklı rakipler üretir', () {
      fakeAsync((async) {
        final game = _botMatch();
        final names = <String>{};
        for (var i = 0; i < 6; i++) {
          game.matchFinished = true;
          game.rematchLocal();
          async.flushMicrotasks();
          names.add(game.opponentName);
        }
        expect(names.length, greaterThan(1),
            reason: 'her maçta aynı isim çıkmamalı');
        game.dispose();
      });
    });

    test('kariyer modunda rakip korunur', () {
      fakeAsync((async) {
        final game = _botMatch()
          ..careerMode = true
          ..isBotFallback = false
          ..opponentName = 'KariyerRakibi';
        game.rematchLocal();
        async.flushMicrotasks();

        expect(game.opponentName, 'KariyerRakibi',
            reason: 'kariyer rakibi sabittir');
        game.dispose();
      });
    });

    test('oyuncunun seçtiği zorluk korunur (Bilgisayara Karşı)', () {
      fakeAsync((async) {
        final game = _botMatch()
          ..isBotFallback = false
          ..aiLevel = AiLevel.easy
          ..opponentName = 'Bot';
        game.rematchLocal();
        async.flushMicrotasks();

        expect(game.aiLevel, AiLevel.easy,
            reason: 'oyuncu zorluğu kendi seçtiyse rastgele değişmemeli');
        game.dispose();
      });
    });
  });
}
