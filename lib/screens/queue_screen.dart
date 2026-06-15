import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/ai_bot.dart';
import '../game/game_controller.dart';
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
  String _status = 'Rakip aranıyor...';
  bool _spinning = true;
  bool _showPreview = false;
  int? _myElo;
  int? _oppElo;
  Timer? _msgTimer;
  Timer? _botTimer;
  GameController? _game;

  static const _msgs = [
    'ELO seviyenizde rakip aranıyor...',
    'Liginizde oyuncu bekleniyor...',
    'Eşleştirme kuruluyor...',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final auth = context.read<AuthService>();
    _game = context.read<GameController>();
    final game = _game!;

    game.onGameStart = () {
      if (mounted) AppRouter.goGame(context);
    };

    game.onToast = (m) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    };

    final ok = await game.openConnection(uid: auth.getUid(), name: auth.getName());
    if (!mounted) return;
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sunucu yok — bot moduna geçiliyor')),
        );
        AppRouter.startBotFallback(context, level: AiLevel.hard);
      }
      return;
    }

    game.enterQueue(auth.getUid(), auth.getName());

    var idx = 0;
    _msgTimer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (!mounted) return;
      setState(() {
        idx = (idx + 1) % _msgs.length;
        _status = _msgs[idx];
      });
    });

    _botTimer = Timer(const Duration(seconds: 20), () {
      if (!mounted) return;
      _botFallback();
    });

    // Listen for matched via game controller notify
    game.addListener(_onGameUpdate);
  }

  void _onGameUpdate() {
    final game = _game;
    if (game == null || !mounted) return;
    if (game.isRanked && game.roomCode.isNotEmpty && !_showPreview) {
      _msgTimer?.cancel();
      _botTimer?.cancel();
      setState(() {
        _status = 'Rakip bulundu!';
        _spinning = false;
        _showPreview = true;
        _myElo = context.read<AuthService>().user?.elo;
        _oppElo = _myElo;
      });
    }
  }

  void _botFallback() {
    _msgTimer?.cancel();
    setState(() {
      _status = 'Rakip bulundu! Başlıyor...';
      _spinning = false;
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted && _game != null) {
        _game!.leave();
        AppRouter.startAi(context, AiLevel.hard);
      }
    });
  }

  @override
  void dispose() {
    _msgTimer?.cancel();
    _botTimer?.cancel();
    _game?.removeListener(_onGameUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;
    final tier = user != null ? RankTier.forElo(user.elo) : RankTier.tiers.first;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3),
            radius: 1.2,
            colors: [Color(0xFF0D1A2A), AppColors.bg],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '🏆 RANKED MAÇ',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF60AAFF),
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: 300,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
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
                      const Text(
                        'ELO PUANINIZ',
                        style: TextStyle(fontSize: 9, color: Color(0xFF555555), letterSpacing: 3),
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
                      const SizedBox(height: 8),
                      Text(_status, style: const TextStyle(color: Color(0xFF666666), fontSize: 12)),
                      if (_showPreview) ...[
                        const SizedBox(height: 14),
                        _vsPreview(_myElo ?? 1000, _oppElo ?? 1000),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                PucketButton(
                  label: 'KUYRUKTAN ÇIK',
                  secondary: true,
                  onPressed: () {
                    context.read<GameController>().leaveQueue();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _vsPreview(int myElo, int oppElo) {
    final myTier = RankTier.forElo(myElo);
    final oppTier = RankTier.forElo(oppElo);
    return Container(
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
                const Text('SEN', style: TextStyle(fontSize: 9, color: Color(0xFF555555))),
                Text('$myElo', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.red)),
                Text(myTier.name, style: const TextStyle(fontSize: 10, color: Color(0xFF666666))),
              ],
            ),
          ),
          const Text('VS', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF333333))),
          Expanded(
            child: Column(
              children: [
                const Text('RAKİP', style: TextStyle(fontSize: 9, color: Color(0xFF555555))),
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
