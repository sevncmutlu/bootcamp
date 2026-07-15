import 'dart:io';

class ApiConfig {
  /// Resolves the backend base URL dynamically depending on the current platform context.
  /// Android emulator connects via 10.0.2.2, while iOS/Desktop connects via localhost.
  static String get baseUrl {
    return Platform.isAndroid ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
  }
}
