import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

Future<void> showRankedLoginDialog(BuildContext context) {
  final l10n = context.l10n;
  final auth = context.read<AuthService>();

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.card,
      title: Text(
        l10n.menuRanked,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      ),
      content: Text(
        l10n.authRankedHint,
        style: const TextStyle(color: AppColors.textMuted, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.queueCancel),
        ),
        if (auth.appleSignInAvailable)
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              auth.signInWithApple();
            },
            child: const Text('Apple'),
          ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            auth.signInWithGoogle();
          },
          child: Text(l10n.authGoogle),
        ),
      ],
    ),
  );
}
