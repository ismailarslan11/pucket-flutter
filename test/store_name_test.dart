import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pucket_flutter/l10n/app_language.dart';
import 'package:pucket_flutter/l10n/app_localizations.dart';

/// App Store incelemesi, iOS uygulamasında rakip platformun adını görünce
/// 2.3.10 (Accurate Metadata) gerekçesiyle reddediyor. Bir kez yaşandı:
/// "Payments are processed securely by Google Play / App Store" satırı.
void main() {
  group('mağaza adı', () {
    test('ödeme metni mağaza adını çalışma anında alır', () {
      for (final lang in AppLanguage.values) {
        final l10n = AppLocalizations(lang);
        expect(l10n.securePayments('App Store'), contains('App Store'));
        expect(l10n.securePayments('App Store'), isNot(contains('Google Play')));
        expect(l10n.securePayments('Google Play'), contains('Google Play'));
        expect(l10n.securePayments('Google Play'), isNot(contains('App Store')));
      }
    });

    test('hiçbir çeviri metninde sabit "Google Play" kalmadı', () {
      // Kaynak üzerinden kontrol: yeni bir metin eklenirken aynı hataya
      // düşülmesin. Yorum satırları hariç, kullanıcıya giden dizeler.
      final src = File('lib/l10n/app_localizations.dart').readAsLinesSync();
      final offenders = src
          .where((l) => !l.trimLeft().startsWith('//'))
          .where((l) => l.contains('Google Play') || l.contains('Play Store'))
          .toList();
      expect(offenders, isEmpty,
          reason: 'iOS derlemesinde görünürse App Store reddi gelir:\n'
              '${offenders.join('\n')}');
    });
  });
}
