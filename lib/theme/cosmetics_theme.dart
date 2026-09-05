import 'package:flutter/material.dart';

import 'app_theme.dart';

class CosmeticsTheme {
  CosmeticsTheme._();

  static const discColors = <String, Color>{
    'green': AppColors.neonYesil,
    'gold': AppColors.sariAna,
    'blue': AppColors.blue,
    'red': AppColors.red,
    'purple': AppColors.acikMavi,
  };

  static Color discColor(String key) => discColors[key] ?? discColors['green']!;

  static BoardPalette boardPalette(String theme) {
    switch (theme) {
      case 'neon':
        return const BoardPalette(
          topGrass: AppColors.geceLacivert,
          bottomGrass: AppColors.laciDerin,
          wall: AppColors.laciKoyu,
          gateFill: Color(0x4422D3EE),
          gateStroke: AppColors.gokDaha,
          topTint: Color(0x22FB923C),
          bottomTint: Color(0x2238BDF8),
          accentLine: AppColors.gokAcik,
          labelColor: Color(0x9938BDF8),
          frameOuter: AppColors.turuncuAna,
          frameInner: AppColors.laciDerin,
          neonPrimary: AppColors.gokDaha,
          neonSecondary: AppColors.turuncuAna,
          gridColor: Color(0x2238BDF8),
        );
      case 'wood':
        return const BoardPalette(
          topGrass: AppColors.koyuGriMavimsi,
          bottomGrass: AppColors.ortaGri,
          wall: AppColors.laciOrta,
          gateFill: Color(0x44FACC15),
          gateStroke: AppColors.sariAna,
          topTint: Color(0x18FB923C),
          bottomTint: Color(0x188B5CF6),
          accentLine: AppColors.vurguMavi,
          labelColor: Color(0x99C4B5FD),
          frameOuter: AppColors.turuncuKoyu,
          frameInner: AppColors.laciDerin,
          neonPrimary: AppColors.vurguMavi,
          neonSecondary: AppColors.turuncuAna,
          gridColor: Color(0x186B7280),
        );
      case 'lava':
        return const BoardPalette(
          topGrass: Color(0xFF3A0D0D),
          bottomGrass: Color(0xFF200606),
          wall: Color(0xFF4A1010),
          gateFill: Color(0x44FB923C),
          gateStroke: AppColors.turuncuAna,
          topTint: Color(0x28EF4444),
          bottomTint: Color(0x22FB923C),
          accentLine: AppColors.turuncuAna,
          labelColor: Color(0x99FDBA74),
          frameOuter: AppColors.turuncuKoyu,
          frameInner: Color(0xFF200606),
          neonPrimary: AppColors.turuncuAna,
          neonSecondary: AppColors.kirmizi,
          gridColor: Color(0x22EF4444),
        );
      case 'ocean':
        return const BoardPalette(
          topGrass: Color(0xFF06283A),
          bottomGrass: Color(0xFF041B28),
          wall: Color(0xFF0A3A52),
          gateFill: Color(0x4422D3EE),
          gateStroke: AppColors.gokDaha,
          topTint: Color(0x2238BDF8),
          bottomTint: Color(0x2222D3EE),
          accentLine: AppColors.gokAcik,
          labelColor: Color(0x9938BDF8),
          frameOuter: AppColors.gokAcik,
          frameInner: Color(0xFF041B28),
          neonPrimary: AppColors.gokDaha,
          neonSecondary: AppColors.neonYesil,
          gridColor: Color(0x2238BDF8),
        );
      case 'royal':
        return const BoardPalette(
          topGrass: Color(0xFF2A2005),
          bottomGrass: Color(0xFF1A1403),
          wall: Color(0xFF3A2E08),
          gateFill: Color(0x44FACC15),
          gateStroke: AppColors.sariAna,
          topTint: Color(0x26FACC15),
          bottomTint: Color(0x1EFB923C),
          accentLine: AppColors.sariAna,
          labelColor: Color(0x99FACC15),
          frameOuter: AppColors.sariAna,
          frameInner: Color(0xFF1A1403),
          neonPrimary: AppColors.sariAna,
          neonSecondary: AppColors.turuncuAna,
          gridColor: Color(0x22FACC15),
        );
      default:
        return const BoardPalette(
          topGrass: AppColors.laciOrta,
          bottomGrass: AppColors.laciDerin,
          wall: AppColors.koyuMavi,
          gateFill: Color(0x44FACC15),
          gateStroke: AppColors.sariAna,
          topTint: Color(0x20FB923C),
          bottomTint: Color(0x208B5CF6),
          accentLine: AppColors.buzMavi,
          labelColor: Color(0x99C4B5FD),
          frameOuter: AppColors.acikMavi,
          frameInner: AppColors.laciDerin,
          neonPrimary: AppColors.vurguMavi,
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
    this.accentLine = AppColors.gokAcik,
    this.labelColor = const Color(0x99C4B5FD),
    this.frameOuter = AppColors.gokAcik,
    this.frameInner = AppColors.laciDerin,
    this.neonPrimary = AppColors.gokAcik,
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
