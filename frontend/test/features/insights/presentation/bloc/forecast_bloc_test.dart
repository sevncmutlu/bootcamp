import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/features/insights/domain/entities/forecast_day_entity.dart';
import 'package:maki_app/features/insights/domain/repositories/insights_repository.dart';
import 'package:maki_app/features/insights/presentation/bloc/forecast_bloc.dart';
import 'package:maki_app/features/insights/presentation/bloc/forecast_event.dart';
import 'package:maki_app/features/insights/presentation/bloc/forecast_state.dart';
import 'package:mocktail/mocktail.dart';

class MockInsightsRepository extends Mock implements InsightsRepository {}

void main() {
  late MockInsightsRepository mockRepository;
  late ForecastBloc bloc;

  setUp(() {
    mockRepository = MockInsightsRepository();
    bloc = ForecastBloc(repository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('ForecastBloc', () {
    final tForecasts = [
      ForecastDayEntity(date: '2023-01-01', predictedAmount: 100),
      ForecastDayEntity(date: '2023-01-02', predictedAmount: 120),
    ];

    test('initial state is ForecastInitial', () {
      expect(bloc.state, isA<ForecastInitial>());
    });

    test('emits [ForecastLoading, ForecastLoaded] when LoadForecastEvent is successful', () async {
      when(() => mockRepository.getForecast()).thenAnswer((_) async => tForecasts);

      final expectedStates = [
        isA<ForecastLoading>(),
        isA<ForecastLoaded>(),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(LoadForecastEvent());
    });

    test('emits [ForecastLoading, ForecastError] when LoadForecastEvent fails', () async {
      when(() => mockRepository.getForecast()).thenThrow(Exception('Failed'));

      final expectedStates = [
        isA<ForecastLoading>(),
        isA<ForecastError>(),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(LoadForecastEvent());
    });
  });
}
