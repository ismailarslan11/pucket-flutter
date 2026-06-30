import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../game/game_constants.dart';
import '../game/game_controller.dart';
import '../services/auth_service.dart';
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

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _game = context.read<GameController>();
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final ms = elapsed.inMicroseconds / 1000.0;
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
          child: ListenableBuilder(
            listenable: context.read<PlayerMetaService>(),
            builder: (context, _) {
              final meta = context.read<PlayerMetaService>();
              final auth = context.read<AuthService>();
              final palette = CosmeticsTheme.boardPalette(meta.boardTheme(auth.getUid()));

              return DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: palette.neonPrimary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: palette.neonSecondary.withValues(alpha: 0.2),
                      blurRadius: 32,
                      spreadRadius: 0,
                    ),
                  ],
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
                    child: GestureDetector(
                      onPanDown: (d) {
                        var vx = d.localPosition.dx / sx;
                        var vy = d.localPosition.dy / sy;
                        if (game.mySeat == 1) {
                          vx = GameConstants.vw - vx;
                          vy = GameConstants.vh - vy;
                        }
                        game.onPointerDown(vx, vy);
                      },
                      onPanUpdate: (d) {
                        var vx = d.localPosition.dx / sx;
                        var vy = d.localPosition.dy / sy;
                        if (game.mySeat == 1) {
                          vx = GameConstants.vw - vx;
                          vy = GameConstants.vh - vy;
                        }
                        game.onPointerMove(vx, vy);
                      },
                      onPanEnd: (_) => game.onPointerUp(),
                      onPanCancel: () => game.onPointerUp(),
                      child: ListenableBuilder(
                        listenable: Listenable.merge([
                          game,
                          context.read<PlayerMetaService>(),
                        ]),
                        builder: (context, _) {
                          final g = context.read<GameController>();
                          final uid = auth.getUid();
                          return CustomPaint(
                            size: Size(innerW, innerH),
                            painter: GamePainter(
                              discs: g.discs,
                              mySeat: g.mySeat,
                              drag: g.drag,
                              visualGeneration: g.visualGeneration,
                              sx: sx,
                              sy: sy,
                              myDiscColor: meta.discColor(uid),
                              boardTheme: meta.boardTheme(uid),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
