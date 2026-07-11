import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/ai_bot.dart';
import '../game/game_controller.dart';
import '../l10n/l10n_extension.dart';
import '../models/rank_tier.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/yesa_background.dart';
import '../widgets/yesa_effects.dart';
import '../widgets/pucket_button.dart';
import 'app_router.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  String _status = '';
  bool _spinning = true;
  bool _showPreview = false;
  bool _queueBlocked = false;
  String? _oppName;
  int? _myElo;
  int? _oppElo;
  Timer? _msgTimer;
  Timer? _botTimer;
  Timer? _watchdog;
  GameController? _game;
  bool _errorHandled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  void _cancelTimers() {
    _msgTimer?.cancel();
    _botTimer?.cancel();
    _msgTimer = null;
    _botTimer = null;
  }

  Future<void> _init() async {
    // Güvenlik ağı: bağlantı kurulumu 12 sn içinde bir sonuca varmazsa
    // sonsuza kadar "aranıyor" ekranında kalmak yerine bot'a düş.
    _watchdog = Timer(const Duration(seconds: 12), () {
      if (mounted) _handleConnectFailure();
    });
    try {
      await _doInit();
    } catch (e, st) {
      debugPrint('QueueScreen._doInit failed: $e\n$st');
      if (mounted) _handleConnectFailure();
    }
  }

  void _handleConnectFailure() {
    if (_errorHandled) return;
    _errorHandled = true;
    _watchdog?.cancel();
    final l10n = context.l10nRead;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.queueNoServer)),
    );
    AppRouter.startBotFallback(context, level: AiLevel.hard, ranked: true);
  }

  Future<void> _doInit() async {
    final auth = context.read<AuthService>();
    final settings = context.read<SettingsService>();
    final l10n = context.l10nRead;

    // İlk maç garantili kolay (gizli) bot — hızlı, kazanılabilir ilk deneyim.
    if (!settings.firstMatchPlayed) {
      _watchdog?.cancel();
      await settings.markFirstMatchPlayed();
      if (!mounted) return;
      AppRouter.startBotFallback(context, level: AiLevel.easy, ranked: true);
      return;
    }

    _status = l10n.queueSearching;
    _game = context.read<GameController>();
    final game = _game!;

    game.onGameStart = () {
      if (mounted) AppRouter.goGame(context);
    };

    game.onToast = (m) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
      if (m.contains('Google') || m.contains('Ranked') || m.contains('giriş')) {
        _cancelTimers();
        setState(() {
          _queueBlocked = true;
          _spinning = false;
          _status = m;
        });
      }
    };

    bool ok;
    try {
      ok = await game
          .openConnection(
            uid: auth.getUid(),
            name: auth.getName(),
            idToken: await auth.getIdToken(),
            isAnonymous: auth.user?.isAnonymous ?? true,
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      ok = false;
    }
    _watchdog?.cancel();
    if (!mounted) return;
    if (!ok) {
      _handleConnectFailure();
      return;
    }

    game.enterQueue(auth.getUid(), auth.getName());

    final msgs = [
      l10n.queueSearching,
      l10n.queueSearchingElo,
      l10n.queueSearchingMatch,
    ];
    var idx = 0;
    _msgTimer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (!mounted) return;
      setState(() {
        idx = (idx + 1) % msgs.length;
        _status = msgs[idx];
      });
    });

    _botTimer = Timer(const Duration(seconds: 20), () {
      if (!mounted || _queueBlocked) return;
      _botFallback();
    });

    game.addListener(_onGameUpdate);
  }

  void _onGameUpdate() {
    final game = _game;
    if (game == null || !mounted) return;
    if (game.isRanked && game.roomCode.isNotEmpty && !_showPreview) {
      _cancelTimers();
      setState(() {
        _status = context.l10nRead.queueFound;
        _spinning = false;
        _showPreview = true;
        _myElo = context.read<AuthService>().user?.elo;
        _oppElo = game.opponentElo;
        _oppName = game.opponentName;
      });
    }
  }

  void _botFallback() {
    if (_queueBlocked) return;
    _cancelTimers();
    // Gizli bot: "rakip bulundu" göster, "AI" ibaresi yok.
    setState(() {
      _status = context.l10nRead.queueFound;
      _spinning = false;
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _game!.leaveQueue();
        AppRouter.startBotFallback(context, level: AiLevel.hard, ranked: true);
      }
    });
  }

  @override
  void dispose() {
    _cancelTimers();
    _watchdog?.cancel();
    _game?.removeListener(_onGameUpdate);
    if (_game != null && _game!.phase == GamePhase.idle) {
      _game!.leaveQueue();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final l10n = context.l10n;
    final user = auth.user;
    final tier = user != null ? RankTier.forElo(user.elo) : RankTier.tiers.first;
    final cardWidth = (MediaQuery.sizeOf(context).width - 48).clamp(280.0, 420.0);

    return Scaffold(
      body: SizedBox.expand(
        child: YesaBackground(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.queueRankedTitle,
                          style: AppTextStyles.glow(AppColors.camgobegi)
                              .copyWith(fontSize: 22, letterSpacing: 3),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: cardWidth,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(22),
                            decoration: YesaDecor.card(radius: 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Radar dalgası içinde ELO — "rakip aranıyor" hissi.
                                RadarPulse(
                                  size: 132,
                                  active: _spinning,
                                  color: AppColors.camgobegi,
                                  child: Container(
                                    width: 88,
                                    height: 88,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: AppGradients.neonPurple,
                                      border: Border.all(
                                          color: AppColors.beyaz.withValues(alpha: 0.3), width: 1.5),
                                      boxShadow: AppShadows.neon(AppColors.anaMor, blur: 16),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          l10n.queueYourElo,
                                          style: const TextStyle(
                                              fontSize: 7,
                                              color: AppColors.pusluBeyaz,
                                              letterSpacing: 2),
                                        ),
                                        Text(
                                          '${user?.elo ?? 1000}',
                                          style: const TextStyle(
                                              fontSize: 26,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.gold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: tier.color),
                                  ),
                                  child: Text(
                                    tier.name,
                                    style: TextStyle(color: tier.color, fontWeight: FontWeight.w700, fontSize: 11),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _status.isEmpty ? l10n.queueSearching : _status,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                ),
                                if (_showPreview) ...[
                                  const SizedBox(height: 14),
                                  _vsPreview(_myElo ?? 1000, _oppElo ?? 1000, _oppName ?? l10n.opponent),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        PucketButton(
                          label: l10n.queueLeave,
                          secondary: true,
                          width: cardWidth,
                          onPressed: () {
                            context.read<GameController>().leaveQueue();
                            Navigator.pop(context);
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _vsPreview(int myElo, int oppElo, String oppName) {
    final l10n = context.l10n;
    final myTier = RankTier.forElo(myElo);
    final oppTier = RankTier.forElo(oppElo);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgDeep,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(l10n.youLabel, style: const TextStyle(fontSize: 9, color: AppColors.textDim)),
                Text('$myElo', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.red)),
                Text(myTier.name, style: const TextStyle(fontSize: 10, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Text('VS', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.borderSubtle)),
          Expanded(
            child: Column(
              children: [
                Text(l10n.opponent, style: const TextStyle(fontSize: 9, color: AppColors.textDim)),
                Text(oppName, style: const TextStyle(fontSize: 10, color: AppColors.textMuted), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                Text('$oppElo', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.blue)),
                Text(oppTier.name, style: const TextStyle(fontSize: 10, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
