import 'package:flutter/material.dart';

import '../game/ai_bot.dart';
import '../l10n/l10n_extension.dart';
import '../theme/app_theme.dart';
import '../widgets/pucket_button.dart';
import 'app_router.dart';

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

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
                              l10n.menuTraining,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: AppColors.green,
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 320),
                              child: Text(
                                l10n.trainingDesc,
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
                              label: l10n.trainingShooting,
                              subtitle: l10n.trainingGoalShooting,
                              width: 280,
                              onPressed: () => AppRouter.startTraining(context, TrainingType.shooting),
                            ),
                            const SizedBox(height: 14),
                            PucketButton(
                              label: l10n.trainingDefense,
                              subtitle: l10n.trainingGoalDefense,
                              color: AppColors.brandOrange,
                              shadowColor: AppColors.darkOrange,
                              width: 280,
                              onPressed: () => AppRouter.startTraining(context, TrainingType.defense),
                            ),
                            const SizedBox(height: 14),
                            PucketButton(
                              label: l10n.trainingFull,
                              subtitle: l10n.trainingGoalFull,
                              color: AppColors.nightBlue,
                              shadowColor: AppColors.bgDeep,
                              width: 280,
                              onPressed: () => AppRouter.startTraining(
                                context,
                                TrainingType.full,
                                level: AiLevel.easy,
                              ),
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

enum TrainingType { shooting, defense, full }
