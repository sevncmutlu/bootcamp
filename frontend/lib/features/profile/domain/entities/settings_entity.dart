import 'package:equatable/equatable.dart';

class SettingsEntity extends Equatable {
  final String primaryGoal;
  final bool isPremium;
  final String themeMode;
  final String accentColor;
  final String language;

  const SettingsEntity({
    required this.primaryGoal,
    required this.isPremium,
    required this.themeMode,
    required this.accentColor,
    required this.language,
  });

  @override
  List<Object?> get props => [
    primaryGoal,
    isPremium,
    themeMode,
    accentColor,
    language,
  ];
}
