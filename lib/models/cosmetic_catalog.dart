/// Kozmetik mağaza kataloğu — jeton fiyatları ve varsayılan öğeler.
class CosmeticCatalog {
  CosmeticCatalog._();

  static const freeDiscs = {'green', 'gold', 'blue', 'red', 'purple'};
  static const freeBoards = {'classic'};

  static const premiumDiscs = [
    CosmeticItem(id: 'gryphon', price: 10, asset: 'assets/images/discs/gryphon.png'),
    CosmeticItem(id: 'abyssal_serpent', price: 100, asset: 'assets/images/discs/abyssal_serpent.png'),
    CosmeticItem(id: 'ascended_phoenix', price: 200, asset: 'assets/images/discs/ascended_phoenix.png'),
    CosmeticItem(id: 'world_tree', price: 250, asset: 'assets/images/discs/world_tree.png'),
    CosmeticItem(id: 'desert_cobra', price: 75, asset: 'assets/images/discs/desert_cobra.png'),
    CosmeticItem(id: 'leviathan', price: 150, asset: 'assets/images/discs/leviathan.png'),
    CosmeticItem(id: 'clockwork_golem', price: 175, asset: 'assets/images/discs/clockwork_golem.png'),
    CosmeticItem(id: 'heavens_step', price: 225, asset: 'assets/images/discs/heavens_step.png'),
    CosmeticItem(id: 'ifrit_fire', price: 300, asset: 'assets/images/discs/ifrit_fire.png'),
    CosmeticItem(id: 'mountain_dwarven', price: 125, asset: 'assets/images/discs/mountain_dwarven.png'),
    CosmeticItem(id: 'void_crystal', price: 500, asset: 'assets/images/discs/void_crystal.png'),
    CosmeticItem(id: 'sprite_blessing', price: 350, asset: 'assets/images/discs/sprite_blessing.png'),
  ];

  static const premiumBoards = [
    CosmeticItem(id: 'neon', price: 120),
    CosmeticItem(id: 'wood', price: 150),
  ];

  static bool isPremiumDisc(String id) => premiumDiscs.any((d) => d.id == id);

  static bool isPremiumBoard(String id) => premiumBoards.any((b) => b.id == id);

  static int? discPrice(String id) => premiumDiscs.where((d) => d.id == id).map((d) => d.price).firstOrNull;

  static int? boardPrice(String id) => premiumBoards.where((b) => b.id == id).map((b) => b.price).firstOrNull;

  static String? discAsset(String id) => premiumDiscs.where((d) => d.id == id).map((d) => d.asset).firstOrNull;

  /// Galibiyet jetonu — ELO kademesine göre artar.
  static int winTokenReward(int elo) {
    if (elo >= 1700) return 35;
    if (elo >= 1500) return 28;
    if (elo >= 1350) return 22;
    if (elo >= 1200) return 18;
    if (elo >= 1100) return 14;
    return 10;
  }

  /// Reklam izleme jetonu.
  static int adTokenReward(int elo) {
    if (elo >= 1700) return 40;
    if (elo >= 1500) return 32;
    if (elo >= 1350) return 26;
    if (elo >= 1200) return 22;
    if (elo >= 1100) return 18;
    return 15;
  }
}

class CosmeticItem {
  const CosmeticItem({required this.id, required this.price, this.asset = ''});
  final String id;
  final int price;
  final String asset;
}
