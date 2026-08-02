abstract class PremiumRepository {
  Future<bool> isPremium();
  Future<bool> purchase();
  Future<bool> restore();

  String? get localizedPrice;
  bool get purchaseAvailable;

  Future<void> dispose();
}
