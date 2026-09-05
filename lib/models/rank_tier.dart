import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class RankTier {
  final String name;
  final String emoji;
  final int minElo;
  final Color color;

  const RankTier(this.name, this.emoji, this.minElo, this.color);

  static const tiers = [
    RankTier('Bronz', '', 0, AppColors.turuncuKoyu),
    RankTier('Gümüş', '', 1100, AppColors.buzMavi),
    RankTier('Altın', '', 1200, AppColors.sariAna),
    RankTier('Elmas', '', 1350, AppColors.acikMavi),
    RankTier('Usta', '', 1500, AppColors.vurguMavi),
    RankTier('Efsane', '', 1700, AppColors.turuncuAna),
  ];

  static RankTier forElo(int elo) {
    var current = tiers.first;
    for (final t in tiers) {
      if (elo >= t.minElo) current = t;
    }
    return current;
  }
}
