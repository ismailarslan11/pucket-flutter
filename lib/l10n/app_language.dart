import 'dart:ui';

enum AppLanguage {
  tr('tr', 'Türkçe', '🇹🇷'),
  en('en', 'English', '🇬🇧'),
  de('de', 'Deutsch', '🇩🇪'),
  es('es', 'Español', '🇪🇸'),
  ar('ar', 'العربية', '🇸🇦'),
  fr('fr', 'Français', '🇫🇷');

  const AppLanguage(this.code, this.label, this.flag);

  final String code;
  final String label;
  final String flag;

  Locale get locale => Locale(code);

  bool get isRtl => this == AppLanguage.ar;

  static AppLanguage fromCode(String? code) {
    if (code == null) return tr;
    for (final l in values) {
      if (l.code == code) return l;
    }
    return tr;
  }

  /// Cihaz dil/ülke ayarından başlangıç dili (ilk kurulum).
  static AppLanguage fromDeviceLocale([Locale? locale]) {
    locale ??= PlatformDispatcher.instance.locale;
    final lang = locale.languageCode.toLowerCase();

    for (final l in values) {
      if (l.code == lang) return l;
    }

    final country = locale.countryCode?.toUpperCase() ?? '';
    switch (country) {
      case 'TR':
      case 'CY':
        return tr;
      case 'DE':
      case 'AT':
      case 'LI':
        return de;
      case 'ES':
      case 'MX':
      case 'AR':
      case 'CO':
      case 'CL':
      case 'PE':
      case 'VE':
      case 'EC':
      case 'UY':
      case 'PY':
      case 'BO':
      case 'CR':
      case 'PA':
      case 'DO':
      case 'GT':
      case 'HN':
      case 'SV':
      case 'NI':
      case 'CU':
        return es;
      case 'FR':
      case 'BE':
      case 'LU':
      case 'MC':
      case 'SN':
      case 'CI':
      case 'CM':
      case 'MA':
        return fr;
      case 'SA':
      case 'AE':
      case 'EG':
      case 'QA':
      case 'KW':
      case 'BH':
      case 'OM':
      case 'JO':
      case 'LB':
      case 'DZ':
      case 'TN':
      case 'IQ':
      case 'SY':
      case 'YE':
      case 'LY':
      case 'SD':
        return ar;
      case 'CH':
        return de;
      default:
        return en;
    }
  }
}
