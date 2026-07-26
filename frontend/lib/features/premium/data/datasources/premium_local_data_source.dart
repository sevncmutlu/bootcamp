import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class PremiumLocalDataSource {
  Future<bool> isPremium();
  Future<void> setPremium(bool value);
}

class PremiumLocalDataSourceImpl implements PremiumLocalDataSource {
  final FlutterSecureStorage _storage;
  static const _key = 'maki_premium_status';

  PremiumLocalDataSourceImpl(this._storage);

  @override
  Future<bool> isPremium() async {
    final status = await _storage.read(key: _key);
    return status == 'true';
  }

  @override
  Future<void> setPremium(bool value) async {
    await _storage.write(key: _key, value: value.toString());
  }
}
