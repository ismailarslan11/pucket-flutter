import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class RankTier {
  final String name;
  final String emoji;
  final int minElo;
  final Color color;

  const RankTier(this.name, this.emoji, this.minElo, this.color);

  static const tiers = [
    RankTier('Bronz', '', 0, AppColors.darkOrange),
    RankTier('Gümüş', '', 1100, AppColors.silver),
    RankTier('Altın', '', 1200, AppColors.accentYellow),
    RankTier('Elmas', '', 1350, AppColors.fieldBlue),
    RankTier('Usta', '', 1500, AppColors.brandBlue),
    RankTier('Efsane', '', 1700, AppColors.brandOrange),
  ];

  static RankTier forElo(int elo) {
    var current = tiers.first;
    for (final t in tiers) {
      if (elo >= t.minElo) current = t;
    }
    return current;
  }
}
