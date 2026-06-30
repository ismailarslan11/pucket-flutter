import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/career_opponent.dart';
import '../models/disc.dart';
import '../services/audio_service.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../services/websocket_service.dart';
import 'ai_bot.dart';
import 'game_constants.dart';
import 'physics_engine.dart';
import 'training_layout.dart';

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
  GameController(
    this.settings, {
    required this.wsUrl,
    this.auth,
    this.audio,
  });

  final SettingsService settings;
  final AuthService? auth;
  final AudioService? audio;
  final String wsUrl;
  final WebSocketService ws = WebSocketService();
  final AiBot aiBot = AiBot();

  static const roundsToWin = 2;
  static const maxPauseSeconds = 60;
  static const afkForfeitSeconds = 120;

  List<Disc> discs = [];
  GamePhase phase = GamePhase.idle;
  int mySeat = 0;
  /// Sunucunun atadığı host (koltuk 0). AI modunda her zaman true.
  bool isOnlineHost = true;
  String roomCode = '';
  bool lobbyWaiting = true;
  bool aiMode = false;
  bool isBotFallback = false;
  bool isRanked = false;
  bool careerMode = false;
  bool trainingMode = false;
  bool localDuoMode = false;
  String localPlayerRed = 'Oyuncu 1';
  String localPlayerBlue = 'Oyuncu 2';
  final Map<int, DragState> _duoDrags = {};
  TrainingLayout trainingLayout = TrainingLayout.full;
  String trainingGoalLabel = '';
  CareerOpponent? careerOpponent;
  AiLevel aiLevel = AiLevel.medium;

  String opponentName = '';
  String opponentUid = '';
  int opponentElo = 1000;
  String opponentLeague = 'Bronz';
  String sessionToken = '';

  bool reconnecting = false;
  bool opponentDisconnected = false;
  int opponentGraceLeft = 0;
  bool myRematchPending = false;
  bool opponentRematchRequested = false;

  final roundWins = [0, 0];
  int currentRound = 1;
  bool matchFinished = false;
  int? lastWinner;
  EloResult? pendingEloResult;

  int seconds = 0;
  int countdown = 3;
  DragState? drag;
  Timer? _matchStartTimer;
  int _onlineSession = 0;
  int _frameCount = 0;
  int _dragMoveCounter = 0;
  int _lastMovingDiscs = 0;
  int _visualGeneration = 0;
  double _physicsAccum = 0;
  double _lastTickWallMs = 0;

  static const _physicsStepMs = 1000 / 60;

  int get visualGeneration => _visualGeneration;

  Timer? _secTimer;
  Timer? _cdTimer;
  Timer? _pauseTimer;
  Timer? _graceTimer;
  Timer? _afkTimer;

  bool pauseByOpponent = false;
  int pauseSecondsLeft = 0;
  int? pingMs;

  void Function(int ms)? onPingUpdate;
  void Function(String message)? onToast;
  void Function()? onOpponentLeft;
  void Function()? onAfkForfeit;
  void Function()? onOpponentDisconnected;
  void Function()? onOpponentReconnected;
  void Function()? onReconnecting;
  void Function()? onReconnected;
  void Function()? onRematchRequest;
  void Function()? onGameStart;
  void Function()? onProfileRefresh;
  void Function(EloResult result)? onEloResult;
  void Function()? onRoundEnd;

  void _setSeat(int seat) {
    if (localDuoMode) {
      mySeat = 0;
      isOnlineHost = true;
    } else {
      mySeat = seat;
      if (!aiMode) isOnlineHost = seat == 0;
    }
  }

  String localPlayerName(int seat) => seat == 0 ? localPlayerRed : localPlayerBlue;

  List<DragState> get activeDrags =>
      localDuoMode ? _duoDrags.values.toList() : (drag != null ? [drag!] : const []);

  void _cancelPendingMatchStart() {
    _matchStartTimer?.cancel();
    _matchStartTimer = null;
  }

  void tick(double nowMs) {
    if (phase != GamePhase.playing) return;

    if (_lastTickWallMs == 0) _lastTickWallMs = nowMs;
    _physicsAccum += nowMs - _lastTickWallMs;
    _lastTickWallMs = nowMs;
    // FPS düşünce fizik fırlamasın
    if (_physicsAccum > _physicsStepMs * 3) _physicsAccum = _physicsStepMs * 3;

    var stepped = false;
    while (_physicsAccum >= _physicsStepMs) {
      _physicsAccum -= _physicsStepMs;
      if (_physicsStep()) return;
      stepped = true;
    }
    if (stepped) {
      _visualGeneration++;
      notifyListeners();
    }
  }

  /// Bir fizik adımı. Round biterse true döner.
  bool _physicsStep() {
    if (aiMode || isOnlineHost || localDuoMode) {
      PhysicsEngine.stepPhysics(discs);

      final moving = discs.where((d) => d.vvx.abs() > 0.05 || d.vvy.abs() > 0.05).length;
      if (moving > _lastMovingDiscs && moving > 0) {
        audio?.playHit();
      }
      _lastMovingDiscs = moving;

      _frameCount++;
      if (aiMode && aiBot.shouldThink(_frameCount * _physicsStepMs, aiLevel)) {
        if (aiBot.think(discs, aiLevel)) _haptic(25);
      } else if (!aiMode && isOnlineHost) {
        _sendState();
      }

      PhysicsEngine.settleGateDiscs(discs);
      final winner = PhysicsEngine.checkWinner(discs);
      if (winner != null) {
        _endRound(winner, broadcast: true);
        return true;
      }
    } else if (!aiMode) {
      // İstemci: host state gelene kadar yerel tahmin (takılmayı azaltır)
      PhysicsEngine.stepPhysics(discs);
      PhysicsEngine.settleGateDiscs(discs);
    }
    return false;
  }

  void resetRound() {
    _secTimer?.cancel();
    _cdTimer?.cancel();
    _afkTimer?.cancel();
    _clearPauseState();
    seconds = 0;
    drag = null;
    _duoDrags.clear();
    _frameCount = 0;
    _lastMovingDiscs = 0;
    _physicsAccum = 0;
    _lastTickWallMs = 0;
    aiBot.reset();
    discs = trainingMode
        ? PhysicsEngine.initTrainingDiscs(trainingLayout)
        : PhysicsEngine.initDiscs();
    phase = GamePhase.idle;
    lastWinner = null;
    myRematchPending = false;
    opponentRematchRequested = false;
    if (localDuoMode) _setSeat(0);
    _visualGeneration++;
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
        _startAfkTimer();
        notifyListeners();
      }
    });
  }

  void _startAfkTimer() {
    _afkTimer?.cancel();
    if (aiMode || localDuoMode) return;
    _afkTimer = Timer(const Duration(seconds: afkForfeitSeconds), () {
      if (phase != GamePhase.playing) return;
      onToast?.call('AFK — maç sonlandırıldı');
      leave();
      onAfkForfeit?.call();
    });
  }

  void startAiGame(AiLevel level, {bool botFallback = false}) {
    ws.disconnect();
    aiMode = true;
    localDuoMode = false;
    careerMode = false;
    trainingMode = false;
    careerOpponent = null;
    isBotFallback = botFallback;
    isRanked = false;
    aiLevel = level;
    _setSeat(0);
    if (botFallback) {
      final profile = BotFallbackProfile.generate(playerElo: auth?.user?.elo ?? 1000);
      roomCode = profile.roomCode;
      opponentName = profile.name;
      opponentElo = profile.elo;
      opponentLeague = profile.league;
    } else {
      roomCode = 'BOT';
      opponentName = 'Bot';
      opponentElo = 1000;
      opponentLeague = 'Bronz';
    }
    resetMatch();
    startCountdown();
  }

  void startCareerGame(CareerOpponent opponent) {
    ws.disconnect();
    aiMode = true;
    localDuoMode = false;
    careerMode = true;
    trainingMode = false;
    careerOpponent = opponent;
    isBotFallback = false;
    isRanked = false;
    aiLevel = opponent.aiLevel;
    _setSeat(0);
    roomCode = 'CAREER';
    opponentName = opponent.name;
    opponentElo = opponent.displayElo;
    opponentLeague = opponent.leagueName;
    resetMatch();
    startCountdown();
  }

  void startTrainingGame(
    AiLevel level, {
    String label = 'Antrenör',
    TrainingLayout layout = TrainingLayout.full,
    String goalLabel = '',
  }) {
    ws.disconnect();
    aiMode = true;
    localDuoMode = false;
    careerMode = false;
    trainingMode = true;
    careerOpponent = null;
    isBotFallback = false;
    isRanked = false;
    aiLevel = level;
    trainingLayout = layout;
    trainingGoalLabel = goalLabel;
    _setSeat(0);
    roomCode = 'TRAINING';
    opponentName = label;
    opponentElo = 0;
    opponentLeague = '';
    resetMatch();
    startCountdown();
  }

  void startLocalDuoGame({String playerRed = 'Oyuncu 1', String playerBlue = 'Oyuncu 2'}) {
    ws.disconnect();
    aiMode = false;
    localDuoMode = true;
    careerMode = false;
    trainingMode = false;
    careerOpponent = null;
    isBotFallback = false;
    isRanked = false;
    localPlayerRed = playerRed;
    localPlayerBlue = playerBlue;
    _duoDrags.clear();
    _setSeat(0);
    roomCode = 'LOCAL';
    opponentName = playerBlue;
    opponentElo = 0;
    opponentLeague = '';
    resetMatch();
    startCountdown();
  }

  void startOnlineGame(int seat, String room) {
    localDuoMode = false;
    aiMode = false;
    isBotFallback = false;
    careerMode = false;
    trainingMode = false;
    careerOpponent = null;
    _setSeat(seat);
    roomCode = room;
    ws.setSession(uid: auth?.getUid(), sessionToken: sessionToken, roomCode: room);
    resetMatch();
    startCountdown();
  }

  Future<bool> openConnection({
    required String uid,
    required String name,
    String? idToken,
    bool isAnonymous = true,
  }) async {
    ws.onMessage = _handleWs;
    ws.onPing = (ms) {
      pingMs = ms;
      onPingUpdate?.call(ms);
      notifyListeners();
    };
    ws.onError = () => onToast?.call('Bağlantı hatası');
    ws.onReconnected = () {
      // Gerçek senkron sunucudan 'reconnected' mesajı ile yapılır
    };
    ws.onClose = () {
      if (ws.isReconnecting) {
        reconnecting = true;
        onReconnecting?.call();
        notifyListeners();
        return;
      }
      if (!aiMode && (phase == GamePhase.playing || phase == GamePhase.countdown)) {
        onOpponentLeft?.call();
      }
    };
    final ok = await ws.connect(wsUrl);
    if (!ok) return false;
    ws.setSession(uid: uid, sessionToken: sessionToken, roomCode: roomCode.isNotEmpty ? roomCode : null);
    ws.send({
      'type': 'login',
      'uid': uid,
      'name': name,
      if (idToken != null) 'idToken': idToken,
      'isAnonymous': isAnonymous,
    });
    return true;
  }

  void joinRoom(String code) {
    ws.send({'type': 'join', 'room': code});
  }

  void enterQueue(String uid, String name) {
    ws.send({'type': 'queue', 'uid': uid, 'name': name});
  }

  void leaveQueue() {
    _cancelPendingMatchStart();
    _onlineSession++;
    ws.send({'type': 'dequeue'});
    ws.disconnect();
  }

  void _applyOpponentInfo(Map<String, dynamic> msg) {
    opponentName = msg['oppName'] as String? ?? opponentName;
    opponentUid = msg['oppUid'] as String? ?? opponentUid;
    opponentElo = (msg['oppElo'] as num?)?.toInt() ?? opponentElo;
    opponentLeague = msg['oppLeague'] as String? ?? opponentLeague;
    if (msg['sessionToken'] is String) {
      sessionToken = msg['sessionToken'] as String;
      ws.setSession(uid: auth?.getUid(), sessionToken: sessionToken, roomCode: roomCode);
    }
  }

  void _restoreSnapshot(Map<String, dynamic>? snap) {
    if (snap == null) return;
    final states = snap['discs'];
    if (states is List) {
      for (var i = 0; i < states.length && i < discs.length; i++) {
        final s = states[i] as List;
        discs[i].vx = (s[0] as num).toDouble();
        discs[i].vy = (s[1] as num).toDouble();
        discs[i].vvx = (s[2] as num).toDouble();
        discs[i].vvy = (s[3] as num).toDouble();
      }
    }
    if (snap['roundWins'] is List) {
      final rw = snap['roundWins'] as List;
      roundWins[0] = (rw[0] as num).toInt();
      roundWins[1] = (rw[1] as num).toInt();
    }
    if (snap['currentRound'] != null) {
      currentRound = (snap['currentRound'] as num).toInt();
    }
    if (snap['phase'] == 'gameover') {
      phase = GamePhase.gameover;
    } else if (snap['phase'] == 'playing') {
      phase = GamePhase.playing;
    }
  }

  void _syncSeatFromServer(Map<String, dynamic> msg) {
    if (aiMode) return;
    final fromYourSeat = (msg['yourSeat'] as num?)?.toInt();
    if (fromYourSeat != null && fromYourSeat >= 0 && fromYourSeat <= 1) {
      _setSeat(fromYourSeat);
      return;
    }
    final fromSeat = (msg['seat'] as num?)?.toInt();
    if (fromSeat != null && fromSeat >= 0 && fromSeat <= 1) {
      _setSeat(fromSeat);
    }
  }

  void _handleWs(Map<String, dynamic> msg) {
    _syncSeatFromServer(msg);
    switch (msg['type']) {
      case 'profile':
        final player = msg['player'];
        if (player is Map<String, dynamic>) {
          auth?.applyServerProfile(player);
          onProfileRefresh?.call();
        }
        break;
      case 'joined':
        _setSeat((msg['seat'] as num).toInt());
        roomCode = msg['room'] as String;
        lobbyWaiting = msg['waiting'] as bool? ?? true;
        _applyOpponentInfo(msg);
        if (msg['sessionToken'] is String) {
          sessionToken = msg['sessionToken'] as String;
          ws.setSession(uid: auth?.getUid(), sessionToken: sessionToken, roomCode: roomCode);
        }
        notifyListeners();
        break;
      case 'waiting':
        lobbyWaiting = true;
        notifyListeners();
        break;
      case 'start':
        isRanked = false;
        if (msg['seat'] != null) {
          _setSeat((msg['seat'] as num).toInt());
        }
        if (msg['room'] is String) {
          roomCode = msg['room'] as String;
        }
        _applyOpponentInfo(msg);
        startOnlineGame(mySeat, roomCode);
        onGameStart?.call();
        break;
      case 'matched':
        isRanked = msg['ranked'] as bool? ?? true;
        _setSeat((msg['seat'] as num).toInt());
        roomCode = msg['room'] as String;
        _applyOpponentInfo(msg);
        notifyListeners();
        _cancelPendingMatchStart();
        final session = ++_onlineSession;
        _matchStartTimer = Timer(const Duration(milliseconds: 1800), () {
          _matchStartTimer = null;
          if (session != _onlineSession || aiMode) return;
          startOnlineGame(mySeat, roomCode);
          onGameStart?.call();
        });
        break;
      case 'reconnected':
        reconnecting = false;
        opponentDisconnected = false;
        _graceTimer?.cancel();
        _setSeat((msg['seat'] as num).toInt());
        roomCode = msg['room'] as String;
        if (msg['ranked'] == true) isRanked = true;
        _applyOpponentInfo(msg);
        _restoreSnapshot(msg['snapshot'] as Map<String, dynamic>?);
        onReconnected?.call();
        notifyListeners();
        break;
      case 'opponent_disconnected':
        opponentDisconnected = true;
        opponentGraceLeft = (msg['graceSeconds'] as num?)?.toInt() ?? 60;
        _graceTimer?.cancel();
        _graceTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          opponentGraceLeft--;
          if (opponentGraceLeft <= 0) t.cancel();
          notifyListeners();
        });
        onOpponentDisconnected?.call();
        notifyListeners();
        break;
      case 'opponent_reconnected':
        opponentDisconnected = false;
        _graceTimer?.cancel();
        onOpponentReconnected?.call();
        notifyListeners();
        break;
      case 'state':
        if (aiMode || isOnlineHost) break;
        var changed = false;
        if (msg['discs'] is List && phase == GamePhase.playing) {
          changed = _applyDiscStates(msg['discs'] as List);
        }
        if (msg['roundWins'] is List) {
          final rw = msg['roundWins'] as List;
          final r0 = (rw[0] as num).toInt();
          final r1 = (rw[1] as num).toInt();
          if (roundWins[0] != r0 || roundWins[1] != r1) {
            roundWins[0] = r0;
            roundWins[1] = r1;
            changed = true;
          }
        }
        if (msg['currentRound'] != null) {
          final cr = (msg['currentRound'] as num).toInt();
          if (currentRound != cr) {
            currentRound = cr;
            changed = true;
          }
        }
        if (msg['phase'] == 'gameover' && msg['lastWinner'] != null) {
          _applyRoundEndFromNetwork({
            'winner': msg['lastWinner'],
            'roundWins': roundWins.toList(),
            'currentRound': currentRound,
          });
        } else if (changed) {
          _visualGeneration++;
          notifyListeners();
        }
        break;
      case 'shot':
        if (isOnlineHost && msg['disc'] != null) {
          final idx = msg['disc'] as int;
          if (idx < discs.length) {
            discs[idx].vvx = (msg['vvx'] as num).toDouble();
            discs[idx].vvy = (msg['vvy'] as num).toDouble();
            audio?.playShot();
            notifyListeners();
          }
        }
        break;
      case 'roundEnd':
        _applyRoundEndFromNetwork(msg);
        break;
      case 'matchEnd':
        if (!isOnlineHost) {
          final w = msg['winner'] as int;
          _finishRoundFromRemote(w);
        }
        break;
      case 'eloResult':
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
        break;
      case 'rematch_request':
        if ((msg['seat'] as num?)?.toInt() != mySeat) {
          opponentRematchRequested = true;
          onRematchRequest?.call();
          notifyListeners();
        }
        break;
      case 'rematch_accepted':
        isRanked = false;
        myRematchPending = false;
        opponentRematchRequested = false;
        resetMatch();
        startCountdown();
        break;
      case 'rematch_declined':
        myRematchPending = false;
        opponentRematchRequested = false;
        onToast?.call('Rakip rematch istemedi');
        notifyListeners();
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
      case 'pause':
        if (phase == GamePhase.playing) {
          _pauseGame(byOpponent: true, broadcast: false);
        }
        break;
      case 'resume':
        if (phase == GamePhase.paused) {
          _resumeFromPause(broadcast: false);
        }
        break;
      case 'opponent_left':
        phase = GamePhase.idle;
        opponentDisconnected = false;
        _graceTimer?.cancel();
        onOpponentLeft?.call();
        break;
      case 'error':
        onToast?.call(msg['msg'] as String? ?? 'Hata');
        break;
    }
  }

  void _applyRoundEndFromNetwork(Map<String, dynamic> msg) {
    if (msg['roundWins'] is List) {
      final rw = msg['roundWins'] as List;
      roundWins[0] = (rw[0] as num).toInt();
      roundWins[1] = (rw[1] as num).toInt();
    }
    if (msg['currentRound'] != null) {
      currentRound = (msg['currentRound'] as num).toInt();
    }

    final winner = (msg['winner'] as num?)?.toInt();
    if (winner == null || winner < 0 || winner > 1) return;

    if (phase == GamePhase.gameover && lastWinner == winner) {
      notifyListeners();
      return;
    }

    phase = GamePhase.gameover;
    lastWinner = winner;
    _secTimer?.cancel();
    _afkTimer?.cancel();
    matchFinished = roundWins[winner] >= roundsToWin;
    _haptic(winner == mySeat ? 50 : 30);
    if (winner == mySeat) {
      audio?.playWin();
    } else {
      audio?.playLose();
    }

    if (matchFinished && isRanked && !isOnlineHost) {
      ws.send({
        'type': 'matchEnd',
        'winner': winner,
        'ranked': true,
      });
    }
    _visualGeneration++;
    onRoundEnd?.call();
    notifyListeners();
  }

  bool _applyDiscStates(List states) {
    var changed = false;
    for (var i = 0; i < states.length && i < discs.length; i++) {
      final s = states[i] as List;
      final nx = (s[0] as num).toDouble();
      final ny = (s[1] as num).toDouble();
      final nvx = (s[2] as num).toDouble();
      final nvy = (s[3] as num).toDouble();
      final d = discs[i];
      final dx = nx - d.vx;
      final dy = ny - d.vy;
      final posErr = math.sqrt(dx * dx + dy * dy);

      if (posErr > 14) {
        d.vx = nx;
        d.vy = ny;
        changed = true;
      } else if (posErr > 0.15) {
        d.vx += dx * 0.4;
        d.vy += dy * 0.4;
        changed = true;
      }

      if ((d.vvx - nvx).abs() > 0.02 || (d.vvy - nvy).abs() > 0.02) {
        d.vvx += (nvx - d.vvx) * 0.55;
        d.vvy += (nvy - d.vvy) * 0.55;
        changed = true;
      }
    }
    return changed;
  }

  void _sendState() {
    if (aiMode || !isOnlineHost) return;
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
      'roundWins': roundWins.toList(),
      'currentRound': currentRound,
      'phase': phase.name,
      'seconds': seconds,
      if (lastWinner != null) 'lastWinner': lastWinner,
    });
  }

  void _sendGameOverSync(int winner) {
    if (aiMode || !isOnlineHost) return;
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
      'roundWins': roundWins.toList(),
      'currentRound': currentRound,
      'phase': 'gameover',
      'lastWinner': winner,
      'seconds': seconds,
    });
  }

  void _endRound(int winner, {required bool broadcast}) {
    if (phase == GamePhase.gameover) return;
    if (!aiMode && !isOnlineHost) return;

    phase = GamePhase.gameover;
    _secTimer?.cancel();
    _afkTimer?.cancel();
    lastWinner = winner;
    roundWins[winner]++;
    currentRound++;
    matchFinished = roundWins[winner] >= roundsToWin;
    _haptic(winner == mySeat ? 50 : 30);
    if (winner == mySeat) {
      audio?.playWin();
    } else {
      audio?.playLose();
    }

    if (broadcast) {
      ws.send({
        'type': 'roundEnd',
        'winner': winner,
        'roundWins': roundWins.toList(),
        'currentRound': currentRound,
      });
      _sendGameOverSync(winner);
      if (matchFinished) {
        ws.send({
          'type': 'matchEnd',
          'winner': winner,
          'ranked': isRanked,
        });
      }
    }

    _visualGeneration++;
    onRoundEnd?.call();
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

  void requestRematch() {
    if (aiMode || localDuoMode) {
      rematchLocal();
      return;
    }
    myRematchPending = true;
    ws.send({'type': 'rematch_request'});
    if (opponentRematchRequested) {
      ws.send({'type': 'rematch_request'});
    }
    notifyListeners();
  }

  void acceptRematch() {
    opponentRematchRequested = false;
    ws.send({'type': 'rematch_request'});
  }

  void declineRematch() {
    opponentRematchRequested = false;
    myRematchPending = false;
    ws.send({'type': 'rematch_decline'});
    notifyListeners();
  }

  void rematchLocal() {
    pendingEloResult = null;
    if (matchFinished) {
      resetMatch();
      startCountdown();
    } else {
      resetRound();
      startCountdown();
    }
  }

  void continueToNextRound() {
    if (matchFinished) return;
    resetRound();
    startCountdown();
    if (!aiMode && !trainingMode) {
      ws.send({'type': 'nextRound'});
    }
  }

  void onPointerDown(int pointerId, double vx, double vy) {
    if (phase != GamePhase.playing) return;
    _startAfkTimer();

    if (localDuoMode) {
      final used = _duoDrags.values.map((d) => d.discIndex).toSet();
      final idx = PhysicsEngine.findDiscAtLocalDuo(discs, vx, vy);
      if (idx == -1 || used.contains(idx)) return;
      final d = discs[idx];
      _duoDrags[pointerId] = DragState(
        discIndex: idx,
        startVx: d.vx,
        startVy: d.vy,
        currentVx: vx,
        currentVy: vy,
      );
      _visualGeneration++;
      notifyListeners();
      return;
    }

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
    _visualGeneration++;
    notifyListeners();
  }

  void onPointerMove(int pointerId, double vx, double vy) {
    if (localDuoMode) {
      final d = _duoDrags[pointerId];
      if (d == null) return;
      d.currentVx = vx;
      d.currentVy = vy;
      _dragMoveCounter++;
      if (_dragMoveCounter.isEven) {
        _visualGeneration++;
        notifyListeners();
      }
      return;
    }

    if (drag == null) return;
    drag!.currentVx = vx;
    drag!.currentVy = vy;
    _dragMoveCounter++;
    if (_dragMoveCounter.isEven) {
      _visualGeneration++;
      notifyListeners();
    }
  }

  void onPointerUp(int pointerId) {
    if (localDuoMode) {
      final d = _duoDrags.remove(pointerId);
      if (d != null) _releaseDrag(d);
      return;
    }

    if (drag == null) return;
    _releaseDrag(drag!);
    drag = null;
  }

  void _releaseDrag(DragState dragState) {
    final dx = dragState.startVx - dragState.currentVx;
    final dy = dragState.startVy - dragState.currentVy;
    final dist = math.sqrt(dx * dx + dy * dy);
    final lim = dist > 0 ? math.min(dist, GameConstants.slingMax) : 0.0;
    if (lim > 6) {
      final vvx = (dx / dist) * lim * GameConstants.slingPower;
      final vvy = (dy / dist) * lim * GameConstants.slingPower;
      if (aiMode || isOnlineHost || localDuoMode) {
        discs[dragState.discIndex].vvx = vvx;
        discs[dragState.discIndex].vvy = vvy;
      } else {
        discs[dragState.discIndex].vvx = vvx;
        discs[dragState.discIndex].vvy = vvy;
        ws.send({
          'type': 'shot',
          'disc': dragState.discIndex,
          'vvx': vvx,
          'vvy': vvy,
        });
      }
      audio?.playShot();
      _haptic(25);
    }
    _visualGeneration++;
    notifyListeners();
  }

  void togglePause() {
    if (phase == GamePhase.gameover || phase == GamePhase.countdown) return;
    if (phase == GamePhase.paused) {
      if (pauseByOpponent) return;
      _resumeFromPause(broadcast: !aiMode && !localDuoMode);
    } else if (phase == GamePhase.playing) {
      _pauseGame(byOpponent: false, broadcast: !aiMode && !localDuoMode);
    }
  }

  void _pauseGame({required bool byOpponent, required bool broadcast}) {
    if (phase != GamePhase.playing) return;
    phase = GamePhase.paused;
    pauseByOpponent = byOpponent;
    _secTimer?.cancel();
    _startPauseTimer();
    if (broadcast && ws.isConnected) {
      ws.send({'type': 'pause'});
    }
    notifyListeners();
  }

  void _resumeFromPause({required bool broadcast}) {
    if (phase != GamePhase.paused) return;
    _pauseTimer?.cancel();
    pauseByOpponent = false;
    pauseSecondsLeft = 0;
    phase = GamePhase.playing;
    _secTimer?.cancel();
    _secTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      seconds++;
      notifyListeners();
    });
    _startAfkTimer();
    if (broadcast && ws.isConnected) {
      ws.send({'type': 'resume'});
    }
    notifyListeners();
  }

  void _startPauseTimer() {
    _pauseTimer?.cancel();
    pauseSecondsLeft = maxPauseSeconds;
    _pauseTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      pauseSecondsLeft--;
      if (pauseSecondsLeft <= 0) {
        t.cancel();
        if (!pauseByOpponent) {
          _resumeFromPause(broadcast: !aiMode && !localDuoMode);
        }
      }
      notifyListeners();
    });
  }

  void _clearPauseState() {
    _pauseTimer?.cancel();
    pauseByOpponent = false;
    pauseSecondsLeft = 0;
  }

  void leave() {
    _cancelPendingMatchStart();
    _onlineSession++;
    ws.disconnect();
    _secTimer?.cancel();
    _cdTimer?.cancel();
    _graceTimer?.cancel();
    _afkTimer?.cancel();
    _clearPauseState();
    phase = GamePhase.idle;
    aiMode = false;
    localDuoMode = false;
    _duoDrags.clear();
    isOnlineHost = true;
    isBotFallback = false;
    isRanked = false;
    careerMode = false;
    trainingMode = false;
    trainingLayout = TrainingLayout.full;
    trainingGoalLabel = '';
    careerOpponent = null;
    reconnecting = false;
    opponentDisconnected = false;
    roundWins[0] = 0;
    roundWins[1] = 0;
    currentRound = 1;
    matchFinished = false;
    pendingEloResult = null;
    drag = null;
    _duoDrags.clear();
    notifyListeners();
  }

  int redRemaining() =>
      discs.where((d) => d.owner == 0 && d.vy >= GameConstants.vHalf).length;

  int blueRemaining() =>
      discs.where((d) => d.owner == 1 && d.vy < GameConstants.vHalf).length;

  int redHalfTotal() => redRemaining() + blueRemainingOnRedSide();

  int blueHalfTotal() => blueRemaining() + redRemainingOnBlueSide();

  int mySideRemaining() => mySeat == 0 ? redHalfTotal() : blueHalfTotal();

  int blueRemainingOnRedSide() =>
      discs.where((d) => d.owner == 1 && d.vy >= GameConstants.vHalf).length;

  int redRemainingOnBlueSide() =>
      discs.where((d) => d.owner == 0 && d.vy < GameConstants.vHalf).length;

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
    _graceTimer?.cancel();
    _afkTimer?.cancel();
    _pauseTimer?.cancel();
    _matchStartTimer?.cancel();
    ws.disconnect();
    super.dispose();
  }
}
