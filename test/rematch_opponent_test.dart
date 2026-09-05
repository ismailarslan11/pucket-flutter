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
      ..opponentDiscColor = 'green'
      ..roomCode = ''
      ..matchFinished = true;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('yeni maç = yeni rakip', () {
    test('yapay zekâ maçında rakip baştan üretilir', () {
      fakeAsync((async) {
        final game = _botMatch();
        game.rematchLocal();
        async.flushMicrotasks();

        // Rakip artık ad taşımıyor: sahte insan adı, maçı insan maçı sandıran
        // şeydi. Yeni maçın "yeni rakip" olması zorluk ve görsel üzerinden.
        expect(game.opponentName, isEmpty,
            reason: 'yapay zekâ rakibe ad verilmemeli');
        expect(game.roomCode, isEmpty,
            reason: 'yapay zekâ maçının odası yok — sahte oda kodu üretilmemeli');
        expect(game.currentRound, 1);
        expect(game.roundWins, [0, 0]);
        expect(game.matchFinished, isFalse);
        game.dispose();
      });
    });

    test('art arda yeniden maçlar rakibi yeniden kurar', () {
      fakeAsync((async) {
        final game = _botMatch();
        final discs = <String>{};
        final levels = <AiLevel>{};
        for (var i = 0; i < 20; i++) {
          game.matchFinished = true;
          game.rematchLocal();
          async.flushMicrotasks();
          discs.add(game.opponentDiscColor);
          levels.add(game.aiLevel);
          expect(game.opponentName, isEmpty);
        }
        expect(discs.length, greaterThan(1),
            reason: 'her maçta aynı rakip görseli çıkmamalı');
        expect(levels.length, greaterThan(1),
            reason: 'zorluk maçtan maça değişmeli');
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
