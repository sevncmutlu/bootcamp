import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages the onboarding completion state on-device.
///
/// Uses [FlutterSecureStorage] for persistence.
class OnboardingService {
  OnboardingService._();

  /// Thread-safe singleton instance.
  static final OnboardingService instance = OnboardingService._();

  static const String _onboardingKey = 'has_completed_onboarding';

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
}
