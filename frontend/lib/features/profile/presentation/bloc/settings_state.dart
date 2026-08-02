import 'package:equatable/equatable.dart';
import 'package:maki_app/features/profile/domain/entities/settings_entity.dart';

class SettingsState extends Equatable {
  final bool isLoading;
  final SettingsEntity? settings;
  final String? error;
  final bool dataCleared;

  const SettingsState({
    required this.isLoading,
    this.settings,
    this.error,
    this.dataCleared = false,
  });

  factory SettingsState.initial() {
    return const SettingsState(isLoading: true);
  }

  SettingsState copyWith({
    bool? isLoading,
    SettingsEntity? settings,
    String? error,
    bool? dataCleared,
    bool clearError = false,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      settings: settings ?? this.settings,
      error: clearError ? null : (error ?? this.error),
      dataCleared: dataCleared ?? this.dataCleared,
    );
  }

  @override
  List<Object?> get props => [isLoading, settings, error, dataCleared];
}
