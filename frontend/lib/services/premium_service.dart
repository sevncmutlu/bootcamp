import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:maki_app/services/maki_api_client.dart';

class PremiumService {
  PremiumService._();

  static final PremiumService instance = PremiumService._();

  static const _debugPremiumKey = 'debug_is_premium';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<bool> isPremium() async {
    if (kDebugMode) {
      final override = await _storage.read(key: _debugPremiumKey);
      if (override != null) {
        return override == 'true';
      }
    }
    try {
      return await MakiApi.instance.hasActiveEntitlement();
    } on MakiApiException {
      return false;
    }
  }

  Future<void> setPremium({required bool value}) async {
    if (!kDebugMode) {
      throw StateError('Üretim abonelik hakkı yerelden değiştirilemez.');
    }
    await _storage.write(key: _debugPremiumKey, value: value.toString());
  }
}
