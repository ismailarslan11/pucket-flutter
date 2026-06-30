import 'dart:ui' as ui;

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
      } catch (_) {}
    }
    _loaded = true;
  }

  static ui.Image? imageFor(String discId) => _cache[discId];
}
