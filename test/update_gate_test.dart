import 'package:flutter_test/flutter_test.dart';
import 'package:pucket_flutter/services/remote_config_service.dart';

/// Zorunlu güncelleme kapısı kullanıcıyı yanlışlıkla oyundan atmamalı.
/// Buradaki her kural, kapıyı yanlış kapatan gerçek bir senaryoyu kapatıyor.
void main() {
  group('sürüm kapısı yalnızca gerekli olduğunda kapanır', () {
    test('eski sürüm engellenir', () {
      expect(
        RemoteConfigService.shouldBlock(
            currentBuild: 45, minBuild: 51, fromRemote: true),
        isTrue,
      );
    });

    test('eşiğe eşit veya üstü geçer', () {
      for (final build in [51, 52, 120]) {
        expect(
          RemoteConfigService.shouldBlock(
              currentBuild: build, minBuild: 51, fromRemote: true),
          isFalse,
          reason: 'build $build engellenmemeliydi',
        );
      }
    });

    test('sunucudan gelmeyen değer engellemez (fetch olmadıysa kapı açık)', () {
      expect(
        RemoteConfigService.shouldBlock(
            currentBuild: 10, minBuild: 51, fromRemote: false),
        isFalse,
      );
    });

    test('sıfır ve negatif eşik kısıtlama değildir', () {
      for (final min in [0, -1, -99]) {
        expect(
          RemoteConfigService.shouldBlock(
              currentBuild: 10, minBuild: min, fromRemote: true),
          isFalse,
          reason: 'eşik $min kısıtlama sayılmamalıydı',
        );
      }
    });

    test('saçma büyüklükteki eşik yok sayılır — 52 yerine 552 yazılırsa', () {
      expect(
        RemoteConfigService.shouldBlock(
            currentBuild: 51, minBuild: 552, fromRemote: true),
        isFalse,
      );
      expect(
        RemoteConfigService.shouldBlock(
            currentBuild: 51, minBuild: 99999, fromRemote: true),
        isFalse,
      );
    });

    test('build numarası okunamadıysa engelleme yok', () {
      expect(
        RemoteConfigService.shouldBlock(
            currentBuild: null, minBuild: 51, fromRemote: true),
        isFalse,
      );
    });
  });
}
