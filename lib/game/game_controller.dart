import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/career_opponent.dart';
import '../models/disc.dart';
import '../models/rank_tier.dart';
import '../services/api_config.dart';
import '../services/audio_service.dart';
import '../services/auth_service.dart';
import '../services/bot_names.dart';
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

  /// Bir maçta oynanabilecek en fazla raunt. İki raunt kazanan maçı alır;
  /// beraberlikle biten raunt kimseye puan yazmadığı için maç bu sınıra
  /// dayanabilir — o durumda daha çok raunt kazanan maçı alır.
  static const maxRounds = 3;
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
  // Süreli mod: belirlenen süre (sn) dolunca alanında daha az pul kalan kazanır;
  // eşitse beraberlik (kazanan yok). Süre dolmadan bir taraf tamamen boşalırsa
  // maç o anda biter ve alanı boşalan taraf kazanır.
  bool timedMode = false;
  int matchDurationSec = 180;

  /// Süreli raunt eşitlikle bitince verilen ek süre (saniye). Uzatma bir kez
  /// verilir; sonunda skor hâlâ eşitse raunt berabere biter.
  static const extraTimeSec = 10;

  /// Raunt uzatmaya girdiyse true.
  bool inExtraTime = false;

  /// Rauntun toplam süresi — uzatmaya girildiyse ek süre dahil.
  int get roundDurationSec =>
      matchDurationSec + (inExtraTime ? extraTimeSec : 0);
  bool isDraw = false;
  String localPlayerRed = 'Oyuncu 1';
  String localPlayerBlue = 'Oyuncu 2';
  final Map<int, DragState> _duoDrags = {};
  TrainingLayout trainingLayout = TrainingLayout.full;
  String trainingGoalLabel = '';
  CareerOpponent? careerOpponent;
  AiLevel aiLevel = AiLevel.medium;

  /// Bu istemcinin sunucuya bildirdiği ad (openConnection'da atanır).
  String _myName = 'Oyuncu';

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
  double _lastStateSentMs = 0;
  double _lastNetworkBoardBumpMs = 0;
  int? _localShotDisc;
  /// Kendi atışının yerel tahminle akacağı an (monotonik ağ saati, ms).
  double _localShotPredictUntil = 0;
  /// Tahminden ağ otoritesine yumuşak devretme süresi.
  static const double _shotBlendMs = 150;

  final boardRepaint = BoardRepaintNotifier();
  final uiSync = UiSyncNotifier();
  final fx = GameFx();

  static const _physicsStepMs = 1000 / 60;

  // ── Ağ saati ──────────────────────────────────────────────────────────
  // Monotonik: duvar saati (DateTime.now) NTP düzeltmesiyle geriye/ileriye
  // sıçrayabilir ve interpolation zaman eksenini bozar. Stopwatch sıçramaz.
  // Host bu saatle damgalar, client kendi saatiyle ölçer; aradaki sabit fark
  // (_clockOffset) kestirilir — mutlak saatlerin uyuşması gerekmez.
  final Stopwatch _netClock = Stopwatch()..start();
  double get _nowNet => _netClock.elapsedMicroseconds / 1000.0;

  /// Host: gönderilen her state paketine artan sıra numarası.
  int _stateSeq = 0;

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
  /// Sürüm uyuşmazlığı: sunucu maçı reddetti. [outdated] true → BU cihaz eski.
  void Function(bool outdated)? onNeedUpdate;
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
      // Sunucu-otoriteli: fizik artık sunucuda çalışır. İKİ koltuk da saf
      // istemcidir (interpolasyon + şut gönderimi); hiçbiri fizik/host değil.
      // Böylece rakip pulları kararlı sunucu zaman çizgisinden akıcı çizilir.
      if (!aiMode) isOnlineHost = false;
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
    // Monotonik: duvar saati geriye sıçrarsa bu kapı kilitlenir ve tahta
    // yeniden çizilmez (görünür donma).
    final now = _nowNet;
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
  /// Tek pul entegrasyonu. [steps] = geçen 60Hz-adım sayısı (kare dt / adım).
  /// Client artık kare başına (108/120Hz) çağırdığı için sabit "1 adım"
  /// varsaymak pulu 1.8× hızlandırırdı; hareket ve sürtünme geçen süreyle
  /// ölçeklenir → kare hızından bağımsız, doğru tahmin.
  void _integrateOne(Disc d, [double steps = 1.0]) {
    if (steps <= 0) return;
    d.vx += d.vvx * steps;
    d.vy += d.vvy * steps;
    final fr = math.pow(GameConstants.friction, steps).toDouble();
    d.vvx *= fr;
    d.vvy *= fr;
    if (d.vvx.abs() < 0.03) d.vvx = 0;
    if (d.vvy.abs() < 0.03) d.vvy = 0;
  }

  // ── İstemci ağ senkronu: snapshot interpolation (gönderen-zaman ekseni) ──
  // Host'tan gelen kareler geldiği anda uygulanmaz. Her kare HOST'un saatiyle
  // (`t`) damgalıdır; client host saatini kendi saatine çevirip (_clockOffset)
  // ~D ms "geçmişten" oynatır. Kritik nokta: zaman ekseni VARIŞ zamanı değil
  // GÖNDERİM zamanıdır — böylece ağ jitter'ı oynatma hızını bozamaz, sadece
  // arabellek derinliğini etkiler.
  // 60Hz gönderim + tipik iyi bağlantı (Jit<10) için daha sıkı tampon: rakip
  // pulları ~100ms yerine ~60ms geçmişten oynatılır → belirgin daha "canlı"/
  // tepkisel his. Jitter yükselince (kötü ağ) uyarlanır ve max'a kadar çıkar.
  static const _interpMinMs = 55.0;
  // Kötü/burst bağlantıda (ör. 5G, yüksek ping) tampon açlığını önlemek için
  // gecikmenin çıkabileceği SERT tavan. İyi bağlantıda kullanılmaz.
  static const _interpMaxHardMs = 260.0;
  /// Pozisyon farkı bunu aşarsa doğrudan atama yerine hızlı-yumuşak düzeltme
  /// (ışınlanma değil, ~3-4 karelik kayma) uygulanır.
  static const _teleportThreshold = GameConstants.discRadius * 3; // 66
  /// Bunu aşarsa gerçek kopmadır (yeniden bağlanma/dev sıçrama) → anında ışınla.
  static const _hardSnapThreshold = GameConstants.discRadius * 8; // 176

  final List<_Snap> _snapBuf = [];
  double _interpDelayMs = 100;
  int _lastSeq = -1;
  /// Son ~1.5sn'deki varış aralıkları — burst/kötü bağlantıda en büyük boşluğu
  /// ölçüp tampon derinliğini (interp gecikmesi) ona göre uyarlar (açlık = yok).
  final List<({double gap, double at})> _rxGapWin = [];

  /// Monotonik oynatma saati. renderT'yi her karede `now+offset-delay` ile
  /// hesaplamak, offset/delay kestirimleri oynadıkça oynatma hızını dalgalandırır
  /// (judder) ve bazen zamanı geri alır (geri kayma). Bunun yerine playhead
  /// gerçek zamanda düzgün ilerler, hedefe yavaşça yakınsar → sabit oynatma hızı.
  double? _playhead;
  double _lastAdvanceNet = 0;

  /// hostSaati − yerelSaat. Kayan pencerede MAKSİMUM ile kestirilir:
  /// örnek = O − d (d = tek yön gecikme ≥ 0), yani en az gecikmiş paket
  /// gerçek ofsete en yakınıdır.
  double? _clockOffset;
  final List<({double sample, double at})> _offsetWin = [];
  double _jitterMs = 0;
  double? _lastRxNet;
  double? _lastSnapT;

  // --- Test/ölçüm göstergesi (kNetDebugHud) ---
  final List<double> _rxTimes = [];
  double debugFps = 0;
  bool get isNetClient => !aiMode && !isOnlineHost && !localDuoMode;
  String get netDebugLine {
    final off = _clockOffset?.round() ?? 0;
    // "SA" = Server-Authoritative sürüm işareti (bu build'i teyit için).
    return 'SA·v40  FPS ${debugFps.round()}  RX ${_rxTimes.length}/s  '
        'Buf ${_snapBuf.length}  Dly ${_interpDelayMs.round()}  Off $off  Jit ${_jitterMs.round()}';
  }

  /// Ağ oturumu değişince (yeniden bağlanma/yeni maç) tüm ağ durumunu sıfırla —
  /// bayat kareler ve eski saat ofseti yeni oturuma taşınmasın.
  void _resetNetSync() {
    _snapBuf.clear();
    _offsetWin.clear();
    _rxGapWin.clear();
    _clockOffset = null;
    _lastSeq = -1;
    _jitterMs = 0;
    _lastRxNet = null;
    _lastSnapT = null;
    _interpDelayMs = 100;
    _playhead = null;
    _lastAdvanceNet = 0;
  }

  bool _bufferSnapshot(List states, {int? seq, num? hostT}) {
    final rx = _nowNet;

    // 1) Sıra koruması: bayat veya tekrar eden kare uygulanmaz.
    //    (WebSocket=TCP sırayı korur; bu koruma yeniden bağlanma sonrası
    //     gecikmiş kareler ve tekrar gönderimler içindir.)
    if (seq != null) {
      if (_lastSeq >= 0 && seq <= _lastSeq) return false;
      _lastSeq = seq;
    }

    // 2) Host damgası yoksa (eski sürüm istemci) varış zamanına düş.
    final t = (hostT ?? rx).toDouble();

    // 3) Saat ofseti kestirimi: pencere içi maksimum.
    final sample = t - rx;
    _offsetWin.add((sample: sample, at: rx));
    _offsetWin.removeWhere((e) => rx - e.at > 2000); // ~2 sn pencere
    var maxSample = _offsetWin.first.sample;
    for (final e in _offsetWin) {
      if (e.sample > maxSample) maxSample = e.sample;
    }
    // Ofset YUMUŞAK takip edilir. Yumuşatmanın doğru yeri burası: ham
    // kestirim sıçrarsa _renderHostTime zıplar ve TÜM pullar aynı anda
    // kayar. Ofseti süzmek, pozisyona gecikme eklemeden süreksizliği önler.
    if (_clockOffset == null) {
      _clockOffset = maxSample;
    } else {
      final diff = maxSample - _clockOffset!;
      // Büyük fark = gerçek kopma/yeniden senkron → tek seferde otur.
      _clockOffset = diff.abs() > 250 ? maxSample : _clockOffset! + diff * 0.05;
    }

    // 4) Jitter ölçümü: varış aralığı ile gönderim aralığı farkı (EWMA).
    if (_lastRxNet != null && _lastSnapT != null) {
      final rxGap = rx - _lastRxNet!;
      final txGap = t - _lastSnapT!;
      final dev = (rxGap - txGap).abs();
      _jitterMs = _jitterMs * 0.9 + dev * 0.1;

      // Gerçek burst boşluğu: son ~1.5sn'deki EN BÜYÜK varış aralığı. 5G/kötü
      // ağda paketler öbek öbek gelir; EWMA jitter bunu kaçırır ama tampon 1'e
      // düşüp açlık (ışınlanma/hızlanma) yaratır. Gecikme, bu boşluğu karşılamalı.
      _rxGapWin.add((gap: rxGap, at: rx));
      _rxGapWin.removeWhere((e) => rx - e.at > 1500);
      var maxGap = 0.0;
      for (final e in _rxGapWin) {
        if (e.gap > maxGap) maxGap = e.gap;
      }

      // Hedef gecikme = hem jitter'ı hem de en büyük burst boşluğunu (1.4× marj)
      // karşılayacak kadar. İyi bağlantıda maxGap küçük → gecikme düşük kalır;
      // kötü bağlantıda derinleşir (açlık olmaz).
      final jitterTarget = _interpMinMs + _jitterMs * 2;
      final gapTarget = maxGap * 1.4;
      final target =
          math.max(jitterTarget, gapTarget).clamp(_interpMinMs, _interpMaxHardMs);
      // Asimetrik: açlığı önlemek için HIZLI derinleş (0.20), bağlantı düzelince
      // gecikmeyi YAVAŞ azalt (0.01) — böylece pul lag'i gereksiz artıp azalmaz.
      final rate = target > _interpDelayMs ? 0.20 : 0.01;
      _interpDelayMs += (target - _interpDelayMs) * rate;
    }
    _lastRxNet = rx;
    _lastSnapT = t;

    final n = states.length;
    final s = _Snap(
      t: t,
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
    if (_snapBuf.length > 24) _snapBuf.removeAt(0);
    _rxTimes.add(rx);
    _rxTimes.removeWhere((t) => rx - t > 1000);
    return true;
  }

  /// Şu an oynatılması gereken host zamanı.
  double get _renderHostTime => _nowNet + (_clockOffset ?? 0) - _interpDelayMs;

  /// Oynatılacak arabellek verisi var mı? (ticker uyanık kalsın)
  bool get _clientSnapPending {
    if (_snapBuf.isEmpty) return false;
    // Son karenin oynatma anı geçene dek uyanık kal.
    if (_renderHostTime < _snapBuf.last.t + 250) return true;
    // Zaman çizgisi bitti ama hedefe tam oturmadıysa oturana dek devam et.
    // (Madde 20: top tamamen dursa bile senkron bozulmasın.)
    return !_settledOnLastSnap;
  }

  /// Son kareye (host'un nihai duruş pozisyonu) tam oturduk mu?
  /// Üstel yakınsama matematiksel olarak sıfıra inmez; bu eşik sayesinde
  /// ticker, kalıcı bir kayma bırakmadan duruyor.
  bool get _settledOnLastSnap {
    if (_snapBuf.isEmpty) return true;
    final s = _snapBuf.last;
    final n = math.min(discs.length, s.xs.length);
    for (var i = 0; i < n; i++) {
      final dx = s.xs[i] - discs[i].vx;
      final dy = s.ys[i] - discs[i].vy;
      if (dx * dx + dy * dy > 0.01) return false; // ~0.1 birim
    }
    return true;
  }

  /// Hedefe doğru yumuşak düzeltme; sadece gerçekten kopmuşsa ışınlar.
  /// Frame-bağımsız: kapanma oranı geçen süreye (dtMs) göre hesaplanır.
  /// Rakip pulu, interpolasyonun ürettiği hedefe oturtur.
  ///
  /// ÖNEMLİ: Hedef ham paket değil, `lerp(s0, s1, f)` ile hesaplanmış
  /// SÜREKLİ bir zaman fonksiyonudur (f monotonik saatle düzgün ilerler),
  /// yani zaten pürüzsüzdür. Üstüne yumuşatma koymak akıcılık katmaz,
  /// yalnızca kalıcı gecikme yaratır: Δ×(1−k)/k ≈ 4.5Δ ≈ bir pul yarıçapı.
  /// Bu yüzden hedef doğrudan uygulanır — profesyonel oyunlarda uzak
  /// varlıklar (Source/Overwatch/Rocket League) böyle çizilir.
  ///
  /// `_teleportThreshold` yalnızca bir emniyet: normal akışta hata ~0'dır,
  /// ama uzun donma/yeniden bağlanma sonrası render ara-kare tamponunun
  /// dev bir sıçramayı yumuşatmaya çalışmasını engeller.
  void _applyNetTarget(Disc d, int i, double tx, double ty, double tvx, double tvy) {
    final dx = tx - d.vx;
    final dy = ty - d.vy;
    final err2 = dx * dx + dy * dy;

    if (err2 <= _teleportThreshold * _teleportThreshold) {
      // Normal akış: hedefi DOĞRUDAN uygula (gecikmesiz, net).
      d.vx = tx;
      d.vy = ty;
    } else if (err2 > _hardSnapThreshold * _hardSnapThreshold) {
      // Gerçek kopma (yeniden bağlanma/dev sıçrama): anında ışınla + prev'i taşı
      // ki painter araya sahte bir "uçuş" çizmesin.
      d.vx = tx;
      d.vy = ty;
      if (i < _prevVx.length) {
        _prevVx[i] = tx;
        _prevVy[i] = ty;
      }
    } else {
      // Eşik ile sert-snap arası: ANINDA zıplama yerine hızlı-yumuşak kayma
      // (kare başına %40 → ~3-4 karede varır). Işınlanma yerine kısa düzeltme.
      d.vx += dx * 0.4;
      d.vy += dy * 0.4;
    }
    d.vvx = tvx;
    d.vvy = tvy;
  }

  /// Yerel şutun devri için: ilgili pulun GECİKMESİZ (present) ağ tahmini.
  /// İnterpolasyon gecikmesi host'un geçmişini gösterir; devir bu geçmişe
  /// yapılırsa pul zamanda geriye sıçrar (titreme/geri kayma). Son snapshot'ı
  /// present host-zamanına extrapolate ederek "şu an nerede" tahminini üretiriz.
  ({double x, double y})? _presentNetPos(int i) {
    if (_snapBuf.isEmpty) return null;
    final last = _snapBuf.last;
    if (i >= last.xs.length) return null;
    final ageHost = ((_nowNet + (_clockOffset ?? 0)) - last.t).clamp(0.0, 300.0);
    final steps = ageHost / _physicsStepMs;
    return (x: last.xs[i] + last.vxs[i] * steps, y: last.ys[i] + last.vys[i] * steps);
  }

  /// Client ağ adımı: host-zaman ekseninde snapshot interpolation.
  /// Fizik burada çalışmaz — host'un ürettiği zaman çizgisi oynatılır.
  void _clientNetAdvance() {
    final nowNet = _nowNet;
    // Kare başına gerçek geçen süre → 60Hz-adım cinsinden (tahmin + playhead).
    final dtReal = _lastAdvanceNet == 0
        ? 0.0
        : (nowNet - _lastAdvanceNet).clamp(0.0, 100.0);
    _lastAdvanceNet = nowNet;
    final steps = dtReal / _physicsStepMs;

    // Kendi atışın: host yankısı gelene dek yerel tahmin (prediction).
    // Süre dolunca ANINDA snap yerine ~150 ms harmanla devredilir (aşağıda).
    final predicting = nowNet < _localShotPredictUntil;
    final localIdx = predicting ? _localShotDisc : null;
    if (localIdx != null && localIdx < discs.length) {
      _integrateOne(discs[localIdx], steps);
      // Tahmin de duvarlardan sekmeli — yoksa fırlatılan pul, sunucu düzeltmesi
      // gelene dek DUVARDAN GEÇİP geri sıçrar (kullanıcının gördüğü hata).
      PhysicsEngine.applyWallsSingle(discs[localIdx]);
    }
    // Devretme harmanı: 0 → tam ağ otoritesi, 1 → tam yerel tahmin.
    var handoff = 0.0;
    final blendIdx = _localShotDisc;
    if (!predicting && blendIdx != null) {
      final since = nowNet - _localShotPredictUntil;
      if (since < _shotBlendMs) {
        handoff = 1 - (since / _shotBlendMs);
      } else {
        // Harman bitti — ama pulu geçmiş-interpolasyona ANINDA snap ETME (pul
        // hâlâ hızlıyken ~78ms geriye sıçrar = kendi pulunda takılma). Pul
        // sunucuda DURANA kadar present-net'te tut; durunca present ve geçmiş
        // aynı noktada birleşir → sıçramasız normal akışa bırakılır.
        var rested = true;
        if (_snapBuf.isNotEmpty && blendIdx < _snapBuf.last.vxs.length) {
          final vx = _snapBuf.last.vxs[blendIdx];
          final vy = _snapBuf.last.vys[blendIdx];
          rested = (vx * vx + vy * vy) < 0.02;
        }
        if (rested || since > 2500) _localShotDisc = null; // emniyet: 2.5sn
      }
    }

    if (_snapBuf.isEmpty) {
      // Hiç kare yok: elde veri olmadığı için hafif tahminle akıt.
      for (var i = 0; i < discs.length; i++) {
        if (i == localIdx) continue;
        _integrateOne(discs[i], steps);
        PhysicsEngine.applyWallsSingle(discs[i]); // açlıkta da duvardan geçme
      }
      return;
    }

    // Monotonik oynatma saati: hedef = now + offset - delay, ama playhead'i
    // gerçek geçen süre kadar ilerletip hedefe YAVAŞÇA yakınsatarak dalgalanmayı
    // (judder) ve geri kaymayı engelle. Sabit oynatma hızı = pürüzsüz hareket.
    final target = nowNet + (_clockOffset ?? 0) - _interpDelayMs;
    if (_playhead == null) {
      _playhead = target;
    } else {
      var ph = _playhead! + dtReal;
      final err = target - ph;
      if (err.abs() > 200) {
        ph = target; // büyük sapma (donma/yeniden bağlanma) → tek seferde otur.
      } else {
        // Oynatma HIZINI ~1x'e KİLİTLE. Düzeltme, geçen gerçek sürenin en çok
        // ~%3'ü kadar olabilir → pullar asla görünür şekilde "bir anda
        // hızlanmaz" (kullanıcının gördüğü sistematik anormal hareket).
        // Ofset/gecikme kestirimi oynasa bile sürüklenme, birkaç saniyede fark
        // edilmeden kapanır. Eskiden `err*0.05` idi ve ~%8 hız sıçratıyordu.
        final maxCorr = (dtReal * 0.03).clamp(0.05, 4.0);
        ph += err.clamp(-maxCorr, maxCorr);
      }
      _playhead = ph;
    }
    final renderT = _playhead!;

    // Oynatma anını geçmiş kareleri düş (s0 = bir önceki kare kalsın).
    while (_snapBuf.length >= 2 && _snapBuf[1].t <= renderT) {
      _snapBuf.removeAt(0);
    }

    final s0 = _snapBuf[0];
    final hasNext = _snapBuf.length >= 2;

    // Hedef durumu belirle: iki kare arası lerp (asıl yol) veya
    // arabellek açlığında son kareden kısa extrapolasyon.
    late final List<double> tx, ty, tvx, tvy;
    final n = hasNext
        ? math.min(discs.length, math.min(s0.xs.length, _snapBuf[1].xs.length))
        : math.min(discs.length, s0.xs.length);
    tx = List<double>.filled(n, 0);
    ty = List<double>.filled(n, 0);
    tvx = List<double>.filled(n, 0);
    tvy = List<double>.filled(n, 0);

    if (hasNext && renderT > s0.t) {
      final s1 = _snapBuf[1];
      final span = (s1.t - s0.t).clamp(1.0, 1000.0);
      final f = ((renderT - s0.t) / span).clamp(0.0, 1.0);
      final stepsInSpan = span / _physicsStepMs;
      // Hermite (kübik) interpolation: iki snapshot'ın POZİSYON ve HIZINI kullanır.
      // Sabit hızda doğrusalla birebir aynıdır (doğru); çarpışmada ise pulun
      // gerçek eğrisini takip eder → doğrusal interpolasyonun "köşe kesme"
      // artefaktı (kullanıcının gördüğü anormal hareket) kaybolur. Profesyonel
      // multiplayer oyunların uzak-varlık interpolasyonu böyledir.
      final f2 = f * f;
      final f3 = f2 * f;
      final h00 = 2 * f3 - 3 * f2 + 1;
      final h10 = f3 - 2 * f2 + f;
      final h01 = -2 * f3 + 3 * f2;
      final h11 = f3 - f2;
      for (var i = 0; i < n; i++) {
        // Teğet = hızın span boyunca ürettiği yer değiştirme (vxs = adım/başına hız).
        final m0x = s0.vxs[i] * stepsInSpan;
        final m1x = _snapBuf[1].vxs[i] * stepsInSpan;
        final m0y = s0.vys[i] * stepsInSpan;
        final m1y = _snapBuf[1].vys[i] * stepsInSpan;
        tx[i] = h00 * s0.xs[i] + h10 * m0x + h01 * s1.xs[i] + h11 * m1x;
        ty[i] = h00 * s0.ys[i] + h10 * m0y + h01 * s1.ys[i] + h11 * m1y;
        tvx[i] = (s1.xs[i] - s0.xs[i]) / stepsInSpan;
        tvy[i] = (s1.ys[i] - s0.ys[i]) / stepsInSpan;
      }
    } else {
      // Arabellek açlığı veya henüz oynatma zamanı gelmedi:
      // son kareyi baz al, gecikme kadar kendi hızıyla ileri taşı (kısa,
      // sınırlı extrapolasyon — 150 ms üstü tahmin edilmez, sabit kalır).
      final ahead = hasNext ? 0.0 : (renderT - s0.t).clamp(0.0, 150.0);
      final steps = ahead / _physicsStepMs;
      for (var i = 0; i < n; i++) {
        tx[i] = s0.xs[i] + s0.vxs[i] * steps;
        ty[i] = s0.ys[i] + s0.vys[i] * steps;
        tvx[i] = s0.vxs[i];
        tvy[i] = s0.vys[i];
      }
    }

    // Hedefe yumuşak sür — hiçbir yerde ham pozisyon doğrudan atanmaz;
    // yalnızca teleport eşiği aşılırsa (_steerTo içinde) ışınlanır.
    for (var i = 0; i < n; i++) {
      if (i == localIdx) continue;
      final d = discs[i];
      if (i == blendIdx) {
        // Kendi pulun: PRESENT (şimdiki) ağ tahminine oturt — gecikmeli tx/ty'ye
        // DEĞİL (yoksa geriye sıçrar). Durana kadar present-net'te kalır.
        final present = _presentNetPos(i);
        final nx = present?.x ?? tx[i];
        final ny = present?.y ?? ty[i];
        final double gx, gy;
        if (handoff > 0) {
          // Yerel tahminden present-net'e yumuşak geçiş (ilk 150ms).
          gx = d.vx * handoff + nx * (1 - handoff);
          gy = d.vy * handoff + ny * (1 - handoff);
        } else {
          gx = nx; // harman sonrası: saf present-net (pul durana dek)
          gy = ny;
        }
        _applyNetTarget(d, i, gx, gy, tvx[i], tvy[i]);
      } else {
        _applyNetTarget(d, i, tx[i], ty[i], tvx[i], tvy[i]);
      }
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
      if (isClient) {
        final clientDrifting = discs.any((d) => d.vvx.abs() > 0.02 || d.vvy.abs() > 0.02) ||
            _clientSnapPending;
        if (!clientDrifting) {
          _lastTickWallMs = 0;
          return false;
        }
      } else if (!aiMode) {
        // Host/yerel maç: tahta dururken input bekle (CPU tasarrufu).
        _lastTickWallMs = 0;
        return false;
      }
      // aiMode: düşürme — bot, tahta dururken de kendi hamlesini başlatabilsin
      // (oyuncunun ilk atışını beklemez).
    }

    if (_lastTickWallMs == 0) _lastTickWallMs = nowMs;
    var delta = nowMs - _lastTickWallMs;
    _lastTickWallMs = nowMs;
    // Pause→resume'da Ticker.elapsed sıfırlanır; nowMs geriye sıçrayıp delta
    // negatif olabilir. Negatif delta fizik birikimini bozup oyunu dondurur —
    // taze kare gibi ele al.
    if (delta < 0) delta = 0;
    if (delta > 100) delta = 100;

    // Ağ istemcisi: interpolasyonu HER EKRAN KARESİNDE bir kez, o anki zamanda
    // örnekle. Rakip pullarını host'un 60Hz fizik-adımı + painter alpha alt-kare
    // hattından geçirmek, 108/120Hz ekranla beat (vuruşma) oluşturup periyodik
    // judder üretiyordu (ölçüm: sabit hız girişinde bile %20 hız dalgalanması,
    // her ~60ms'de yarı hıza düşen hitch). Her kare doğrudan örnekleyip prev=cur
    // yapınca painter alpha'sı no-op olur ve _clientNetAdvance'in monotonik
    // playhead'i düzgün hareketi tam kare hızında çizer (%20 → %0.6).
    if (isClient) {
      fx.step();
      _clientNetAdvance();
      _capturePrevPositions();
      _frameCount++;
      _syncUiIfDiscCountsChanged();
      return true;
    }

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
      } else if (!aiMode && isOnlineHost && _frameCount % 2 == 0) {
        _sendState();
      }

      if (moving == 0 && _lastMovingDiscs > 0) {
        PhysicsEngine.settleGateDiscs(discs);
        if (isOnlineHost && !aiMode) _sendState(force: true);
      }
      final winner = PhysicsEngine.checkWinner(discs);
      if (winner != null) {
        // Süreli mod: süre dolmadan bir taraf tamamen boşalırsa maç orada biter.
        if (timedMode) {
          _endTimedMatch(clearWinner: winner);
        } else {
          _endRound(winner, broadcast: true);
        }
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
    _localShotPredictUntil = 0;
    _resetNetSync();
    aiBot.reset();
    inExtraTime = false;
    discs = trainingMode
        ? PhysicsEngine.initTrainingDiscs(trainingLayout)
        : PhysicsEngine.initDiscs();
    _initPrevFromCurrent();
    phase = GamePhase.idle;
    lastWinner = null;
    isDraw = false;
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
          if (timedMode &&
              phase == GamePhase.playing &&
              seconds >= roundDurationSec) {
            _endTimedMatch();
          }
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
    timedMode = false;
    careerOpponent = null;
    isBotFallback = botFallback;
    // Gizli bot: ranked kuyruğunda rakip bulunamayınca bota düşülse de
    // oyuncu için maç ranked görünmeli (ELO değişir, "bot" ibaresi yok).
    isRanked = botFallback && ranked;
    aiLevel = level;
    _setSeat(0);
    if (botFallback) {
      final profile = BotFallbackProfile.generate(
        playerElo: auth?.user?.elo ?? 1000,
        namePool: BotNames.pool,
      );
      roomCode = profile.roomCode;
      opponentName = profile.name;
      opponentElo = profile.elo;
      opponentLeague = profile.league;
      // Gerçek oyuncu hissi: rakip bazen premium pul kullanır.
      opponentDiscColor = profile.discId;
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

  /// Süreli mod: gizli bota karşı, belirli süreyle. Süre dolunca alanında daha
  /// az pul kalan kazanır; eşitse beraberlik.
  void startTimedGame(int durationSec, {AiLevel level = AiLevel.hard}) {
    ws.disconnect();
    aiMode = true;
    localDuoMode = false;
    careerMode = false;
    trainingMode = false;
    careerOpponent = null;
    isBotFallback = true;
    isRanked = false;
    timedMode = true;
    matchDurationSec = durationSec;
    aiLevel = level;
    _setSeat(0);
    final profile = BotFallbackProfile.generate(
      playerElo: auth?.user?.elo ?? 1000,
      namePool: BotNames.pool,
    );
    roomCode = profile.roomCode;
    opponentName = profile.name;
    opponentElo = profile.elo;
    opponentLeague = profile.league;
    opponentDiscColor = profile.discId;
    resetMatch();
    startCountdown();
    _maybeBotEmote(const ['👍', '🤝', '😎'], chance: 0.45);
  }

  /// Raunt sonucunu işler ve maçın bitip bitmediğine karar verir.
  ///
  /// Maç en fazla [maxRounds] raunttur, [roundsToWin] raunt kazanan maçı alır.
  /// Beraberlikle biten raunt kimseye puan yazmaz; raunt hakkı dolduğunda
  /// daha çok raunt kazanan maçı alır, eşitlikte maç berabere biter.
  @visibleForTesting
  void scoreRound(int? roundWinner) {
    if (roundWinner != null) roundWins[roundWinner]++;
    currentRound++;

    final decided =
        roundWinner != null && roundWins[roundWinner] >= roundsToWin;
    matchFinished = decided || currentRound > maxRounds;

    if (matchFinished && !decided) {
      // Raunt hakkı bitti ama kimse ikiye ulaşamadı: en az bir raunt berabere
      // bitmiş demektir. Maçı daha çok raunt kazanan alır.
      if (roundWins[0] == roundWins[1]) {
        isDraw = true;
        lastWinner = null;
      } else {
        isDraw = false;
        lastWinner = roundWins[0] > roundWins[1] ? 0 : 1;
      }
    }
  }

  /// Süreli mod bitişi. Süre dolunca alanında daha az pul kalan kazanır;
  /// [clearWinner] verilirse (bir taraf süre dolmadan tamamen boşaldı) sayım
  /// yapılmadan doğrudan o taraf kazanır.
  void _endTimedMatch({int? clearWinner}) {
    if (phase != GamePhase.playing) return;
    int? winner;
    if (clearWinner != null) {
      winner = clearWinner;
    } else {
      // Üst yarı = mavi (seat 1 / bot), alt yarı = kırmızı (seat 0 / oyuncu).
      final topCount = discs.where((d) => d.vy < GameConstants.vHalf).length;
      final bottomCount = discs.length - topCount;
      if (bottomCount < topCount) {
        winner = 0; // oyuncunun alanında daha az pul → oyuncu kazandı
      } else if (topCount < bottomCount) {
        winner = 1; // botun alanında daha az pul → bot kazandı
      } else {
        winner = null; // eşit → beraberlik
      }
    }
    // Süre doldu ve skor eşit: raunt berabere kapanmadan önce bir kez
    // uzatma verilir. Sayaç çalışmaya devam eder, uzatma bitince buraya
    // yeniden gelinir ve bu kez beraberlik kabul edilir.
    if (winner == null && !inExtraTime) {
      inExtraTime = true;
      fx.addShake(5);
      _haptic(25);
      _markVisualGeneration();
      notifyListeners();
      return;
    }

    _secTimer?.cancel();
    _afkTimer?.cancel();
    phase = GamePhase.gameover;
    fx.addShake(8);
    if (winner == null) {
      isDraw = true;
      lastWinner = null;
      scoreRound(null);
    } else {
      isDraw = false;
      lastWinner = winner;
      scoreRound(winner);
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
        _maybeBotEmote(const ['😅', '😮', '👏']);
      } else {
        audio?.playLose();
        _maybeBotEmote(const ['🔥', '😎', '🎯']);
      }
    }
    _markVisualGeneration();
    onRoundEnd?.call();
    notifyListeners();
  }

  void startCareerGame(CareerOpponent opponent) {
    ws.disconnect();
    aiMode = true;
    localDuoMode = false;
    careerMode = true;
    trainingMode = false;
    timedMode = false;
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
    timedMode = false;
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
    timedMode = false;
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
    timedMode = false;
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
    _myName = name;
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
    // Haritayı AÇIKÇA kur — null-aware harita elemanı (`'idToken': ?idToken`)
    // release AOT'ta sonraki alanları (proto dahil) düşürebiliyor; debug/JIT'te
    // sorunsuz. Bu yüzden tüm release build'ler proto göndermeyip "güncel değil"
    // hatası veriyordu. Açık kurulum bunu kesin engeller.
    final loginMsg = <String, dynamic>{
      'type': 'login',
      'uid': uid,
      'name': name,
      'isAnonymous': isAnonymous,
      // Sunucu-otoriteli protokol sürümü. Sunucu, iki oyuncunun sürümü
      // eşleşmezse maçı başlatmaz (eski istemci + yeni istemci = ışınlanma).
      'proto': kProtocolVersion,
    };
    if (idToken != null) loginMsg['idToken'] = idToken;
    ws.send(loginMsg);
    return true;
  }

  void joinRoom(String code) {
    // Ad DA gönderilmeli: sunucu oda koltuğunun adını `login`'de kaydettiği
    // profilden değil, `join` mesajından okuyor (server.js Room.join). Ad
    // gönderilmezse iki oyuncu da rakibini "Oyuncu" olarak görür.
    ws.send({'type': 'join', 'room': code, 'name': _myName});
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
        // Kopma boyunca biriken bayat kareler ve eski saat ofseti atılır;
        // host yeni bir seq/t serisiyle devam edecek.
        _resetNetSync();
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
          boardChanged = _bufferSnapshot(
            msg['discs'] as List,
            seq: (msg['seq'] as num?)?.toInt(),
            hostT: msg['t'] as num?,
          );
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
      case 'needUpdate':
        // Sürüm uyuşmazlığı: maç başlatılmadı. Sessiz ışınlanma yerine net uyarı.
        final outdated = msg['outdated'] as bool? ?? true;
        phase = GamePhase.idle;
        onToast?.call(outdated
            ? 'Uygulaman güncel değil — en son sürüme güncelle.'
            : 'Rakibin uygulaması eski — güncellemesi gerekiyor.');
        onNeedUpdate?.call(outdated);
        onOpponentLeft?.call();
        notifyListeners();
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
      // Monotonik saat: duvar saati (DateTime.now) NTP ile GERİYE sıçrarsa
      // fark negatife düşer, `< 40` sürekli doğru olur ve gönderim tamamen
      // durur — rakip için oyun donar. Stopwatch geri gitmez.
      final now = _nowNet;
      if (now - _lastStateSentMs < 28) return;
      final sig = _discStateSignature();
      if (sig == _lastSentStateSig) return;
      _lastSentStateSig = sig;
      _lastStateSentMs = now;
    } else {
      _lastSentStateSig = _discStateSignature();
      _lastStateSentMs = _nowNet;
    }

    final discPayload = discs
        .map((d) => [
              (d.vx * 10).round() / 10,
              (d.vy * 10).round() / 10,
              (d.vvx * 100).round() / 100,
              (d.vvy * 100).round() / 100,
            ])
        .toList();

    // seq: bayat/tekrar kare koruması.
    // t: HOST'un OYUN-ZAMANI (frameCount × adım) — duvar saati DEĞİL. Fizik her
    // adımda tam 16.6ms oyun-zamanı ilerler; duvar-saati damgası ise host'un kare
    // temposu düzensizse (özellikle emülatör: BlueStacks) pozisyon oyun-zamanında
    // eşit ama damgalar sıkışık/gevşek olur → client bunu judder olarak oynatır.
    // Oyun-zamanı damgası zaman çizgisini host temposundan bağımsız kusursuz
    // düzgün yapar; client interpolation'ı (t ekseninde) tam pürüzsüz çizer.
    // (Ölçüm: jank'lı host + iyi ağda judder %39 → %0.3.)
    final seq = ++_stateSeq;
    final t = (_frameCount * _physicsStepMs).round();

    if (phase == GamePhase.playing && !force) {
      ws.send({'type': 'state', 'seq': seq, 't': t, 'discs': discPayload});
      return;
    }

    ws.send({
      'type': 'state',
      'seq': seq,
      't': t,
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
      'seq': ++_stateSeq,
      't': _nowNet.round(),
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
    isDraw = false;
    scoreRound(winner);
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
      // Yeni maç = yeni rakip. Gizli bot maçlarında oyuncu gerçek biriyle
      // eşleştiğini sanıyor; aynı isimle arka arkaya karşılaşmak yanılsamayı
      // bozar. Kariyer/antrenman/2 kişilik modda rakip sabittir, dokunulmaz.
      if (isBotFallback && !careerMode && !trainingMode && !localDuoMode) {
        _assignNewBotOpponent();
      }
      resetMatch();
      startCountdown();
    } else {
      resetRound();
      startCountdown();
    }
  }

  /// Gizli bot maçı için yeni bir rakip üretir: ad, ELO, lig, pul kozmetiği,
  /// oda kodu ve zorluk seviyesi baştan seçilir.
  void _assignNewBotOpponent() {
    final previousName = opponentName;
    final pick = pickHiddenBotLevel(settings.botMatchesSinceEasy);
    unawaited(settings.setBotMatchesSinceEasy(pick.nextCounter));
    aiLevel = pick.level;

    // Aynı ad üst üste gelmesin: havuz küçükse birkaç deneme sonra kabul et.
    BotFallbackProfile profile;
    var attempts = 0;
    do {
      profile = BotFallbackProfile.generate(
        playerElo: auth?.user?.elo ?? 1000,
        namePool: BotNames.pool,
      );
      attempts++;
    } while (profile.name == previousName && attempts < 5);

    roomCode = profile.roomCode;
    opponentName = profile.name;
    opponentElo = profile.elo;
    opponentLeague = profile.league;
    opponentDiscColor = profile.discId;

    // Ad havuzu lobide tazeleniyor; burada yeniden ağa gitmeye gerek yok.
    // Havuz boşsa generate() yerleşik listeye düşer.
    _maybeBotEmote(const ['👍', '🤝', '😎'], chance: 0.45);
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
        _localShotPredictUntil = _nowNet + 280;
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
    // Ticker yeniden başlarken zamanlamayı sıfırla (donmayı önler).
    _lastTickWallMs = 0;
    _physicsAccum = 0;
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
    required this.t,
    required this.xs,
    required this.ys,
    required this.vxs,
    required this.vys,
  });

  /// HOST'un monotonik saatindeki gönderim anı (ms). Interpolation ekseni
  /// budur — varış zamanı DEĞİL; jitter bağışıklığının temeli.
  final double t;
  final List<double> xs;
  final List<double> ys;
  final List<double> vxs;
  final List<double> vys;
}
