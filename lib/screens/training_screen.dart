import 'package:flutter/material.dart';

import '../game/ai_bot.dart';
import '../l10n/l10n_extension.dart';
import '../theme/app_theme.dart';
import '../widgets/pucket_button.dart';
import 'app_router.dart';

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.menuTraining),
        backgroundColor: AppColors.bg,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              l10n.trainingDesc,
              style: const TextStyle(color: Color(0xFF888888), height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PucketButton(
              label: l10n.trainingShooting,
              onPressed: () => AppRouter.startTraining(context, TrainingType.shooting),
            ),
            const SizedBox(height: 12),
            PucketButton(
              label: l10n.trainingDefense,
              secondary: true,
              onPressed: () => AppRouter.startTraining(context, TrainingType.defense),
            ),
            const SizedBox(height: 12),
            PucketButton(
              label: l10n.trainingFull,
              secondary: true,
              onPressed: () => AppRouter.startTraining(context, TrainingType.full, level: AiLevel.easy),
            ),
          ],
        ),
      ),
    );
  }
}

enum TrainingType { shooting, defense, full }
