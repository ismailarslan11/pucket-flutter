import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/career_opponent.dart';
import '../models/disc.dart';
import '../models/rank_tier.dart';
import '../services/audio_service.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../services/websocket_service.dart';
import 'ai_bot.dart';
import 'game_constants.dart';
import 'game_fx.dart';
import 'physics_engine.dart';
import 'training_layout.dart';

enum GamePhase { idle, countdown, playing, paused, gameover }

/// Sadece tahta CustomPaint yenilemesi — üst/alt bar rebuild etmez.
class BoardRepaintNotifier extends ChangeNotifier {
  void bump() => notifyListeners();
}

/// Sadece süre / pul sayacı gibi hafif HUD güncellemeleri.
class UiSyncNotifier extends ChangeNotifier {
  void bump() => notifyListeners();
}

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
  String opponentDiscColor = 'green';
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
  int _lastMovingDiscs = 0;
  int _visualGeneration = 0;
  double _physicsAccum = 0;
  double _lastTickWallMs = 0;
  final List<double> _prevVx = [];
  final List<double> _prevVy = [];
  int _lastUiDiscSignature = -1;
  int _lastHitAudioFrame = 0;
  int _lastSentStateSig = 0;
  int _lastStateSentMs = 0;
  int _lastNetworkBoardBumpMs = 0;
  int? _localShotDisc;
  int _localShotUntilMs = 0;

  final boardRepaint = BoardRepaintNotifier();
  final uiSync = UiSyncNotifier();
  final fx = GameFx();

  static const _physicsStepMs = 1000 / 60;

  int get visualGeneration => _visualGeneration;

  /// Fizik adımları arasında yumuşak ara kare (0→1).
  double get discRenderAlpha {
    if (_physicsAccum <= 0) return 1;
    return (_physicsAccum / _physicsStepMs).clamp(0.0, 1.0);
  }

  double renderDiscX(int i) {
    if (i >= discs.length) return 0;
    if (i >= _prevVx.length) return discs[i].vx;
    final a = discRenderAlpha;
    return _prevVx[i] + (discs[i].vx - _prevVx[i]) * a;
  }

  double renderDiscY(int i) {
    if (i >= discs.length) return 0;
    if (i >= _prevVy.length) return discs[i].vy;
    final a = discRenderAlpha;
    return _prevVy[i] + (discs[i].vy - _prevVy[i]) * a;
  }

  void _syncPrevBuffers() {
    final n = discs.length;
    while (_prevVx.length < n) {
      _prevVx.add(0);
      _prevVy.add(0);
    }
    if (_prevVx.length > n) {
      _prevVx.length = n;
      _prevVy.length = n;
    }
  }

  void _initPrevFromCurrent() {
    _syncPrevBuffers();
    for (var i = 0; i < discs.length; i++) {
      _prevVx[i] = discs[i].vx;
      _prevVy[i] = discs[i].vy;
    }
  }

  void _capturePrevPositions() {
    _syncPrevBuffers();
    for (var i = 0; i < discs.length; i++) {
      _prevVx[i] = discs[i].vx;
      _prevVy[i] = discs[i].vy;
    }
  }

  Timer? _secTimer;
  Timer? _cdTimer;
  Timer? _pauseTimer;
  Timer? _graceTimer;
  Timer? _afkTimer;

  bool pauseByOpponent = false;
  int pauseSecondsLeft = 0;
  int? pingMs;

  // Maç içi emote (reaksiyon).
  static const emotes = ['👍', '🔥', '😎', '😅', '😮', '🎯', '👏', '🤝'];
  String? myEmote;
  String? oppEmote;
  Timer? _myEmoteTimer;
  Timer? _oppEmoteTimer;

  void sendEmote(String e) {
    if (aiMode || localDuoMode) {
      // Botla/yerelde sadece kendi tarafında göster.
      myEmote = e;
      _myEmoteTimer?.cancel();
      _myEmoteTimer = Timer(const Duration(seconds: 2), () {
        myEmote = null;
        uiSync.bump();
      });
      uiSync.bump();
      return;
    }
    myEmote = e;
    _myEmoteTimer?.cancel();
    _myEmoteTimer = Timer(const Duration(seconds: 2), () {
      myEmote = null;
      uiSync.bump();
    });
    ws.send({'type': 'emote', 'e': e});
    uiSync.bump();
  }

  void _showOppEmote(String e) {
    oppEmote = e;
    _oppEmoteTimer?.cancel();
    _oppEmoteTimer = Timer(const Duration(seconds: 2), () {
      oppEmote = null;
      uiSync.bump();
    });
    uiSync.bump();
  }

  // Bot insanlaştırma: gizli bot ara sıra insan gibi emote atar.
  Timer? _botEmoteTimer;
  final _botEmoteRng = math.Random();

  void _maybeBotEmote(List<String> pool, {double chance = 0.35}) {
    if (!aiMode) return;
    if (_botEmoteRng.nextDouble() > chance) return;
    _botEmoteTimer?.cancel();
    // İnsan gecikmesi: hemen değil, 0.8-2.2 sn sonra.
    _botEmoteTimer = Timer(
      Duration(milliseconds: 800 + _botEmoteRng.nextInt(1400)),
      () {
        if (phase == GamePhase.playing || phase == GamePhase.gameover) {
          _showOppEmote(pool[_botEmoteRng.nextInt(pool.length)]);
        }
      },
    );
  }

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

  List<DragState> _cachedActiveDrags = const [];

  List<DragState> get activeDrags => _cachedActiveDrags;

  void _refreshActiveDrags() {
    _cachedActiveDrags = localDuoMode
        ? _duoDrags.values.toList(growable: false)
        : (drag != null ? [drag!] : const []);
  }

  void _bumpBoard() {
    boardRepaint.bump();
  }

  /// Ağ paketlerinden gelen repaint — frame başına en fazla bir kez.
  void _bumpBoardFromNetwork() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastNetworkBoardBumpMs < 14) return;
    _lastNetworkBoardBumpMs = now;
    _bumpBoard();
  }

  int _discStateSignature() {
    var sig = 17;
    for (final d in discs) {
      sig = sig * 31 + (d.vx * 10).round();
      sig = sig * 31 + (d.vy * 10).round();
      sig = sig * 31 + (d.vvx * 100).round();
      sig = sig * 31 + (d.vvy * 100).round();
    }
    return sig;
  }

  void _markVisualGeneration() {
    _visualGeneration++;
  }

  /// Client: paket yokken tek pulu hızıyla ilerlet (çarpışma yok).
  void _integrateOne(Disc d) {
    d.vx += d.vvx;
    d.vy += d.vvy;
    d.vvx *= GameConstants.friction;
    d.vvy *= GameConstants.friction;
    if (d.vvx.abs() < 0.03) d.vvx = 0;
    if (d.vvy.abs() < 0.03) d.vvy = 0;
  }

  // ── İstemci ağ senkronu: anlık görüntü arabelleği (snapshot interpolation) ──
  // Host'tan gelen durumlar geldiği anda uygulanmaz; ~110 ms "geçmişten",
  // iki paket arasında yumuşak geçişle oynatılır. Böylece ağ titremesi
  // (jitter) ışınlanma/zıplama yerine akıcı harekete dönüşür.
  static const _interpDelayMs = 110.0;
  final List<_Snap> _snapBuf = [];
  double _starvedBaseRx = -1;

  bool _bufferSnapshot(List states) {
    final n = states.length;
    final s = _Snap(
      rxMs: DateTime.now().millisecondsSinceEpoch.toDouble(),
      xs: List<double>.filled(n, 0),
      ys: List<double>.filled(n, 0),
      vxs: List<double>.filled(n, 0),
      vys: List<double>.filled(n, 0),
    );
    for (var i = 0; i < n; i++) {
      final e = states[i] as List;
      s.xs[i] = (e[0] as num).toDouble();
      s.ys[i] = (e[1] as num).toDouble();
      s.vxs[i] = (e[2] as num).toDouble();
      s.vys[i] = (e[3] as num).toDouble();
    }
    _snapBuf.add(s);
    if (_snapBuf.length > 16) _snapBuf.removeAt(0);
    return true;
  }

  /// Oynatılacak arabellek verisi var mı? (ticker uyanık kalsın)
  bool get _clientSnapPending {
    if (_snapBuf.isEmpty) return false;
    final renderMs =
        DateTime.now().millisecondsSinceEpoch - _interpDelayMs;
    return renderMs < _snapBuf.last.rxMs + 250;
  }

  /// Pozisyon+hızı doğrudan bir kareden uygula (sert geçiş anları için).
  void _applySnap(_Snap s, int? skipIdx) {
    final n = math.min(discs.length, s.xs.length);
    for (var i = 0; i < n; i++) {
      if (i == skipIdx) continue;
      final d = discs[i];
      d.vx = s.xs[i];
      d.vy = s.ys[i];
      d.vvx = s.vxs[i];
      d.vvy = s.vys[i];
      if (i < _prevVx.length) {
        _prevVx[i] = d.vx;
        _prevVy[i] = d.vy;
      }
    }
  }

  /// Client fizik adımı: arabellekten geçmişe dönük yumuşak oynatma.
  void _clientNetAdvance() {
    final nowMs = DateTime.now().millisecondsSinceEpoch.toDouble();
    final localIdx =
        (nowMs < _localShotUntilMs) ? _localShotDisc : null;

    // Kendi atışın: host yankısı gelene dek yerel tahminle aksın.
    if (localIdx != null && localIdx < discs.length) {
      _integrateOne(discs[localIdx]);
    }

    if (_snapBuf.length < 2) {
      // Arabellek daha dolmadı: eski hafif tahmin (skip: atış zaten aktı).
      for (var i = 0; i < discs.length; i++) {
        if (i == localIdx) continue;
        _integrateOne(discs[i]);
      }
      return;
    }

    final renderMs = nowMs - _interpDelayMs;

    // Geride kalan kareleri düş — s0 olarak bir öncekini tut.
    while (_snapBuf.length >= 2 && _snapBuf[1].rxMs <= renderMs) {
      _snapBuf.removeAt(0);
    }

    final s0 = _snapBuf[0];
    if (renderMs <= s0.rxMs) {
      // Henüz oynatma zamanı gelmedi: ilk kareye sabitle.
      if (_starvedBaseRx != s0.rxMs) {
        _applySnap(s0, localIdx);
        _starvedBaseRx = s0.rxMs;
      }
      return;
    }

    if (_snapBuf.length == 1) {
      // Arabellek açlığı (paket gecikti): son kare + hafif tahmin.
      if (_starvedBaseRx != s0.rxMs) {
        _applySnap(s0, localIdx);
        _starvedBaseRx = s0.rxMs;
      }
      for (var i = 0; i < discs.length; i++) {
        if (i == localIdx) continue;
        _integrateOne(discs[i]);
      }
      return;
    }

    _starvedBaseRx = -1;
    final s1 = _snapBuf[1];
    final span = (s1.rxMs - s0.rxMs).clamp(1.0, 1000.0);
    final t = ((renderMs - s0.rxMs) / span).clamp(0.0, 1.0);
    final stepsInSpan = span / _physicsStepMs;
    final n = math.min(
        discs.length, math.min(s0.xs.length, s1.xs.length));
    for (var i = 0; i < n; i++) {
      if (i == localIdx) continue;
      final d = discs[i];
      d.vx = s0.xs[i] + (s1.xs[i] - s0.xs[i]) * t;
      d.vy = s0.ys[i] + (s1.ys[i] - s0.ys[i]) * t;
      // Hareket algısı ve render ara-karesi için adım başına hız.
      d.vvx = (s1.xs[i] - s0.xs[i]) / stepsInSpan;
      d.vvy = (s1.ys[i] - s0.ys[i]) / stepsInSpan;
    }
  }

  void _cancelPendingMatchStart() {
    _matchStartTimer?.cancel();
    _matchStartTimer = null;
  }

  /// Tahta ticker'ından çağrılır. Yeniden çizim gerekiyorsa true döner.
  bool tick(double nowMs) {
    if (phase != GamePhase.playing) return false;

    final dragging = drag != null || _duoDrags.isNotEmpty;
    final movingCount = PhysicsEngine.countMoving(discs);
    final isClient = !aiMode && !isOnlineHost && !localDuoMode;

    if (!dragging && movingCount == 0 && !fx.active) {
      if (!isClient) {
        _lastTickWallMs = 0;
        return false;
      }
      final clientDrifting = discs.any((d) => d.vvx.abs() > 0.02 || d.vvy.abs() > 0.02) ||
          _clientSnapPending;
      if (!clientDrifting) {
        _lastTickWallMs = 0;
        return false;
      }
    }

    if (_lastTickWallMs == 0) _lastTickWallMs = nowMs;
    var delta = nowMs - _lastTickWallMs;
    _lastTickWallMs = nowMs;
    if (delta > 100) delta = 100;
    _physicsAccum += delta;
    if (_physicsAccum > _physicsStepMs * 3) _physicsAccum = _physicsStepMs * 3;

    var stepped = false;
    while (_physicsAccum >= _physicsStepMs) {
      _physicsAccum -= _physicsStepMs;
      _capturePrevPositions();
      fx.step();
      if (_physicsStep()) return true;
      stepped = true;
    }

    if (stepped) _syncUiIfDiscCountsChanged();

    return stepped || dragging || movingCount > 0 || _lastMovingDiscs > 0 || fx.active;
  }

  void _syncUiIfDiscCountsChanged() {
    final sig = localDuoMode
        ? (redHalfTotal() << 16) | blueHalfTotal()
        : mySideRemaining();
    if (sig == _lastUiDiscSignature) return;
    // Bir disk karşı tarafa geçti (skor hissi): geçit hizasında parlama.
    if (_lastUiDiscSignature != -1) {
      fx.burst(
        GameConstants.vw / 2,
        GameConstants.vh / 2,
        count: 14,
        color: const Color(0xFFFACC15),
        speed: 3.2,
        size: 2.6,
      );
      fx.addShake(3);
      _haptic(20);
    }
    _lastUiDiscSignature = sig;
    uiSync.bump();
  }

  void _spawnHitFx() {
    // En hızlı hareket eden diski bul, orada küçük kıvılcım.
    Disc? fastest;
    var best = 0.0;
    for (final d in discs) {
      final sp = d.vvx * d.vvx + d.vvy * d.vvy;
      if (sp > best) {
        best = sp;
        fastest = d;
      }
    }
    if (fastest == null || best < 4) return;
    final color = fastest.owner == 0 ? const Color(0xFFFB923C) : const Color(0xFF38BDF8);
    fx.burst(fastest.vx, fastest.vy, count: 6, color: color, speed: 2.2, size: 2.0);
    if (best > 40) fx.addShake(2);
  }

  /// Bir fizik adımı. Round biterse true döner.
  bool _physicsStep() {
    if (aiMode || isOnlineHost || localDuoMode) {
      PhysicsEngine.stepPhysics(discs);

      final moving = PhysicsEngine.countMoving(discs);
      if (moving > _lastMovingDiscs &&
          moving > 0 &&
          _frameCount - _lastHitAudioFrame > 10) {
        _lastHitAudioFrame = _frameCount;
        audio?.playHit();
        // Çarpışma juice'u: en hızlı diskte kıvılcım + hafif sarsıntı.
        _spawnHitFx();
      }
      _lastMovingDiscs = moving;

      _frameCount++;
      if (aiMode && aiBot.shouldThink(_frameCount * _physicsStepMs, aiLevel)) {
        if (aiBot.think(discs, aiLevel)) _haptic(25);
      } else if (!aiMode && isOnlineHost && _frameCount % 3 == 0) {
        _sendState();
      }

      if (moving == 0 && _lastMovingDiscs > 0) {
        PhysicsEngine.settleGateDiscs(discs);
        if (isOnlineHost && !aiMode) _sendState(force: true);
      }
      final winner = PhysicsEngine.checkWinner(discs);
      if (winner != null) {
        _endRound(winner, broadcast: true);
        return true;
      }
    } else if (!aiMode && !isOnlineHost) {
      // Online client: tam fizik yok — arabellekten geçmişe dönük oynatma.
      _clientNetAdvance();
    }
    return false;
  }

  void resetRound() {
    _secTimer?.cancel();
    _cdTimer?.cancel();
    _afkTimer?.cancel();
    _clearPauseState();
    fx.clear();
    seconds = 0;
    drag = null;
    _duoDrags.clear();
    _refreshActiveDrags();
    _frameCount = 0;
    _lastMovingDiscs = 0;
    _physicsAccum = 0;
    _lastTickWallMs = 0;
    _lastUiDiscSignature = -1;
    _lastSentStateSig = 0;
    _lastStateSentMs = 0;
    _localShotDisc = null;
    _localShotUntilMs = 0;
    _snapBuf.clear();
    _starvedBaseRx = -1;
    aiBot.reset();
    discs = trainingMode
        ? PhysicsEngine.initTrainingDiscs(trainingLayout)
        : PhysicsEngine.initDiscs();
    _initPrevFromCurrent();
    phase = GamePhase.idle;
    lastWinner = null;
    myRematchPending = false;
    opponentRematchRequested = false;
    if (localDuoMode) _setSeat(0);
    _markVisualGeneration();
    _bumpBoard();
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
    _bumpBoard();
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
          uiSync.bump();
        });
        _startAfkTimer();
        _bumpBoard();
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

  void startAiGame(AiLevel level, {bool botFallback = false, bool ranked = false}) {
    ws.disconnect();
    aiMode = true;
    localDuoMode = false;
    careerMode = false;
    trainingMode = false;
    careerOpponent = null;
    isBotFallback = botFallback;
    // Gizli bot: ranked kuyruğunda rakip bulunamayınca bota düşülse de
    // oyuncu için maç ranked görünmeli (ELO değişir, "bot" ibaresi yok).
    isRanked = botFallback && ranked;
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
    // Gizli bot: maç başında bazen insan gibi selamlar.
    if (botFallback) {
      _maybeBotEmote(const ['👍', '🤝', '😎'], chance: 0.45);
    }
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
      uiSync.bump();
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
      'idToken': ?idToken,
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
    final oppDisc = msg['oppDisc'] as String?;
    if (oppDisc != null && oppDisc.isNotEmpty) opponentDiscColor = oppDisc;
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
      _initPrevFromCurrent();
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
      if (snap['seconds'] is num) seconds = (snap['seconds'] as num).toInt();
      // Yeniden bağlanınca süre sayacı ve AFK koruması tekrar kurulmalı.
      _secTimer?.cancel();
      _secTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        seconds++;
        uiSync.bump();
      });
      _startAfkTimer();
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
        _bumpBoard();
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
          uiSync.bump();
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
        var boardChanged = false;
        var uiChanged = false;
        if (msg['discs'] is List && phase == GamePhase.playing) {
          boardChanged = _bufferSnapshot(msg['discs'] as List);
        }
        if (msg['roundWins'] is List) {
          final rw = msg['roundWins'] as List;
          final r0 = (rw[0] as num).toInt();
          final r1 = (rw[1] as num).toInt();
          if (roundWins[0] != r0 || roundWins[1] != r1) {
            roundWins[0] = r0;
            roundWins[1] = r1;
            uiChanged = true;
          }
        }
        if (msg['currentRound'] != null) {
          final cr = (msg['currentRound'] as num).toInt();
          if (currentRound != cr) {
            currentRound = cr;
            uiChanged = true;
          }
        }
        if (msg['phase'] == 'gameover' && msg['lastWinner'] != null) {
          if (phase != GamePhase.countdown) {
            _applyRoundEndFromNetwork({
              'winner': msg['lastWinner'],
              'roundWins': roundWins.toList(),
              'currentRound': currentRound,
            });
          }
        } else {
          if (boardChanged) {
            _bumpBoardFromNetwork();
            _syncUiIfDiscCountsChanged();
          }
          if (uiChanged) notifyListeners();
        }
        break;
      case 'shot':
        if (isOnlineHost && msg['disc'] != null) {
          final idx = msg['disc'] as int;
          if (idx < discs.length) {
            discs[idx].vvx = (msg['vvx'] as num).toDouble();
            discs[idx].vvy = (msg['vvy'] as num).toDouble();
            audio?.playShot();
            _bumpBoard();
            _sendState(force: true);
          }
        }
        break;
      case 'roundEnd':
        // Sadece geri sayım sırasında yok say (gecikmiş mesaj yeni round'u
        // geri çekmesin); oyun sırasında gelen round bitişi normal akıştır.
        if (phase != GamePhase.countdown) {
          _applyRoundEndFromNetwork(msg);
        }
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
      case 'emote':
        final e = msg['e'] as String?;
        if (e != null && e.isNotEmpty) _showOppEmote(e);
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
    // Gol juice'u: güçlü sarsıntı + kutlama patlaması.
    fx.addShake(10);
    fx.burst(
      GameConstants.vw / 2,
      GameConstants.vh / 2,
      count: 34,
      color: winner == mySeat ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
      speed: 5,
      size: 3.2,
    );
    if (winner == mySeat) {
      audio?.playWin();
    } else {
      audio?.playLose();
    }

    _markVisualGeneration();
    onRoundEnd?.call();
    notifyListeners();
  }

  void _sendState({bool force = false}) {
    if (aiMode || !isOnlineHost) return;
    if (!force) {
      final anyMoving = discs.any((d) => d.vvx.abs() > 0.01 || d.vvy.abs() > 0.01);
      if (!anyMoving) return;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastStateSentMs < 40) return;
      final sig = _discStateSignature();
      if (sig == _lastSentStateSig) return;
      _lastSentStateSig = sig;
      _lastStateSentMs = now;
    } else {
      _lastSentStateSig = _discStateSignature();
      _lastStateSentMs = DateTime.now().millisecondsSinceEpoch;
    }

    final discPayload = discs
        .map((d) => [
              (d.vx * 10).round() / 10,
              (d.vy * 10).round() / 10,
              (d.vvx * 100).round() / 100,
              (d.vvy * 100).round() / 100,
            ])
        .toList();

    if (phase == GamePhase.playing && !force) {
      ws.send({'type': 'state', 'discs': discPayload});
      return;
    }

    ws.send({
      'type': 'state',
      'discs': discPayload,
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
    // Gol juice'u: güçlü sarsıntı + kutlama patlaması.
    fx.addShake(10);
    fx.burst(
      GameConstants.vw / 2,
      GameConstants.vh / 2,
      count: 34,
      color: winner == mySeat ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
      speed: 5,
      size: 3.2,
    );
    if (winner == mySeat) {
      audio?.playWin();
      // Bot kaybetti — bazen insan gibi hayıflanır/alkışlar.
      _maybeBotEmote(const ['😅', '😮', '👏']);
    } else {
      audio?.playLose();
      // Bot kazandı — bazen sevinir.
      _maybeBotEmote(const ['🔥', '😎', '🎯']);
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

    // Gizli ranked bot: maç bitince gerçek maç gibi ELO uygula (istemci tarafı).
    if (matchFinished && isBotFallback && isRanked && auth?.user != null) {
      _applyBotEloResult(winner == mySeat);
    }

    _markVisualGeneration();
    onRoundEnd?.call();
    notifyListeners();
  }

  void _applyBotEloResult(bool won) {
    final u = auth!.user!;
    const k = 32;
    final expected = 1 / (1 + math.pow(10, (opponentElo - u.elo) / 400));
    final change = (k * ((won ? 1 : 0) - expected)).round();
    final newElo = (u.elo + change).clamp(0, 9999);
    final newLeague = RankTier.forElo(newElo).name;
    auth!.applyEloResult(newElo: newElo, newLeague: newLeague, won: won);
    auth!.syncEloToFirestore(won, newElo, newLeague);
    pendingEloResult = EloResult(
      won: won,
      eloChange: change,
      newElo: newElo,
      newLeague: newLeague,
    );
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
      _refreshActiveDrags();
      _bumpBoard();
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
    _refreshActiveDrags();
    _bumpBoard();
  }

  void onPointerMove(int pointerId, double vx, double vy) {
    if (localDuoMode) {
      final d = _duoDrags[pointerId];
      if (d == null) return;
      d.currentVx = vx;
      d.currentVy = vy;
      _refreshActiveDrags();
      _bumpBoard();
      return;
    }

    if (drag == null) return;
    drag!.currentVx = vx;
    drag!.currentVy = vy;
    _refreshActiveDrags();
    _bumpBoard();
  }

  void onPointerUp(int pointerId) {
    if (localDuoMode) {
      final d = _duoDrags.remove(pointerId);
      if (d != null) _releaseDrag(d);
      _refreshActiveDrags();
      return;
    }

    if (drag == null) return;
    _releaseDrag(drag!);
    drag = null;
    _refreshActiveDrags();
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
        if (isOnlineHost && !aiMode && !localDuoMode) {
          _sendState(force: true);
        }
      } else {
        discs[dragState.discIndex].vvx = vvx;
        discs[dragState.discIndex].vvy = vvy;
        _localShotDisc = dragState.discIndex;
        _localShotUntilMs = DateTime.now().millisecondsSinceEpoch + 280;
        ws.send({
          'type': 'shot',
          'disc': dragState.discIndex,
          'vvx': vvx,
          'vvy': vvy,
        });
      }
      audio?.playShot();
      _haptic(25);
      // Atış juice'u: güce göre sarsıntı + fırlatılan diskte iz.
      final power = lim / GameConstants.slingMax;
      fx.addShake(1.5 + power * 3.5);
      final d = discs[dragState.discIndex];
      fx.burst(
        d.vx,
        d.vy,
        count: 8,
        color: const Color(0xFFEDE9FE),
        speed: 2.4 + power * 2,
        size: 2.2,
      );
    }
    _bumpBoard();
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
      uiSync.bump();
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
      uiSync.bump();
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
    _myEmoteTimer?.cancel();
    _oppEmoteTimer?.cancel();
    _botEmoteTimer?.cancel();
    ws.disconnect();
    super.dispose();
  }
}

/// Host'tan gelen bir pul-durumu karesi (istemci interpolasyon arabelleği).
class _Snap {
  _Snap({
    required this.rxMs,
    required this.xs,
    required this.ys,
    required this.vxs,
    required this.vys,
  });

  final double rxMs; // istemciye varış zamanı (duvar saati, ms)
  final List<double> xs;
  final List<double> ys;
  final List<double> vxs;
  final List<double> vys;
}
