import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n_extension.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

/// iOS: pul atarken ekranın aşağı kayması "Ulaşılabilirlik" (tek el modu)
/// hareketinden kaynaklanır ve uygulamadan kapatılamaz. iOS bu ayarın açık mı
/// kapalı mı olduğunu okumaya da izin vermez; bu yüzden kullanıcı "Kapattım,
/// gösterme" diyene kadar menü her açıldığında hatırlatma gösterilir.
///
/// iPad'de gösterilmez: Ulaşılabilirlik iPhone'a özgü bir özellik, iPad'de
/// hiç yok. Uyarı orada hem gereksiz hem de "iPhone'un" diye başladığı için
/// yanlış cihazdan bahsediyordu.
Future<void> maybeShowReachabilityHint(BuildContext context) async {
  if (kIsWeb || !Platform.isIOS) return;
  // iPad ayıklaması: en kısa kenar 600'ün altındaysa telefon. iPhone'ların en
  // genişi ~430, iPad'lerin en darı ~744 — arada geniş bir boşluk var.
  if (MediaQuery.of(context).size.shortestSide >= 600) return;
  final settings = context.read<SettingsService>();
  // "Kapattım, gösterme" seçilmişse artık hiç gösterme.
  if (settings.reachabilityHintShown) return;
  if (!context.mounted) return;
  final l10n = context.l10nRead;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.card,
      title: Text(l10n.reachabilityHintTitle,
          style: const TextStyle(color: AppColors.beyaz, fontWeight: FontWeight.w800)),
      content: Text(l10n.reachabilityHintBody,
          style: const TextStyle(color: AppColors.textMuted, height: 1.5)),
      actions: [
        // Kullanıcı ayarı kapattığını söyler → bir daha gösterme.
        TextButton(
          onPressed: () async {
            await settings.markReachabilityHintShown();
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: Text(l10n.reachabilityHintStop,
              style: const TextStyle(color: AppColors.textMuted)),
        ),
        // Ayarları aç — bayrağı kaydetmez; kullanıcı gerçekten kapatana kadar
        // (yani "Kapattım" diyene kadar) hatırlatma gelmeye devam eder.
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            _openAccessibilitySettings();
          },
          child: Text(l10n.reachabilityHintOpen,
              style: const TextStyle(color: AppColors.sariAna, fontWeight: FontWeight.w800)),
        ),
      ],
    ),
  );
}

/// Uygulamanın Ayarlar sayfasını aç. (iOS, üçüncü parti uygulamaların doğrudan
/// Erişilebilirlik gibi sistem sayfalarına derin bağlantı vermesine izin vermez;
/// belgesiz App-Prefs şeması App Store reddine yol açabildiği için kullanılmaz.
/// Kullanıcı penceredeki yolu izleyerek Erişilebilirlik'e ulaşır.)
Future<void> _openAccessibilitySettings() async {
  try {
    await launchUrl(Uri.parse('app-settings:'), mode: LaunchMode.externalApplication);
  } catch (_) {}
}
