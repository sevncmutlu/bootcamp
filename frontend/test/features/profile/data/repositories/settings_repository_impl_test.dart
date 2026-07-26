import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:maki_app/core/database/database.dart';
import 'package:maki_app/features/profile/data/datasources/onboarding_local_data_source.dart';
import 'package:maki_app/features/premium/data/datasources/premium_local_data_source.dart';
import 'package:maki_app/features/profile/data/repositories/settings_repository_impl.dart';


class MockOnboardingLocalDataSource extends Mock implements OnboardingLocalDataSource {}
class MockPremiumLocalDataSource extends Mock implements PremiumLocalDataSource {}
class MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  late SettingsRepositoryImpl repository;
  late MockOnboardingLocalDataSource mockOnboardingDataSource;
  late MockPremiumLocalDataSource mockPremiumDataSource;
  late MockAppDatabase mockDatabase;

  setUp(() {
    mockOnboardingDataSource = MockOnboardingLocalDataSource();
    mockPremiumDataSource = MockPremiumLocalDataSource();
    mockDatabase = MockAppDatabase();

    repository = SettingsRepositoryImpl(
      onboardingDataSource: mockOnboardingDataSource,
      premiumDataSource: mockPremiumDataSource,
      database: mockDatabase,
    );
  });

  group('getSettings', () {
    test('returns SettingsEntity with default values when null', () async {
      when(() => mockOnboardingDataSource.getPrimaryGoal()).thenAnswer((_) async => null);
      when(() => mockPremiumDataSource.isPremium()).thenAnswer((_) async => false);
      when(() => mockOnboardingDataSource.getThemeMode()).thenAnswer((_) async => 'system');
      when(() => mockOnboardingDataSource.getAccent()).thenAnswer((_) async => 'green');
      when(() => mockOnboardingDataSource.getLanguage()).thenAnswer((_) async => 'tr');

      final result = await repository.getSettings();

      expect(result.primaryGoal, 'track_spending');
      expect(result.isPremium, false);
      expect(result.themeMode, 'system');
      expect(result.accentColor, 'green');
      expect(result.language, 'tr');
    });

    test('returns SettingsEntity with retrieved values', () async {
      when(() => mockOnboardingDataSource.getPrimaryGoal()).thenAnswer((_) async => 'pay_debt');
      when(() => mockPremiumDataSource.isPremium()).thenAnswer((_) async => true);
      when(() => mockOnboardingDataSource.getThemeMode()).thenAnswer((_) async => 'dark');
      when(() => mockOnboardingDataSource.getAccent()).thenAnswer((_) async => 'blue');
      when(() => mockOnboardingDataSource.getLanguage()).thenAnswer((_) async => 'en');

      final result = await repository.getSettings();

      expect(result.primaryGoal, 'pay_debt');
      expect(result.isPremium, true);
      expect(result.themeMode, 'dark');
      expect(result.accentColor, 'blue');
      expect(result.language, 'en');
    });
  });

  group('update actions', () {
    test('updatePrimaryGoal calls dataSource', () async {
      when(() => mockOnboardingDataSource.setPrimaryGoal(any())).thenAnswer((_) async => {});

      await repository.updatePrimaryGoal('pay_debt');
      verify(() => mockOnboardingDataSource.setPrimaryGoal('pay_debt')).called(1);
    });

    test('updateThemeMode calls dataSource', () async {
      when(() => mockOnboardingDataSource.setThemeMode(any())).thenAnswer((_) async => {});

      await repository.updateThemeMode('dark');
      verify(() => mockOnboardingDataSource.setThemeMode('dark')).called(1);
    });

    test('updateAccentColor calls dataSource', () async {
      when(() => mockOnboardingDataSource.setAccent(any())).thenAnswer((_) async => {});

      await repository.updateAccentColor('blue');
      verify(() => mockOnboardingDataSource.setAccent('blue')).called(1);
    });

    test('updateLanguage calls dataSource', () async {
      when(() => mockOnboardingDataSource.setLanguage(any())).thenAnswer((_) async => {});

      await repository.updateLanguage('en');
      verify(() => mockOnboardingDataSource.setLanguage('en')).called(1);
    });

    test('updatePremiumStatus calls dataSource', () async {
      when(() => mockPremiumDataSource.setPremium(any())).thenAnswer((_) async => {});

      await repository.updatePremiumStatus(true);
      verify(() => mockPremiumDataSource.setPremium(true)).called(1);
    });
  });

  group('clearAllData', () {
    test('SettingsRepositoryImpl clearAllData clears database and preferences', () async {
      when(() => mockDatabase.clearAllData()).thenAnswer((_) async => {});
      when(() => mockOnboardingDataSource.clearAllData()).thenAnswer((_) async => {});
      
      await repository.clearAllData();
      
      verify(() => mockDatabase.clearAllData()).called(1);
      verify(() => mockOnboardingDataSource.clearAllData()).called(1);
    });
  });
}
