import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../services/auth_service.dart';
import '../services/player_meta_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pucket_button.dart';

class DailyQuestsPanel extends StatelessWidget {
  const DailyQuestsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final meta = context.watch<PlayerMetaService>();
    final auth = context.watch<AuthService>();
    final l10n = context.l10n;
    final q = meta.meta?.quests ?? {};
    final play = (q['play'] as num?)?.toInt() ?? 0;
    final win = (q['win'] as num?)?.toInt() ?? 0;
    final career = (q['career'] as num?)?.toInt() ?? 0;
    final streak = meta.meta?.streak ?? 0;
    final claimed = meta.meta?.questsClaimed ?? false;
    final complete = meta.meta?.questsComplete ?? false;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.all(16),
      decoration: YesaDecor.card(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.dailyQuests.toUpperCase(),
                style: AppTextStyles.title.copyWith(fontSize: 12, letterSpacing: 0.8),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppGradients.heroPlay,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: AppShadows.neon(AppColors.sariAna, blur: 8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        size: 13, color: AppColors.laciDerin),
                    const SizedBox(width: 3),
                    Text(
                      '$streak',
                      style: AppTextStyles.tileFeatured.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _questRow(l10n.questPlay3, play, 3),
          _questRow(l10n.questWin1, win, 1),
          _questRow(l10n.questCareer1, career, 1),
          if (meta.lastMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              meta.lastMessage!,
              style: AppTextStyles.glow(AppColors.neonYesil).copyWith(fontSize: 11),
            ),
          ],
          const SizedBox(height: 12),
          PucketButton(
            label: claimed ? l10n.questClaimed : (complete ? l10n.questClaim : l10n.questInProgress),
            width: double.infinity,
            primary: complete && !claimed,
            secondary: !complete || claimed,
            enabled: complete && !claimed,
            onPressed: complete && !claimed
                ? () => meta.claimDailyReward(auth.getUid())
                : () {},
          ),
        ],
      ),
    );
  }

  Widget _questRow(String label, int current, int target) {
    final done = current >= target;
    final progress = (current / target).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                size: 14,
                color: done ? AppColors.neonYesil : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: done ? AppColors.neonYesil : AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '$current/$target',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: done ? AppColors.neonYesil : AppColors.sariAna,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: AppColors.laciDerin.withValues(alpha: 0.8),
              valueColor: AlwaysStoppedAnimation(
                done ? AppColors.neonYesil : AppColors.sariAna,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
