import 'package:flutter/material.dart';

import 'app_theme.dart';

class CosmeticsTheme {
  CosmeticsTheme._();

  static const discColors = <String, Color>{
    'green': AppColors.neonYesil,
    'gold': AppColors.sariAna,
    'blue': AppColors.camgobegi,
    'red': AppColors.turuncuAna,
    'purple': AppColors.acikMor,
  };

  static Color discColor(String key) => discColors[key] ?? discColors['green']!;

  static BoardPalette boardPalette(String theme) {
    switch (theme) {
      case 'neon':
        return const BoardPalette(
          topGrass: AppColors.geceLacivert,
          bottomGrass: AppColors.morDahaKoyu,
          wall: AppColors.koyuIndigo,
          gateFill: Color(0x4422D3EE),
          gateStroke: AppColors.acikCamgobegi,
          topTint: Color(0x22FB923C),
          bottomTint: Color(0x2238BDF8),
          accentLine: AppColors.camgobegi,
          labelColor: Color(0x9938BDF8),
          frameOuter: AppColors.turuncuAna,
          frameInner: AppColors.morDahaKoyu,
          neonPrimary: AppColors.acikCamgobegi,
          neonSecondary: AppColors.turuncuAna,
          gridColor: Color(0x2238BDF8),
        );
      case 'wood':
        return const BoardPalette(
          topGrass: AppColors.koyuGriMorumsu,
          bottomGrass: AppColors.ortaGri,
          wall: AppColors.morKoyu,
          gateFill: Color(0x44FACC15),
          gateStroke: AppColors.sariAna,
          topTint: Color(0x18FB923C),
          bottomTint: Color(0x188B5CF6),
          accentLine: AppColors.vurguMoru,
          labelColor: Color(0x99C4B5FD),
          frameOuter: AppColors.turuncuKoyu,
          frameInner: AppColors.morDahaKoyu,
          neonPrimary: AppColors.vurguMoru,
          neonSecondary: AppColors.turuncuAna,
          gridColor: Color(0x186B7280),
        );
      default:
        return const BoardPalette(
          topGrass: AppColors.morKoyu,
          bottomGrass: AppColors.morDahaKoyu,
          wall: AppColors.koyuMor,
          gateFill: Color(0x44FACC15),
          gateStroke: AppColors.sariAna,
          topTint: Color(0x20FB923C),
          bottomTint: Color(0x208B5CF6),
          accentLine: AppColors.lavanta,
          labelColor: Color(0x99C4B5FD),
          frameOuter: AppColors.acikMor,
          frameInner: AppColors.morDahaKoyu,
          neonPrimary: AppColors.vurguMoru,
          neonSecondary: AppColors.sariAna,
          gridColor: Color(0x188B5CF6),
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
    this.accentLine = AppColors.camgobegi,
    this.labelColor = const Color(0x99C4B5FD),
    this.frameOuter = AppColors.camgobegi,
    this.frameInner = AppColors.morDahaKoyu,
    this.neonPrimary = AppColors.camgobegi,
    this.neonSecondary = AppColors.turuncuAna,
    this.gridColor = const Color(0x188B5CF6),
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
