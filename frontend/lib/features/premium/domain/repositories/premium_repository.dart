abstract class PremiumRepository {
  Future<bool> isPremium();
  Future<void> setPremium(bool value);
}
