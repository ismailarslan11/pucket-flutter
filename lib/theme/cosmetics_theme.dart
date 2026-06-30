import 'package:flutter/material.dart';

class CosmeticsTheme {
  CosmeticsTheme._();

  static const discColors = <String, Color>{
    'green': Color(0xFF00FF88),
    'gold': Color(0xFFFFD700),
    'blue': Color(0xFF00D4FF),
    'red': Color(0xFFFF3366),
    'purple': Color(0xFFBF5FFF),
  };

  static Color discColor(String key) => discColors[key] ?? discColors['green']!;

  static BoardPalette boardPalette(String theme) {
    switch (theme) {
      case 'neon':
        return const BoardPalette(
          topGrass: Color(0xFF080818),
          bottomGrass: Color(0xFF0E0820),
          wall: Color(0xFF2A1050),
          gateFill: Color(0x44FF00FF),
          gateStroke: Color(0xFFFF44FF),
          topTint: Color(0x22FF0066),
          bottomTint: Color(0x220066FF),
          accentLine: Color(0xFFFF44FF),
          labelColor: Color(0x99FF44FF),
          frameOuter: Color(0xFFFF00AA),
          frameInner: Color(0xFF060010),
          neonPrimary: Color(0xFFFF44FF),
          neonSecondary: Color(0xFF00FFFF),
          gridColor: Color(0x22FF44FF),
        );
      case 'wood':
        return const BoardPalette(
          topGrass: Color(0xFF1A1420),
          bottomGrass: Color(0xFF201828),
          wall: Color(0xFF3D2A50),
          gateFill: Color(0x44A855F7),
          gateStroke: Color(0xFFA855F7),
          topTint: Color(0x18FF3366),
          bottomTint: Color(0x183366FF),
          accentLine: Color(0xFF7C3AED),
          labelColor: Color(0x997C3AED),
          frameOuter: Color(0xFF5B21B6),
          frameInner: Color(0xFF0D0818),
          neonPrimary: Color(0xFFA855F7),
          neonSecondary: Color(0xFF38BDF8),
          gridColor: Color(0x187C3AED),
        );
      default:
        return const BoardPalette(
          topGrass: Color(0xFF060818),
          bottomGrass: Color(0xFF0A0620),
          wall: Color(0xFF141030),
          gateFill: Color(0x4400F0FF),
          gateStroke: Color(0xFF00F0FF),
          topTint: Color(0x20FF2255),
          bottomTint: Color(0x202255FF),
          accentLine: Color(0xFF00F0FF),
          labelColor: Color(0x9900F0FF),
          frameOuter: Color(0xFF00F0FF),
          frameInner: Color(0xFF040612),
          neonPrimary: Color(0xFF00F0FF),
          neonSecondary: Color(0xFFFF00AA),
          gridColor: Color(0x1800F0FF),
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
    this.topTint = Colors.transparent,
    this.bottomTint = Colors.transparent,
    this.accentLine = const Color(0xFF00F0FF),
    this.labelColor = const Color(0x9900F0FF),
    this.frameOuter = const Color(0xFF00F0FF),
    this.frameInner = const Color(0xFF040612),
    this.neonPrimary = const Color(0xFF00F0FF),
    this.neonSecondary = const Color(0xFFFF00AA),
    this.gridColor = const Color(0x1800F0FF),
  });

  final Color topGrass;
  final Color bottomGrass;
  final Color wall;
  final Color gateFill;
  final Color gateStroke;
  final Color topTint;
  final Color bottomTint;
  final Color accentLine;
  final Color labelColor;
  final Color frameOuter;
  final Color frameInner;
  final Color neonPrimary;
  final Color neonSecondary;
  final Color gridColor;
}
