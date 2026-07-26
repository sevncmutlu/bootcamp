import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/features/premium/domain/repositories/premium_repository.dart';
import 'package:maki_app/features/premium/presentation/bloc/premium_bloc.dart';
import 'package:maki_app/features/premium/presentation/bloc/premium_event.dart';
import 'package:maki_app/features/premium/presentation/bloc/premium_state.dart';
import 'package:mocktail/mocktail.dart';

class MockPremiumRepository extends Mock implements PremiumRepository {}

void main() {
  late MockPremiumRepository mockRepository;
  late PremiumBloc bloc;

  setUp(() {
    mockRepository = MockPremiumRepository();
    bloc = PremiumBloc(repository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('PremiumBloc', () {
    test('initial state is correct', () {
      expect(bloc.state, PremiumState.initial());
    });

    test('emits state with isPremium updated on CheckPremiumStatusEvent', () async {
      when(() => mockRepository.isPremium()).thenAnswer((_) async => true);

      final expectedStates = [
        PremiumState.initial().copyWith(isPremium: true),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(CheckPremiumStatusEvent());
    });

    test('emits correct states on PurchasePremiumEvent', () async {
      when(() => mockRepository.setPremium(true)).thenAnswer((_) async => {});

      final expectedStates = [
        PremiumState.initial().copyWith(isLoading: true, clearError: true),
        PremiumState.initial().copyWith(isLoading: false, isPremium: true, purchaseSuccess: true),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(PurchasePremiumEvent());
    });
    
    test('emits error state on PurchasePremiumEvent failure', () async {
      when(() => mockRepository.setPremium(true)).thenThrow(Exception('Failed'));

      final expectedStates = [
        PremiumState.initial().copyWith(isLoading: true, clearError: true),
        PremiumState.initial().copyWith(isLoading: false, error: 'Abonelik etkinleştirilemedi.'),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(PurchasePremiumEvent());
    });
  });
}
