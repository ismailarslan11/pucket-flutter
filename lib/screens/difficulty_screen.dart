import 'package:flutter/material.dart';

import '../game/ai_bot.dart';
import '../l10n/l10n_extension.dart';
import '../theme/app_theme.dart';
import '../widgets/pucket_button.dart';
import 'app_router.dart';

class DifficultyScreen extends StatelessWidget {
  const DifficultyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4),
            radius: 1.2,
            colors: [Color(0xFF1A1A3A), AppColors.bg],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.sizeOf(context).height -
                    MediaQuery.paddingOf(context).top -
                    MediaQuery.paddingOf(context).bottom -
                    48,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.pickDifficulty,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFA0A0FF),
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.youRedBotBlue,
                    style: const TextStyle(color: Color(0xFF666666), fontSize: 12, letterSpacing: 2),
                  ),
                  const SizedBox(height: 24),
                  PucketButton(
                    label: l10n.diffEasy,
                    subtitle: l10n.diffEasySub,
                    color: const Color(0xFF27AE60),
                    shadowColor: const Color(0xFF1E8449),
                    width: 260,
                    onPressed: () => AppRouter.startAi(context, AiLevel.easy),
                  ),
                  const SizedBox(height: 16),
                  PucketButton(
                    label: l10n.diffMedium,
                    subtitle: l10n.diffMediumSub,
                    color: const Color(0xFFE67E22),
                    shadowColor: const Color(0xFFCA6F1E),
                    width: 260,
                    onPressed: () => AppRouter.startAi(context, AiLevel.medium),
                  ),
                  const SizedBox(height: 16),
                  PucketButton(
                    label: l10n.diffHard,
                    subtitle: l10n.diffHardSub,
                    color: const Color(0xFFC0392B),
                    shadowColor: const Color(0xFFA93226),
                    width: 260,
                    onPressed: () => AppRouter.startAi(context, AiLevel.hard),
                  ),
                  const SizedBox(height: 24),
                  PucketButton(
                    label: l10n.back,
                    secondary: true,
                    onPressed: () => Navigator.pop(context),
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
