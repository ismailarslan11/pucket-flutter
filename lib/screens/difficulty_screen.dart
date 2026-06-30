import 'package:flutter/material.dart';

import '../game/ai_bot.dart';
import '../l10n/l10n_extension.dart';
import '../theme/app_theme.dart';
import '../widgets/pucket_button.dart';
import 'app_router.dart';

class DifficultyScreen extends StatelessWidget {
  const DifficultyScreen({super.key});

  void _goBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      AppRouter.goMenu(context);
    }
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
                              l10n.menuVsBot,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: AppColors.fieldBlue,
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.pickDifficulty,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 320),
                              child: Text(
                                l10n.youRedBotBlue,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                  height: 1.5,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            PucketButton(
                              label: l10n.diffEasy,
                              subtitle: l10n.diffEasySub,
                              color: AppColors.brandBlue,
                              shadowColor: AppColors.nightBlue,
                              width: 280,
                              onPressed: () => AppRouter.startAi(context, AiLevel.easy),
                            ),
                            const SizedBox(height: 14),
                            PucketButton(
                              label: l10n.diffMedium,
                              subtitle: l10n.diffMediumSub,
                              color: AppColors.brandOrange,
                              shadowColor: AppColors.darkOrange,
                              width: 280,
                              onPressed: () => AppRouter.startAi(context, AiLevel.medium),
                            ),
                            const SizedBox(height: 14),
                            PucketButton(
                              label: l10n.diffHard,
                              subtitle: l10n.diffHardSub,
                              color: AppColors.darkOrange,
                              shadowColor: AppColors.bgDeep,
                              width: 280,
                              onPressed: () => AppRouter.startAi(context, AiLevel.hard),
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
}
