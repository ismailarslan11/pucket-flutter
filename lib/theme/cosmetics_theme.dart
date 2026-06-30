import 'package:flutter/material.dart';

import 'app_theme.dart';

class CosmeticsTheme {
  CosmeticsTheme._();

  static const discColors = <String, Color>{
    'green': AppColors.fieldBlue,
    'gold': AppColors.accentYellow,
    'blue': AppColors.brandBlue,
    'red': AppColors.brandOrange,
    'purple': AppColors.nightBlue,
  };

  static Color discColor(String key) => discColors[key] ?? discColors['green']!;

  static BoardPalette boardPalette(String theme) {
    switch (theme) {
      case 'neon':
        return const BoardPalette(
          topGrass: Color(0xFF001A33),
          bottomGrass: Color(0xFF002244),
          wall: Color(0xFF003366),
          gateFill: Color(0x440088CC),
          gateStroke: AppColors.fieldBlue,
          topTint: Color(0x22FF6600),
          bottomTint: Color(0x220088CC),
          accentLine: AppColors.fieldBlue,
          labelColor: Color(0x9944AAEE),
          frameOuter: AppColors.brandOrange,
          frameInner: AppColors.bgDeep,
          neonPrimary: AppColors.fieldBlue,
          neonSecondary: AppColors.brandOrange,
          gridColor: Color(0x2244AAEE),
        );
      case 'wood':
        return const BoardPalette(
          topGrass: Color(0xFF1A2030),
          bottomGrass: Color(0xFF152035),
          wall: Color(0xFF2A3548),
          gateFill: Color(0x440088CC),
          gateStroke: AppColors.brandBlue,
          topTint: Color(0x18FF6600),
          bottomTint: Color(0x180088CC),
          accentLine: AppColors.brandBlue,
          labelColor: Color(0x990088CC),
          frameOuter: AppColors.darkOrange,
          frameInner: AppColors.bgDeep,
          neonPrimary: AppColors.brandBlue,
          neonSecondary: AppColors.brandOrange,
          gridColor: Color(0x180088CC),
        );
      default:
        return const BoardPalette(
          topGrass: Color(0xFF001428),
          bottomGrass: Color(0xFF001A33),
          wall: Color(0xFF002845),
          gateFill: Color(0x440088CC),
          gateStroke: AppColors.fieldBlue,
          topTint: Color(0x20FF6600),
          bottomTint: Color(0x200088CC),
          accentLine: AppColors.fieldBlue,
          labelColor: Color(0x9944AAEE),
          frameOuter: AppColors.brandBlue,
          frameInner: AppColors.bgDeep,
          neonPrimary: AppColors.fieldBlue,
          neonSecondary: AppColors.brandOrange,
          gridColor: Color(0x1844AAEE),
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
    this.accentLine = AppColors.fieldBlue,
    this.labelColor = const Color(0x9944AAEE),
    this.frameOuter = AppColors.brandBlue,
    this.frameInner = AppColors.bgDeep,
    this.neonPrimary = AppColors.fieldBlue,
    this.neonSecondary = AppColors.brandOrange,
    this.gridColor = const Color(0x1844AAEE),
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
