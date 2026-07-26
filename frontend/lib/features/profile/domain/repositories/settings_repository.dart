import 'package:maki_app/features/profile/domain/entities/settings_entity.dart';

abstract class SettingsRepository {
  Future<SettingsEntity> getSettings();
  Future<void> updatePrimaryGoal(String goal);
  Future<void> updateThemeMode(String mode);
  Future<void> updateAccentColor(String color);
  Future<void> updateLanguage(String language);
  Future<void> updatePremiumStatus(bool isPremium);
  Future<void> clearAllData();
}
