import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../game/ai_bot.dart';
import '../game/game_controller.dart';
import '../l10n/l10n_extension.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../services/share_service.dart';
import '../services/websocket_service.dart';
import '../theme/app_theme.dart';
import '../widgets/yesa_background.dart';
import '../widgets/pucket_button.dart';
import 'app_router.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({
    super.key,
    this.createRoom = false,
    this.joinCode,
    this.timedSeconds,
  });

  final bool createRoom;
  final String? joinCode;

  /// Doluysa: süreli mod. Sahte arama sonrası bu süreyle maç başlar.
  final int? timedSeconds;

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  String _title = '';
  String _roomCode = '——';
  String _message = '';
  bool _showShare = false;
  bool _spinning = true;
  Timer? _msgTimer;
  Timer? _botFallback;
  Timer? _watchdog;
  GameController? _game;
  bool _errorShown = false;

  bool get _showRoomCode => widget.timedSeconds == null && _roomCode != '——';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    // Güvenlik ağı: bağlantı kurulumu (öncesi dahil) 12 sn içinde bir sonuca
    // varmazsa, kullanıcıyı sonsuza kadar "bağlanıyor" ekranında bırakmak
    // yerine bağlantı hatası göster. openConnection tamamlanınca iptal edilir.
    _watchdog = Timer(const Duration(seconds: 12), () {
      if (mounted) _showConnectionError();
    });

    try {
      await _doInit();
    } catch (e, st) {
      debugPrint('LobbyScreen._doInit failed: $e\n$st');
      if (mounted) _showConnectionError();
    }
  }

  Future<void> _doInit() async {
    final l10n = context.l10nRead;

    // Süreli mod rakibi her zaman yapay zekâdır — bu ekranda gerçek eşleştirme
    // aranmıyor. Eskiden burada 3 saniyelik sahte bir "rakip aranıyor" gösterisi
    // dönüyor, sonra "rakip bulundu!" yazıp bota düşülüyordu; hiçbir yerde yapay
    // zekâ olduğu söylenmiyordu. Aldatıcı olan gecikme değil, gecikmenin bir
    // arama gibi sunulmasıydı: ikisi de kaldırıldı.
    if (widget.timedSeconds != null) {
      _watchdog?.cancel();
      final settings = context.read<SettingsService>();
      final firstMatch = !settings.firstMatchPlayed;
      if (firstMatch) await settings.markFirstMatchPlayed();
      if (!mounted) return;

      setState(() {
        // Başlık nötr: bu ekran ~700 ms görünüyor ve hiçbir iddiada bulunmuyor.
        _title = l10n.matchStarting;
        _message = '';
        _roomCode = '';
        _showShare = false;
        _spinning = false;
      });

      if (firstMatch) {
        // İlk deneyim garantili kolay rakiple başlar.
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) _launchAiMatch(AiLevel.easy);
        });
        return;
      }

      final pick = pickBotLevel(settings.botMatchesSinceEasy);
      unawaited(settings.setBotMatchesSinceEasy(pick.nextCounter));
      _botFallback = Timer(const Duration(milliseconds: 700), () {
        if (mounted) _launchAiMatch(pick.level);
      });
      return;
    }

    _title = l10n.lobbyWaiting;
    _message = l10n.lobbyConnecting;

    _game = context.read<GameController>();
    final game = _game!;
    final auth = context.read<AuthService>();

    game.onGameStart = () {
      if (mounted) AppRouter.goGame(context);
    };

    game.onToast = (m) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
      }
    };

    game.addListener(_onGameUpdate);

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
      _showConnectionError();
      return;
    }

    if (widget.createRoom) {
      final code = makeRoomCode();
      setState(() {
        _title = l10n.lobbyRoomCreated;
        _roomCode = code;
        _message = l10n.lobbyWaitFriendShare;
        _showShare = true;
        _spinning = true;
      });
      game.joinRoom(code);
    } else if (widget.joinCode != null) {
      setState(() {
        _title = l10n.lobbyJoining;
        _roomCode = widget.joinCode!;
        _message = l10n.lobbyJoiningRoom;
        _showShare = false;
        _spinning = true;
      });
      game.joinRoom(widget.joinCode!);
    }
  }

  /// Süreli modsa süreli maç, değilse yapay zekâ maçı başlatır.
  void _launchAiMatch(AiLevel level) {
    final secs = widget.timedSeconds;
    if (secs != null) {
      AppRouter.startTimed(context, secs, level: level);
    } else {
      AppRouter.startBotFallback(context, level: level);
    }
  }

  void _onGameUpdate() {
    final game = _game;
    if (game == null || !mounted) return;
    if (game.roomCode.isEmpty) return;
    final l10n = context.l10nRead;

    _botFallback?.cancel();
    _msgTimer?.cancel();
    setState(() {
      _roomCode = game.roomCode;
      if (game.lobbyWaiting) {
        _message = widget.createRoom ? l10n.lobbyWaitFriendShare : l10n.lobbyWaitFriend;
        _showShare = widget.createRoom;
        _spinning = true;
      } else {
        _message = l10n.lobbyOpponentFound;
        _spinning = false;
        _showShare = false;
      }
    });
  }

  void _showConnectionError() {
    if (_errorShown) return;
    _errorShown = true;
    _watchdog?.cancel();
    final l10n = context.l10nRead;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.lobbyConnectionError), duration: const Duration(seconds: 4)),
    );
    Navigator.pop(context);
  }

  void _goBack() {
    _botFallback?.cancel();
    _msgTimer?.cancel();
    _game?.leave();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _msgTimer?.cancel();
    _botFallback?.cancel();
    _watchdog?.cancel();
    _game?.removeListener(_onGameUpdate);
    if (_game != null && _game!.phase == GamePhase.idle) {
      _game!.leave();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cardWidth = MediaQuery.sizeOf(context).width - 48;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: YesaBackground(
        child: SafeArea(
          child: Stack(
              children: [
                Positioned(
                  top: 4,
                  left: 4,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textMuted),
                    onPressed: _goBack,
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _title.isEmpty ? l10n.lobbyWaiting : _title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.green,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: cardWidth,
                          constraints: const BoxConstraints(maxWidth: 340),
                          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              if (_spinning)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: AppColors.green,
                                    ),
                                  ),
                                ),
                              if (_showRoomCode) ...[
                                Text(
                                  l10n.lobbyRoomCode,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textDim,
                                    letterSpacing: 3,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _copyCode,
                                  child: Text(
                                    _roomCode,
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.green,
                                      letterSpacing: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],
                              Text(
                                _message.isEmpty ? l10n.lobbyConnecting : _message,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                  height: 1.55,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_showShare)
                          PucketButton(label: l10n.lobbyShareCode, onPressed: _shareCode),
                        if (_showShare) const SizedBox(height: 12),
                        PucketButton(label: l10n.lobbyBack, secondary: true, onPressed: _goBack),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  void _copyCode() {
    if (_roomCode == '——') return;
    Clipboard.setData(ClipboardData(text: _roomCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10nRead.lobbyCodeCopied(_roomCode))),
    );
  }

  void _shareCode() {
    if (_roomCode == '——') return;
    ShareService.shareRoomInvite(_roomCode);
  }
}
