import 'package:maki_app/core/database/database.dart';
import 'package:maki_app/features/profile/data/datasources/onboarding_local_data_source.dart';
import 'package:maki_app/features/premium/data/datasources/premium_local_data_source.dart';
import 'package:maki_app/features/profile/domain/entities/settings_entity.dart';
import 'package:maki_app/features/profile/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final OnboardingLocalDataSource onboardingDataSource;
  final PremiumLocalDataSource premiumDataSource;
  final AppDatabase database;

  SettingsRepositoryImpl({
    required this.onboardingDataSource,
    required this.premiumDataSource,
    required this.database,
  });

  @override
  Future<SettingsEntity> getSettings() async {
    final goal = await onboardingDataSource.getPrimaryGoal();
    final premium = await premiumDataSource.isPremium();
    final themeMode = await onboardingDataSource.getThemeMode();
    final accent = await onboardingDataSource.getAccent();
    final lang = await onboardingDataSource.getLanguage();

    return SettingsEntity(
      primaryGoal: goal ?? 'track_spending',
      isPremium: premium,
      themeMode: themeMode,
      accentColor: accent,
      language: lang,
    );
  }

  @override
  Future<void> updatePrimaryGoal(String goal) async {
    await onboardingDataSource.setPrimaryGoal(goal);
  }

  @override
  Future<void> updateThemeMode(String mode) async {
    await onboardingDataSource.setThemeMode(mode);
  }

  @override
  Future<void> updateAccentColor(String color) async {
    await onboardingDataSource.setAccent(color);
  }

  @override
  Future<void> updateLanguage(String language) async {
    await onboardingDataSource.setLanguage(language);
  }

  @override
  Future<void> updatePremiumStatus(bool isPremium) async {
    await premiumDataSource.setPremium(isPremium);
  }

  @override
  Future<void> clearAllData() async {
    await database.clearAllData();
  }
}
