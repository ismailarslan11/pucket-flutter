import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import 'app_version.dart';

/// Zorunlu güncelleme eşiğini Firebase Remote Config'ten okur.
///
/// Tasarım kuralı: **şüphede kal, kapıyı açık bırak.** Bu servis yalnızca
/// "bu oturumda sunucudan taze geldiği kesin olan, makul bir sayı" gördüğünde
/// engelle der. Ağ hatası, eksik anahtar, bozuk tip, okunamayan build numarası
/// ve saçma büyüklükteki değerlerin hepsi kullanıcıyı içeri alır.
///
/// Firebase Console'da iki parametre (Number) tutuluyor:
///   min_build_android — Android'de izin verilen en düşük versionCode
///   min_build_ios     — iOS'ta izin verilen en düşük CFBundleVersion
/// İkisinin de varsayılanı 0'dır ve 0 "kısıtlama yok" demektir.
///
/// Platform başına ayrı anahtar şart: iOS ve Android build numaraları birbirini
/// tutmuyor (iOS 50, Android 51). Tek anahtar, mağazada karşılığı olmayan bir
/// eşikle bir platformu çıkışsız kilitlerdi.
class RemoteConfigService {
  RemoteConfigService._();

  static const _keyAndroid = 'min_build_android';
  static const _keyIos = 'min_build_ios';

  /// Mutlak akıl sınırı. Console'a 52 yerine 552 yazılması tüm kullanıcıları
  /// kilitlemesin diye. Bilerek mutlak — "mevcut build + N" gibi göreli bir
  /// sınır, eski sürümdeki kullanıcıyı meşru şekilde engellemeyi de bozardı.
  static const _sanityCeiling = 500;

  static Future<bool>? _prewarm;

  /// Marka animasyonu sırasında önden başlat — kullanıcı beklemeyi görmez.
  static void prewarm() => _prewarm ??= _evaluate();

  /// true = bu sürüm artık desteklenmiyor, güncelleme şart.
  static Future<bool> get blocked => _prewarm ??= _evaluate();

  static Future<bool> _evaluate() async {
    try {
      // Sürüm okunmadan eşik karşılaştırılamaz; sıraya bağlı kalmasın diye
      // burada da garantiye alıyoruz (load kendini bir kez çalıştırıyor).
      await AppVersion.load();

      final rc = FirebaseRemoteConfig.instance;

      // Varsayılanlar önce: fetch hiç başarılamazsa 0 okunur, kapı açık kalır.
      await rc.setDefaults(const {_keyAndroid: 0, _keyIos: 0});
      await rc.setConfigSettings(RemoteConfigSettings(
        // Varsayılan 60 sn; kötü şebekede açılışı o kadar bekletmeyelim.
        fetchTimeout: const Duration(seconds: 10),
        // Varsayılan 12 saat. Yanlış bir eşik yayınlanırsa geri dönüşün
        // kullanıcıya ulaşma süresi bu kadardır; 1 saat makul bir denge.
        minimumFetchInterval: const Duration(hours: 1),
      ));

      await rc.fetchAndActivate();

      final key =
          defaultTargetPlatform == TargetPlatform.iOS ? _keyIos : _keyAndroid;
      final value = rc.getValue(key);

      return shouldBlock(
        currentBuild: AppVersion.build,
        minBuild: value.asInt(),
        fromRemote: value.source == ValueSource.valueRemote,
      );
    } catch (_) {
      // Ağ, throttle, Firebase kapalı, plugin hatası — hepsi kapıyı açar.
      return false;
    }
  }

  /// Engelleme karar kuralı. Firebase'den ayrıldı ki test edilebilsin —
  /// buradaki bir hata kullanıcıyı oyundan atar.
  ///
  /// Engelle demek için dördü birden gerekir:
  ///  1. değer gerçekten sunucudan gelmiş olmalı (varsayılan/statik değil),
  ///  2. eşik pozitif olmalı (0 = kısıtlama yok),
  ///  3. eşik makul olmalı (Console'a fazladan hane yazılması herkesi kilitlemesin),
  ///  4. uygulamanın kendi build numarası okunabilmiş olmalı.
  @visibleForTesting
  static bool shouldBlock({
    required int? currentBuild,
    required int minBuild,
    required bool fromRemote,
  }) {
    if (!fromRemote) return false;
    if (minBuild <= 0 || minBuild > _sanityCeiling) return false;
    if (currentBuild == null) return false;
    return currentBuild < minBuild;
  }

  /// Kapı ekranındaki "tekrar dene" için: önbelleği atlayıp yeniden bak.
  static Future<bool> recheck() async {
    _prewarm = null;
    return blocked;
  }
}
