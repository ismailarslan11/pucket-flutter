import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Uygulama içi satın alma (IAP).
///
/// ÜRÜNLER: Aşağıdaki ID'ler App Store Connect ve Google Play Console'da
/// birebir aynı şekilde tanımlanmalıdır. Tanımlanana kadar mağaza ürün
/// döndürmez ve satın alma başlatılamaz (kod güvenle no-op olur).
class ProductIds {
  ProductIds._();
  static const removeAds = 'pucket_remove_ads'; // non-consumable
  static const tokens100 = 'pucket_tokens_100'; // consumable
  static const tokens500 = 'pucket_tokens_550'; // consumable (bonus)
  static const battlePassPremium = 'pucket_bp_premium'; // non-consumable / seasonal

  static const all = {removeAds, tokens100, tokens500, battlePassPremium};
  static const consumables = {tokens100, tokens500};
}

class PurchaseService extends ChangeNotifier {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool available = false;
  List<ProductDetails> products = [];
  String? lastError;

  /// Satın alma tamamlandığında ilgili ürün ID'si ile çağrılır (ödül ver).
  void Function(String productId)? onPurchased;

  Future<void> init() async {
    try {
      available = await _iap.isAvailable();
    } catch (_) {
      available = false;
    }
    if (!available) return;

    _sub = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _sub?.cancel(),
      onError: (_) {},
    );

    try {
      final resp = await _iap.queryProductDetails(ProductIds.all);
      products = resp.productDetails;
    } catch (e) {
      lastError = e.toString();
    }
    notifyListeners();
  }

  ProductDetails? productFor(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> buy(String productId) async {
    final product = productFor(productId);
    if (product == null) {
      lastError = 'Ürün bulunamadı (mağazada tanımlı değil)';
      notifyListeners();
      return;
    }
    final param = PurchaseParam(productDetails: product);
    if (ProductIds.consumables.contains(productId)) {
      await _iap.buyConsumable(purchaseParam: param);
    } else {
      await _iap.buyNonConsumable(purchaseParam: param);
    }
  }

  Future<void> restore() async {
    if (!available) return;
    await _iap.restorePurchases();
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored) {
        onPurchased?.call(p.productID);
      } else if (p.status == PurchaseStatus.error) {
        lastError = p.error?.message;
        notifyListeners();
      }
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
