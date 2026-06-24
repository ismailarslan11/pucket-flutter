import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/ad_service.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import 'legal_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/pucket_button.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

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
                  const Text(
                    '⚙ AYARLAR',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.green,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _row(
                    'Müzik',
                    'Menü arkaplan müziği',
                    Switch(
                      value: settings.musicOn,
                      activeThumbColor: AppColors.green,
                      onChanged: settings.setMusic,
                    ),
                  ),
                  _row(
                    'Ses Efektleri',
                    'Fırlatma, çarpışma sesleri',
                    Switch(
                      value: settings.sfxOn,
                      activeThumbColor: AppColors.green,
                      onChanged: settings.setSfx,
                    ),
                  ),
                  _sliderRow(
                    'Müzik Ses',
                    settings.musicVolume,
                    settings.setMusicVolume,
                  ),
                  _sliderRow(
                    'Efekt Ses',
                    settings.sfxVolume,
                    settings.setSfxVolume,
                  ),
                  _row(
                    'Titreşim',
                    'Atış ve kazanma titreşimi',
                    Switch(
                      value: settings.vibrationOn,
                      activeThumbColor: AppColors.green,
                      onChanged: settings.setVibration,
                    ),
                  ),
                  _row(
                    'Reklamlar',
                    'Banner + maç arası reklamlar (gelir)',
                    Switch(
                      value: settings.adsOn,
                      activeThumbColor: AppColors.green,
                      onChanged: (v) {
                        settings.setAds(v);
                        context.read<AdService>().onAdsSettingChanged();
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => LegalScreen.showPrivacy(context),
                    child: const Text('Gizlilik Politikası', style: TextStyle(color: Color(0xFF666666))),
                  ),
                  TextButton(
                    onPressed: () => LegalScreen.showTerms(context),
                    child: const Text('Kullanım Şartları', style: TextStyle(color: Color(0xFF666666))),
                  ),
                  const SizedBox(height: 16),
                  PucketButton(
                    label: 'KAYDET & GERİ',
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
