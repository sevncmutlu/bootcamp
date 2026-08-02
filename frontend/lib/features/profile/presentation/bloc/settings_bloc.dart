import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/features/profile/domain/repositories/settings_repository.dart';
import 'package:maki_app/features/profile/presentation/bloc/settings_event.dart';
import 'package:maki_app/features/profile/presentation/bloc/settings_state.dart';
import 'package:maki_app/features/profile/domain/entities/settings_entity.dart';
import 'dart:developer' as developer;

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository repository;

  SettingsBloc({required this.repository}) : super(SettingsState.initial()) {
    on<LoadSettingsEvent>(_onLoadSettings);
    on<UpdatePrimaryGoalEvent>(_onUpdatePrimaryGoal);
    on<UpdateThemeModeEvent>(_onUpdateThemeMode);
    on<UpdateAccentColorEvent>(_onUpdateAccentColor);
    on<UpdateLanguageEvent>(_onUpdateLanguage);
    on<UpgradeToPremiumEvent>(_onUpgradeToPremium);
    on<UpdatePremiumStatusEvent>(_onUpdatePremiumStatus);
    on<ClearAllDataEvent>(_onClearAllData);
  }

  Future<void> _onLoadSettings(
    LoadSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final settings = await repository.getSettings();
      emit(state.copyWith(isLoading: false, settings: settings));
    } catch (e, stackTrace) {
      developer.log(
        'Failed to load settings',
        error: e,
        stackTrace: stackTrace,
        name: 'SettingsBloc',
      );
      emit(state.copyWith(isLoading: false, error: 'errLoadSettings'));
    }
  }

  Future<void> _onUpdatePrimaryGoal(
    UpdatePrimaryGoalEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await repository.updatePrimaryGoal(event.goal);
      if (state.settings != null) {
        emit(
          state.copyWith(
            settings: SettingsEntity(
              primaryGoal: event.goal,
              isPremium: state.settings!.isPremium,
              themeMode: state.settings!.themeMode,
              accentColor: state.settings!.accentColor,
              language: state.settings!.language,
            ),
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(error: 'errUpdateGoal'));
    }
  }

  Future<void> _onUpdateThemeMode(
    UpdateThemeModeEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await repository.updateThemeMode(event.themeMode);
      if (state.settings != null) {
        emit(
          state.copyWith(
            settings: SettingsEntity(
              primaryGoal: state.settings!.primaryGoal,
              isPremium: state.settings!.isPremium,
              themeMode: event.themeMode,
              accentColor: state.settings!.accentColor,
              language: state.settings!.language,
            ),
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(error: 'errUpdateTheme'));
    }
  }

  Future<void> _onUpdateAccentColor(
    UpdateAccentColorEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await repository.updateAccentColor(event.accentColor);
      if (state.settings != null) {
        emit(
          state.copyWith(
            settings: SettingsEntity(
              primaryGoal: state.settings!.primaryGoal,
              isPremium: state.settings!.isPremium,
              themeMode: state.settings!.themeMode,
              accentColor: event.accentColor,
              language: state.settings!.language,
            ),
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(error: 'errUpdateAccent'));
    }
  }

  Future<void> _onUpdateLanguage(
    UpdateLanguageEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await repository.updateLanguage(event.language);
      if (state.settings != null) {
        emit(
          state.copyWith(
            settings: SettingsEntity(
              primaryGoal: state.settings!.primaryGoal,
              isPremium: state.settings!.isPremium,
              themeMode: state.settings!.themeMode,
              accentColor: state.settings!.accentColor,
              language: event.language,
            ),
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(error: 'errUpdateLang'));
    }
  }

  Future<void> _onUpgradeToPremium(
    UpgradeToPremiumEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await repository.updatePremiumStatus(true);
      if (state.settings != null) {
        emit(
          state.copyWith(
            settings: SettingsEntity(
              primaryGoal: state.settings!.primaryGoal,
              isPremium: true,
              themeMode: state.settings!.themeMode,
              accentColor: state.settings!.accentColor,
              language: state.settings!.language,
            ),
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(error: 'errUpdatePremium'));
    }
  }

  Future<void> _onUpdatePremiumStatus(
    UpdatePremiumStatusEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await repository.updatePremiumStatus(event.isPremium);
      if (state.settings != null) {
        emit(
          state.copyWith(
            settings: SettingsEntity(
              primaryGoal: state.settings!.primaryGoal,
              isPremium: event.isPremium,
              themeMode: state.settings!.themeMode,
              accentColor: state.settings!.accentColor,
              language: state.settings!.language,
            ),
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(error: 'errUpdatePremium'));
    }
  }

  Future<void> _onClearAllData(
    ClearAllDataEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await repository.clearAllData();
      emit(state.copyWith(dataCleared: true));
    } catch (e) {
      emit(state.copyWith(error: 'errClearData'));
    }
  }
}
