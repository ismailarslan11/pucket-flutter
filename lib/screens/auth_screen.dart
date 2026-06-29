import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../l10n/l10n_extension.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pucket_logo.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final l10n = context.l10n;
    final googleOk = auth.googleSignInAvailable;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.screenBg),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const PucketLogo(height: 120, showTagline: true),
                  const SizedBox(height: 6),
                  Text(
                    l10n.onlineMultiplayer,
                    style: const TextStyle(color: AppColors.cyan, letterSpacing: 4, fontSize: 10),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: 300,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Text(
                          l10n.authContinueLogin,
                          style: const TextStyle(color: Color(0xFF666666), fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        if (auth.loading)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(color: AppColors.green),
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
                                style: const TextStyle(color: Color(0xFF555555), fontSize: 10),
                              ),
                            ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(child: Container(height: 1, color: AppColors.border)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(l10n.or, style: const TextStyle(color: Color(0xFF444444), fontSize: 11)),
                              ),
                              Expanded(child: Container(height: 1, color: AppColors.border)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: () => auth.signInAsGuest(),
                            icon: const Text('👤', style: TextStyle(fontSize: 16)),
                            label: Text(l10n.authGuest),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF666666),
                              side: const BorderSide(color: AppColors.border),
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                        ],
                        if (auth.lastError != null) ...[
                          const SizedBox(height: 12),
                          Text(auth.lastError!, style: const TextStyle(color: AppColors.red, fontSize: 12)),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          l10n.authRankedHint,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF444444), fontSize: 10, height: 1.6),
                        ),
                      ],
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
                    color: Color(0xFF333333),
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
