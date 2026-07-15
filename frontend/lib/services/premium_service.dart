import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages the premium subscription state.
///
/// Uses [FlutterSecureStorage] for persistence - the same secure hardware
/// storage backend used by [SecureKeyHelper] for the database encryption key.
class PremiumService {
  PremiumService._();

  /// Thread-safe singleton instance.
  static final PremiumService instance = PremiumService._();

  static const String _premiumKey = 'is_premium';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Returns `true` if the user has an active premium subscription.
  Future<bool> isPremium() async {
    final value = await _storage.read(key: _premiumKey);
    return value == 'true';
  }

  /// Persists the premium subscription status.
  Future<void> setPremium({required bool value}) async {
    await _storage.write(key: _premiumKey, value: value.toString());
  }
}
