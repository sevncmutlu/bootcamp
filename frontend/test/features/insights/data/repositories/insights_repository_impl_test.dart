import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/core/database/database.dart';
import 'package:maki_app/core/network/maki_api_client.dart';
import 'package:maki_app/features/insights/data/repositories/insights_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockMakiApiClient extends Mock implements MakiApiClient {}

void main() {
  late AppDatabase database;
  late MockMakiApiClient mockApiClient;
  late InsightsRepositoryImpl repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    mockApiClient = MockMakiApiClient();
    repository = InsightsRepositoryImpl(
      database: database,
      apiClient: mockApiClient,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('InsightsRepositoryImpl', () {
    test('getForecast throws MakiApiException when not enough data (less than 3 days)', () async {
      final companion = ExpensesCompanion.insert(
        title: 'Test',
        amount: 10,
        date: DateTime.now(),
        category: 'Food',
      );
      await database.insertExpense(companion);
      
      expect(
        () => repository.getForecast(),
        throwsA(isA<MakiApiException>()),
      );
    });

    test('getForecast returns forecasts when enough data is available', () async {
      final today = DateTime.now();
      // Insert expenses for 3 different days
      await database.insertExpense(ExpensesCompanion.insert(
        title: 'Day 1', amount: 10, date: today, category: 'Food',
      ));
      await database.insertExpense(ExpensesCompanion.insert(
        title: 'Day 2', amount: 20, date: today.subtract(const Duration(days: 1)), category: 'Food',
      ));
      await database.insertExpense(ExpensesCompanion.insert(
        title: 'Day 3', amount: 30, date: today.subtract(const Duration(days: 2)), category: 'Food',
      ));

      when(() => mockApiClient.forecast(relativeIndexes: any(named: 'relativeIndexes')))
          .thenAnswer((_) async => const ForecastReply(predictions: [110, 120, 130], modelName: 'test'));

      final forecasts = await repository.getForecast();

      expect(forecasts, isNotEmpty);
      expect(forecasts.length, 3);
      verify(() => mockApiClient.forecast(relativeIndexes: any(named: 'relativeIndexes'))).called(1);
    });

    test('getInflation returns empty inflation data', () async {
      final inflation = await repository.getInflation();

      expect(inflation.hasPriceBasket, isFalse);
      expect(inflation.personalInflation, isNull);
      expect(inflation.officialInflation, isNull);
      expect(inflation.breakdowns, isEmpty);
    });
  });
}
