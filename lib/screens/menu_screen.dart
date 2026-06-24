import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/rank_tier.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/pucket_button.dart';
import 'app_router.dart';
import 'rank_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;
    final tier = user != null ? RankTier.forElo(user.elo) : null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4),
            radius: 1.2,
            colors: [Color(0xFF1C3A0A), AppColors.bg],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (user != null && tier != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Color(0x0AFFFFFF),
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _profileTap(context, auth),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.green.withValues(alpha: 0.15),
                            border: Border.all(color: AppColors.green, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppColors.green,
                              fontSize: 17,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${user.elo} ELO  •  ${user.wins}G ${user.losses}M',
                              style: const TextStyle(color: Color(0xFF666666), fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RankScreen()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: tier.color),
                          ),
                          child: Text(
                            '${tier.emoji} ${tier.name}',
                            style: TextStyle(color: tier.color, fontWeight: FontWeight.w700, fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [AppColors.green, Color(0xFFB0EE50)],
                          ).createShader(bounds),
                          child: const Text(
                            'PUCKET',
                            style: TextStyle(
                              fontSize: 72,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 8,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const Text(
                        'ONLINE MULTIPLAYER',
                        style: TextStyle(color: AppColors.gold, fontSize: 10, letterSpacing: 4),
                      ),
                      const SizedBox(height: 28),
                      PucketButton(
                        label: '🏆 RANKED MAÇ',
                        gradient: const LinearGradient(colors: [Color(0xFF2060C0), AppColors.green]),
                        shadowColor: const Color(0xFF1040A0),
                        onPressed: () => AppRouter.goQueue(context),
                      ),
                      const SizedBox(height: 14),
                      PucketButton(
                        label: '⚡ HIZLI EŞLEŞTİR',
                        onPressed: () => AppRouter.goLobby(context, quickMatch: true),
                      ),
                      const SizedBox(height: 14),
                      PucketButton(
                        label: '🏠 ODA OLUŞTUR',
                        onPressed: () => AppRouter.goLobby(context, createRoom: true),
                      ),
                      const SizedBox(height: 14),
                      PucketButton(
                        label: '🔑 ODAYA KATIL',
                        onPressed: () => AppRouter.goJoin(context),
                      ),
                      const SizedBox(height: 14),
                      PucketButton(
                        label: '🤖 BİLGİSAYARA KARŞI',
                        color: const Color(0xFF252525),
                        shadowColor: const Color(0xFF111111),
                        onPressed: () => AppRouter.goDifficulty(context),
                      ),
                      const SizedBox(height: 20),
                      const _DividerRow(label: 'daha fazla'),
                      const SizedBox(height: 10),
                      PucketButton(
                        label: '🏅 SIRALAMALAR',
                        secondary: true,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RankScreen()),
                        ),
                      ),
                      const SizedBox(height: 14),
                      PucketButton(
                        label: 'NASIL OYNANIR?',
                        secondary: true,
                        onPressed: () => AppRouter.goTutorial(context),
                      ),
                      const SizedBox(height: 14),
                      PucketButton(
                        label: '👤 PROFİLİM',
                        secondary: true,
                        onPressed: () => AppRouter.goProfile(context),
                      ),
                      const SizedBox(height: 14),
                      PucketButton(
                        label: '⚙ AYARLAR',
                        secondary: true,
                        onPressed: () => AppRouter.goSettings(context),
                      ),
                    ],
                  ),
                ),
              ),
              const AdBannerWidget(),
            ],
          ),
        ),
      ),
    );
  }

  void _profileTap(BuildContext context, AuthService auth) {
    if (auth.user?.isAnonymous ?? true) {
      auth.signInWithGoogle();
    } else {
      AppRouter.goProfile(context);
    }
  }
}

class _DividerRow extends StatelessWidget {
  const _DividerRow({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(label, style: const TextStyle(color: Color(0xFF444444), fontSize: 11)),
        ),
        Expanded(child: Container(height: 1, color: AppColors.border)),
      ],
    );
  }
}
