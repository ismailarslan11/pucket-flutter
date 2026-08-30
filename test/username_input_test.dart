import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kullanıcı adı alanındaki giriş filtresi. Sunucu da aynı kümeyi dayatıyor
/// (server.js validateUsername), o yüzden istemci fazlasını kabul etmemeli.
final _filter = FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]'));

String _typed(String input) => _filter
    .formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(text: input),
    )
    .text;

void main() {
  group('kullanıcı adı giriş filtresi', () {
    test('ASCII harf, rakam ve alt çizgi geçer', () {
      expect(_typed('PucketKing_7'), 'PucketKing_7');
    });

    test('Türkçe karakterler süzülür, kalanı yazılır', () {
      // Kullanıcı "İsmail" yazmaya çalışırsa alan "smail" gösterir; kafa
      // karıştıran "geçersiz ad" hatası yerine ne olduğu anında görünür.
      expect(_typed('İsmail'), 'smail');
      expect(_typed('Gökhan'), 'Gkhan');
      expect(_typed('Şeyma'), 'eyma');
      expect(_typed('Çağla'), 'ala');
    });

    test('boşluk ve noktalama süzülür', () {
      expect(_typed('Pucket King!'), 'PucketKing');
      expect(_typed('a.b-c'), 'abc');
    });

    test('emoji süzülür', () {
      expect(_typed('Pucket🔥'), 'Pucket');
    });
  });
}
