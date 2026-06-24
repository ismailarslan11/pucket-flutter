import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../game/game_controller.dart';
import '../services/auth_service.dart';
import '../services/websocket_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pucket_button.dart';
import 'app_router.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({
    super.key,
    this.quickMatch = false,
    this.createRoom = false,
    this.joinCode,
  });

  final bool quickMatch;
  final bool createRoom;
  final String? joinCode;

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  String _title = 'BEKLENIYOR';
  String _roomCode = '——';
  String _message = 'Bağlanıyor...';
  bool _showShare = false;
  bool _spinning = true;
  Timer? _msgTimer;
  Timer? _botFallback;
  GameController? _game;

  bool get _showRoomCode => !widget.quickMatch && _roomCode != '——';

  static const _matchMsgs = [
    'Yakında ELO eşleşmesi aranıyor...',
    'Oyuncu bekleniyor...',
    'Bağlanılıyor...',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
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

    final ok = await game.openConnection(uid: auth.getUid(), name: auth.getName());
    if (!mounted) return;
    if (!ok) {
      if (widget.quickMatch && mounted) {
        AppRouter.startBotFallback(context);
        return;
      }
      _showConnectionError();
      return;
    }

    if (widget.quickMatch) {
      setState(() {
        _title = 'EŞLEŞTİRİLİYOR';
        _message = 'Rakip aranıyor...';
        _roomCode = '——';
        _showShare = false;
        _spinning = true;
      });
      game.joinRoom('');
      var idx = 0;
      _msgTimer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
        if (!mounted) return;
        setState(() {
          idx = (idx + 1) % _matchMsgs.length;
          _message = _matchMsgs[idx];
        });
      });
      _botFallback = Timer(const Duration(seconds: 8), () {
        if (mounted && game.phase == GamePhase.idle) {
          setState(() {
            _message = 'Rakip bulundu! Başlıyor...';
            _spinning = false;
          });
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (mounted) AppRouter.startBotFallback(context);
          });
        }
      });
    } else if (widget.createRoom) {
      final code = makeRoomCode();
      setState(() {
        _title = 'ODA OLUŞTURULDU';
        _roomCode = code;
        _message = 'Arkadaşın katılmasını bekle\nKodu paylaşmak için dokun';
        _showShare = true;
        _spinning = true;
      });
      game.joinRoom(code);
    } else if (widget.joinCode != null) {
      setState(() {
        _title = 'KATILINIYOR';
        _roomCode = widget.joinCode!;
        _message = 'Odaya bağlanılıyor...';
        _showShare = false;
        _spinning = true;
      });
      game.joinRoom(widget.joinCode!);
    }
  }

  void _onGameUpdate() {
    final game = _game;
    if (game == null || !mounted) return;
    if (game.roomCode.isEmpty) return;

    if (widget.quickMatch) {
      if (!game.lobbyWaiting) {
        _botFallback?.cancel();
        _msgTimer?.cancel();
        setState(() {
          _message = 'Rakip bulundu! Başlıyor...';
          _spinning = false;
        });
      }
      return;
    }

    _botFallback?.cancel();
    _msgTimer?.cancel();
    setState(() {
      _roomCode = game.roomCode;
      if (game.lobbyWaiting) {
        _message = widget.createRoom
            ? 'Arkadaşın katılmasını bekle\nKodu paylaşmak için dokun'
            : 'Arkadaşın katılmasını bekle';
        _showShare = widget.createRoom;
        _spinning = true;
      } else {
        _message = 'Rakip bulundu! Başlıyor...';
        _spinning = false;
        _showShare = false;
      }
    });
  }

  void _showConnectionError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sunucuya bağlanılamadı. Önce node server.js çalıştırın.'),
        duration: Duration(seconds: 4),
      ),
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
    _game?.removeListener(_onGameUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.sizeOf(context).width - 48;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.3),
              radius: 1.4,
              colors: [Color(0xFF0D2A0D), AppColors.bg],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 4,
                  left: 4,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF666666)),
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
                          _title,
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
                                const Text(
                                  'ODA KODU',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF555555),
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
                                _message,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF888888),
                                  fontSize: 13,
                                  height: 1.55,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_showShare)
                          PucketButton(label: '📤 KODU PAYLAŞ', onPressed: _shareCode),
                        if (_showShare) const SizedBox(height: 12),
                        PucketButton(label: 'GERİ', secondary: true, onPressed: _goBack),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _copyCode() {
    if (_roomCode == '——') return;
    Clipboard.setData(ClipboardData(text: _roomCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Kod kopyalandı: $_roomCode')),
    );
  }

  void _shareCode() {
    if (_roomCode == '——') return;
    SharePlus.instance.share(ShareParams(text: 'PUCKET oynuyorum! Oda kodum: $_roomCode'));
  }
}
