import '../game/ai_bot.dart';
import 'rank_tier.dart';

class CareerOpponent {
  const CareerOpponent({
    required this.id,
    required this.name,
    required this.leagueIndex,
    required this.orderInLeague,
    required this.aiLevel,
    required this.displayElo,
    required this.pointsReward,
  });

  final String id;
  final String name;
  final int leagueIndex;
  final int orderInLeague;
  final AiLevel aiLevel;
  final int displayElo;
  final int pointsReward;

  RankTier get league => RankTier.tiers[leagueIndex.clamp(0, RankTier.tiers.length - 1)];
  String get leagueName => league.name;

  String get difficultyLabel => switch (aiLevel) {
        AiLevel.easy => 'Kolay',
        AiLevel.medium => 'Orta',
        AiLevel.hard => 'Zor',
      };
}

/// 6 lig × 3 rakip = 18 bot maçı
const careerOpponents = <CareerOpponent>[
  // Bronz
  CareerOpponent(id: 'br1', name: 'Yavuz', leagueIndex: 0, orderInLeague: 0, aiLevel: AiLevel.easy, displayElo: 920, pointsReward: 25),
  CareerOpponent(id: 'br2', name: 'Selin', leagueIndex: 0, orderInLeague: 1, aiLevel: AiLevel.easy, displayElo: 980, pointsReward: 30),
  CareerOpponent(id: 'br3', name: 'Kerem', leagueIndex: 0, orderInLeague: 2, aiLevel: AiLevel.medium, displayElo: 1050, pointsReward: 40),
  // Gümüş
  CareerOpponent(id: 'gm1', name: 'Deniz', leagueIndex: 1, orderInLeague: 0, aiLevel: AiLevel.medium, displayElo: 1120, pointsReward: 45),
  CareerOpponent(id: 'gm2', name: 'Ayşe', leagueIndex: 1, orderInLeague: 1, aiLevel: AiLevel.medium, displayElo: 1160, pointsReward: 50),
  CareerOpponent(id: 'gm3', name: 'Burak', leagueIndex: 1, orderInLeague: 2, aiLevel: AiLevel.medium, displayElo: 1190, pointsReward: 55),
  // Altın
  CareerOpponent(id: 'al1', name: 'Cem', leagueIndex: 2, orderInLeague: 0, aiLevel: AiLevel.medium, displayElo: 1230, pointsReward: 60),
  CareerOpponent(id: 'al2', name: 'Elif', leagueIndex: 2, orderInLeague: 1, aiLevel: AiLevel.hard, displayElo: 1280, pointsReward: 70),
  CareerOpponent(id: 'al3', name: 'Onur', leagueIndex: 2, orderInLeague: 2, aiLevel: AiLevel.hard, displayElo: 1320, pointsReward: 80),
  // Elmas
  CareerOpponent(id: 'el1', name: 'Mert', leagueIndex: 3, orderInLeague: 0, aiLevel: AiLevel.hard, displayElo: 1380, pointsReward: 90),
  CareerOpponent(id: 'el2', name: 'Zeynep', leagueIndex: 3, orderInLeague: 1, aiLevel: AiLevel.hard, displayElo: 1420, pointsReward: 100),
  CareerOpponent(id: 'el3', name: 'Kaan', leagueIndex: 3, orderInLeague: 2, aiLevel: AiLevel.hard, displayElo: 1460, pointsReward: 110),
  // Usta
  CareerOpponent(id: 'us1', name: 'Arda', leagueIndex: 4, orderInLeague: 0, aiLevel: AiLevel.hard, displayElo: 1520, pointsReward: 125),
  CareerOpponent(id: 'us2', name: 'Defne', leagueIndex: 4, orderInLeague: 1, aiLevel: AiLevel.hard, displayElo: 1580, pointsReward: 140),
  CareerOpponent(id: 'us3', name: 'Tolga', leagueIndex: 4, orderInLeague: 2, aiLevel: AiLevel.hard, displayElo: 1640, pointsReward: 155),
  // Efsane
  CareerOpponent(id: 'ef1', name: 'Vega', leagueIndex: 5, orderInLeague: 0, aiLevel: AiLevel.hard, displayElo: 1720, pointsReward: 175),
  CareerOpponent(id: 'ef2', name: 'Nova', leagueIndex: 5, orderInLeague: 1, aiLevel: AiLevel.hard, displayElo: 1780, pointsReward: 200),
  CareerOpponent(id: 'ef3', name: 'Atlas', leagueIndex: 5, orderInLeague: 2, aiLevel: AiLevel.hard, displayElo: 1850, pointsReward: 250),
];

CareerOpponent? careerOpponentById(String id) {
  for (final o in careerOpponents) {
    if (o.id == id) return o;
  }
  return null;
}

List<CareerOpponent> opponentsInLeague(int leagueIndex) {
  return careerOpponents.where((o) => o.leagueIndex == leagueIndex).toList()
    ..sort((a, b) => a.orderInLeague.compareTo(b.orderInLeague));
}
