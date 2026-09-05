import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../services/auth_service.dart';
import '../services/career_service.dart';
import '../services/player_meta_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/daily_quests_panel.dart';
import '../widgets/pucket_logo.dart';
import '../widgets/ranked_login_dialog.dart';
import '../widgets/yesa_background.dart';
import '../widgets/yesa_effects.dart';
import 'app_router.dart';

/// Ana menü.
///
/// Önceki hâli dikey bir panel listesiydi: profil kartı, görev paneli, sonra
/// oyun kartları — hepsi aynı boyda dikdörtgen. Hiyerarşi olmadığı için ekran
/// bir ayarlar sayfası gibi okunuyordu. Bu düzen üç kademeye ayrılır:
///
///   1. İnce üst şerit — kimlik ve sayaçlar, kart değil
///   2. Kahraman alan — süzülen logo + nabız atan OYNA
///   3. İkincil modlar, sonra yuvarlak ikonlar — küçülen ağırlıkta
///
/// Görev listesi satır satır ekranda durmak yerine üst şeritteki alev
/// rozetinin arkasına alındı; menüye giren oyuncu önce oynamayı görüyor.
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  /// Tek denetleyici hem logonun süzülmesini hem OYNA'nın nabzını sürer —
  /// iki ayrı denetleyici menüde gereksiz kare tüketiyordu.
  late final AnimationController _idle;

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  void _openQuests() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.buzMavi.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const DailyQuestsPanel(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final career = context.watch<CareerService>();
    final meta = context.watch<PlayerMetaService>();
    final l10n = context.l10n;
    final user = auth.user;

    return Scaffold(
      body: YesaBackground(
        child: SafeArea(
          child: Column(
            children: [
              if (user != null)
                _TopBar(
                  name: user.name,
                  tokens: meta.tokens,
                  onAvatar: () {
                    if (!auth.canPlayRanked) {
                      showRankedLoginDialog(context);
                    } else {
                      AppRouter.goProfile(context);
                    }
                  },
                  onQuests: _openQuests,
                  onPremium: () => AppRouter.goPremium(context),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Column(
                    children: [
                      // ── Kahraman alan ──────────────────────────────────
                      _FloatingLogo(idle: _idle),
                      const SizedBox(height: 18),
                      StaggerIn(
                        index: 1,
                        child: _PlayButton(
                          label: l10n.menuTimed,
                          idle: _idle,
                          onPressed: () => _pickTimedDuration(context),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── İkincil modlar ─────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: StaggerIn(
                              index: 2,
                              child: _ModeButton(
                                label: l10n.menuCareer,
                                icon: Icons.military_tech_rounded,
                                color: AppColors.acikMavi,
                                badge: '${career.careerPoints}p',
                                onPressed: () => AppRouter.goCareer(context),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StaggerIn(
                              index: 3,
                              child: _ModeButton(
                                label: l10n.menuVsBot,
                                icon: Icons.smart_toy_rounded,
                                color: AppColors.anaMavi,
                                onPressed: () => AppRouter.goDifficulty(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Yuvarlak ikonlar ───────────────────────────────
                      StaggerIn(
                        index: 4,
                        child: Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          alignment: WrapAlignment.center,
                          children: [
                            _IconOrb(
                              label: l10n.menuTraining,
                              icon: Icons.fitness_center_rounded,
                              onPressed: () => AppRouter.goTraining(context),
                            ),
                            _IconOrb(
                              label: l10n.menuLocalDuo,
                              icon: Icons.people_alt_rounded,
                              onPressed: () => AppRouter.goLocalDuo(context),
                            ),
                            _IconOrb(
                              label: l10n.menuCosmetics,
                              icon: Icons.storefront_rounded,
                              onPressed: () => AppRouter.goCosmetics(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      // ── Alt şerit ──────────────────────────────────────
                      StaggerIn(
                        index: 5,
                        // Premium çubuğu üst şeritteki yıldıza taşındı; geriye
                        // kalan iki düğme ortalanıyor, sola yaslı durmasınlar.
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _SmallSquare(
                              icon: Icons.help_outline_rounded,
                              onPressed: () => AppRouter.goTutorial(context),
                            ),
                            const SizedBox(width: 12),
                            _SmallSquare(
                              icon: Icons.settings_rounded,
                              onPressed: () => AppRouter.goSettings(context),
                            ),
                          ],
                        ),
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

  void _pickTimedDuration(BuildContext context) {
    final l10n = context.l10nRead;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          l10n.timedPickTitle,
          style: const TextStyle(
              color: AppColors.beyaz, fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.timedPickHint,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 18),
            Row(
              children: [1, 3, 5].map((m) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: m == 5 ? 0 : 8),
                    child: ScalePress(
                      onTap: () {
                        Navigator.pop(ctx);
                        AppRouter.goLobby(context, timedSeconds: m * 60);
                      },
                      child: Container(
                        height: 68,
                        alignment: Alignment.center,
                        decoration:
                            GameSurface.key(AppColors.turuncuAna, radius: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$m',
                              style: const TextStyle(
                                color: AppColors.beyaz,
                                fontWeight: FontWeight.w900,
                                fontSize: 24,
                              ),
                            ),
                            Text(
                              l10n.minutesShort,
                              style: const TextStyle(
                                  color: AppColors.beyaz, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════

/// İnce üst şerit: kimlik solda, sayaçlar sağda. Çerçevesiz olması menünün
/// "form doldurma" hissini kırıyor.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.name,
    required this.tokens,
    required this.onAvatar,
    required this.onQuests,
    required this.onPremium,
  });

  final String name;
  final int tokens;
  final VoidCallback onAvatar;
  final VoidCallback onQuests;
  final VoidCallback onPremium;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAvatar,
            child: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.turuncuAna,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.turuncuAna.withValues(alpha: 0.5),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: Text(
                name.isEmpty ? '?' : name[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.beyaz,
                  fontWeight: FontWeight.w900,
                  fontSize: 19,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.beyaz,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
          // Premium girişi: altta koca turuncu bir düğmeydi, üst şeritte
          // küçük bir yıldıza indi. Kalıcı ve ulaşılabilir ama menünün
          // ana akışını kesmiyor.
          GestureDetector(
            onTap: onPremium,
            child: const _Chip(
              icon: Icons.star_rounded,
              value: '',
              gold: true,
            ),
          ),
          const SizedBox(width: 7),
          _Chip(icon: Icons.paid_rounded, value: '$tokens'),
          const SizedBox(width: 7),
          GestureDetector(
            onTap: onQuests,
            child: const _Chip(
              icon: Icons.local_fire_department_rounded,
              value: '',
              accent: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.value,
    this.accent = false,
    this.gold = false,
  });

  final IconData icon;
  final String value;
  final bool accent;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final c = gold
        ? AppColors.sariAna
        : accent
            ? AppColors.turuncuAna
            : AppColors.acikMavi;
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: value.isEmpty ? 8 : 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.laciDerin.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.6), width: 1.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: c),
          if (value.isNotEmpty) ...[
            const SizedBox(width: 5),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.beyaz,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Logo yavaşça süzülür. Duran bir görsel menüyü ölü gösteriyordu; hareket
/// az ama sürekli olduğu için ekran canlı okunuyor.
class _FloatingLogo extends StatelessWidget {
  const _FloatingLogo({required this.idle});

  final Animation<double> idle;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: idle,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, math.sin(idle.value * 2 * math.pi) * 5),
        child: child,
      ),
      child: const PucketLogo(height: 96),
    );
  }
}

/// Menünün tek kahramanı. Diğer her şeyden belirgin biçimde iri ve nabız
/// atıyor; menüye giren oyuncunun gözü buraya gitsin diye.
class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.label,
    required this.idle,
    required this.onPressed,
  });

  final String label;
  final Animation<double> idle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: idle,
      builder: (_, child) {
        final t = (math.sin(idle.value * 2 * math.pi) + 1) / 2; // 0..1
        return Transform.scale(scale: 1 + t * 0.022, child: child);
      },
      child: ScalePress(
        onTap: onPressed,
        child: Container(
          height: 96,
          alignment: Alignment.center,
          decoration: GameSurface.key(AppColors.turuncuAna, radius: 26),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_arrow_rounded,
                  size: 44, color: AppColors.beyaz),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.beyaz,
                  fontWeight: FontWeight.w900,
                  fontSize: 30,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                        color: Color(0xAA000000),
                        offset: Offset(0, 3),
                        blurRadius: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.badge,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return ScalePress(
      onTap: onPressed,
      child: Container(
        height: 84,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: GameSurface.key(color, radius: 20, glow: false),
        // StackFit.expand olmadan Stack, konumlandırılmamış çocuğunu kendi
        // doğal genişliğinde sol üste yaslıyordu: Column kendi içinde ortalı
        // olsa da blok kartın solunda duruyordu. Genişleyince gerçekten ortalanır.
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, size: 28, color: AppColors.beyaz),
                const SizedBox(height: 6),
                Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.beyaz,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    height: 1.1,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
            if (badge != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF000000).withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: AppColors.beyaz,
                      fontWeight: FontWeight.w900,
                      fontSize: 9.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Yuvarlak ikon düğmesi. Kare kart yerine daire kullanmak listeden
/// uzaklaştırıyor: göz sırayı tarıyor, satır okumuyor.
class _IconOrb extends StatelessWidget {
  const _IconOrb({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      child: ScalePress(
        onTap: onPressed,
        child: Column(
          children: [
            Container(
              width: 76,
              height: 76,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF14456F), Color(0xFF0A2440)],
                ),
                border: Border.all(
                  color: AppColors.acikMavi.withValues(alpha: 0.55),
                  width: 2,
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF04101E), offset: Offset(0, 4)),
                  BoxShadow(
                      color: Color(0x66000000),
                      offset: Offset(0, 7),
                      blurRadius: 10),
                ],
              ),
              child: Icon(icon, size: 32, color: AppColors.sariAna),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w800,
                fontSize: 10,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _SmallSquare extends StatelessWidget {
  const _SmallSquare({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ScalePress(
      onTap: onPressed,
      child: Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: GameSurface.key(AppColors.koyuMavi, radius: 14, glow: false),
        child: Icon(icon, size: 21, color: AppColors.buzMavi),
      ),
    );
  }
}
