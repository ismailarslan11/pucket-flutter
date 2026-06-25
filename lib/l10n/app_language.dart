import 'package:flutter/material.dart';

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
}
