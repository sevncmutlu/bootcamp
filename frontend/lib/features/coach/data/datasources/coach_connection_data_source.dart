import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class CoachConnectionDataSource {
  Future<String?> getGeminiApiKey();
  Future<bool> hasGeminiApiKey();
  Future<void> saveGeminiApiKey(String apiKey);
  Future<void> clearGeminiApiKey();
}

class CoachConnectionDataSourceImpl implements CoachConnectionDataSource {
  CoachConnectionDataSourceImpl(this._storage);

  final FlutterSecureStorage _storage;

  static const _geminiKey = 'maki_gemini_api_key';

  @override
  Future<String?> getGeminiApiKey() async {
    final value = (await _storage.read(key: _geminiKey))?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  @override
  Future<bool> hasGeminiApiKey() async => (await getGeminiApiKey()) != null;

  @override
  Future<void> saveGeminiApiKey(String apiKey) async {
    final cleaned = apiKey.trim();
    if (cleaned.length < 20 ||
        cleaned.length > 256 ||
        cleaned.contains(RegExp(r'\s'))) {
      throw const FormatException('Gemini anahtarı geçersiz.');
    }
    await _storage.write(key: _geminiKey, value: cleaned);
  }

  @override
  Future<void> clearGeminiApiKey() async {
    await _storage.delete(key: _geminiKey);
  }
}
