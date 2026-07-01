import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/ai_bot.dart';
import '../game/game_controller.dart';
import '../l10n/l10n_extension.dart';
import '../models/career_result.dart';
import '../models/rank_tier.dart';
import '../services/ad_service.dart';
import '../services/audio_service.dart';
import '../services/auth_service.dart';
import '../services/career_service.dart';
import '../services/meta_api.dart';
import '../services/player_meta_service.dart';
import '../services/settings_service.dart';
import '../services/share_service.dart';
import '../theme/app_theme.dart';
import '../widgets/game_board.dart';
import '../widgets/ping_indicator.dart';
import '../widgets/pucket_logo.dart';
import '../widgets/pucket_button.dart';
import 'app_router.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _rematchDialogOpen = false;
  bool _showPause = false;
  bool _showSettings = false;
  bool _showOverlay = false;
  bool _showElo = false;
  String _overlayTitle = '';
  String _overlaySub = '';
  String? _overlayPrimaryLabel;
  VoidCallback? _overlayPrimaryAction;
  GamePhase? _lastPhase;
  EloResult? _eloResult;
  CareerMatchResult? _careerResult;
  bool _showCareer = false;
  GameController? _game;
  Timer? _eloFallbackTimer;
  int _lastRoundAdKey = -1;
  int _lastWinTokenKey = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final game = context.read<GameController>();
    if (_game == game) return;
    _game?.removeListener(_onGameChanged);
    _game = game;
    game.addListener(_onGameChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _game == game) _onGameChanged();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final game = context.read<GameController>();
      if (game.isBotFallback) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10nRead.lobbyBotFallback)),
        );
      }
      game.onOpponentLeft = () {
        if (mounted) {
          final l10n = context.l10nRead;
          _showEndOverlay(
            title: l10n.opponentLeft,
            sub: l10n.opponentLeftSub,
          );
        }
      };
      game.onAfkForfeit = () {
        if (mounted) {
          final l10n = context.l10nRead;
          _showEndOverlay(
            title: l10n.afkTitle,
            sub: l10n.afkSub,
            primaryLabel: l10n.backToMenu,
            onPrimary: () => AppRouter.goMenu(context),
          );
        }
      };
      game.onRematchRequest = () {
        if (!mounted || _rematchDialogOpen) return;
        _rematchDialogOpen = true;
        final l10n = context.l10nRead;
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.card,
            title: Text(l10n.rematchAsk),
            content: Text(l10n.rematchAskSub),
            actions: [
              TextButton(onPressed: () {
                game.declineRematch();
                Navigator.pop(ctx);
              }, child: Text(l10n.no)),
              TextButton(onPressed: () {
                game.acceptRematch();
                Navigator.pop(ctx);
              }, child: Text(l10n.yes)),
            ],
          ),
        ).whenComplete(() {
          if (mounted) _rematchDialogOpen = false;
        });
      };
      game.onEloResult = (r) {
        if (mounted) {
          context.read<AdService>().maybeShowInterstitial(
            matchFinished: true,
            skip: game.trainingMode,
          );
          final uid = context.read<AuthService>().getUid();
          context.read<PlayerMetaService>().onMatchPlayed(uid, won: r.won, ranked: true);
          setState(() {
            _eloResult = r;
            _showElo = true;
          });
        }
      };
      game.onRoundEnd = () {
        if (!mounted) return;
        final g = _game;
        if (g == null) return;
        _maybeShowRoundAd(g);
      };
    });
  }

  @override
  void dispose() {
    _eloFallbackTimer?.cancel();
    _game?.removeListener(_onGameChanged);
    super.dispose();
  }

  void _onGameChanged() {
    if (!mounted) return;
    final game = _game;
    if (game == null) return;

    if (game.phase == GamePhase.playing &&
        (_lastPhase == GamePhase.countdown || _lastPhase == null)) {
      context.read<AudioService>().playGameMusic();
    }

    if (game.phase == GamePhase.gameover && _lastPhase != GamePhase.gameover) {
      _maybeAwardWinTokens(game);
      if (game.careerMode && game.matchFinished && game.careerOpponent != null) {
        final won = game.lastWinner == game.mySeat;
        final career = context.read<CareerService>();
        final uid = context.read<AuthService>().getUid();
        career.recordResult(opponent: game.careerOpponent!, won: won, uid: uid).then((result) async {
          if (!mounted) return;
          if (won) await context.read<PlayerMetaService>().onCareerWin(uid);
          context.read<AdService>().maybeShowInterstitial(
            matchFinished: true,
            skip: game.trainingMode,
          );
          setState(() {
            _careerResult = result;
            _showCareer = true;
            _showElo = false;
            _showOverlay = false;
          });
        });
      } else if (game.isRanked && game.matchFinished && !game.isBotFallback) {
        if (game.pendingEloResult != null) {
          final r = game.pendingEloResult!;
          setState(() {
            _eloResult = r;
            _showElo = true;
          });
        } else {
          _scheduleEloFallback(game);
        }
      } else {
        _showRoundOverlay(game);
      }
    }

    if (game.phase == GamePhase.paused && _lastPhase != GamePhase.paused) {
      setState(() => _showPause = true);
    } else if (game.phase == GamePhase.playing && _lastPhase == GamePhase.paused) {
      setState(() => _showPause = false);
    }

    // Yedek: roundEnd kaçırılsa bile reklam / yan etkiler
    if (game.phase == GamePhase.gameover &&
        !_showElo &&
        !_showCareer &&
        !(game.isRanked && game.matchFinished && !game.isBotFallback)) {
      _maybeShowRoundAd(game);
    }

    _lastPhase = game.phase;
  }

  void _maybeAwardWinTokens(GameController game) {
    if (!game.matchFinished || game.lastWinner != game.mySeat) return;
    if (game.trainingMode || game.localDuoMode) return;
    final key = game.visualGeneration;
    if (_lastWinTokenKey == key) return;
    _lastWinTokenKey = key;

    final uid = context.read<AuthService>().getUid();
    context.read<PlayerMetaService>().earnWinTokens(uid).then((gain) {
      if (!mounted || gain == null || gain <= 0) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.tokensEarned(gain))),
      );
    });
  }

  void _maybeShowRoundAd(GameController game) {
    if (game.lastWinner == null) return;
    final adKey = game.currentRound * 10 + game.lastWinner!;
    if (_lastRoundAdKey == adKey) return;
    _lastRoundAdKey = adKey;
    context.read<AdService>().maybeShowInterstitial(
      matchFinished: game.matchFinished,
      skip: game.trainingMode,
    );
  }

  void _scheduleEloFallback(GameController game) {
    _eloFallbackTimer?.cancel();
    _eloFallbackTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      if (_eloResult != null || game.pendingEloResult != null) return;
      _showRoundOverlay(game);
    });
  }

  void _showRoundOverlay(GameController game) {
    // Overlay artık game.phase üzerinden doğrudan çiziliyor; burada sadece reklam tetiklenir.
    _maybeShowRoundAd(game);
  }

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameController>();
    final gameHud = Listenable.merge([game, game.uiSync]);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            ListenableBuilder(
              listenable: gameHud,
              builder: (context, _) {
                final g = context.read<GameController>();
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _topBar(g, l10n),
                    if (g.reconnecting)
                      Container(
                        width: double.infinity,
                        color: AppColors.darkOrange.withValues(alpha: 0.35),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          l10n.reconnecting,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    if (g.opponentDisconnected)
                      Container(
                        width: double.infinity,
                        color: AppColors.nightBlue.withValues(alpha: 0.6),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          l10n.opponentDisconnected(g.opponentGraceLeft),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.red, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    _roundRow(
                      g,
                      '${(g.seconds ~/ 60).toString().padLeft(2, '0')}:${(g.seconds % 60).toString().padLeft(2, '0')}',
                      l10n,
                    ),
                  ],
                );
              },
            ),
            Expanded(
              child: DecoratedBox(
                decoration: const BoxDecoration(gradient: AppGradients.boardBg),
                child: Stack(
                children: [
                  const RepaintBoundary(child: GameBoard()),
                  ListenableBuilder(
                    listenable: game,
                    builder: (context, _) {
                      final g = context.read<GameController>();
                      final phaseOverlay = _phaseOverlay(g, l10n);
                      return Stack(
                        children: [
                          if (phaseOverlay != null) phaseOverlay,
                          if (g.phase == GamePhase.countdown)
                            _buildCountdownOverlay(g, l10n),
                          if (_showOverlay &&
                              g.phase != GamePhase.gameover &&
                              g.phase != GamePhase.countdown &&
                              !_showElo &&
                              !_showCareer)
                            _buildOverlay(g, l10n),
                          if (_showElo && _eloResult != null) _buildEloOverlay(g, _eloResult!),
                          if (_showCareer && _careerResult != null) _buildCareerOverlay(g, _careerResult!),
                          if (_showPause) _buildPause(g),
                          if (_showSettings) _buildInGameSettings(g),
                        ],
                      );
                    },
                  ),
                ],
              ),
              ),
            ),
            ListenableBuilder(
              listenable: gameHud,
              builder: (context, _) => _bottomBar(context.read<GameController>(), l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(GameController game, l10n) {
    final lbl0 = game.localDuoMode ? game.localPlayerRed.toUpperCase() : l10n.youRed;
    final lbl1 = game.localDuoMode
        ? game.localPlayerBlue.toUpperCase()
        : game.careerMode || game.isBotFallback
            ? game.opponentName.toUpperCase()
            : game.aiMode
                ? l10n.botBlue
                : (game.opponentName.isNotEmpty ? game.opponentName.toUpperCase() : l10n.blue);

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(
          bottom: BorderSide(color: AppColors.fieldBlue.withValues(alpha: 0.25)),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _scoreBox(lbl0, game.roundWins[0], AppColors.red, alignEnd: false)),
          if (game.careerMode ||
              game.isBotFallback ||
              game.trainingMode ||
              game.localDuoMode ||
              (!game.aiMode && game.opponentName.isNotEmpty))
            Flexible(
              flex: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      game.localDuoMode
                          ? l10n.localDuoMode
                          : game.trainingMode
                          ? l10n.trainingMode
                          : game.isBotFallback
                              ? l10n.botFallbackLabel
                              : game.careerMode
                                  ? l10n.careerMode
                                  : (game.isRanked && !game.isBotFallback ? l10n.ranked : l10n.online),
                      style: TextStyle(
                        fontSize: 7,
                        color: game.careerMode ? AppColors.gold : AppColors.textDim,
                        letterSpacing: 1,
                        fontWeight: game.careerMode ? FontWeight.w800 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      game.localDuoMode
                          ? l10n.localDuoSimultaneous
                          : game.trainingMode
                          ? (game.trainingGoalLabel.isNotEmpty ? game.trainingGoalLabel : l10n.trainingMode)
                          : game.isBotFallback
                              ? l10n.botFallbackEloHint
                              : game.careerMode
                                  ? game.opponentLeague
                                  : '${game.opponentElo}',
                      style: TextStyle(
                        fontSize: 10,
                        color: game.careerMode ? AppColors.textMuted : AppColors.gold,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(child: _scoreBox(lbl1, game.roundWins[1], AppColors.blue, alignEnd: true)),
                IconButton(
                  onPressed: game.phase == GamePhase.gameover
                      ? null
                      : () {
                          game.togglePause();
                          setState(() => _showPause = game.phase == GamePhase.paused);
                        },
                  icon: Icon(
                    game.phase == GamePhase.paused ? Icons.play_arrow : Icons.pause,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  style: IconButton.styleFrom(
                    side: const BorderSide(color: AppColors.borderSubtle),
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

  Widget _roundRow(GameController game, String timer, l10n) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.bgDeep,
        border: Border(
          bottom: BorderSide(color: AppColors.brandBlue.withValues(alpha: 0.2)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'ROUND ${game.currentRound}/3',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: AppColors.fieldBlue.withValues(alpha: 0.45),
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
              color: const Color(0xFF2A4A66),
            ),
            _pip(game.roundWins[1] > 0, AppColors.blue),
            _pip(game.roundWins[1] > 1, AppColors.blue),
            const SizedBox(width: 8),
            Text(timer, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 11)),
            if (!game.aiMode && !game.localDuoMode && game.pingMs != null) ...[
              const SizedBox(width: 6),
              PingIndicator(pingMs: game.pingMs),
            ],
            if (game.roomCode.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                game.localDuoMode
                    ? l10n.localDuoMode
                    : game.careerMode
                    ? l10n.careerMode
                    : game.isBotFallback
                        ? game.roomCode
                        : game.aiMode
                            ? l10n.bot
                            : game.roomCode,
                style: TextStyle(
                  color: game.careerMode ? AppColors.gold : AppColors.textFaint,
                  fontSize: 9,
                  letterSpacing: 1,
                  fontWeight: game.careerMode ? FontWeight.w800 : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
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

  Widget _scoreBox(String label, int score, Color color, {bool alignEnd = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 8, letterSpacing: 1, fontWeight: FontWeight.bold, color: color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
        ),
        Text(
          '$score',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1, color: color),
        ),
      ],
    );
  }

  Widget _bottomBar(GameController game, l10n) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(
          top: BorderSide(color: AppColors.cyan.withValues(alpha: 0.25)),
        ),
      ),
      child: Center(
        child: game.localDuoMode
            ? FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${game.localPlayerRed}: ${game.redHalfTotal()}',
                      style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        '·',
                        style: TextStyle(color: AppColors.textDim.withValues(alpha: 0.6), fontSize: 16),
                      ),
                    ),
                    Text(
                      '${game.localPlayerBlue}: ${game.blueHalfTotal()}',
                      style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                  ],
                ),
              )
            : Text(
                l10n.discsLeft(game.mySideRemaining()),
                style: TextStyle(
                  color: game.mySeat == 0 ? AppColors.red : AppColors.blue,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildCountdownOverlay(GameController game, l10n) {
    final team = game.mySeat == 0 ? l10n.teamRed : l10n.teamBlue;
    return _buildOverlayContent(
      game,
      l10n,
      title: '${game.countdown}',
      sub: game.localDuoMode ? l10n.localDuoSimultaneous : l10n.youAreTeam(team),
    );
  }

  Widget? _phaseOverlay(GameController game, l10n) {
    if (game.phase != GamePhase.gameover || _showElo || _showCareer) return null;
    if (game.isRanked && game.matchFinished && !game.isBotFallback) return null;
    if (game.lastWinner == null) return null;
    return _buildRoundEndOverlay(game, l10n);
  }

  Widget _buildRoundEndOverlay(GameController game, l10n) {
    final score = '${game.roundWins[0]} - ${game.roundWins[1]}';
    final winnerSeat = game.lastWinner!;
    final String title;
    final String sub;
    if (game.localDuoMode) {
      final winner = game.localPlayerName(winnerSeat);
      title = game.matchFinished ? l10n.localDuoWinner(winner) : l10n.localDuoRoundWin(winner);
      sub = score;
    } else {
      final won = winnerSeat == game.mySeat;
      title = game.matchFinished
          ? (won ? l10n.matchWon : l10n.matchLost)
          : l10n.roundEnded(game.currentRound - 1);
      sub = game.matchFinished
          ? (won ? l10n.congrats(score) : l10n.sorry(score))
          : '${won ? l10n.roundWon : l10n.roundLost}\n$score';
    }
    final primaryLabel = game.matchFinished ? l10n.newMatch : l10n.nextRound;
    final onPrimary = game.matchFinished
        ? () {
            if (game.aiMode || game.trainingMode || game.localDuoMode) {
              game.rematchLocal();
            } else {
              game.requestRematch();
            }
          }
        : game.continueToNextRound;

    return _buildOverlayContent(
      game,
      l10n,
      title: title,
      sub: sub,
      primaryLabel: primaryLabel,
      onPrimary: onPrimary,
    );
  }

  Widget _buildOverlay(GameController game, l10n) {
    return _buildOverlayContent(
      game,
      l10n,
      title: _overlayTitle,
      sub: _overlaySub,
      primaryLabel: _overlayPrimaryLabel,
      onPrimary: _overlayPrimaryAction,
    );
  }

  Widget _buildOverlayContent(
    GameController game,
    l10n, {
    required String title,
    required String sub,
    String? primaryLabel,
    VoidCallback? onPrimary,
  }) {
    return Container(
      color: Colors.black.withValues(alpha: 0.82),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: title.length <= 2 ? 88 : 32,
                  fontWeight: FontWeight.w900,
                  color: title.length <= 2 ? AppColors.green : AppColors.gold,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                sub,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.6),
              ),
              if (primaryLabel != null && onPrimary != null) ...[
                const SizedBox(height: 20),
                PucketButton(
                  label: primaryLabel,
                  width: 260,
                  onPressed: () {
                    if (game.phase != GamePhase.gameover) {
                      setState(() => _showOverlay = false);
                    }
                    onPrimary();
                    if (!game.aiMode &&
                        !game.trainingMode &&
                        game.matchFinished &&
                        game.myRematchPending) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.rematchSent)),
                      );
                    }
                  },
                ),
              ],
              if (game.matchFinished) ...[
                const SizedBox(height: 14),
                PucketButton(
                  label: l10n.shareResult,
                  secondary: true,
                  width: 260,
                  onPressed: () {
                    final auth = context.read<AuthService>();
                    final won = game.lastWinner == game.mySeat;
                    ShareService.shareMatchResult(
                      playerName: auth.getName(),
                      won: won,
                      score: '${game.roundWins[0]} - ${game.roundWins[1]}',
                      eloChange: _eloResult?.eloChange,
                      newElo: _eloResult?.newElo,
                      league: _eloResult?.newLeague,
                    );
                  },
                ),
              ],
              const SizedBox(height: 14),
              PucketButton(
                label: l10n.backToMenu,
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

  Widget _buildCareerOverlay(GameController game, CareerMatchResult result) {
    final l10n = context.l10n;
    final tier = result.newLeague;
    final tierLabel = l10n.tierName(tier);
    final career = context.read<CareerService>();
    final next = career.nextOpponent();
    final score = '${game.roundWins[0]} - ${game.roundWins[1]}';

    return Container(
      color: Colors.black.withValues(alpha: 0.92),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                result.won ? l10n.matchWon : l10n.matchLost,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: result.won ? AppColors.gold : AppColors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(score, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
              if (result.won && result.firstTimeWin) ...[
                const SizedBox(height: 16),
                Text(
                  '+${result.pointsEarned}',
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: AppColors.green,
                  ),
                ),
                Text(l10n.careerPoints, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                Text(
                  '${result.totalCareerPoints} KP',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ] else if (result.won && !result.firstTimeWin)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    l10n.kpAlreadyEarned,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    l10n.opponentBeatYou(result.opponent.name),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tier.color),
                ),
                child: Text(l10n.leagueLabel(tierLabel), style: TextStyle(color: tier.color, fontWeight: FontWeight.w700)),
              ),
              if (result.promoted) ...[
                const SizedBox(height: 10),
                Text(
                  l10n.promotedToLeague(tierLabel),
                  style: const TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
              ],
              if (result.careerComplete) ...[
                const SizedBox(height: 10),
                Text(
                  l10n.careerAllDone,
                  style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 20),
              if (result.won && next != null && result.firstTimeWin)
                PucketButton(
                  label: l10n.nextFight(next.name),
                  width: 280,
                  onPressed: () {
                    setState(() => _showCareer = false);
                    AppRouter.startCareer(context, next);
                  },
                ),
              if (!result.won || !result.firstTimeWin || next == null) ...[
                PucketButton(
                  label: result.won ? l10n.playAgain : l10n.retry,
                  width: 280,
                  onPressed: () {
                    setState(() => _showCareer = false);
                    game.rematchLocal();
                  },
                ),
              ],
              const SizedBox(height: 12),
              PucketButton(
                label: l10n.backToCareer,
                secondary: true,
                width: 280,
                onPressed: () => AppRouter.returnToCareer(context),
              ),
              const SizedBox(height: 10),
              PucketButton(
                label: l10n.menu,
                secondary: true,
                width: 280,
                onPressed: () => AppRouter.goMenu(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEloOverlay(GameController game, EloResult result) {
    final l10n = context.l10n;
    final tier = RankTier.forElo(result.newElo);
    final tierLabel = l10n.tierName(tier);
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
                result.won ? l10n.matchWon : l10n.matchLost,
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
              Text(l10n.eloPoints, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              Text('${result.newElo} ELO', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              if (game.opponentName.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '${l10n.opponentProfile}: ${game.opponentName} · ${game.opponentElo} ELO · ${game.opponentLeague}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tier.color),
                ),
                child: Text(tierLabel, style: TextStyle(color: tier.color, fontWeight: FontWeight.w700)),
              ),
              if (result.newLeague != oldLeague && result.won)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.promotedLeagueMsg(result.newLeague),
                    style: const TextStyle(color: AppColors.gold, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 18),
              PucketButton(
                label: l10n.shareResult,
                secondary: true,
                width: 260,
                onPressed: () {
                  final auth = context.read<AuthService>();
                  ShareService.shareMatchResult(
                    playerName: auth.getName(),
                    won: result.won,
                    score: '${game.roundWins[0]} - ${game.roundWins[1]}',
                    eloChange: result.eloChange,
                    newElo: result.newElo,
                    league: result.newLeague,
                  );
                },
              ),
              const SizedBox(height: 12),
              PucketButton(
                label: l10n.ok,
                width: 260,
                onPressed: () {
                  setState(() {
                    _showElo = false;
                    _showOverlay = true;
                  });
                  final won = result.won;
                  final score = '${game.roundWins[0]} - ${game.roundWins[1]}';
                  _showEndOverlay(
                    title: won ? l10n.matchWon : l10n.matchLost,
                    sub: won ? l10n.congrats(score) : l10n.sorry(score),
                    primaryLabel: l10n.newMatch,
                    onPrimary: () {
                      if (game.aiMode || game.trainingMode || game.localDuoMode) {
                        game.rematchLocal();
                      } else {
                        game.requestRematch();
                      }
                    },
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
    final l10n = context.l10n;
    final isOpponentPause = game.pauseByOpponent && !game.aiMode;
    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PucketLogo(height: 56, compact: true),
              const SizedBox(height: 16),
              Text(
                isOpponentPause ? l10n.pausedByOpponent : l10n.paused,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.gold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                isOpponentPause
                    ? l10n.pauseWait(GameController.maxPauseSeconds)
                    : l10n.pauseSelfMsg(GameController.maxPauseSeconds),
                style: const TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.4),
                textAlign: TextAlign.center,
              ),
              if (game.pauseSecondsLeft > 0) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.pauseRemaining.replaceAll('{sec}', '${game.pauseSecondsLeft}'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ],
              const SizedBox(height: 20),
              if (!isOpponentPause)
                PucketButton(
                  label: l10n.resume,
                  width: 260,
                  onPressed: () {
                    game.togglePause();
                    setState(() => _showPause = false);
                  },
                ),
              if (game.aiMode || game.localDuoMode) ...[
                const SizedBox(height: 12),
                PucketButton(
                  label: l10n.restart,
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
                label: l10n.menuSettings,
                secondary: true,
                width: 260,
                onPressed: () => setState(() {
                  _showSettings = true;
                  _showPause = false;
                }),
              ),
              const SizedBox(height: 12),
              if (!game.aiMode && game.opponentUid.isNotEmpty)
                PucketButton(
                  label: l10n.reportPlayer,
                  secondary: true,
                  width: 260,
                  onPressed: () async {
                    final auth = context.read<AuthService>();
                    await MetaApi.reportPlayer(
                      reporter: auth.getUid(),
                      reported: game.opponentUid,
                      reason: 'in-game report',
                      room: game.roomCode,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.reportSent)));
                    }
                  },
                ),
              const SizedBox(height: 12),
              PucketButton(label: l10n.backToMenu, secondary: true, width: 260, onPressed: () => AppRouter.goMenu(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInGameSettings(GameController game) {
    final settings = context.watch<SettingsService>();
    final l10n = context.l10n;
    return Container(
      color: Colors.black.withValues(alpha: 0.92),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const PucketLogo(height: 48, compact: true),
              const SizedBox(height: 12),
              Text(l10n.settingsTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.purple, letterSpacing: 3)),
              SwitchListTile(title: Text(l10n.settingsMusic), value: settings.musicOn, onChanged: settings.setMusic),
              SwitchListTile(title: Text(l10n.settingsSfx), value: settings.sfxOn, onChanged: settings.setSfx),
              SwitchListTile(title: Text(l10n.settingsVibration), value: settings.vibrationOn, onChanged: settings.setVibration),
              if (game.aiMode)
                ListTile(
                  title: Text(l10n.botDifficulty),
                  trailing: DropdownButton<AiLevel>(
                    value: game.aiLevel,
                    dropdownColor: AppColors.card,
                    items: [
                      DropdownMenuItem(value: AiLevel.easy, child: Text(l10n.diffEasy)),
                      DropdownMenuItem(value: AiLevel.medium, child: Text(l10n.diffMedium)),
                      DropdownMenuItem(value: AiLevel.hard, child: Text(l10n.diffHard)),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => game.aiLevel = v);
                    },
                  ),
                ),
              const SizedBox(height: 16),
              PucketButton(
                label: l10n.ok,
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

  void _showEndOverlay({
    required String title,
    required String sub,
    String? primaryLabel,
    VoidCallback? onPrimary,
  }) {
    setState(() {
      _showOverlay = true;
      _overlayTitle = title;
      _overlaySub = sub;
      _overlayPrimaryLabel = primaryLabel;
      _overlayPrimaryAction = onPrimary;
    });
  }
}
