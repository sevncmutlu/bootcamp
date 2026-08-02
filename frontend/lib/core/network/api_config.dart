import 'package:maki_app/core/config/app_environment.dart';

class ApiConfig {
  static String get baseUrl => AppEnvironment.current.backendUri.toString();
}
