import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../l10n/app_language.dart';
import '../l10n/l10n_extension.dart';
import '../config/ad_config.dart';
import '../services/ad_service.dart';
import '../services/auth_service.dart';
import '../services/consent_service.dart';
import '../services/purchase_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/yesa_background.dart';
import '../widgets/yesa_effects.dart';
import '../widgets/yesa_menu_tile.dart';
import 'legal_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
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
                        l10n.settingsTitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.glow(AppColors.sariAna).copyWith(fontSize: 18, letterSpacing: 2),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    StaggerIn(index: 0, child: _shopCard(context, l10n)),
                    const SizedBox(height: 14),
                    StaggerIn(index: 1, child: _languageCard(context, settings, l10n)),
                    const SizedBox(height: 14),
                    StaggerIn(
                      index: 2,
                      child: _SettingsCard(
                        title: l10n.settingsSoundSection.toUpperCase(),
                        children: [
                          _switchRow(
                            l10n.settingsMusic,
                            l10n.settingsMusicSub,
                            settings.musicOn,
                            settings.setMusic,
                          ),
                          _sliderRow(l10n.settingsMusicVol, settings.musicVolume, settings.setMusicVolume),
                          const Divider(color: AppColors.borderSubtle, height: 20),
                          _switchRow(
                            l10n.settingsSfx,
                            l10n.settingsSfxSub,
                            settings.sfxOn,
                            settings.setSfx,
                          ),
                          _sliderRow(l10n.settingsSfxVol, settings.sfxVolume, settings.setSfxVolume),
                          const Divider(color: AppColors.borderSubtle, height: 20),
                          _switchRow(
                            l10n.settingsVibration,
                            l10n.settingsVibrationSub,
                            settings.vibrationOn,
                            settings.setVibration,
                          ),
                        ],
                      ),
                    ),
                    if (AdConfig.supported) ...[
                      const SizedBox(height: 14),
                      StaggerIn(
                        index: 3,
                        child: _SettingsCard(
                          title: l10n.settingsPrivacySection.toUpperCase(),
                          children: [
                            _linkRow(
                              l10n.settingsAds,
                              l10n.settingsAdsSub,
                              l10n.settingsAdPrivacy,
                              () async {
                                final ok = await ConsentService.showPrivacyOptions();
                                if (!context.mounted) return;
                                if (!ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(l10n.settingsAdPrivacyUnavailable)),
                                  );
                                  return;
                                }
                                await context.read<AdService>().refreshAfterConsent();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(l10n.settingsAdPrivacySaved)),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    StaggerIn(
                      index: 4,
                      child: Column(
                        children: [
                          ScalePress(
                            onTap: () async {
                              await context.read<AuthService>().signOut();
                              if (context.mounted) Navigator.pop(context);
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.kirmizi.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.kirmizi.withValues(alpha: 0.4)),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                l10n.signOut,
                                style: const TextStyle(color: AppColors.kirmizi, fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () => LegalScreen.showPrivacy(context),
                                child: Text(l10n.privacyPolicy, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                              ),
                              TextButton(
                                onPressed: () => LegalScreen.showTerms(context),
                                child: Text(l10n.termsOfUse, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: () => _confirmDeleteAccount(context),
                            child: Text(
                              l10n.deleteAccount,
                              style: const TextStyle(color: AppColors.kirmizi, fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final l10n = context.l10nRead;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardElevated,
        title: Text(l10n.deleteAccountConfirm, style: const TextStyle(color: AppColors.beyaz)),
        content: Text(l10n.deleteAccountBody, style: const TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel, style: const TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.deleteAccount, style: const TextStyle(color: AppColors.kirmizi, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final ok = await context.read<AuthService>().deleteAccount();
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(ok ? l10n.deleteAccountDone : l10n.deleteAccountFailed)),
    );
    if (ok) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Widget _shopCard(BuildContext context, AppLocalizations l10n) {
    final purchases = context.watch<PurchaseService>();
    final settings = context.watch<SettingsService>();
    final removeAdsProduct = purchases.productFor(ProductIds.removeAds);
    final tokenProduct = purchases.productFor(ProductIds.tokens100);
    return _SettingsCard(
      title: l10n.shop.toUpperCase(),
      children: [
        if (!purchases.available)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(l10n.iapUnavailable,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          )
        else ...[
          _shopRow(
            icon: Icons.block_rounded,
            label: settings.adsRemoved ? l10n.adsAlreadyRemoved : l10n.removeAds,
            price: settings.adsRemoved ? null : (removeAdsProduct?.price ?? ''),
            onTap: settings.adsRemoved ? null : () => purchases.buy(ProductIds.removeAds),
          ),
          _shopRow(
            icon: Icons.monetization_on_rounded,
            label: '${l10n.buyTokens} (100)',
            price: tokenProduct?.price ?? '',
            onTap: () => purchases.buy(ProductIds.tokens100),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => purchases.restore(),
              child: Text(l10n.restorePurchases,
                  style: const TextStyle(color: AppColors.sariAna, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _shopRow({
    required IconData icon,
    required String label,
    String? price,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.sariAna, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(color: AppColors.beyaz, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          if (onTap != null)
            ScalePress(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: AppGradients.heroPlay,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(price ?? '',
                    style: const TextStyle(
                        color: AppColors.laciDerin, fontWeight: FontWeight.w900, fontSize: 12)),
              ),
            )
          else
            const Icon(Icons.check_circle_rounded, color: AppColors.neonYesil, size: 20),
        ],
      ),
    );
  }

  Widget _languageCard(BuildContext context, SettingsService settings, AppLocalizations l10n) {
    return _SettingsCard(
      title: l10n.settingsLanguage.toUpperCase(),
      children: [
        Text(l10n.settingsLanguageSub, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppLanguage.values.map((lang) {
            final selected = settings.language == lang;
            return ScalePress(
              onTap: () => settings.setLanguage(lang),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: selected ? AppGradients.neonPurple : null,
                  color: selected ? null : AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: selected ? AppColors.beyaz.withValues(alpha: 0.35) : AppColors.borderSubtle),
                  boxShadow: selected ? AppShadows.neon(AppColors.acikMavi, blur: 6) : null,
                ),
                child: Text(
                  '${lang.flag} ${lang.label}',
                  style: TextStyle(
                    color: selected ? AppColors.beyaz : AppColors.textMuted,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _switchRow(String title, String sub, bool value, void Function(bool) onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.beyaz, fontSize: 13)),
              Text(sub, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: AppColors.sariAna,
          activeTrackColor: AppColors.sariAna.withValues(alpha: 0.35),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _sliderRow(String title, double value, void Function(double) onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        SizedBox(
          width: 140,
          child: Slider(
            value: value,
            activeColor: AppColors.sariAna,
            inactiveColor: AppColors.borderSubtle,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _linkRow(String title, String sub, String actionLabel, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.beyaz, fontSize: 13)),
                if (sub.isNotEmpty) Text(sub, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
            onPressed: onTap,
            child: Text(
              actionLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.sariAna, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: YesaDecor.card(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          YesaSectionLabel(title),
          ...children,
        ],
      ),
    );
  }
}
