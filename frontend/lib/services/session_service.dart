import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final class SessionService {
  SessionService._();

  static final SessionService instance = SessionService._();

  static const _accessTokenKey = 'maki_access_token';
  static const _debugToken = String.fromEnvironment('MAKI_ACCESS_TOKEN');

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> accessToken() async {
    final stored = await _storage.read(key: _accessTokenKey);
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }
    return kDebugMode && _debugToken.isNotEmpty ? _debugToken : null;
  }

  Future<void> saveAccessToken(String token) async {
    final normalized = token.trim();
    if (normalized.isEmpty) {
      throw const FormatException('Oturum belirteci boş olamaz.');
    }
    await _storage.write(key: _accessTokenKey, value: normalized);
  }

  Future<void> clear() => _storage.delete(key: _accessTokenKey);
}
