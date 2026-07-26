import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/features/gamification/domain/entities/daily_challenge_entity.dart';
import 'package:maki_app/features/gamification/domain/entities/gamification_status_entity.dart';
import 'package:maki_app/features/gamification/domain/repositories/gamification_repository.dart';
import 'package:maki_app/features/gamification/presentation/bloc/gamification_bloc.dart';
import 'package:maki_app/features/gamification/presentation/bloc/gamification_event.dart';
import 'package:maki_app/features/gamification/presentation/bloc/gamification_state.dart';
import 'package:mocktail/mocktail.dart';

class MockGamificationRepository extends Mock implements GamificationRepository {}

void main() {
  late MockGamificationRepository mockRepository;
  late GamificationBloc bloc;

  setUpAll(() {
    registerFallbackValue(DateTime.now());
    registerFallbackValue(DailyChallengeEntity(
      id: '1',
      titleKey: 'title',
      descKey: 'desc',
      xpReward: 10,
      isCompleted: true,
      date: DateTime.now(),
    ));
  });

  setUp(() {
    mockRepository = MockGamificationRepository();
    bloc = GamificationBloc(repository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('GamificationBloc', () {
    test('initial state is correct', () {
      expect(bloc.state, GamificationState.initial());
    });

    test('LoadGamificationDataEvent emits loaded state', () async {
      when(() => mockRepository.getDailyChallenges(any())).thenAnswer((_) async => []);
      when(() => mockRepository.getGamificationStatus())
          .thenAnswer((_) async => const GamificationStatusEntity(xp: 100, level: 2));
      when(() => mockRepository.getSavingsScoreBasisPoints()).thenAnswer((_) async => 5000);
      when(() => mockRepository.hasWeeklyIncome()).thenAnswer((_) async => true);

      final expectedStates = [
        isA<GamificationState>().having((s) => s.isLoading, 'isLoading', true),
        isA<GamificationState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.status?.xp, 'xp', 100)
            .having((s) => s.savingsScoreBasisPoints, 'savingsScoreBasisPoints', 5000)
            .having((s) => s.hasWeeklyIncome, 'hasWeeklyIncome', true),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(LoadGamificationDataEvent());
    });

    test('ClaimXPEvent does nothing if not completed or reward is 0', () async {
      final challenge = DailyChallengeEntity(
        id: '1',
        titleKey: 'title',
        descKey: 'desc',
        xpReward: 0,
        isCompleted: false,
        date: DateTime.now(),
      );

      bloc.add(ClaimXPEvent(challenge));
      // Shouldn't emit any new state since we return early
      expect(bloc.state, GamificationState.initial());
    });

    test('ClaimXPEvent emits updated status when successful', () async {
      final challenge = DailyChallengeEntity(
        id: '1',
        titleKey: 'title',
        descKey: 'desc',
        xpReward: 50,
        isCompleted: true, // MUST be true
        date: DateTime.now(),
      );

      when(() => mockRepository.claimXP(any()))
          .thenAnswer((_) async => const GamificationStatusEntity(xp: 50, level: 1));
      when(() => mockRepository.getDailyChallenges(any())).thenAnswer((_) async => []);

      final expectedStates = [
        isA<GamificationState>()
            .having((s) => s.status?.xp, 'xp', 50)
            .having((s) => s.newlyClaimedXP, 'newlyClaimedXP', 50),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(ClaimXPEvent(challenge));
    });
  });
}
