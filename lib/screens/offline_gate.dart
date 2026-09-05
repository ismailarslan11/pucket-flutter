import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../theme/app_theme.dart';
import '../widgets/yesa_background.dart';
import '../widgets/yesa_effects.dart';

/// Açılış internet kapısı — bağlantı yoksa oyuna sokmaz.
///
/// Bağlantı gelene kadar engel ekranı gösterir, arka planda birkaç saniyede
/// bir yeniden dener; internet gelince kendiliğinden oyuna geçer. Kapı bir
/// kez geçildikten sonra oturum boyunca bir daha devreye girmez (maç
/// ortasında anlık kopmalar oyun soketinin kendi akışına bırakılır).
class OfflineGate extends StatefulWidget {
  const OfflineGate({super.key, required this.child});

  final Widget child;

  /// Marka animasyonu sırasında kontrolü önden başlat — çevrimiçi kullanıcı
  /// kapıyı hiç görmeden geçer.
  static Future<bool>? _prewarm;
  static void prewarm() => _prewarm ??= _lookupOnline();

  @override
  State<OfflineGate> createState() => _OfflineGateState();
}

Future<bool> _lookupOnline() async {
  if (kIsWeb) return true; // Web'de kapı yok.
  try {
    final result =
        await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 4));
    return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}

class _OfflineGateState extends State<OfflineGate> with WidgetsBindingObserver {
  bool _passed = false;
  bool _checking = true;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Uygulama geri gelince hâlâ kapıdaysak tekrar dene.
    if (state == AppLifecycleState.resumed && !_passed) _check();
  }

  bool _usedPrewarm = false;

  Future<void> _check() async {
    if (_passed) return;
    if (mounted) setState(() => _checking = true);

    // İlk kontrolde (varsa) splash sırasında başlatılan sonucu kullan.
    bool online;
    if (!_usedPrewarm && OfflineGate._prewarm != null) {
      _usedPrewarm = true;
      online = await OfflineGate._prewarm!;
    } else {
      online = await _lookupOnline();
    }

    if (!mounted) return;
    if (online) {
      _retryTimer?.cancel();
      setState(() {
        _passed = true;
        _checking = false;
      });
    } else {
      setState(() => _checking = false);
      // Otomatik yeniden deneme — internet gelince kapı kendiliğinden açılır.
      _retryTimer ??= Timer.periodic(const Duration(seconds: 3), (_) => _check());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_passed) return widget.child;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: _OfflineScreen(checking: _checking, onRetry: _check),
    );
  }
}

class _OfflineScreen extends StatelessWidget {
  const _OfflineScreen({required this.checking, required this.onRetry});

  final bool checking;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: YesaBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
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
                          border: Border.all(color: AppColors.beyaz.withValues(alpha: 0.3), width: 1.5),
                        ),
                        child: const Icon(Icons.wifi_off_rounded,
                            color: AppColors.turuncuAcik, size: 42),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.noInternetTitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.glow(AppColors.turuncuAna)
                        .copyWith(fontSize: 20, letterSpacing: 1),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.noInternetBody,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ScalePress(
                    onTap: checking ? () {} : onRetry,
                    child: Container(
                      width: 220,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppGradients.heroPlay,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.beyaz.withValues(alpha: 0.4)),
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
                              l10n.noInternetRetry,
                              style: const TextStyle(
                                color: AppColors.laciDerin,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 1.2,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (checking)
                    Text(
                      l10n.noInternetChecking,
                      style: const TextStyle(color: AppColors.textFaint, fontSize: 11),
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
