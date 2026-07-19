import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OnboardingService {
  OnboardingService._();

  static final OnboardingService instance = OnboardingService._();

  static const String _onboardingKey = 'has_completed_onboarding';
  static const String _primaryGoalKey = 'primary_financial_goal';
  static const String _themeModeKey = 'app_theme_mode';
  static const String _accentKey = 'app_theme_accent';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<bool> hasCompletedOnboarding() async {
    final value = await _storage.read(key: _onboardingKey);
    return value == 'true';
  }

  Future<void> setCompletedOnboarding(bool value) async {
    await _storage.write(key: _onboardingKey, value: value.toString());
  }

  Future<String?> getPrimaryGoal() async {
    return await _storage.read(key: _primaryGoalKey);
  }

  Future<void> setPrimaryGoal(String goal) async {
    await _storage.write(key: _primaryGoalKey, value: goal);
  }

  Future<String> getThemeMode() async {
    final value = await _storage.read(key: _themeModeKey);
    return value ?? 'system';
  }

  Future<void> setThemeMode(String mode) async {
    await _storage.write(key: _themeModeKey, value: mode);
  }

  Future<String> getAccent() async {
    final value = await _storage.read(key: _accentKey);
    return value ?? 'forest';
  }

  Future<void> setAccent(String key) async {
    await _storage.write(key: _accentKey, value: key);
  }
}
