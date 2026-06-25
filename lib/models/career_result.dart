import 'career_opponent.dart';
import 'rank_tier.dart';

class CareerMatchResult {
  const CareerMatchResult({
    required this.won,
    required this.pointsEarned,
    required this.firstTimeWin,
    required this.promoted,
    required this.newLeague,
    required this.opponent,
    required this.totalCareerPoints,
    required this.careerComplete,
  });

  final bool won;
  final int pointsEarned;
  final bool firstTimeWin;
  final bool promoted;
  final RankTier newLeague;
  final CareerOpponent opponent;
  final int totalCareerPoints;
  final bool careerComplete;
}
