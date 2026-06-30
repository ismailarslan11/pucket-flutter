import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../l10n/app_language.dart';
import '../l10n/l10n_extension.dart';
import '../services/audio_service.dart';
import '../services/auth_service.dart';
import '../services/consent_service.dart';
import '../services/push_service.dart';
import '../services/settings_service.dart';
import 'legal_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/pucket_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF888888), size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 52, 24, 24),
              child: Column(
                children: [
                  Text(
                    l10n.settingsTitle,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.green,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _languageRow(context, settings, l10n),
                  _row(
                    l10n.settingsMusic,
                    l10n.settingsMusicSub,
                    Switch(
                      value: settings.musicOn,
                      activeThumbColor: AppColors.green,
                      onChanged: settings.setMusic,
                    ),
                  ),
                  _row(
                    l10n.settingsSfx,
                    l10n.settingsSfxSub,
                    Switch(
                      value: settings.sfxOn,
                      activeThumbColor: AppColors.green,
                      onChanged: settings.setSfx,
                    ),
                  ),
                  _sliderRow(l10n.settingsMusicVol, settings.musicVolume, settings.setMusicVolume),
                  _sliderRow(l10n.settingsSfxVol, settings.sfxVolume, settings.setSfxVolume),
                  _pushSection(),
                  _row(
                    l10n.settingsVibration,
                    l10n.settingsVibrationSub,
                    Switch(
                      value: settings.vibrationOn,
                      activeThumbColor: AppColors.green,
                      onChanged: settings.setVibration,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      await context.read<AuthService>().signOut();
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Text(l10n.signOut, style: const TextStyle(color: Color(0xFFAA4444))),
                  ),
                  TextButton(
                    onPressed: () => LegalScreen.showPrivacy(context),
                    child: Text(l10n.privacyPolicy, style: const TextStyle(color: Color(0xFF666666))),
                  ),
                  TextButton(
                    onPressed: () => ConsentService.showPrivacyOptions(),
                    child: const Text('Reklam gizlilik tercihleri', style: TextStyle(color: Color(0xFF666666))),
                  ),
                  TextButton(
                    onPressed: () => LegalScreen.showTerms(context),
                    child: Text(l10n.termsOfUse, style: const TextStyle(color: Color(0xFF666666))),
                  ),
                  const SizedBox(height: 16),
                  PucketButton(
                    label: l10n.saveAndBack,
                    width: 260,
                    onPressed: () {
                      context.read<AudioService>().onSettingsChanged();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _languageRow(BuildContext context, SettingsService settings, AppLocalizations l10n) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF222222))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.settingsLanguage,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDDDDDD), fontSize: 13),
          ),
          Text(l10n.settingsLanguageSub, style: const TextStyle(color: Color(0xFF666666), fontSize: 11)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppLanguage.values.map((lang) {
              final selected = settings.language == lang;
              return ChoiceChip(
                label: Text('${lang.flag} ${lang.label}'),
                selected: selected,
                selectedColor: AppColors.green.withValues(alpha: 0.25),
                side: BorderSide(color: selected ? AppColors.green : const Color(0xFF333333)),
                labelStyle: TextStyle(
                  color: selected ? AppColors.green : const Color(0xFFAAAAAA),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                  fontSize: 12,
                ),
                onSelected: (_) => settings.setLanguage(lang),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _pushSection() {
    final auth = context.read<AuthService>();
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF222222))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bildirimler',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDDDDDD), fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            PushService.statusMessage,
            style: const TextStyle(color: Color(0xFF888888), fontSize: 10),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () async {
                  await PushService.refreshToken();
                  if (auth.user != null) {
                    await PushService.initAndRegister(auth.getUid());
                  }
                  if (mounted) setState(() {});
                },
                child: const Text('Yenile', style: TextStyle(fontSize: 11)),
              ),
              OutlinedButton(
                onPressed: () async {
                  await PushService.copyTokenToClipboard();
                  if (mounted) setState(() {});
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('FCM token panoya kopyalandı')),
                    );
                  }
                },
                child: const Text('Token kopyala', style: TextStyle(fontSize: 11)),
              ),
              OutlinedButton(
                onPressed: () async {
                  final ok = await PushService.showTestNotification();
                  if (mounted) setState(() {});
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok ? 'Yerel test bildirimi gönderildi' : PushService.statusMessage),
                      ),
                    );
                  }
                },
                child: const Text('Test bildirimi', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Firebase test: Messaging → Send test message → token yapıştır.\n'
            'Topic kampanya: hedef topic = pucket',
            style: TextStyle(color: Color(0xFF555555), fontSize: 9, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _row(String title, String sub, Widget trailing) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF222222))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDDDDDD), fontSize: 13)),
                Text(sub, style: const TextStyle(color: Color(0xFF666666), fontSize: 11)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _sliderRow(String title, double value, void Function(double) onChanged) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF222222))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDDDDDD), fontSize: 13)),
          ),
          SizedBox(
            width: 140,
            child: Slider(
              value: value,
              activeColor: AppColors.green,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
