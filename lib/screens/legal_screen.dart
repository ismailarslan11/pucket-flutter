import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/legal_config.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_extension.dart';
import '../theme/app_theme.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.title, required this.body, this.url});

  final String title;
  final String body;
  final String? url;

  static void showPrivacy(BuildContext context) {
    final l10n = context.l10n;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LegalScreen(
          title: l10n.privacyPolicy,
          body: _privacyBody(l10n),
          url: LegalConfig.privacyPolicyUrl,
        ),
      ),
    );
  }

  static void showTerms(BuildContext context) {
    final l10n = context.l10n;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LegalScreen(
          title: l10n.termsOfUse,
          body: _termsBody(l10n),
          url: LegalConfig.termsUrl,
        ),
      ),
    );
  }

  static String _privacyBody(AppLocalizations l10n) => '''
PUCKET — ${l10n.privacyPolicy}

• ${l10n.authGoogleHint}
• ELO, maç sonuçları ve kullanıcı adı sunucuda saklanır.
• Misafir mod: yerel kimlik; ranked için Google girişi gerekir.
• Reklam: Google AdMob; cihaz tanımlayıcıları kullanılabilir.
• Üçüncü taraflar: Firebase (Google), AdMob, oyun sunucusu.
• İletişim: ${LegalConfig.supportEmail}
''';

  static String _termsBody(AppLocalizations l10n) => '''
PUCKET — ${l10n.termsOfUse}

• Oyun 13+ yaş içindir.
• Hile, ELO manipülasyonu ve taciz yasaktır.
• Ranked maçlar sunucu kayıtlarına dayanır.
• Uygulama "olduğu gibi" sunulur; kesinti olabilir.
''';

  Future<void> _openUrl(BuildContext context) async {
    final target = url;
    if (target == null || target.isEmpty) return;
    final uri = Uri.parse(target);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(title.toUpperCase()), backgroundColor: AppColors.bg),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(body.trim(), style: const TextStyle(height: 1.6, color: AppColors.silver)),
            if (url != null) ...[
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => _openUrl(context),
                child: Text(l10n.openInBrowser),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
