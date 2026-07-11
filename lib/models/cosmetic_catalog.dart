import 'package:flutter/material.dart';

/// Kozmetik mağaza kataloğu — jeton fiyatları ve varsayılan öğeler.
class CosmeticCatalog {
  CosmeticCatalog._();

  /// Test için tüm pullar/temalar ücretsiz — yayın öncesi `false` yap.
  static const freeForTesting = false;

  static const freeDiscs = {'green', 'gold', 'blue', 'red', 'purple'};
  static const freeBoards = {'classic'};

  static const premiumDiscs = [
    CosmeticItem(id: 'dragon', price: 500, asset: 'assets/images/discs/dragon.png'),
    CosmeticItem(id: 'diamond', price: 620, asset: 'assets/images/discs/diamond.png'),
    CosmeticItem(id: 'goldcoin', price: 250, asset: 'assets/images/discs/goldcoin.png'),
    CosmeticItem(id: 'frost', price: 380, asset: 'assets/images/discs/frost.png'),
    CosmeticItem(id: 'tiger', price: 440, asset: 'assets/images/discs/tiger.png'),
    CosmeticItem(id: 'robot', price: 320, asset: 'assets/images/discs/robot.png'),
    CosmeticItem(id: 'swan', price: 300, asset: 'assets/images/discs/swan.png'),
    CosmeticItem(id: 'alien', price: 750, asset: 'assets/images/discs/alien.png'),
    CosmeticItem(id: 'pirate', price: 560, asset: 'assets/images/discs/pirate.png'),
    CosmeticItem(id: 'nature', price: 400, asset: 'assets/images/discs/nature.png'),
  ];

  /// Jetonla satın alınabilir emojili pullar — premium pullardan ucuz (40–90 jeton).
  static const emojiDiscs = [
    CosmeticItem(id: 'emoji_fire', price: 40, emoji: '🔥', bgArgb: 0xFF4A1810),
    CosmeticItem(id: 'emoji_basketball', price: 40, emoji: '🏀', bgArgb: 0xFF3A2010),
    CosmeticItem(id: 'emoji_ice', price: 45, emoji: '❄️', bgArgb: 0xFF0A2840),
    CosmeticItem(id: 'emoji_lightning', price: 45, emoji: '⚡', bgArgb: 0xFF3A3208),
    CosmeticItem(id: 'emoji_clover', price: 50, emoji: '🍀', bgArgb: 0xFF0A3018),
    CosmeticItem(id: 'emoji_cry', price: 50, emoji: '😢', bgArgb: 0xFF1A2848),
    CosmeticItem(id: 'emoji_star', price: 55, emoji: '⭐', bgArgb: 0xFF3A3008),
    CosmeticItem(id: 'emoji_skull', price: 60, emoji: '💀', bgArgb: 0xFF1A1A22),
    CosmeticItem(id: 'emoji_ghost', price: 65, emoji: '👻', bgArgb: 0xFF2A2048),
    CosmeticItem(id: 'emoji_rocket', price: 70, emoji: '🚀', bgArgb: 0xFF1A2040),
    CosmeticItem(id: 'emoji_devil', price: 75, emoji: '😈', bgArgb: 0xFF3A0A18),
    CosmeticItem(id: 'emoji_crown', price: 80, emoji: '👑', bgArgb: 0xFF403008),
    CosmeticItem(id: 'emoji_trophy', price: 90, emoji: '🏆', bgArgb: 0xFF403010),
  ];

  /// VIP pulu — sadece VIP paketi (gerçek para) ile açılır, jetonla satılmaz.
  static const vipDisc = CosmeticItem(id: 'vip_gold', price: 0, emoji: '👑', bgArgb: 0xFF4A3808);

  static const premiumBoards = [
    CosmeticItem(id: 'neon', price: 300),
    CosmeticItem(id: 'wood', price: 380),
    CosmeticItem(id: 'lava', price: 450),
    CosmeticItem(id: 'ocean', price: 550),
    CosmeticItem(id: 'royal', price: 650),
  ];

  /// Jetonla alınan maç içi emote'lar — rakip de görür (sosyal gösteriş).
  static const premiumEmotes = [
    CosmeticItem(id: 'clown', price: 100, emoji: '🤡'),
    CosmeticItem(id: 'flex', price: 110, emoji: '💪'),
    CosmeticItem(id: 'freeze', price: 125, emoji: '🥶'),
    CosmeticItem(id: 'devil', price: 140, emoji: '😈'),
    CosmeticItem(id: 'mindblown', price: 150, emoji: '🤯'),
    CosmeticItem(id: 'goat', price: 200, emoji: '🐐'),
  ];

  /// Zafer efektleri — maç sonu konfeti stili. 'classic' ücretsiz.
  static const winFxItems = [
    CosmeticItem(id: 'classic', price: 0, emoji: '🎊'),
    CosmeticItem(id: 'gold', price: 380, emoji: '🏆'),
    CosmeticItem(id: 'neon', price: 500, emoji: '⚡'),
  ];

  static int? emotePrice(String id) {
    if (freeForTesting) return 0;
    return premiumEmotes.where((e) => e.id == id).map((e) => e.price).firstOrNull;
  }

  static int? winFxPrice(String id) {
    if (freeForTesting) return 0;
    return winFxItems.where((e) => e.id == id).map((e) => e.price).firstOrNull;
  }

  static bool isPremiumDisc(String id) =>
      premiumDiscs.any((d) => d.id == id) || emojiDiscs.any((d) => d.id == id) || id == vipDisc.id;

  static bool isEmojiDisc(String id) => emojiDiscs.any((d) => d.id == id) || id == vipDisc.id;

  static bool isImageDisc(String id) => premiumDiscs.any((d) => d.id == id);

  static bool isPremiumBoard(String id) => premiumBoards.any((b) => b.id == id);

  static int? discPrice(String id) {
    if (freeForTesting) return 0;
    for (final d in premiumDiscs) {
      if (d.id == id) return d.price;
    }
    for (final d in emojiDiscs) {
      if (d.id == id) return d.price;
    }
    return null;
  }

  static int? boardPrice(String id) {
    if (freeForTesting) return 0;
    return premiumBoards.where((b) => b.id == id).map((b) => b.price).firstOrNull;
  }

  static String? discAsset(String id) => premiumDiscs.where((d) => d.id == id).map((d) => d.asset).firstOrNull;

  static CosmeticItem? emojiDisc(String id) =>
      id == vipDisc.id ? vipDisc : emojiDiscs.where((d) => d.id == id).firstOrNull;

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
  const CosmeticItem({
    required this.id,
    required this.price,
    this.asset = '',
    this.emoji = '',
    this.bgArgb,
  });

  final String id;
  final int price;
  final String asset;
  final String emoji;
  final int? bgArgb;

  Color get bgColor => Color(bgArgb ?? 0xFF1A2840);
}
