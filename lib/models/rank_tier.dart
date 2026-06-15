import 'package:flutter/material.dart';

class RankTier {
  final String name;
  final String emoji;
  final int minElo;
  final Color color;

  const RankTier(this.name, this.emoji, this.minElo, this.color);

  static const tiers = [
    RankTier('Bronz', '🥉', 0, Color(0xFFCD7F32)),
    RankTier('Gümüş', '🥈', 1100, Color(0xFFAAAAAA)),
    RankTier('Altın', '🥇', 1200, Color(0xFFF0C040)),
    RankTier('Elmas', '💎', 1350, Color(0xFF60D0FF)),
    RankTier('Usta', '🏆', 1500, Color(0xFF9B59B6)),
    RankTier('Efsane', '👑', 1700, Color(0xFFE83030)),
  ];

  static RankTier forElo(int elo) {
    var current = tiers.first;
    for (final t in tiers) {
      if (elo >= t.minElo) current = t;
    }
    return current;
  }
}
