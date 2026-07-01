import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pucket_flutter/l10n/app_language.dart';

void main() {
  group('AppLanguage.fromDeviceLocale', () {
    test('matches device language code directly', () {
      expect(AppLanguage.fromDeviceLocale(const Locale('de')), AppLanguage.de);
      expect(AppLanguage.fromDeviceLocale(const Locale('tr', 'TR')), AppLanguage.tr);
    });

    test('maps country when language unsupported', () {
      expect(AppLanguage.fromDeviceLocale(const Locale('en', 'TR')), AppLanguage.en);
      expect(AppLanguage.fromDeviceLocale(const Locale('nl', 'BE')), AppLanguage.fr);
      expect(AppLanguage.fromDeviceLocale(const Locale('xx', 'SA')), AppLanguage.ar);
    });

    test('defaults to English for unknown regions', () {
      expect(AppLanguage.fromDeviceLocale(const Locale('ja', 'JP')), AppLanguage.en);
      expect(AppLanguage.fromDeviceLocale(const Locale('pt', 'BR')), AppLanguage.en);
    });
  });
}
