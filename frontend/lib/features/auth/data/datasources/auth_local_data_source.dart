import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class AuthLocalDataSource {
  Future<String?> getAccessToken();
  Future<void> saveAccessToken(String token);
  Future<void> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage _storage;

  AuthLocalDataSourceImpl(this._storage);

  static const _accessTokenKey = 'maki_access_token';
  static const _debugToken = String.fromEnvironment('MAKI_ACCESS_TOKEN');

  @override
  Future<String?> getAccessToken() async {
    final stored = await _storage.read(key: _accessTokenKey);
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }
    if (_debugToken.isNotEmpty) {
      return _debugToken;
    }
    if (kDebugMode) {
      const defaultToken = 'maki_debug_anonymous_session_token';
      await _storage.write(key: _accessTokenKey, value: defaultToken);
      return defaultToken;
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
