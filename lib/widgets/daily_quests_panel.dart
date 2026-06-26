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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(l10n.dailyQuests, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              const Spacer(),
              Text('🔥 $streak', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          _questRow('🎮 ${l10n.questPlay3}', play, 3),
          _questRow('🏆 ${l10n.questWin1}', win, 1),
          _questRow('🎯 ${l10n.questCareer1}', career, 1),
          if (meta.lastMessage != null) ...[
            const SizedBox(height: 6),
            Text(meta.lastMessage!, style: const TextStyle(color: AppColors.green, fontSize: 11)),
          ],
          const SizedBox(height: 10),
          PucketButton(
            label: claimed ? l10n.questClaimed : (complete ? l10n.questClaim : l10n.questInProgress),
            width: double.infinity,
            secondary: !complete || claimed,
            onPressed: (!complete || claimed)
                ? () {}
                : () => meta.claimDailyReward(auth.getUid()),
          ),
        ],
      ),
    );
  }

  Widget _questRow(String label, int current, int target) {
    final done = current >= target;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 11, color: done ? AppColors.green : const Color(0xFF888888)))),
          Text('$current/$target', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: done ? AppColors.green : const Color(0xFF666666))),
        ],
      ),
    );
  }
}
