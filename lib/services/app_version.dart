import 'package:package_info_plus/package_info_plus.dart';

/// Uygulamanın kendi sürüm bilgisi.
///
/// `buildNumber` Android'de versionCode, iOS'ta CFBundleVersion olarak gelir;
/// ikisi de pubspec'teki `1.3.6+51` satırının `+` sonrasından üretilir. Eklenti
/// her iki platformda da String döndürdüğü için tamsayıya çevirmek gerekiyor —
/// çevrilemezse sürüm kapısı kilitlenmesin diye null bırakıyoruz.
class AppVersion {
  static int? _build;
  static String _name = '';
  static bool _loaded = false;

  /// Açılışta bir kez çağrılır. Hata olursa sessizce geçer; sürüm bilinmezse
  /// kapı kendini açık bırakır.
  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final info = await PackageInfo.fromPlatform();
      _name = info.version;
      _build = int.tryParse(info.buildNumber.trim());
    } catch (_) {
      // Bilinmiyor olarak kalsın.
    }
  }

  /// Bilinmiyorsa null — çağıranlar bunu "kısıtlama uygulama" olarak okumalı.
  static int? get build => _build;

  static String get name => _name;
}
