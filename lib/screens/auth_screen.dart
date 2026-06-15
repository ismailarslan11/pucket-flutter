import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4),
            radius: 1.2,
            colors: [Color(0xFF1C3A0A), AppColors.bg],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppColors.green, Color(0xFFB0EE50)],
                      ).createShader(bounds),
                      child: const Text(
                        'PUCKET',
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'ONLINE MULTIPLAYER',
                    style: TextStyle(color: AppColors.gold, letterSpacing: 4, fontSize: 10),
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
                        const Text(
                          'Devam etmek için giriş yap',
                          style: TextStyle(color: Color(0xFF666666), fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        if (auth.loading)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(color: AppColors.green),
                          )
                        else ...[
                          Opacity(
                            opacity: auth.firebaseAvailable ? 1 : 0.45,
                            child: _GoogleButton(
                              onPressed: auth.firebaseAvailable
                                  ? () => auth.signInWithGoogle()
                                  : () {},
                            ),
                          ),
                          if (!auth.firebaseAvailable)
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text(
                                'Google girişi için: bash tool/setup_firebase.sh',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFF555555), fontSize: 10),
                              ),
                            ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(child: Container(height: 1, color: AppColors.border)),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text('veya', style: TextStyle(color: Color(0xFF444444), fontSize: 11)),
                              ),
                              Expanded(child: Container(height: 1, color: AppColors.border)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: () => auth.signInAsGuest(),
                            icon: const Text('👤', style: TextStyle(fontSize: 16)),
                            label: const Text('Misafir Olarak Devam Et'),
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
                        const Text(
                          'Google ile giriş yaparak sıralama listesine katılır,\nilerlemen kaydedilir.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF444444), fontSize: 10, height: 1.6),
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
  const _GoogleButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.g_mobiledata, color: Color(0xFF4285F4), size: 28),
              SizedBox(width: 8),
              Text(
                'Google ile Giriş Yap',
                style: TextStyle(
                  color: Color(0xFF333333),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
