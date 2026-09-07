import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Mağaza adresleri ve mağazayı açma.
///
/// Burada bilerek `canLaunchUrl` KULLANILMIYOR. `market://` (Android) ve
/// `itms-apps://` (iOS) şemaları için canLaunchUrl false döner — Android'de
/// paket görünürlüğü filtresi, iOS'ta Info.plist'teki LSApplicationQueriesSchemes
/// eksikliği yüzünden. Onun yerine önce uygulama şemasını deniyor, olmazsa
/// https adresine düşüyoruz.
class StoreConfig {
  static const androidPackage = 'com.yesastudio.pucket';
  static const appStoreId = '6793585706';

  static const _androidNative = 'market://details?id=$androidPackage';
  static const _androidWeb =
      'https://play.google.com/store/apps/details?id=$androidPackage';
  static const _iosNative = 'itms-apps://apps.apple.com/app/id$appStoreId';
  static const _iosWeb = 'https://apps.apple.com/app/id$appStoreId';

  /// Kullanıcıya gösterilecek (kopyalanabilir) adres — mağaza hiç açılmazsa.
  static String get webUrl =>
      defaultTargetPlatform == TargetPlatform.iOS ? _iosWeb : _androidWeb;

  static List<String> get _candidates =>
      defaultTargetPlatform == TargetPlatform.iOS
          ? const [_iosNative, _iosWeb]
          : const [_androidNative, _androidWeb];

  /// Mağazayı açar. Hiçbiri açılamazsa false döner; çağıran adresi ekranda
  /// göstermeli, sessiz kalmamalı.
  static Future<bool> openStore() async {
    for (final url in _candidates) {
      try {
        final ok = await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
        if (ok) return true;
      } catch (_) {
        // Sıradakini dene.
      }
    }
    return false;
  }
}
