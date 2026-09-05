import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/legal_config.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_extension.dart';
import '../theme/app_theme.dart';
import '../widgets/yesa_background.dart';
import '../widgets/yesa_effects.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.title, required this.body, this.url});

  final String title;
  final String body;
  final String? url;

  static void showPrivacy(BuildContext context) {
    final l10n = context.l10nRead;
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
    final l10n = context.l10nRead;
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

  // Gövdeler sabit Türkçeydi; inceleyicinin cihazı İngilizce olduğunda
  // yapay zekâ ifşası hiç görünmüyordu. Altı dile taşındı.
  static String _privacyBody(AppLocalizations l10n) =>
      'PUCKET — ${l10n.privacyPolicy}\n\n'
      '${l10n.privacyBodyText.replaceAll('{email}', LegalConfig.supportEmail)}';

  static String _termsBody(AppLocalizations l10n) =>
      'PUCKET — ${l10n.termsOfUse}\n\n${l10n.termsBodyText}';

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
      body: YesaBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 16, 4),
                child: Row(
                  children: [
                    ScalePress(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppGradients.neonPurple,
                          border: Border.all(color: AppColors.beyaz.withValues(alpha: 0.3)),
                          boxShadow: AppShadows.depth(AppColors.laciDerin),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: AppColors.beyaz, size: 20),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        title.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: AppColors.beyaz,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: YesaDecor.card(radius: 18),
                        child: Text(
                          body.trim(),
                          style: const TextStyle(height: 1.6, color: AppColors.pusluBeyaz),
                        ),
                      ),
                      if (url != null) ...[
                        const SizedBox(height: 20),
                        OutlinedButton(
                          onPressed: () => _openUrl(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.sariAna,
                            side: const BorderSide(color: AppColors.sariAna),
                          ),
                          child: Text(l10n.openInBrowser),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
