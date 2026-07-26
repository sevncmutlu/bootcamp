import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:maki_app/features/profile/domain/entities/settings_entity.dart';
import 'package:maki_app/features/profile/domain/repositories/settings_repository.dart';
import 'package:maki_app/features/profile/presentation/bloc/settings_bloc.dart';
import 'package:maki_app/features/profile/presentation/bloc/settings_event.dart';
import 'package:maki_app/features/profile/presentation/bloc/settings_state.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late SettingsBloc settingsBloc;
  late MockSettingsRepository mockRepository;

  final tSettings = SettingsEntity(
    primaryGoal: 'track_spending',
    isPremium: false,
    themeMode: 'system',
    accentColor: 'green',
    language: 'tr',
  );

  setUp(() {
    mockRepository = MockSettingsRepository();
    settingsBloc = SettingsBloc(repository: mockRepository);
  });

  tearDown(() {
    settingsBloc.close();
  });

  test('initial state is correct', () {
    expect(settingsBloc.state.isLoading, isTrue);
    expect(settingsBloc.state.settings, isNull);
    expect(settingsBloc.state.error, isNull);
  });

  group('LoadSettingsEvent', () {
    test('emits loading then settings when successful', () async {
      when(() => mockRepository.getSettings()).thenAnswer((_) async => tSettings);

      final expectedStates = [
        SettingsState(isLoading: true, settings: null, error: null),
        SettingsState(isLoading: false, settings: tSettings, error: null),
      ];

      expectLater(settingsBloc.stream, emitsInOrder(expectedStates));

      settingsBloc.add(LoadSettingsEvent());
    });

    test('emits error when repository throws exception', () async {
      when(() => mockRepository.getSettings()).thenThrow(Exception('DB Error'));

      final expectedStates = [
        SettingsState(isLoading: true, settings: null, error: null),
        SettingsState(isLoading: false, settings: null, error: 'Ayarlar yüklenirken bir hata oluştu.'),
      ];

      expectLater(settingsBloc.stream, emitsInOrder(expectedStates));

      settingsBloc.add(LoadSettingsEvent());
    });
  });

  group('UpdatePrimaryGoalEvent', () {
    test('emits updated settings when successful', () async {
      when(() => mockRepository.updatePrimaryGoal(any())).thenAnswer((_) async => {});

      // First load settings so state has settings
      settingsBloc.emit(SettingsState(isLoading: false, settings: tSettings, error: null));

      final tUpdatedSettings = SettingsEntity(
        primaryGoal: 'pay_debt',
        isPremium: false,
        themeMode: 'system',
        accentColor: 'green',
        language: 'tr',
      );

      final expectedStates = [
        SettingsState(isLoading: false, settings: tUpdatedSettings, error: null),
      ];

      expectLater(settingsBloc.stream, emitsInOrder(expectedStates));

      settingsBloc.add(UpdatePrimaryGoalEvent('pay_debt'));
      
      await Future.delayed(Duration.zero);
      verify(() => mockRepository.updatePrimaryGoal('pay_debt')).called(1);
    });

    test('emits error when updating fails', () async {
      when(() => mockRepository.updatePrimaryGoal(any())).thenThrow(Exception());

      // Pre-seed state so isLoading is false
      settingsBloc.emit(SettingsState(isLoading: false, settings: tSettings, error: null));

      final expectedStates = [
        SettingsState(isLoading: false, settings: tSettings, error: 'Hedef güncellenemedi.'),
      ];

      expectLater(settingsBloc.stream, emitsInOrder(expectedStates));

      settingsBloc.add(UpdatePrimaryGoalEvent('pay_debt'));
    });
  });

  group('ClearAllDataEvent', () {
    test('emits success when successful', () async {
      when(() => mockRepository.clearAllData()).thenAnswer((_) async => {});

      // Initial state has isLoading: true, so the copyWith will inherit that.
      final expectedStates = [
        SettingsState(isLoading: true, settings: null, error: null, dataCleared: true),
      ];

      expectLater(settingsBloc.stream, emitsInOrder(expectedStates));

      settingsBloc.add(ClearAllDataEvent());
    });
  });
}
