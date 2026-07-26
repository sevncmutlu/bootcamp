import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class OnboardingLocalDataSource {
  Future<bool> hasCompletedOnboarding();
  Future<void> setCompletedOnboarding(bool value);
  Future<String?> getPrimaryGoal();
  Future<void> setPrimaryGoal(String goal);
  Future<String> getThemeMode();
  Future<void> setThemeMode(String mode);
  Future<String> getAccent();
  Future<void> setAccent(String key);
  Future<String> getLanguage();
  Future<void> setLanguage(String code);
}

class OnboardingLocalDataSourceImpl implements OnboardingLocalDataSource {
  final FlutterSecureStorage _storage;

  OnboardingLocalDataSourceImpl(this._storage);

  static const String _onboardingKey = 'has_completed_onboarding';
  static const String _primaryGoalKey = 'primary_financial_goal';
  static const String _themeModeKey = 'app_theme_mode';
  static const String _accentKey = 'app_theme_accent';
  static const String _languageKey = 'app_language';

  @override
  Future<bool> hasCompletedOnboarding() async {
    final value = await _storage.read(key: _onboardingKey);
    return value == 'true';
  }

  @override
  Future<void> setCompletedOnboarding(bool value) async {
    await _storage.write(key: _onboardingKey, value: value.toString());
  }

  @override
  Future<String?> getPrimaryGoal() async {
    return await _storage.read(key: _primaryGoalKey);
  }

  @override
  Future<void> setPrimaryGoal(String goal) async {
    await _storage.write(key: _primaryGoalKey, value: goal);
  }

  @override
  Future<String> getThemeMode() async {
    final value = await _storage.read(key: _themeModeKey);
    return value ?? 'system';
  }

  @override
  Future<void> setThemeMode(String mode) async {
    await _storage.write(key: _themeModeKey, value: mode);
  }

  @override
  Future<String> getAccent() async {
    final value = await _storage.read(key: _accentKey);
    return value ?? 'forest';
  }

  @override
  Future<void> setAccent(String key) async {
    await _storage.write(key: _accentKey, value: key);
  }

  @override
  Future<String> getLanguage() async {
    final value = await _storage.read(key: _languageKey);
    return value ?? 'en';
  }

  @override
  Future<void> setLanguage(String code) async {
    await _storage.write(key: _languageKey, value: code);
  }
}
