import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/ai_bot.dart';
import '../game/game_controller.dart';
import '../l10n/l10n_extension.dart';
import '../models/rank_tier.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
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
  GameController? _game;

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
    final auth = context.read<AuthService>();
    final l10n = context.l10n;
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

    final ok = await game.openConnection(
      uid: auth.getUid(),
      name: auth.getName(),
      idToken: await auth.getIdToken(),
      isAnonymous: auth.user?.isAnonymous ?? true,
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.queueNoServer)),
      );
      AppRouter.startBotFallback(context, level: AiLevel.hard);
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
        _status = context.l10n.queueFound;
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
    setState(() {
      _status = context.l10n.queueBotStarting;
      _spinning = false;
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _game!.leaveQueue();
        AppRouter.startBotFallback(context, level: AiLevel.hard);
      }
    });
  }

  @override
  void dispose() {
    _cancelTimers();
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
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.3),
              radius: 1.2,
              colors: [Color(0xFF0D1A2A), AppColors.bg],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Text(
                    l10n.queueRankedTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF60AAFF),
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: cardWidth,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_spinning)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 14),
                              child: SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.green),
                              ),
                            ),
                          Text(
                            l10n.queueYourElo,
                            style: const TextStyle(fontSize: 9, color: Color(0xFF555555), letterSpacing: 3),
                          ),
                          Text(
                            '${user?.elo ?? 1000}',
                            style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: AppColors.gold),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 8),
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
                          const SizedBox(height: 12),
                          Text(
                            _status.isEmpty ? l10n.queueSearching : _status,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF666666), fontSize: 12),
                          ),
                          if (_showPreview) ...[
                            const SizedBox(height: 14),
                            _vsPreview(_myElo ?? 1000, _oppElo ?? 1000, _oppName ?? l10n.opponent),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 3),
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
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(l10n.youLabel, style: const TextStyle(fontSize: 9, color: Color(0xFF555555))),
                Text('$myElo', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.red)),
                Text(myTier.name, style: const TextStyle(fontSize: 10, color: Color(0xFF666666))),
              ],
            ),
          ),
          const Text('VS', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF333333))),
          Expanded(
            child: Column(
              children: [
                Text(l10n.opponent, style: const TextStyle(fontSize: 9, color: Color(0xFF555555))),
                Text(oppName, style: const TextStyle(fontSize: 10, color: Color(0xFF888888)), textAlign: TextAlign.center),
                Text('$oppElo', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.blue)),
                Text(oppTier.name, style: const TextStyle(fontSize: 10, color: Color(0xFF666666))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
