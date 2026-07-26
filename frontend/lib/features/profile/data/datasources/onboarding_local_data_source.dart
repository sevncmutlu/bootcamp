import 'package:shared_preferences/shared_preferences.dart';

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
  Future<void> clearAllData();
}

class OnboardingLocalDataSourceImpl implements OnboardingLocalDataSource {
  final SharedPreferences _prefs;

  OnboardingLocalDataSourceImpl(this._prefs);

  static const String _onboardingKey = 'has_completed_onboarding';
  static const String _primaryGoalKey = 'primary_financial_goal';
  static const String _themeModeKey = 'app_theme_mode';
  static const String _accentKey = 'app_theme_accent';
  static const String _languageKey = 'app_language';

  @override
  Future<bool> hasCompletedOnboarding() async {
    return _prefs.getBool(_onboardingKey) ?? false;
  }

  @override
  Future<void> setCompletedOnboarding(bool value) async {
    await _prefs.setBool(_onboardingKey, value);
  }

  @override
  Future<String?> getPrimaryGoal() async {
    return _prefs.getString(_primaryGoalKey);
  }

  @override
  Future<void> setPrimaryGoal(String goal) async {
    await _prefs.setString(_primaryGoalKey, goal);
  }

  @override
  Future<String> getThemeMode() async {
    return _prefs.getString(_themeModeKey) ?? 'system';
  }

  @override
  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(_themeModeKey, mode);
  }

  @override
  Future<String> getAccent() async {
    return _prefs.getString(_accentKey) ?? 'forest';
  }

  @override
  Future<void> setAccent(String key) async {
    await _prefs.setString(_accentKey, key);
  }

  @override
  Future<String> getLanguage() async {
    return _prefs.getString(_languageKey) ?? 'system';
  }

  @override
  Future<void> setLanguage(String code) async {
    await _prefs.setString(_languageKey, code);
  }

  @override
  Future<void> clearAllData() async {
    await _prefs.remove(_onboardingKey);
    await _prefs.remove(_primaryGoalKey);
    await _prefs.remove(_themeModeKey);
    await _prefs.remove(_accentKey);
    await _prefs.remove(_languageKey);
  }
}
