import 'dart:io';

class ApiConfig {
  static String get baseUrl {
    const definedUrl = String.fromEnvironment('BACKEND_URL');
    if (definedUrl.isNotEmpty) {
      return definedUrl;
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000';
      }
    } catch (_) {}
    return 'http://localhost:8000';
  }
}
