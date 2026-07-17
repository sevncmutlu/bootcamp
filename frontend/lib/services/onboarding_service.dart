import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages the onboarding completion state on-device.
///
/// Uses [FlutterSecureStorage] for persistence.
class OnboardingService {
  OnboardingService._();

  /// Thread-safe singleton instance.
  static final OnboardingService instance = OnboardingService._();

  static const String _onboardingKey = 'has_completed_onboarding';
  static const String _primaryGoalKey = 'primary_financial_goal';
  static const String _themeModeKey = 'app_theme_mode';
  static const String _appLocaleKey = 'app_locale';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Returns `true` if the user has completed the onboarding flow.
  Future<bool> hasCompletedOnboarding() async {
    final value = await _storage.read(key: _onboardingKey);
    return value == 'true';
  }

  /// Persists the onboarding completion status.
  Future<void> setCompletedOnboarding(bool value) async {
    await _storage.write(key: _onboardingKey, value: value.toString());
  }

  /// Returns the saved primary financial goal.
  Future<String?> getPrimaryGoal() async {
    return await _storage.read(key: _primaryGoalKey);
  }

  /// Persists the selected primary financial goal.
  Future<void> setPrimaryGoal(String goal) async {
    await _storage.write(key: _primaryGoalKey, value: goal);
  }

  /// Returns the saved theme mode ('system', 'light', 'dark').
  Future<String> getThemeMode() async {
    final value = await _storage.read(key: _themeModeKey);
    return value ?? 'system';
  }

  /// Persists the selected theme mode.
  Future<void> setThemeMode(String mode) async {
    await _storage.write(key: _themeModeKey, value: mode);
  }

  /// Returns the saved app locale.
  Future<String?> getAppLocale() async {
    return await _storage.read(key: _appLocaleKey);
  }

  /// Persists the selected app locale.
  Future<void> setAppLocale(String locale) async {
    await _storage.write(key: _appLocaleKey, value: locale);
  }
}
