import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/ai_bot.dart';
import '../game/game_controller.dart';
import 'difficulty_screen.dart';
import 'game_screen.dart';
import 'instructions_screen.dart';
import 'join_screen.dart';
import 'lobby_screen.dart';
import 'menu_screen.dart';
import 'queue_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
import 'tutorial_screen.dart';

class AppRouter {
  static void goMenu(BuildContext context) {
    context.read<GameController>().leave();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MenuScreen()),
      (_) => false,
    );
  }

  static void goJoin(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinScreen()));
  }

  static void goDifficulty(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const DifficultyScreen()));
  }

  static void goInstructions(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const InstructionsScreen()));
  }

  static void goSettings(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  static void goQueue(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const QueueScreen()));
  }

  static void goLobby(
    BuildContext context, {
    bool quickMatch = false,
    bool createRoom = false,
    String? joinCode,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LobbyScreen(
          quickMatch: quickMatch,
          createRoom: createRoom,
          joinCode: joinCode,
        ),
      ),
    );
  }

  static void goGame(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }

  static void startAi(BuildContext context, AiLevel level) {
    context.read<GameController>().startAiGame(level);
    goGame(context);
  }

  static void startBotFallback(BuildContext context, {AiLevel level = AiLevel.medium}) {
    final game = context.read<GameController>();
    game.leave();
    game.startAiGame(level, botFallback: true);
    goGame(context);
  }

  static void goProfile(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }

  static void goTutorial(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const TutorialScreen()));
  }
}
