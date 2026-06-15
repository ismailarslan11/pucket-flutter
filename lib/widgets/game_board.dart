import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../game/game_constants.dart';
import '../game/game_controller.dart';
import 'game_painter.dart';

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _lastMs = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final ms = elapsed.inMicroseconds / 1000.0;
    if (ms - _lastMs >= 16) {
      _lastMs = ms;
      context.read<GameController>().tick(ms);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final sx = constraints.maxWidth / GameConstants.vw;
        final sy = constraints.maxHeight / GameConstants.vh;

        return GestureDetector(
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
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: GamePainter(
              discs: game.discs,
              mySeat: game.mySeat,
              drag: game.drag,
              sx: sx,
              sy: sy,
            ),
          ),
        );
      },
    );
  }
}
