import 'package:flutter/material.dart';

import '../game/ai_bot.dart';
import '../theme/app_theme.dart';
import '../widgets/pucket_button.dart';
import 'app_router.dart';

class DifficultyScreen extends StatelessWidget {
  const DifficultyScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                const Text(
                  'ZORLUK SEÇ',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFA0A0FF),
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'SEN 🔴 KIRMIZI · BOT 🔵 MAVİ',
                  style: TextStyle(color: Color(0xFF666666), fontSize: 12, letterSpacing: 2),
                ),
                const SizedBox(height: 24),
                PucketButton(
                  label: '🟢 KOLAY',
                  subtitle: 'Yavaş · Az isabetli',
                  color: const Color(0xFF27AE60),
                  shadowColor: const Color(0xFF1E8449),
                  width: 260,
                  onPressed: () => AppRouter.startAi(context, AiLevel.easy),
                ),
                const SizedBox(height: 16),
                PucketButton(
                  label: '🟡 ORTA',
                  subtitle: 'Dengeli · Makul',
                  color: const Color(0xFFE67E22),
                  shadowColor: const Color(0xFFCA6F1E),
                  width: 260,
                  onPressed: () => AppRouter.startAi(context, AiLevel.medium),
                ),
                const SizedBox(height: 16),
                PucketButton(
                  label: '🔴 ZOR',
                  subtitle: 'Hızlı · İsabetli · Acımasız',
                  color: const Color(0xFFC0392B),
                  shadowColor: const Color(0xFFA93226),
                  width: 260,
                  onPressed: () => AppRouter.startAi(context, AiLevel.hard),
                ),
                const SizedBox(height: 24),
                PucketButton(
                  label: 'GERİ',
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
