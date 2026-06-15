import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/disc.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../services/websocket_service.dart';
import 'ai_bot.dart';
import 'game_constants.dart';
import 'physics_engine.dart';

enum GamePhase { idle, countdown, playing, paused, gameover }

class DragState {
  final int discIndex;
  final double startVx;
  final double startVy;
  double currentVx;
  double currentVy;

  DragState({
    required this.discIndex,
    required this.startVx,
    required this.startVy,
    required this.currentVx,
    required this.currentVy,
  });
}

class EloResult {
  final bool won;
  final int eloChange;
  final int newElo;
  final String newLeague;

  EloResult({
    required this.won,
    required this.eloChange,
    required this.newElo,
    required this.newLeague,
  });
}

class GameController extends ChangeNotifier {
  GameController(this.settings, {required this.wsUrl, this.auth});

  final SettingsService settings;
  final AuthService? auth;
  final String wsUrl;
  final WebSocketService ws = WebSocketService();
  final AiBot aiBot = AiBot();

  static const roundsToWin = 2;

  List<Disc> discs = [];
  GamePhase phase = GamePhase.idle;
  int mySeat = 0;
  String roomCode = '';
  bool lobbyWaiting = true;
  bool aiMode = false;
  bool isRanked = false;
  AiLevel aiLevel = AiLevel.medium;

  final roundWins = [0, 0];
  int currentRound = 1;
  bool matchFinished = false;
  int? lastWinner;
  EloResult? pendingEloResult;

  int seconds = 0;
  int countdown = 3;
  DragState? drag;
  int _frameCount = 0;

  Timer? _secTimer;
  Timer? _cdTimer;

  void Function(String message)? onToast;
  void Function()? onOpponentLeft;
  void Function()? onGameStart;
  void Function()? onProfileRefresh;
  void Function(EloResult result)? onEloResult;

  void tick(double nowMs) {
    if (phase != GamePhase.playing) return;

    if (mySeat == 0 || aiMode) {
      PhysicsEngine.stepPhysics(discs);
      _frameCount++;
      if (aiMode && aiBot.shouldThink(nowMs, aiLevel)) {
        if (aiBot.think(discs, aiLevel)) _haptic(25);
      } else if (!aiMode && mySeat == 0) {
        if (_frameCount % 2 == 0) _sendState();
      }
      final winner = PhysicsEngine.checkWinner(discs);
      if (winner != null) _endRound(winner, broadcast: true);
    }
    notifyListeners();
  }

  void resetRound() {
    _secTimer?.cancel();
    _cdTimer?.cancel();
    seconds = 0;
    drag = null;
    _frameCount = 0;
    aiBot.reset();
    discs = PhysicsEngine.initDiscs();
    phase = GamePhase.idle;
    lastWinner = null;
    notifyListeners();
  }

  void resetMatch() {
    roundWins[0] = 0;
    roundWins[1] = 0;
    currentRound = 1;
    matchFinished = false;
    pendingEloResult = null;
    resetRound();
  }

