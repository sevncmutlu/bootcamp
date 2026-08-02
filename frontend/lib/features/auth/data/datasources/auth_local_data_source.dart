import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class AuthLocalDataSource {
  Future<String?> getAccessToken();
  Future<void> saveAccessToken(String token);
  Future<void> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const _accessTokenKey = 'maki_access_token';
  static const _debugToken = String.fromEnvironment('MAKI_ACCESS_TOKEN');

  AuthLocalDataSourceImpl(
    this._storage, {
    String developmentToken = _debugToken,
  }) : _developmentToken = developmentToken.trim();

  final FlutterSecureStorage _storage;
  final String _developmentToken;

  @override
  Future<String?> getAccessToken() async {
    if (_developmentToken.isNotEmpty) {
      return _developmentToken;
    }
    final stored = await _storage.read(key: _accessTokenKey);
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }
    return null;
  }

  @override
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  @override
  Future<void> clearSession() async {
    await _storage.delete(key: _accessTokenKey);
  }
}
