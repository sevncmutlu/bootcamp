import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/core/config/app_environment.dart';
import 'package:maki_app/core/database/database.dart';
import 'package:maki_app/core/network/maki_api_client.dart';
import 'package:maki_app/features/gamification/data/datasources/gamification_local_data_source.dart';
import 'package:maki_app/features/gamification/data/repositories/gamification_repository_impl.dart';
import 'package:maki_app/features/gamification/domain/entities/daily_challenge_entity.dart';
import 'package:mocktail/mocktail.dart';

class MockGamificationLocalDataSource extends Mock
    implements GamificationLocalDataSource {}

class MockAppDatabase extends Mock implements AppDatabase {}

class MockMakiApiClient extends Mock implements MakiApiClient {}

void main() {
  late MockGamificationLocalDataSource mockDataSource;
  late MockAppDatabase mockDatabase;
  late MockMakiApiClient mockApiClient;
  late GamificationRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      UserGamificationState(id: 1, xp: 0, level: 1, badges: '[]'),
    );
    registerFallbackValue(
      DailyChallenge(
        id: '1',
        titleKey: 'test',
        descKey: 'test',
        xpReward: 10,
        isCompleted: false,
        date: DateTime.now(),
      ),
    );
  });

  setUp(() {
    mockDataSource = MockGamificationLocalDataSource();
    mockDatabase = MockAppDatabase();
    mockApiClient = MockMakiApiClient();
    repository = GamificationRepositoryImpl(
      gamificationDataSource: mockDataSource,
      database: mockDatabase,
      apiClient: mockApiClient,
      environment: AppEnvironment(
        stage: MakiStage.development,
        backendUri: Uri.parse('http://localhost:8000'),
      ),
    );
  });

  group('GamificationRepositoryImpl', () {
    test('getGamificationStatus returns entity', () async {
      when(() => mockDatabase.getGamificationState()).thenAnswer(
        (_) async =>
            UserGamificationState(id: 1, xp: 150, level: 2, badges: '[]'),
      );

      final result = await repository.getGamificationStatus();

      expect(result.xp, 150);
      expect(result.level, 2);
    });

    test('getDailyChallenges returns mapped entities', () async {
      final now = DateTime.now();
      when(() => mockDataSource.getOrSeedDailyChallenges(now)).thenAnswer(
        (_) async => [
          DailyChallenge(
            id: '1',
            titleKey: 'title',
            descKey: 'desc',
            xpReward: 50,
            isCompleted: false,
            date: now,
          ),
        ],
      );

      final result = await repository.getDailyChallenges(now);

      expect(result.length, 1);
      expect(result.first.xpReward, 50);
      expect(result.first.isCompleted, false);
    });

    test(
      'claimXP updates challenge and status, then returns new status',
      () async {
        final now = DateTime.now();
        final challengeEntity = DailyChallengeEntity(
          id: '1',
          titleKey: 'title',
          descKey: 'desc',
          xpReward: 100,
          isCompleted: true,
          date: now,
        );

        when(
          () => mockDataSource.updateChallenge(any()),
        ).thenAnswer((_) async => {});
        when(() => mockDataSource.getGamificationStatus()).thenAnswer(
          (_) async =>
              UserGamificationState(id: 1, xp: 50, level: 1, badges: '[]'),
        );
        when(
          () => mockDataSource.updateGamificationStatus(any()),
        ).thenAnswer((_) async => {});

        final result = await repository.claimXP(challengeEntity);

        // Previous xp = 50, reward = 100 -> new total = 150 -> level 2
        expect(result.xp, 150);
        expect(result.level, 2);

        verify(() => mockDataSource.updateChallenge(any())).called(1);
        verify(() => mockDataSource.updateGamificationStatus(any())).called(1);
      },
    );

    test(
      'development leaderboard uses local estimate without network',
      () async {
        final result = await repository.getLeaderboard(
          ageBand: '25-34',
          householdBand: '1',
          scoreBasisPoints: 3000,
        );

        expect(result.available, isFalse);
        expect(result.percentile, isNotNull);
        expect(result.cohortSize, '50-99');
        verifyNever(
          () => mockApiClient.leaderboard(
            ageBand: any(named: 'ageBand'),
            householdBand: any(named: 'householdBand'),
            scoreBasisPoints: any(named: 'scoreBasisPoints'),
          ),
        );
      },
    );

    test('staging leaderboard falls back locally when network fails', () async {
      repository = GamificationRepositoryImpl(
        gamificationDataSource: mockDataSource,
        database: mockDatabase,
        apiClient: mockApiClient,
        environment: AppEnvironment(
          stage: MakiStage.staging,
          backendUri: Uri.parse('https://staging-api.maki.test'),
        ),
      );
      when(
        () => mockApiClient.leaderboard(
          ageBand: any(named: 'ageBand'),
          householdBand: any(named: 'householdBand'),
          scoreBasisPoints: any(named: 'scoreBasisPoints'),
        ),
      ).thenThrow(
        const MakiApiException('service_unavailable', 'Hizmet kullanılamıyor.'),
      );

      final result = await repository.getLeaderboard(
        ageBand: '25-34',
        householdBand: '1',
        scoreBasisPoints: 4500,
      );

      expect(result.available, isFalse);
      expect(result.percentile, isNotNull);
      expect(result.cohortSize, '50-99');
      verify(
        () => mockApiClient.leaderboard(
          ageBand: '25-34',
          householdBand: '1',
          scoreBasisPoints: 4500,
        ),
      ).called(1);
    });
  });
}
