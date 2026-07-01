import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/cosmetic_catalog.dart';

/// Premium pul PNG'lerini oyun tahtasında çizmek için önbellek.
class DiscImageCache {
  DiscImageCache._();

  static final Map<String, ui.Image> _cache = {};
  static bool _loaded = false;

  static Future<void> preload() async {
    if (_loaded) return;
    for (final item in CosmeticCatalog.premiumDiscs) {
      if (item.asset.isEmpty) continue;
      try {
        final data = await rootBundle.load(item.asset);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        _cache[item.id] = frame.image;
      } catch (e) {
        debugPrint('DiscImageCache: failed ${item.id}: $e');
      }
    }
    _loaded = true;
  }

  static Future<void> ensureLoaded(String discId) async {
    if (_cache.containsKey(discId)) return;
    final item = CosmeticCatalog.premiumDiscs.where((d) => d.id == discId).firstOrNull;
    if (item == null || item.asset.isEmpty) return;
    try {
      final data = await rootBundle.load(item.asset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _cache[item.id] = frame.image;
    } catch (e) {
      debugPrint('DiscImageCache: ensureLoaded failed $discId: $e');
    }
  }

  static ui.Image? imageFor(String discId) => _cache[discId];
}
