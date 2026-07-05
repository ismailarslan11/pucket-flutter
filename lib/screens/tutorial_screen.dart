import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pucket_button.dart';
import '../widgets/yesa_background.dart';
import '../widgets/yesa_effects.dart';

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key, this.onDone});

  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: YesaBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              children: [
                StaggerIn(
                  index: 0,
                  child: GlowPulse(
                    color: AppColors.sariAna,
                    min: 0.2,
                    max: 0.5,
                    child: Text(
                      'PUCKET REHBERİ',
                      style: AppTextStyles.glow(AppColors.sariAna).copyWith(fontSize: 22, letterSpacing: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _Step(
                          n: '1',
                          index: 1,
                          color: AppColors.sariAna,
                          title: 'Amaç',
                          body:
                              'Kendi yarındaki TÜM pulları (kendi rengin + rakibin sende kalan pulları) karşı tarafa geçir. Alt yarı tamamen boş olunca kazanırsın.',
                        ),
                        _Step(
                          n: '2',
                          index: 2,
                          color: AppColors.acikMor,
                          title: 'Atış',
                          body: 'Puluna dokun, geri çek, bırak. Sadece kendi yarındaki pulları oynayabilirsin.',
                        ),
                        _Step(
                          n: '3',
                          index: 3,
                          color: AppColors.pembe,
                          title: 'Maç',
                          body: 'Best of 3 — 2 round kazanan maçı alır. Ranked modda ELO değişir.',
                        ),
                        _Step(
                          n: '4',
                          index: 4,
                          color: AppColors.camgobegi,
                          title: 'Online',
                          body:
                              'Duraklatma 60 sn ile sınırlı. Rakip koparsa 60 sn içinde dönebilir. Rematch için iki taraf da onaylamalı.',
                        ),
                      ],
                    ),
                  ),
                ),
                StaggerIn(
                  index: 5,
                  child: PucketButton(
                    label: 'ANLADIM, BAŞLA!',
                    width: double.infinity,
                    onPressed: () async {
                      await context.read<SettingsService>().markTutorialSeen();
                      if (context.mounted) {
                        if (onDone != null) {
                          onDone!();
                        } else {
                          Navigator.pop(context);
                        }
                      }
                    },
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

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.index, required this.color, required this.title, required this.body});

  final String n;
  final int index;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return StaggerIn(
      index: index,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: AppGradients.glassCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.5),
                boxShadow: AppShadows.neon(color, blur: 8),
              ),
              child: Text(n, style: TextStyle(fontWeight: FontWeight.w900, color: color)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.beyaz)),
                  const SizedBox(height: 4),
                  Text(body, style: const TextStyle(color: AppColors.textMuted, height: 1.45, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
