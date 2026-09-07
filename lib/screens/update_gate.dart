import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../l10n/app_language.dart';
import '../l10n/l10n_extension.dart';
import '../services/remote_config_service.dart';
import '../services/settings_service.dart';
import '../config/store_config.dart';
import '../theme/app_theme.dart';
import '../widgets/yesa_background.dart';
import '../widgets/yesa_effects.dart';

/// Zorunlu güncelleme kapısı — desteklenmeyen sürümü oyuna sokmaz.
///
/// Eşiği Firebase Remote Config belirler (bkz. [RemoteConfigService]); orası
/// şüphede kaldığı her durumda "engelleme" der, dolayısıyla bu kapı yalnızca
/// gerçekten eski bir sürümde kapanır.
///
/// [OfflineGate]'in İÇİNDE durmalı: Remote Config internet ister, internetsiz
/// kullanıcı zaten dış kapıda bekliyor olur.
class UpdateGate extends StatefulWidget {
  const UpdateGate({super.key, required this.child});

  final Widget child;

  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<UpdateGate> with WidgetsBindingObserver {
  bool _blocked = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Mağazadan dönen kullanıcı için tekrar bak.
    if (state == AppLifecycleState.resumed && _blocked) _recheck();
  }

  Future<void> _check() async {
    final blocked = await RemoteConfigService.blocked;
    if (!mounted) return;
    setState(() {
      _blocked = blocked;
      _checking = false;
    });
  }

  Future<void> _recheck() async {
    if (mounted) setState(() => _checking = true);
    final blocked = await RemoteConfigService.recheck();
    if (!mounted) return;
    setState(() {
      _blocked = blocked;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Kontrol sürerken oyunu göstermeye devam et — marka animasyonunun
    // altında biten bir işlem için ekstra bir bekleme ekranı koymuyoruz.
    if (!_blocked) return widget.child;

    final language = context.watch<SettingsService>().language;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      locale: language.locale,
      supportedLocales: AppLanguage.values.map((l) => l.locale),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Kapı kendi MaterialApp'ini kurduğu için yönü burada da vermek gerekiyor;
      // aksi halde Arapça soldan sağa çiziliyor.
      builder: (context, child) => Directionality(
        textDirection:
            language.isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: child ?? const SizedBox.shrink(),
      ),
      home: _UpdateRequiredScreen(checking: _checking, onUpdate: _openStore),
    );
  }

  Future<void> _openStore() async {
    final opened = await StoreConfig.openStore();
    if (opened || !mounted) return;
    // Mağaza açılamadıysa sessiz kalma — adresi göster.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(StoreConfig.webUrl)),
    );
  }
}

class _UpdateRequiredScreen extends StatelessWidget {
  const _UpdateRequiredScreen({required this.checking, required this.onUpdate});

  final bool checking;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: YesaBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatY(
                    amplitude: 5,
                    child: GlowPulse(
                      color: AppColors.turuncuAna,
                      min: 0.25,
                      max: 0.55,
                      child: Container(
                        width: 92,
                        height: 92,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppGradients.neonPurple,
                          border: Border.all(
                              color: AppColors.beyaz.withValues(alpha: 0.3),
                              width: 1.5),
                        ),
                        child: const Icon(Icons.system_update_rounded,
                            color: AppColors.turuncuAcik, size: 42),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.updateRequiredTitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.glow(AppColors.turuncuAna)
                        .copyWith(fontSize: 20, letterSpacing: 1),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.updateRequiredBody,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ScalePress(
                    onTap: checking ? () {} : onUpdate,
                    child: Container(
                      width: 220,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppGradients.heroPlay,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.beyaz.withValues(alpha: 0.4)),
                        boxShadow: AppShadows.neon(AppColors.sariAna, blur: 12),
                      ),
                      child: checking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: AppColors.laciDerin,
                              ),
                            )
                          : Text(
                              l10n.updateNow,
                              style: const TextStyle(
                                color: AppColors.laciDerin,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 1.2,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
