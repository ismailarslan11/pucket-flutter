import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../game/ai_bot.dart';
import '../game/game_controller.dart';
import '../models/career_opponent.dart';
import '../services/ad_service.dart';
import '../services/audio_service.dart';
import '../screens/cosmetics_screen.dart';
import '../game/training_layout.dart';
import '../screens/training_screen.dart';
import 'career_screen.dart';
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
  static Future<void> goMenu(BuildContext context) async {
    await context.read<AdService>().showInterstitialOnMenuReturn();
    if (!context.mounted) return;
    context.read<GameController>().leave();
    await context.read<AudioService>().playMenuMusic();
    if (!context.mounted) return;
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

  static void goCareer(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CareerScreen()));
  }

  static void returnToCareer(BuildContext context) {
    context.read<GameController>().leave();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const CareerScreen()),
      (_) => false,
    );
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

  static void startCareer(BuildContext context, CareerOpponent opponent) {
    context.read<GameController>().startCareerGame(opponent);
    goGame(context);
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

  static void goTraining(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const TrainingScreen()));
  }

  static void goCosmetics(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CosmeticsScreen()));
  }

  static void startTraining(BuildContext context, TrainingType type, {AiLevel level = AiLevel.easy}) {
    final game = context.read<GameController>();
    final l10n = context.l10nRead;
    game.leave();
    switch (type) {
      case TrainingType.shooting:
        game.startTrainingGame(
          AiLevel.easy,
          label: l10n.trainingShooting,
          layout: TrainingLayout.shooting,
          goalLabel: l10n.trainingGoalShooting,
        );
      case TrainingType.defense:
        game.startTrainingGame(
          AiLevel.medium,
          label: l10n.trainingDefense,
          layout: TrainingLayout.defense,
          goalLabel: l10n.trainingGoalDefense,
        );
      case TrainingType.full:
        game.startTrainingGame(
          level,
          label: l10n.trainingFull,
          layout: TrainingLayout.full,
          goalLabel: l10n.trainingGoalFull,
        );
    }
    goGame(context);
  }
}
