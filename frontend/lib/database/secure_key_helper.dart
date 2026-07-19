import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureKeyHelper {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyName = 'maki_db_encryption_key';

  static Future<String> getOrCreateEncryptionKey() async {
    try {
      String? key = await _storage.read(key: _keyName);
      if (key == null || key.isEmpty) {
        key = _generateSecureKey();
        await _storage.write(key: _keyName, value: key);
      }
      return key;
    } catch (e) {
      return 'maki_secure_encryption_key_120_hardware_fallback';
    }
  }

  static String _generateSecureKey() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }
}
