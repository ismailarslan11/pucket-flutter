import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../game/game_constants.dart';
import '../game/game_controller.dart';
import '../models/cosmetic_catalog.dart';
import '../services/auth_service.dart';
import '../services/disc_image_cache.dart';
import '../services/player_meta_service.dart';
import '../theme/cosmetics_theme.dart';
import 'game_painter.dart';

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  GameController? _game;
  double _lastMs = 0;
  String _discColor = 'green';
  String _boardTheme = 'classic';
  double _innerW = 0;
  double _innerH = 0;
  double _sx = 1;
  double _sy = 1;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final game = context.read<GameController>();
    if (_game != game) {
      _game?.removeListener(_syncTicker);
      _game = game;
      _game!.addListener(_syncTicker);
    }
    _refreshCosmetics();
    _syncTicker();
  }

  void _syncTicker() {
    final game = _game;
    if (game == null) return;
    if (game.phase == GamePhase.playing) {
      if (!_ticker.isActive) _ticker.start();
    } else if (_ticker.isActive) {
      _ticker.stop();
    }
  }

  void _refreshCosmetics() {
    final meta = context.read<PlayerMetaService>();
    final auth = context.read<AuthService>();
    final disc = meta.discColor(auth.getUid());
    final board = meta.boardTheme(auth.getUid());
    if (disc != _discColor || board != _boardTheme) {
      setState(() {
        _discColor = disc;
        _boardTheme = board;
      });
      if (CosmeticCatalog.isPremiumDisc(_discColor)) {
        DiscImageCache.ensureLoaded(_discColor).then((_) {
          if (mounted) _game?.boardRepaint.bump();
        });
      }
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final game = _game;
    if (game == null || game.phase != GamePhase.playing) {
      _lastMs = elapsed.inMicroseconds / 1000.0;
      return;
    }
    final ms = elapsed.inMicroseconds / 1000.0;
    if (ms - _lastMs >= 15) {
      _lastMs = ms;
      game.tick(ms);
    }
  }

  @override
  void dispose() {
    _game?.removeListener(_syncTicker);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameController>();
    final palette = CosmeticsTheme.boardPalette(_boardTheme);

    return LayoutBuilder(
      builder: (context, constraints) {
        const outerPad = 8.0;
        const frameWidth = 3.0;
        final innerW = constraints.maxWidth - outerPad * 2;
        final innerH = constraints.maxHeight - outerPad * 2;
        final sx = innerW / GameConstants.vw;
        final sy = innerH / GameConstants.vh;
        _innerW = innerW;
        _innerH = innerH;
        _sx = sx;
        _sy = sy;

        return Padding(
          padding: const EdgeInsets.all(outerPad),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: palette.neonPrimary.withValues(alpha: 0.7),
                width: 1.5,
              ),
              color: palette.frameInner,
            ),
            child: Padding(
              padding: const EdgeInsets.all(frameWidth),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: game.localDuoMode
                    ? Listener(
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: (e) {
                          if (game.phase != GamePhase.playing) return;
                          game.onPointerDown(
                            e.pointer,
                            e.localPosition.dx / sx,
                            e.localPosition.dy / sy,
                          );
                        },
                        onPointerMove: (e) {
                          game.onPointerMove(
                            e.pointer,
                            e.localPosition.dx / sx,
                            e.localPosition.dy / sy,
                          );
                        },
                        onPointerUp: (e) => game.onPointerUp(e.pointer),
                        onPointerCancel: (e) => game.onPointerUp(e.pointer),
                        child: _canvas(game),
                      )
                    : GestureDetector(
                        onPanDown: (d) {
                          var vx = d.localPosition.dx / sx;
                          var vy = d.localPosition.dy / sy;
                          if (game.mySeat == 1) {
                            vx = GameConstants.vw - vx;
                            vy = GameConstants.vh - vy;
                          }
                          game.onPointerDown(0, vx, vy);
                        },
                        onPanUpdate: (d) {
                          var vx = d.localPosition.dx / sx;
                          var vy = d.localPosition.dy / sy;
                          if (game.mySeat == 1) {
                            vx = GameConstants.vw - vx;
                            vy = GameConstants.vh - vy;
                          }
                          game.onPointerMove(0, vx, vy);
                        },
                        onPanEnd: (_) => game.onPointerUp(0),
                        onPanCancel: () => game.onPointerUp(0),
                        child: _canvas(game),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _canvas(GameController game) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(_innerW, _innerH),
        painter: GamePainter(
          game: game,
          sx: _sx,
          sy: _sy,
          discColor: _discColor,
          boardTheme: _boardTheme,
        ),
      ),
    );
  }
}
