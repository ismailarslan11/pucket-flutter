import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../theme/app_theme.dart';
import '../widgets/pucket_button.dart';
import 'app_router.dart';

class LocalDuoScreen extends StatefulWidget {
  const LocalDuoScreen({super.key});

  @override
  State<LocalDuoScreen> createState() => _LocalDuoScreenState();
}

class _LocalDuoScreenState extends State<LocalDuoScreen> {
  final _p1 = TextEditingController(text: 'Oyuncu 1');
  final _p2 = TextEditingController(text: 'Oyuncu 2');

  @override
  void dispose() {
    _p1.dispose();
    _p2.dispose();
    super.dispose();
  }

  void _goBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      AppRouter.goMenu(context);
    }
  }

  void _start(BuildContext context) {
    final p1 = _p1.text.trim();
    final p2 = _p2.text.trim();
    AppRouter.startLocalDuo(
      context,
      playerRed: p1.isEmpty ? 'Oyuncu 1' : p1,
      playerBlue: p2.isEmpty ? 'Oyuncu 2' : p2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.screenBg),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => _goBack(context),
                  icon: const Icon(Icons.arrow_back, color: AppColors.textMuted),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              l10n.localDuoTitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: AppColors.gold,
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 320),
                              child: Text(
                                l10n.localDuoDesc,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            _nameField(
                              label: l10n.localDuoPlayer1,
                              controller: _p1,
                              color: AppColors.red,
                            ),
                            const SizedBox(height: 14),
                            _nameField(
                              label: l10n.localDuoPlayer2,
                              controller: _p2,
                              color: AppColors.blue,
                            ),
                            const SizedBox(height: 28),
                            PucketButton(
                              label: l10n.localDuoStart,
                              width: 280,
                              gradient: AppGradients.accent,
                              shadowColor: AppColors.nightBlue,
                              onPressed: () => _start(context),
                            ),
                            const SizedBox(height: 24),
                            PucketButton(
                              label: l10n.back,
                              secondary: true,
                              width: 200,
                              onPressed: () => _goBack(context),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nameField({
    required String label,
    required TextEditingController controller,
    required Color color,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLength: 16,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: AppColors.card,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color.withValues(alpha: 0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
