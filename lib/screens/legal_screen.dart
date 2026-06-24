import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.title, required this.body});

  final String title;
  final String body;

  static void showPrivacy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LegalScreen(
          title: 'Gizlilik Politikası',
          body: _privacy,
        ),
      ),
    );
  }

  static void showTerms(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LegalScreen(
          title: 'Kullanım Şartları',
          body: _terms,
        ),
      ),
    );
  }

  static const _privacy = '''
PUCKET Gizlilik Politikası (özet)

• Hesap: Google/Apple girişinde ad, e-posta ve profil fotoğrafı Firebase üzerinden işlenebilir.
• Oyun verisi: ELO, maç sonuçları ve kullanıcı adı sunucuda saklanır.
• Misafir mod: Yerel cihazda geçici kimlik tutulur; ranked için Google girişi gerekir.
• Reklam: Google AdMob banner ve tam ekran reklamlar; cihaz tanımlayıcıları kullanılabilir.
• Üçüncü taraflar: Firebase (Google), AdMob (Google), oyun sunucusu.
• Veri silme: Ayarlar > Hesap > çıkış yaparak oturumu kapatabilirsiniz. Kalıcı silme için destek ile iletişime geçin.
• İletişim: uygulama geliştiricisi ile Play/App Store üzerinden.
''';

  static const _terms = '''
PUCKET Kullanım Şartları (özet)

• Oyun 13+ yaş içindir.
• Hile, ELO manipülasyonu ve taciz yasaktır; hesap kapatılabilir.
• Ranked maçlar sunucu kayıtlarına dayanır.
• Uygulama "olduğu gibi" sunulur; kesinti ve bakım olabilir.
• Kurallara uymayan davranışlarda erişim kısıtlanabilir.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title.toUpperCase()), backgroundColor: AppColors.bg),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(body.trim(), style: const TextStyle(height: 1.6, color: Color(0xFFCCCCCC))),
      ),
    );
  }
}
