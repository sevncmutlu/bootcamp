import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/features/simulator/data/repositories/simulator_repository_impl.dart';
import 'package:maki_app/features/simulator/domain/entities/debt_entity.dart';
import 'package:maki_finance_core/maki_finance_core.dart';

void main() {
  late SimulatorRepositoryImpl repository;

  setUp(() {
    repository = SimulatorRepositoryImpl();
  });

  group('SimulatorRepositoryImpl', () {
    test('simulatePayoff calculates successfully', () async {
      final debts = [
        const DebtEntity(
          id: '1',
          name: 'Credit Card',
          balance: 1000,
          minPayment: 100,
          interestRate: 1.5,
        ), // minPayment 100
      ];

      final result = await repository.simulatePayoff(
        debts: debts,
        extraBudget: 50,
        strategy: 'snowball',
      );

      // It will take some months to pay 1000 with 150/month.
      expect(result.monthsToFree, greaterThan(0));
      expect(result.totalInterestPaid, greaterThanOrEqualTo(0));
      expect(result.schedule, isNotEmpty);
    });

    test(
      'simulatePayoff throws exception if payment plan is not safe',
      () async {
        final debts = [
          const DebtEntity(
            id: '1',
            name: 'Loan',
            balance: 10000,
            minPayment: 1,
            interestRate: 20.0,
          ), // interest much larger than min payment
        ];

        expect(
          () => repository.simulatePayoff(
            debts: debts,
            extraBudget: 0,
            strategy: 'snowball',
          ),
          throwsA(isA<DebtValidationException>()),
        );
      },
    );
  });
}
