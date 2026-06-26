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
import '../services/match_api.dart';
import '../services/meta_api.dart';
import '../services/player_meta_service.dart';
import '../services/settings_service.dart';
import '../services/share_service.dart';
import '../theme/app_theme.dart';
import '../widgets/game_board.dart';
import '../widgets/ping_indicator.dart';
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
  String? _overlayPrimaryLabel;
  VoidCallback? _overlayPrimaryAction;
  int _lastCountdown = -1;
  GamePhase? _lastPhase;
  EloResult? _eloResult;
  CareerMatchResult? _careerResult;
  bool _showCareer = false;
  GameController? _game;
  Timer? _eloFallbackTimer;

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
        if (!mounted) return;
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
        );
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

    if (game.phase == GamePhase.countdown && game.countdown != _lastCountdown) {
      _lastCountdown = game.countdown;
      final l10n = context.l10n;
      final team = game.mySeat == 0 ? l10n.teamRed : l10n.teamBlue;
      setState(() {
        _showOverlay = true;
        _showElo = false;
        _overlayTitle = '${game.countdown}';
        _overlaySub = l10n.youAreTeam(team);
        _overlayPrimaryLabel = null;
        _overlayPrimaryAction = null;
      });
    } else if (game.phase == GamePhase.playing && _lastPhase == GamePhase.countdown) {
      _lastCountdown = 0;
      context.read<AudioService>().playGameMusic();
      setState(() => _showOverlay = false);
    }

    if (game.phase == GamePhase.gameover && _lastPhase != GamePhase.gameover) {
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

    // Yedek: roundEnd/state kaçırılsa bile gameover overlay göster
    if (game.phase == GamePhase.gameover &&
        !_showOverlay &&
        !_showElo &&
        !_showCareer &&
        !(game.isRanked && game.matchFinished && !game.isBotFallback)) {
      _showRoundOverlay(game);
    }

    _lastPhase = game.phase;
  }

  void _scheduleEloFallback(GameController game) {
    _eloFallbackTimer?.cancel();
    _eloFallbackTimer = Timer(const Duration(seconds: 3), () async {
      if (!mounted) return;
      if (_eloResult != null || game.pendingEloResult != null) return;

      final auth = context.read<AuthService>();
      final uid = auth.getUid();
      final oldElo = auth.user?.elo ?? 1000;
      final player = await MatchApi.fetchPlayer(uid);
      if (!mounted || _eloResult != null || game.pendingEloResult != null) return;

      if (player != null) {
        final newElo = (player['elo'] as num?)?.toInt() ?? oldElo;
        final league = player['league'] as String? ?? auth.user?.league ?? 'Bronz';
        auth.applyServerProfile(player);
        final won = game.lastWinner == game.mySeat;
        setState(() {
          _eloResult = EloResult(
            won: won,
            eloChange: newElo - oldElo,
            newElo: newElo,
            newLeague: league,
          );
          _showElo = true;
        });
        return;
      }

      _showRoundOverlay(game);
    });
  }

  void _showRoundOverlay(GameController game) {
    final l10n = context.l10n;
    final won = game.lastWinner == game.mySeat;
    final score = '${game.roundWins[0]} - ${game.roundWins[1]}';
    context.read<AdService>().maybeShowInterstitial(
      matchFinished: game.matchFinished,
      skip: game.trainingMode,
    );
    if (game.matchFinished) {
      _showEndOverlay(
        title: won ? l10n.matchWon : l10n.matchLost,
        sub: won ? l10n.congrats(score) : l10n.sorry(score),
        primaryLabel: l10n.newMatch,
        onPrimary: () {
          if (game.aiMode || game.trainingMode) {
            game.rematchLocal();
          } else {
            game.requestRematch();
          }
        },
      );
    } else {
      _showEndOverlay(
        title: l10n.roundEnded(game.currentRound - 1),
        sub: '${won ? l10n.roundWon : l10n.roundLost}\n$score',
        primaryLabel: l10n.nextRound,
        onPrimary: game.continueToNextRound,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final l10n = context.l10n;
    final timer =
        '${(game.seconds ~/ 60).toString().padLeft(2, '0')}:${(game.seconds % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(game, l10n),
            if (game.reconnecting)
              Container(
                width: double.infinity,
                color: const Color(0xFF3A2A00),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  l10n.reconnecting,
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
                  l10n.opponentDisconnected(game.opponentGraceLeft),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.red, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            _roundRow(game, timer, l10n),
            Expanded(
              child: Stack(
                children: [
                  const GameBoard(),
                  if (_showOverlay && !_showElo && !_showCareer) _buildOverlay(game, l10n),
                  if (_showElo && _eloResult != null) _buildEloOverlay(game, _eloResult!),
                  if (_showCareer && _careerResult != null) _buildCareerOverlay(game, _careerResult!),
                  if (_showPause) _buildPause(game),
                  if (_showSettings) _buildInGameSettings(game),
                ],
              ),
            ),
            _bottomBar(game, l10n),
          ],
        ),
      ),
    );
  }

  Widget _topBar(GameController game, l10n) {
    final lbl0 = l10n.youRed;
    final lbl1 = game.careerMode || game.isBotFallback
        ? game.opponentName.toUpperCase()
        : game.aiMode
            ? l10n.botBlue
            : (game.opponentName.isNotEmpty ? game.opponentName.toUpperCase() : l10n.blue);

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
          if (game.careerMode || game.isBotFallback || (!game.aiMode && game.opponentName.isNotEmpty))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    game.trainingMode
                        ? l10n.trainingMode
                        : game.careerMode
                            ? l10n.careerMode
                            : (game.isRanked && !game.isBotFallback ? l10n.ranked : l10n.online),
                    style: TextStyle(
                      fontSize: 7,
                      color: game.careerMode ? AppColors.gold : const Color(0xFF555555),
                      letterSpacing: 1,
                      fontWeight: game.careerMode ? FontWeight.w800 : FontWeight.normal,
                    ),
                  ),
                  Text(
                    game.careerMode ? game.opponentLeague : '${game.opponentElo}',
                    style: TextStyle(
                      fontSize: 10,
                      color: game.careerMode ? const Color(0xFF888888) : AppColors.gold,
                      fontWeight: FontWeight.w800,
                    ),
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

  Widget _roundRow(GameController game, String timer, l10n) {
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
          if (!game.aiMode && game.pingMs != null) ...[
            const SizedBox(width: 6),
            PingIndicator(pingMs: game.pingMs),
          ],
          if (game.roomCode.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              game.careerMode
                  ? l10n.careerMode
                  : game.isBotFallback
                      ? game.roomCode
                      : game.aiMode
                          ? l10n.bot
                          : game.roomCode,
              style: TextStyle(
                color: game.careerMode ? AppColors.gold : const Color(0xFF444444),
                fontSize: 9,
                letterSpacing: 1,
                fontWeight: game.careerMode ? FontWeight.w800 : FontWeight.normal,
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

  Widget _bottomBar(GameController game, l10n) {
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
          Text(l10n.yourHalf, style: const TextStyle(color: Color(0xFF444444), fontSize: 10, letterSpacing: 1)),
          const SizedBox(width: 8),
          Text(l10n.discsLeft(game.mySideRemaining()), style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildOverlay(GameController game, l10n) {
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
              if (_overlayPrimaryLabel != null && _overlayPrimaryAction != null) ...[
                const SizedBox(height: 20),
                PucketButton(
                  label: _overlayPrimaryLabel!,
                  width: 260,
                  onPressed: () {
                    setState(() => _showOverlay = false);
                    _overlayPrimaryAction!();
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
              Text(score, style: const TextStyle(color: Color(0xFF666666), fontSize: 13)),
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
                Text(l10n.careerPoints, style: const TextStyle(color: Color(0xFF666666), fontSize: 12)),
                Text(
                  '${result.totalCareerPoints} KP',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ] else if (result.won && !result.firstTimeWin)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    l10n.kpAlreadyEarned,
                    style: const TextStyle(color: Color(0xFF777777), fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    l10n.opponentBeatYou(result.opponent.name),
                    style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
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
              Text(l10n.eloPoints, style: const TextStyle(color: Color(0xFF666666), fontSize: 12)),
              Text('${result.newElo} ELO', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              if (game.opponentName.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '${l10n.opponentProfile}: ${game.opponentName} · ${game.opponentElo} ELO · ${game.opponentLeague}',
                  style: const TextStyle(color: Color(0xFF777777), fontSize: 11),
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
                child: Text('${tier.emoji} $tierLabel', style: TextStyle(color: tier.color, fontWeight: FontWeight.w700)),
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
                      if (game.aiMode || game.trainingMode) {
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
                style: const TextStyle(fontSize: 14, color: Color(0xFFAAAAAA), height: 1.4),
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
              if (game.aiMode) ...[
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
              Text(l10n.settingsTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.green, letterSpacing: 3)),
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
