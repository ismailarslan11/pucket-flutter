import 'package:flutter/material.dart';

class CosmeticsTheme {
  CosmeticsTheme._();

  static const discColors = <String, Color>{
    'green': Color(0xFF4CAF50),
    'gold': Color(0xFFF0C040),
    'blue': Color(0xFF2196F3),
    'red': Color(0xFFE53935),
    'purple': Color(0xFF9C27B0),
  };

  static Color discColor(String key) => discColors[key] ?? discColors['green']!;

  static BoardPalette boardPalette(String theme) {
    switch (theme) {
      case 'neon':
        return const BoardPalette(
          topGrass: Color(0xFF1A6B3A),
          bottomGrass: Color(0xFF228B4A),
          wall: Color(0xFF1A0A2E),
          gateFill: Color(0x33FF00FF),
          gateStroke: Color(0xCCFF44FF),
        );
      case 'wood':
        return const BoardPalette(
          topGrass: Color(0xFF6B4E2E),
          bottomGrass: Color(0xFF7A5A35),
          wall: Color(0xFF2A1810),
          gateFill: Color(0x33D4A574),
          gateStroke: Color(0xCCD4A574),
        );
      default:
        return const BoardPalette(
          topGrass: Color(0xFF4A8C0C),
          bottomGrass: Color(0xFF57A00F),
          wall: Color(0xFF0D0D0D),
          gateFill: Color(0x337C3AED),
          gateStroke: Color(0xB3A855F7),
        );
    }
  }
}

class BoardPalette {
  const BoardPalette({
    required this.topGrass,
    required this.bottomGrass,
    required this.wall,
    required this.gateFill,
    required this.gateStroke,
  });

  final Color topGrass;
  final Color bottomGrass;
  final Color wall;
  final Color gateFill;
  final Color gateStroke;
}
