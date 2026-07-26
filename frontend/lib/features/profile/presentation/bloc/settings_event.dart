import 'package:equatable/equatable.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettingsEvent extends SettingsEvent {}

class UpdatePrimaryGoalEvent extends SettingsEvent {
  final String goal;

  const UpdatePrimaryGoalEvent(this.goal);

  @override
  List<Object?> get props => [goal];
}

class UpdateThemeModeEvent extends SettingsEvent {
  final String themeMode;

  const UpdateThemeModeEvent(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

class UpdateAccentColorEvent extends SettingsEvent {
  final String accentColor;

  const UpdateAccentColorEvent(this.accentColor);

  @override
  List<Object?> get props => [accentColor];
}

class UpdateLanguageEvent extends SettingsEvent {
  final String language;

  const UpdateLanguageEvent(this.language);

  @override
  List<Object?> get props => [language];
}

class UpgradeToPremiumEvent extends SettingsEvent {}

class UpdatePremiumStatusEvent extends SettingsEvent {
  final bool isPremium;

  const UpdatePremiumStatusEvent(this.isPremium);

  @override
  List<Object?> get props => [isPremium];
}

class ClearAllDataEvent extends SettingsEvent {}
