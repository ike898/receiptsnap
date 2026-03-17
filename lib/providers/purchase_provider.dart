import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:path_provider/path_provider.dart';

const _kPremiumId = 'premium_unlock';

final isPremiumProvider = StateProvider<bool>((ref) => false);

final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final service = PurchaseService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});

class PurchaseService {
  final Ref _ref;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  PurchaseService(this._ref) {
    _init();
  }

  Future<void> _init() async {
    final cached = await _loadPremiumStatus();
    _ref.read(isPremiumProvider.notifier).state = cached;
    if (!await InAppPurchase.instance.isAvailable()) return;
    _subscription = InAppPurchase.instance.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (_) {},
    );
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        if (purchase.productID == _kPremiumId) {
          _ref.read(isPremiumProvider.notifier).state = true;
          _savePremiumStatus(true);
        }
      }
      if (purchase.pendingCompletePurchase) {
        InAppPurchase.instance.completePurchase(purchase);
      }
    }
  }

  Future<void> buyPremium() async {
    final available = await InAppPurchase.instance.isAvailable();
    if (!available) return;
    final response =
        await InAppPurchase.instance.queryProductDetails({_kPremiumId});
    if (response.productDetails.isEmpty) return;
    final product = response.productDetails.first;
    final param = PurchaseParam(productDetails: product);
    await InAppPurchase.instance.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restorePurchases() async {
    await InAppPurchase.instance.restorePurchases();
  }

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/premium.txt');
  }

  Future<bool> _loadPremiumStatus() async {
    try {
      final file = await _file;
      if (await file.exists()) {
        return (await file.readAsString()).trim() == 'true';
      }
    } catch (_) {}
    return false;
  }

  Future<void> _savePremiumStatus(bool value) async {
    final file = await _file;
    await file.writeAsString(value.toString());
  }

  void dispose() {
    _subscription?.cancel();
  }
}
