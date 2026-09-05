import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../l10n/l10n_extension.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/yesa_background.dart';
import '../widgets/pucket_logo.dart';
import '../widgets/yesa_effects.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final l10n = context.l10n;
    final googleOk = auth.googleSignInAvailable;

    return Scaffold(
      body: YesaBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  // Süzülen logo + etrafında parıltılar.
                  SizedBox(
                    height: 150,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        const Positioned(left: 10, top: 14, child: Twinkle(size: 14, phase: 0.0)),
                        const Positioned(right: 16, top: 30, child: Twinkle(size: 10, phase: 0.4, color: AppColors.gokAcik)),
                        const Positioned(right: 34, bottom: 6, child: Twinkle(size: 13, phase: 0.7)),
                        const Positioned(left: 40, bottom: 18, child: Twinkle(size: 9, phase: 0.2, color: AppColors.buzMavi)),
                        FloatY(
                          amplitude: 5,
                          child: const PucketLogo(height: 120, showTagline: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.appTagline,
                    style: const TextStyle(
                      color: AppColors.accentYellow,
                      letterSpacing: 4,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: YesaDecor.card(radius: 24),
                    child: Column(
                      children: [
                        Text(
                          l10n.authContinueLogin,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        if (auth.loading)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(color: AppColors.accentYellow),
                          )
                        else ...[
                          _GoogleButton(
                            enabled: googleOk,
                            label: l10n.authGoogle,
                            onPressed: () => auth.signInWithGoogle(),
                            notConfiguredMsg: l10n.authGoogleNotConfigured,
                          ),
                          if (!kIsWeb &&
                              defaultTargetPlatform == TargetPlatform.iOS &&
                              auth.firebaseAvailable) ...[
                            const SizedBox(height: 12),
                            SignInWithAppleButton(
                              onPressed: () => auth.signInWithApple(),
                              height: 48,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ],
                          if (!googleOk)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                l10n.authGoogleSetup,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.textDim, fontSize: 10),
                              ),
                            ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(child: Container(height: 1, color: AppColors.border)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(l10n.or, style: const TextStyle(color: AppColors.textFaint, fontSize: 11)),
                              ),
                              Expanded(child: Container(height: 1, color: AppColors.border)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: () => auth.signInAsGuest(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.pusluBeyaz,
                              side: BorderSide(color: AppColors.buzMavi.withValues(alpha: 0.55), width: 1.4),
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: AppColors.anaMavi.withValues(alpha: 0.12),
                            ),
                            icon: const Icon(Icons.rocket_launch_rounded, size: 18, color: AppColors.buzMavi),
                            label: Text(
                              l10n.authGuest,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                        if (auth.lastError != null) ...[
                          const SizedBox(height: 12),
                          Text(auth.lastError!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          l10n.authRankedHint,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textFaint, fontSize: 10, height: 1.6),
                        ),
                      ],
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

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({
    required this.enabled,
    required this.label,
    required this.onPressed,
    required this.notConfiguredMsg,
  });

  final bool enabled;
  final String label;
  final VoidCallback onPressed;
  final String notConfiguredMsg;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: enabled
              ? onPressed
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(notConfiguredMsg), duration: const Duration(seconds: 3)),
                  );
                },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.g_mobiledata, color: Color(0xFF4285F4), size: 28),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF3C4043),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
