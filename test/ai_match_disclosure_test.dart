import 'package:flutter_test/flutter_test.dart';
import 'package:pucket_flutter/game/ai_bot.dart';
import 'package:pucket_flutter/game/game_controller.dart';
import 'package:pucket_flutter/models/cosmetic_catalog.dart';
import 'package:pucket_flutter/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Yapay zekâ maçının gerçek bir insan maçı gibi sunulmasını engelleyen
/// kuralları kilitler.
///
/// Uygulama, App Store Guideline 5.6 (Developer Code of Conduct) gerekçesiyle
/// satıştan kaldırıldı: süreli/ranked modda rakip gizli bir bottu, gerçek
/// kullanıcı adı taşıyordu, ekranda "ONLINE"/"RANKED" yazıyordu ve maç sonunda
/// gerçek ELO yazdırıyordu. Aşağıdaki testler o davranışların geri gelmesini
/// engelliyor — her biri kaldırılan somut bir aldatmacaya karşılık geliyor.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  GameController controller() => GameController(
        SettingsService()..vibrationOn = false,
        wsUrl: 'ws://localhost:8080',
      );

  group('yapay zekâ maçı ifşası', () {
    test('ranked istense bile yapay zekâ maçı ranked sayılmaz', () {
      final game = controller();
      // Eski davranış: startAiGame(..., ranked: true) maçı ranked yapıyor,
      // ELO değiştiriyor ve hiçbir yerde bot olduğu yazmıyordu.
      game.startAiGame(AiLevel.hard, botFallback: true, ranked: true);

      expect(game.isRanked, isFalse,
          reason: 'yapay zekâ maçı sıralamayı etkileyemez');
      expect(game.isBotFallback, isTrue,
          reason: 'arayüz bunu yapay zekâ olarak etiketleyebilmeli');
      game.dispose();
    });

    test('yapay zekâ maçında sahte oda kodu üretilmez', () {
      final game = controller();
      game.startAiGame(AiLevel.medium, botFallback: true);

      expect(game.roomCode, isEmpty,
          reason: 'oda kodu, maçı gerçek bir çevrimiçi oturum gibi gösteriyordu');
      game.dispose();
    });

    test('süreli mod da ranked değildir ve oda kodu taşımaz', () {
      final game = controller();
      game.startTimedGame(60);

      expect(game.isRanked, isFalse);
      expect(game.roomCode, isEmpty);
      expect(game.isBotFallback, isTrue);
      game.dispose();
    });

    test('yapay zekâ rakibin adı hiç üretilmez', () {
      // Eski davranış: isim havuzu sunucunun /leaderboard ucundan çekilen
      // GERÇEK kullanıcı adlarıyla dolduruluyordu. Sonra kurgusal listeye
      // düşürüldü, şimdi ad diye bir alan yok: rakip arayüzde CPU olarak
      // gösteriliyor, taklit edilecek kimlik kalmadı.
      for (var i = 0; i < 200; i++) {
        final p = BotFallbackProfile.generate(playerElo: 1000 + i);
        expect(p.roomCode, isEmpty);
      }
    });

    test('bot maçında rakip adı boş kalır', () {
      final game = controller();
      game.startTimedGame(60);
      expect(game.opponentName, isEmpty,
          reason: 'sahte insan adı, rakibi insan sandıran şeydi');
      game.dispose();
    });

    test('yapay zekâ rakip hiçbir ücretli kozmetik taşımaz', () {
      // Eski davranış: %30 premium (250-750 jeton) + %15 emoji (40-80 jeton).
      // Gerekçesi "gerçek oyuncu hissi" idi — satın alma için sahte sosyal kanıt.
      // isPremiumDisc premium, emoji ve VIP pulların hepsini kapsıyor.
      for (var i = 0; i < 400; i++) {
        final p = BotFallbackProfile.generate(playerElo: 1000);
        expect(CosmeticCatalog.isPremiumDisc(p.discId), isFalse,
            reason: 'yapay zekâ rakip ödemeli pul kullanmamalı: ${p.discId}');
      }
    });
  });
}
