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
    when(() => mockRepository.localizedPrice).thenReturn(null);
    when(() => mockRepository.purchaseAvailable).thenReturn(false);
    bloc = PremiumBloc(repository: mockRepository);
  });

  tearDown(() => bloc.close());

  group('PremiumBloc', () {
    test('initial state is correct', () {
      expect(bloc.state, PremiumState.initial());
    });

    test('loads the server-authoritative premium state', () async {
      when(() => mockRepository.isPremium()).thenAnswer((_) async => true);

      expectLater(
        bloc.stream,
        emits(PremiumState.initial().copyWith(isPremium: true)),
      );
      bloc.add(CheckPremiumStatusEvent());
    });

    test('activates premium only after verified purchase', () async {
      when(() => mockRepository.purchase()).thenAnswer((_) async => true);

      expectLater(
        bloc.stream,
        emitsInOrder([
          PremiumState.initial().copyWith(isLoading: true, clearError: true),
          PremiumState.initial().copyWith(
            isLoading: false,
            isPremium: true,
            purchaseSuccess: true,
          ),
        ]),
      );
      bloc.add(PurchasePremiumEvent());
    });

    test('keeps premium locked when verification fails', () async {
      when(() => mockRepository.purchase()).thenThrow(Exception('Failed'));

      expectLater(
        bloc.stream,
        emitsInOrder([
          PremiumState.initial().copyWith(isLoading: true, clearError: true),
          PremiumState.initial().copyWith(
            isLoading: false,
            error: 'Abonelik etkinleştirilemedi.',
          ),
        ]),
      );
      bloc.add(PurchasePremiumEvent());
    });
  });
}
