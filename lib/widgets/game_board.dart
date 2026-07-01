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
  late GameController _game;
  double _lastMs = 0;
  String _discColor = 'green';
  String _boardTheme = 'classic';

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _game = context.read<GameController>();
    _refreshCosmetics();
  }

  void _refreshCosmetics() {
    final meta = context.read<PlayerMetaService>();
    final auth = context.read<AuthService>();
    final disc = meta.discColor(auth.getUid());
    final board = meta.boardTheme(auth.getUid());
    if (disc != _discColor || board != _boardTheme) {
      _discColor = disc;
      _boardTheme = board;
      if (CosmeticCatalog.isPremiumDisc(_discColor)) {
        DiscImageCache.ensureLoaded(_discColor).then((_) {
          if (mounted) _game.boardRepaint.bump();
        });
      }
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final ms = elapsed.inMicroseconds / 1000.0;
    if (_game.phase != GamePhase.playing) {
      _lastMs = ms;
      return;
    }
    if (ms - _lastMs >= 16) {
      _lastMs = ms;
      _game.tick(ms);
    }
  }

  @override
  void dispose() {
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

        return Padding(
          padding: const EdgeInsets.all(outerPad),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: palette.neonPrimary.withValues(alpha: 0.7),
                width: 1.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  palette.frameInner,
                  Color.lerp(palette.frameInner, palette.neonPrimary, 0.08)!,
                ],
              ),
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
                        child: _buildPaint(innerW, innerH, sx, sy, game),
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
                        child: _buildPaint(innerW, innerH, sx, sy, game),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaint(double innerW, double innerH, double sx, double sy, GameController game) {
    return ListenableBuilder(
      listenable: game.boardRepaint,
      builder: (context, _) {
        final g = context.read<GameController>();
        return RepaintBoundary(
          child: CustomPaint(
            size: Size(innerW, innerH),
            isComplex: true,
            willChange: g.phase == GamePhase.playing,
            painter: GamePainter(
              discs: g.discs,
              mySeat: g.mySeat,
              drags: g.activeDrags,
              visualGeneration: g.visualGeneration,
              sx: sx,
              sy: sy,
              localDuoMode: g.localDuoMode,
              myDiscColor: _discColor,
              boardTheme: _boardTheme,
            ),
          ),
        );
      },
    );
  }
}
