import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/ai_bot.dart';
import '../game/game_controller.dart';
import '../models/rank_tier.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/game_board.dart';
import '../widgets/pucket_button.dart';
import 'app_router.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _showPause = false;
  bool _showSettings = false;
  bool _showOverlay = false;
  bool _showElo = false;
  String _overlayTitle = '';
  String _overlaySub = '';
  bool _showRematch = false;
  String _rematchLabel = 'DEVAM';
  int _lastCountdown = -1;
  GamePhase? _lastPhase;
  EloResult? _eloResult;
  GameController? _game;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final game = context.read<GameController>();
    if (_game == game) return;
    _game?.removeListener(_onGameChanged);
    _game = game;
    game.addListener(_onGameChanged);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final game = context.read<GameController>();
      game.onOpponentLeft = () {
        if (mounted) {
          _showEndOverlay('RAKİP AYRILDI', 'Bağlantı kesildi.', false, 'MENÜYE DÖN');
        }
      };
      game.onRematchRequest = () {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.card,
            title: const Text('Tekrar oyna?'),
            content: const Text('Rakip yeni maç istiyor.'),
            actions: [
              TextButton(onPressed: () {
                game.declineRematch();
                Navigator.pop(ctx);
              }, child: const Text('Hayır')),
              TextButton(onPressed: () {
                game.acceptRematch();
                Navigator.pop(ctx);
              }, child: const Text('Evet')),
            ],
          ),
        );
      };
      game.onEloResult = (r) {
        if (mounted) {
          setState(() {
            _eloResult = r;
            _showElo = true;
          });
        }
      };
    });
  }

  @override
  void dispose() {
    _game?.removeListener(_onGameChanged);
    super.dispose();
  }

  void _onGameChanged() {
    if (!mounted) return;
    final game = _game;
    if (game == null) return;

    if (game.phase == GamePhase.countdown && game.countdown != _lastCountdown) {
      _lastCountdown = game.countdown;
      final team = game.mySeat == 0 ? '🔴 Kırmızı' : '🔵 Mavi';
      setState(() {
        _showOverlay = true;
        _showElo = false;
        _overlayTitle = '${game.countdown}';
        _overlaySub = 'SEN → $team';
        _showRematch = false;
      });
    } else if (game.phase == GamePhase.playing && _lastPhase == GamePhase.countdown) {
      _lastCountdown = 0;
      setState(() => _showOverlay = false);
    }

    if (game.phase == GamePhase.gameover && _lastPhase != GamePhase.gameover) {
      if (game.isRanked && game.matchFinished && game.pendingEloResult != null) {
        // ELO overlay onEloResult ile
      } else {
        _showRoundOverlay(game);
      }
    }

    if (game.phase == GamePhase.paused && _lastPhase != GamePhase.paused) {
      setState(() => _showPause = true);
    } else if (game.phase == GamePhase.playing && _lastPhase == GamePhase.paused) {
      setState(() => _showPause = false);
    }

    _lastPhase = game.phase;
  }

  void _showRoundOverlay(GameController game) {
    final won = game.lastWinner == game.mySeat;
    final score = '${game.roundWins[0]} - ${game.roundWins[1]}';
    if (game.matchFinished) {
      _showEndOverlay(
        won ? '🏆 MAÇ KAZANDIN!' : '💀 MAÇ KAYBETTİN',
        '${won ? 'Tebrikler! ' : 'Maalesef... '}$score',
        !game.isRanked || game.pendingEloResult == null,
        'YENİ MAÇ',
      );
    } else {
      _showEndOverlay(
        'ROUND ${game.currentRound - 1} BİTTİ',
        '${won ? 'Round kazandın 🎉' : 'Round kaybettin'}\n$score',
        true,
        'SONRAKİ ROUND →',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final timer =
        '${(game.seconds ~/ 60).toString().padLeft(2, '0')}:${(game.seconds % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(game),
            if (game.reconnecting)
              Container(
                width: double.infinity,
                color: const Color(0xFF3A2A00),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: const Text(
                  'Bağlantı yeniden kuruluyor...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            if (game.opponentDisconnected)
              Container(
                width: double.infinity,
                color: const Color(0xFF2A1010),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'Rakip bağlantısı koptu — ${game.opponentGraceLeft} sn bekleniyor',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.red, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            _roundRow(game, timer),
            Expanded(
              child: Stack(
                children: [
                  const GameBoard(),
                  if (_showOverlay && !_showElo) _buildOverlay(game),
                  if (_showElo && _eloResult != null) _buildEloOverlay(game, _eloResult!),
                  if (_showPause) _buildPause(game),
                  if (_showSettings) _buildInGameSettings(game),
                ],
              ),
            ),
            _bottomBar(game),
          ],
        ),
      ),
    );
  }

  Widget _topBar(GameController game) {
    final lbl0 = game.aiMode ? (game.isBotFallback ? 'SEN 🔴' : 'SEN 🔴') : 'KIRMIZI';
    final lbl1 = game.aiMode
        ? (game.isBotFallback ? 'BOT 🤖' : 'BOT 🔵')
        : (game.opponentName.isNotEmpty ? game.opponentName.toUpperCase() : 'MAVİ');

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        children: [
          Expanded(child: _scoreBox(lbl0, game.roundWins[0], AppColors.red)),
          if (!game.aiMode && game.opponentName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    game.isRanked ? 'RANKED' : 'ONLINE',
                    style: const TextStyle(fontSize: 7, color: Color(0xFF555555), letterSpacing: 1),
                  ),
                  Text(
                    '${game.opponentElo}',
                    style: const TextStyle(fontSize: 10, color: AppColors.gold, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _scoreBox(lbl1, game.roundWins[1], AppColors.blue),
                IconButton(
                  onPressed: game.phase == GamePhase.gameover
                      ? null
                      : () {
                          game.togglePause();
                          setState(() => _showPause = game.phase == GamePhase.paused);
                        },
                  icon: Icon(
                    game.phase == GamePhase.paused ? Icons.play_arrow : Icons.pause,
                    color: const Color(0xFF666666),
                    size: 20,
                  ),
                  style: IconButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF333333)),
                    minimumSize: const Size(32, 32),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundRow(GameController game, String timer) {
    return Container(
      height: 28,
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'ROUND ${game.currentRound}/3',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Color(0xFF444444),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 8),
          _pip(game.roundWins[0] > 0, AppColors.red),
          _pip(game.roundWins[0] > 1, AppColors.red),
          Container(
            width: 1,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: const Color(0xFF2A2A2A),
          ),
          _pip(game.roundWins[1] > 0, AppColors.blue),
          _pip(game.roundWins[1] > 1, AppColors.blue),
          const SizedBox(width: 8),
          Text(timer, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 11)),
          if (game.roomCode.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              game.aiMode
                  ? (game.isBotFallback ? 'BOT MODU' : 'BOT')
                  : game.roomCode,
              style: TextStyle(
                color: game.isBotFallback ? AppColors.gold : const Color(0xFF444444),
                fontSize: 9,
                letterSpacing: 1,
                fontWeight: game.isBotFallback ? FontWeight.w800 : FontWeight.normal,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pip(bool filled, Color color) {
    return Container(
      width: 9,
      height: 9,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? color : Colors.transparent,
        border: Border.all(color: color, width: 1.5),
      ),
    );
  }

  Widget _scoreBox(String label, int score, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 8, letterSpacing: 1, fontWeight: FontWeight.bold, color: color),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '$score',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1, color: color),
        ),
      ],
    );
  }

  Widget _bottomBar(GameController game) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🔴 ${game.redRemaining()}', style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(width: 8),
          const Text('SENİN YARINDA', style: TextStyle(color: Color(0xFF444444), fontSize: 10, letterSpacing: 1)),
          const SizedBox(width: 8),
          Text('${game.mySideRemaining()} pul', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildOverlay(GameController game) {
    return Container(
      color: Colors.black.withValues(alpha: 0.82),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _overlayTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: _overlayTitle.length <= 2 ? 88 : 32,
                  fontWeight: FontWeight.w900,
                  color: _overlayTitle.length <= 2 ? AppColors.green : AppColors.gold,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _overlaySub,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF777777), fontSize: 13, height: 1.6),
              ),
              if (_showRematch) ...[
                const SizedBox(height: 20),
                PucketButton(
                  label: _rematchLabel,
                  width: 260,
                  onPressed: () {
                    setState(() => _showOverlay = false);
                    if (game.aiMode) {
                      game.rematchLocal();
                    } else {
                      game.requestRematch();
                      if (game.myRematchPending) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Rematch isteği gönderildi — rakip onayı bekleniyor')),
                        );
                      }
                    }
                  },
                ),
              ],
              const SizedBox(height: 14),
              PucketButton(
                label: 'MENÜYE DÖN',
                secondary: true,
                width: 260,
                onPressed: () => AppRouter.goMenu(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEloOverlay(GameController game, EloResult result) {
    final tier = RankTier.forElo(result.newElo);
    final auth = context.read<AuthService>();
    final oldLeague = auth.user?.league ?? 'Bronz';

    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                result.won ? '🏆 MAÇ KAZANDIN!' : '💀 MAÇ KAYBETTİN',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: result.won ? AppColors.gold : AppColors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '${result.eloChange >= 0 ? '+' : ''}${result.eloChange}',
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: result.eloChange >= 0 ? AppColors.green : AppColors.red,
                ),
              ),
              const Text('ELO puanı', style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
              Text('${result.newElo} ELO', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tier.color),
                ),
                child: Text('${tier.emoji} ${tier.name}', style: TextStyle(color: tier.color, fontWeight: FontWeight.w700)),
              ),
              if (result.newLeague != oldLeague && result.won)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '🎉 ${result.newLeague.toUpperCase()} LİGİNE ÇIKTIN!',
                    style: const TextStyle(color: AppColors.gold, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 18),
              PucketButton(
                label: 'TAMAM',
                width: 260,
                onPressed: () {
                  setState(() {
                    _showElo = false;
                    _showOverlay = true;
                  });
                  final won = result.won;
                  final score = '${game.roundWins[0]} - ${game.roundWins[1]}';
                  _showEndOverlay(
                    won ? '🏆 MAÇ KAZANDIN!' : '💀 MAÇ KAYBETTİN',
                    '${won ? 'Tebrikler! ' : 'Maalesef... '}$score',
                    true,
                    'YENİ MAÇ',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPause(GameController game) {
    final isOpponentPause = game.pauseByOpponent && !game.aiMode;
    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isOpponentPause ? '⏸ OYUN DURDURULDU' : '⏸ DURAKLATILDI',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.gold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                isOpponentPause
                    ? 'Rakip oyunu durdurdu.\nEn fazla ${GameController.maxPauseSeconds} saniye beklenir.'
                    : 'Oyun duraklatıldı.\nEn fazla ${GameController.maxPauseSeconds} saniye.',
                style: const TextStyle(fontSize: 14, color: Color(0xFFAAAAAA), height: 1.4),
                textAlign: TextAlign.center,
              ),
              if (game.pauseSecondsLeft > 0) ...[
                const SizedBox(height: 16),
                Text(
                  'Kalan: ${game.pauseSecondsLeft} sn',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ],
              const SizedBox(height: 20),
              if (!isOpponentPause)
                PucketButton(
                  label: '▶ DEVAM ET',
                  width: 260,
                  onPressed: () {
                    game.togglePause();
                    setState(() => _showPause = false);
                  },
                ),
              if (game.aiMode) ...[
                const SizedBox(height: 12),
                PucketButton(
                  label: '↺ YENİDEN BAŞLA',
                  secondary: true,
                  width: 260,
                  onPressed: () {
                    setState(() => _showPause = false);
                    game.resetMatch();
                    game.startCountdown();
                  },
                ),
              ],
              const SizedBox(height: 12),
              PucketButton(
                label: '⚙ AYARLAR',
                secondary: true,
                width: 260,
                onPressed: () => setState(() {
                  _showSettings = true;
                  _showPause = false;
                }),
              ),
              const SizedBox(height: 12),
              PucketButton(label: '✕ MENÜYE DÖN', secondary: true, width: 260, onPressed: () => AppRouter.goMenu(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInGameSettings(GameController game) {
    final settings = context.watch<SettingsService>();
    return Container(
      color: Colors.black.withValues(alpha: 0.92),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text('⚙ AYARLAR', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.green, letterSpacing: 3)),
              SwitchListTile(title: const Text('Müzik'), value: settings.musicOn, onChanged: settings.setMusic),
              SwitchListTile(title: const Text('Ses Efektleri'), value: settings.sfxOn, onChanged: settings.setSfx),
              SwitchListTile(title: const Text('Titreşim'), value: settings.vibrationOn, onChanged: settings.setVibration),
              if (game.aiMode)
                ListTile(
                  title: const Text('Bot Zorluğu'),
                  trailing: DropdownButton<AiLevel>(
                    value: game.aiLevel,
                    dropdownColor: AppColors.card,
                    items: const [
                      DropdownMenuItem(value: AiLevel.easy, child: Text('🟢 Kolay')),
                      DropdownMenuItem(value: AiLevel.medium, child: Text('🟡 Orta')),
                      DropdownMenuItem(value: AiLevel.hard, child: Text('🔴 Zor')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => game.aiLevel = v);
                    },
                  ),
                ),
              const SizedBox(height: 16),
              PucketButton(
                label: 'TAMAM',
                width: 260,
                onPressed: () => setState(() {
                  _showSettings = false;
                  if (game.phase == GamePhase.paused) _showPause = true;
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEndOverlay(String title, String sub, bool rematch, String buttonLabel) {
    setState(() {
      _showOverlay = true;
      _overlayTitle = title;
      _overlaySub = sub;
      _showRematch = rematch;
      _rematchLabel = buttonLabel;
    });
  }
}