  void startCountdown() {
    phase = GamePhase.countdown;
    countdown = 3;
    notifyListeners();
    _cdTimer?.cancel();
    _cdTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      countdown--;
      notifyListeners();
      if (countdown <= 0) {
        t.cancel();
        phase = GamePhase.playing;
        _secTimer?.cancel();
        seconds = 0;
        _secTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          seconds++;
          notifyListeners();
        });
        notifyListeners();
      }
    });
  }

  void startAiGame(AiLevel level) {
    ws.disconnect();
    aiMode = true;
    isRanked = false;
    aiLevel = level;
    mySeat = 0;
    roomCode = 'BOT';
    resetMatch();
    startCountdown();
  }

  void startOnlineGame(int seat, String room) {
    aiMode = false;
    mySeat = seat;
    roomCode = room;
    resetMatch();
    startCountdown();
  }

  Future<bool> openConnection({
    required String uid,
    required String name,
  }) async {
    ws.onMessage = _handleWs;
    ws.onError = () => onToast?.call('Bağlantı hatası');
    ws.onClose = () {
      if (phase == GamePhase.playing || phase == GamePhase.countdown) {
        onOpponentLeft?.call();
      }
    };
    final ok = await ws.connect(wsUrl);
    if (!ok) return false;
    ws.send({'type': 'login', 'uid': uid, 'name': name});
    return true;
  }

  void joinRoom(String code) {
    ws.send({'type': 'join', 'room': code});
  }

  void enterQueue(String uid, String name) {
    ws.send({'type': 'queue', 'uid': uid, 'name': name});
  }

  void leaveQueue() {
    ws.send({'type': 'dequeue'});
    ws.disconnect();
  }

  void _handleWs(Map<String, dynamic> msg) {
    switch (msg['type']) {
      case 'profile':
        final player = msg['player'];
        if (player is Map<String, dynamic>) {
          auth?.applyServerProfile(player);
          onProfileRefresh?.call();
        }
        break;
      case 'joined':
        mySeat = msg['seat'] as int;
        roomCode = msg['room'] as String;
        lobbyWaiting = msg['waiting'] as bool? ?? true;
        notifyListeners();
        break;
      case 'start':
        isRanked = false;
        startOnlineGame(mySeat, roomCode);
        onGameStart?.call();
        break;
      case 'matched':
        isRanked = true;
        mySeat = msg['seat'] as int;
        roomCode = msg['room'] as String;
        notifyListeners();
        Future.delayed(const Duration(milliseconds: 1800), () {
          startOnlineGame(mySeat, roomCode);
          onGameStart?.call();
        });
        break;
      case 'state':
        if (mySeat == 1 && msg['discs'] != null) {
          final states = msg['discs'] as List;
          for (var i = 0; i < states.length && i < discs.length; i++) {
            final s = states[i] as List;
            discs[i].vx = (s[0] as num).toDouble();
            discs[i].vy = (s[1] as num).toDouble();
            discs[i].vvx = (s[2] as num).toDouble();
            discs[i].vvy = (s[3] as num).toDouble();
          }
          notifyListeners();
        }
        break;
      case 'shot':
        if (mySeat == 0 && msg['disc'] != null) {
          final idx = msg['disc'] as int;
          if (idx < discs.length) {
            discs[idx].vvx = (msg['vvx'] as num).toDouble();
            discs[idx].vvy = (msg['vvy'] as num).toDouble();
            notifyListeners();
          }
        }
        break;
      case 'roundEnd':
        if (msg['roundWins'] is List) {
          final rw = msg['roundWins'] as List;
          roundWins[0] = (rw[0] as num).toInt();
          roundWins[1] = (rw[1] as num).toInt();
        }
        if (msg['currentRound'] != null) {
          currentRound = (msg['currentRound'] as num).toInt();
        }
        if (mySeat != 0) {
          final winner = msg['winner'] as int;
          phase = GamePhase.gameover;
          lastWinner = winner;
          _secTimer?.cancel();
          matchFinished = roundWins[winner] >= roundsToWin;
          _haptic(winner == mySeat ? 50 : 30);
        }
        notifyListeners();
        break;
      case 'matchEnd':
        if (mySeat != 0) {
          final w = msg['winner'] as int;
          _finishRoundFromRemote(w);
        }
        break;
      case 'eloResult':
        if (isRanked) {
          final result = EloResult(
            won: msg['won'] as bool? ?? false,
            eloChange: (msg['eloChange'] as num?)?.toInt() ?? 0,
            newElo: (msg['newElo'] as num?)?.toInt() ?? 1000,
            newLeague: msg['newLeague'] as String? ?? 'Bronz',
          );
          pendingEloResult = result;
          auth?.applyEloResult(
            newElo: result.newElo,
            newLeague: result.newLeague,
            won: result.won,
          );
          auth?.syncEloToFirestore(result.won, result.newElo, result.newLeague);
          onEloResult?.call(result);
          onProfileRefresh?.call();
        }
        break;
      case 'newMatch':
        resetMatch();
        startCountdown();
        break;
      case 'nextRound':
        resetRound();
        startCountdown();
        break;
      case 'rematch':
        resetRound();
        startCountdown();
        break;
      case 'opponent_left':
        phase = GamePhase.idle;
        onOpponentLeft?.call();
        break;
      case 'error':
        onToast?.call(msg['msg'] as String? ?? 'Hata');
        break;
    }
  }

  void _sendState() {
    final anyMoving = discs.any((d) => d.vvx.abs() > 0.01 || d.vvy.abs() > 0.01);
    if (!anyMoving) return;
    ws.send({
      'type': 'state',
      'discs': discs
          .map((d) => [
                (d.vx * 10).round() / 10,
                (d.vy * 10).round() / 10,
                (d.vvx * 100).round() / 100,
                (d.vvy * 100).round() / 100,
              ])
          .toList(),
    });
  }

  void _endRound(int winner, {required bool broadcast}) {
    if (phase == GamePhase.gameover) return;

    phase = GamePhase.gameover;
    _secTimer?.cancel();
    lastWinner = winner;
    roundWins[winner]++;
    currentRound++;
    matchFinished = roundWins[winner] >= roundsToWin;
    _haptic(winner == mySeat ? 50 : 30);

    if (broadcast) {
      ws.send({
        'type': 'roundEnd',
        'winner': winner,
        'roundWins': roundWins.toList(),
        'currentRound': currentRound,
      });
      if (matchFinished) {
        ws.send({
          'type': 'matchEnd',
          'winner': winner,
          'ranked': isRanked,
        });
      }
    }

    notifyListeners();
  }

  void _finishRoundFromRemote(int winner) {
    if (phase == GamePhase.gameover && lastWinner == winner) return;
    phase = GamePhase.gameover;
    _secTimer?.cancel();
    lastWinner = winner;
    matchFinished = roundWins[winner] >= roundsToWin;
    notifyListeners();
  }

  void rematch() {
    pendingEloResult = null;
    if (matchFinished) {
      if (!aiMode) ws.send({'type': 'newMatch'});
      resetMatch();
      startCountdown();
    } else {
      if (!aiMode) ws.send({'type': 'nextRound'});
      resetRound();
      startCountdown();
    }
  }

  void onPointerDown(double vx, double vy) {
    if (phase != GamePhase.playing) return;
    final idx = PhysicsEngine.findDiscAt(discs, vx, vy, mySeat);
    if (idx == -1) return;
    final d = discs[idx];
    drag = DragState(
      discIndex: idx,
      startVx: d.vx,
      startVy: d.vy,
      currentVx: vx,
      currentVy: vy,
    );
    notifyListeners();
  }

  void onPointerMove(double vx, double vy) {
    if (drag == null) return;
    drag!.currentVx = vx;
    drag!.currentVy = vy;
    notifyListeners();
  }

  void onPointerUp() {
    if (drag == null) return;
    final dx = drag!.startVx - drag!.currentVx;
    final dy = drag!.startVy - drag!.currentVy;
    final dist = math.sqrt(dx * dx + dy * dy);
    final lim = dist > 0 ? math.min(dist, GameConstants.slingMax) : 0.0;
    if (lim > 6) {
      final vvx = (dx / dist) * lim * GameConstants.slingPower;
      final vvy = (dy / dist) * lim * GameConstants.slingPower;
      if (mySeat == 0 || aiMode) {
        discs[drag!.discIndex].vvx = vvx;
        discs[drag!.discIndex].vvy = vvy;
      } else {
        ws.send({
          'type': 'shot',
          'disc': drag!.discIndex,
          'vvx': vvx,
          'vvy': vvy,
        });
      }
      _haptic(25);
    }
    drag = null;
    notifyListeners();
  }

  void togglePause() {
    if (phase == GamePhase.gameover) return;
    if (phase == GamePhase.paused) {
      phase = GamePhase.playing;
      _secTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        seconds++;
        notifyListeners();
      });
    } else if (phase == GamePhase.playing) {
      phase = GamePhase.paused;
      _secTimer?.cancel();
    }
    notifyListeners();
  }

  void leave() {
    ws.disconnect();
    _secTimer?.cancel();
    _cdTimer?.cancel();
    phase = GamePhase.idle;
    aiMode = false;
    isRanked = false;
    roundWins[0] = 0;
    roundWins[1] = 0;
    currentRound = 1;
    matchFinished = false;
    pendingEloResult = null;
    drag = null;
    notifyListeners();
  }

  int redRemaining() =>
      discs.where((d) => d.owner == 0 && d.vy >= GameConstants.vHalf).length;

  int blueRemaining() =>
      discs.where((d) => d.owner == 1 && d.vy < GameConstants.vHalf).length;

  void _haptic(int ms) {
    if (!settings.vibrationOn) return;
    if (ms > 100) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _secTimer?.cancel();
    _cdTimer?.cancel();
    ws.disconnect();
    super.dispose();
  }
}
