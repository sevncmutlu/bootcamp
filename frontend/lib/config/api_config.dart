import 'dart:io';

import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    const definedUrl = String.fromEnvironment('BACKEND_URL');
    if (definedUrl.isNotEmpty) {
      final uri = Uri.tryParse(definedUrl);
      if (uri == null || !uri.hasAuthority) {
        throw StateError('API adresi geçersiz.');
      }
      if (kReleaseMode && uri.scheme != 'https') {
        throw StateError('Üretim API adresi HTTPS kullanmalıdır.');
      }
      return uri.toString();
    }
    if (kReleaseMode) {
      throw StateError('Üretim API adresi tanımlanmadı.');
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }
}
