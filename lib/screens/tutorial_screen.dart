import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pucket_button.dart';

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key, this.onDone});

  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.95),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                'PUCKET REHBERİ',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.gold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _Step(
                        n: '1',
                        title: 'Amaç',
                        body:
                            'Kendi yarındaki TÜM pulları (kendi rengin + rakibin sende kalan pulları) karşı tarafa geçir. Alt yarı tamamen boş olunca kazanırsın.',
                      ),
                      _Step(
                        n: '2',
                        title: 'Atış',
                        body: 'Puluna dokun, geri çek, bırak. Sadece kendi yarındaki pulları oynayabilirsin.',
                      ),
                      _Step(
                        n: '3',
                        title: 'Maç',
                        body: 'Best of 3 — 2 round kazanan maçı alır. Ranked modda ELO değişir.',
                      ),
                      _Step(
                        n: '4',
                        title: 'Online',
                        body:
                            'Duraklatma 60 sn ile sınırlı. Rakip koparsa 60 sn içinde dönebilir. Rematch için iki taraf da onaylamalı.',
                      ),
                    ],
                  ),
                ),
              ),
              PucketButton(
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
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.title, required this.body});
  final String n;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.green),
            ),
            child: Text(n, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.green)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(color: AppColors.textMuted, height: 1.45, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
