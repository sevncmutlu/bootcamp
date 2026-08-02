import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/features/insights/domain/entities/inflation_data_entity.dart';
import 'package:maki_app/features/insights/domain/repositories/insights_repository.dart';
import 'package:maki_app/features/insights/presentation/bloc/inflation_bloc.dart';
import 'package:maki_app/features/insights/presentation/bloc/inflation_event.dart';
import 'package:maki_app/features/insights/presentation/bloc/inflation_state.dart';
import 'package:mocktail/mocktail.dart';

class MockInsightsRepository extends Mock implements InsightsRepository {}

void main() {
  late MockInsightsRepository mockRepository;
  late InflationBloc bloc;

  setUp(() {
    mockRepository = MockInsightsRepository();
    bloc = InflationBloc(repository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('InflationBloc', () {
    const tInflation = InflationDataEntity(
      hasPriceBasket: false,
      personalInflation: null,
      officialInflation: null,
      breakdowns: [],
    );

    test('initial state is InflationInitial', () {
      expect(bloc.state, isA<InflationInitial>());
    });

    test(
      'emits [InflationLoading, InflationLoaded] when LoadInflationEvent is successful',
      () async {
        when(
          () => mockRepository.getInflation(),
        ).thenAnswer((_) async => tInflation);

        final expectedStates = [
          isA<InflationLoading>(),
          isA<InflationLoaded>(),
        ];

        expectLater(bloc.stream, emitsInOrder(expectedStates));
        bloc.add(LoadInflationEvent());
      },
    );

    test(
      'emits [InflationLoading, InflationError] when LoadInflationEvent fails',
      () async {
        when(
          () => mockRepository.getInflation(),
        ).thenThrow(Exception('Failed'));

        final expectedStates = [isA<InflationLoading>(), isA<InflationError>()];

        expectLater(bloc.stream, emitsInOrder(expectedStates));
        bloc.add(LoadInflationEvent());
      },
    );
  });
}
