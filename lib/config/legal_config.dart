import '../services/api_config.dart';

class LegalConfig {
  LegalConfig._();

  /// Canlı sunucuda barındırılan yasal sayfalar (Play Store gereksinimi).
  static String get privacyPolicyUrl => '$apiBaseUrl/privacy';
  static String get termsUrl => '$apiBaseUrl/terms';
  static const supportEmail = 'support@pucket.app';
}
