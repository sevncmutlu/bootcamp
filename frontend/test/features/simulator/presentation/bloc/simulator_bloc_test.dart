import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/features/simulator/domain/entities/debt_entity.dart';
import 'package:maki_app/features/simulator/domain/entities/simulation_result_entity.dart';
import 'package:maki_app/features/simulator/domain/repositories/simulator_repository.dart';
import 'package:maki_app/features/simulator/presentation/bloc/simulator_bloc.dart';
import 'package:maki_app/features/simulator/presentation/bloc/simulator_event.dart';
import 'package:maki_app/features/simulator/presentation/bloc/simulator_state.dart';
import 'package:mocktail/mocktail.dart';

class MockSimulatorRepository extends Mock implements SimulatorRepository {}

void main() {
  late MockSimulatorRepository mockRepository;
  late SimulatorBloc bloc;

  setUp(() {
    mockRepository = MockSimulatorRepository();
    bloc = SimulatorBloc(repository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('SimulatorBloc', () {
    test('initial state is correct', () {
      expect(bloc.state, SimulatorState.initial());
    });

    test('InitSimulatorEvent adds debts if state is empty', () {
      const debt = DebtEntity(id: '1', name: 'Card', balance: 100, minPayment: 10, interestRate: 1);
      
      bloc.add(const InitSimulatorEvent([debt]));
      
      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SimulatorState>().having((s) => s.debts.length, 'debts', 1),
        ]),
      );
    });

    test('SimulatePayoffEvent early returns if debts is empty', () {
      bloc.add(SimulatePayoffEvent());
      expect(bloc.state, SimulatorState.initial());
    });

    test('SimulatePayoffEvent runs simulation', () {
      const debt = DebtEntity(id: '1', name: 'Card', balance: 100, minPayment: 10, interestRate: 1);
      bloc.add(const InitSimulatorEvent([debt]));
      bloc.add(const UpdateBudgetEvent(50));
      
      const expectedResult = SimulationResultEntity(monthsToFree: 10, totalInterestPaid: 5, schedule: []);
      
      when(() => mockRepository.simulatePayoff(
        debts: any(named: 'debts'),
        extraBudget: any(named: 'extraBudget'),
        strategy: any(named: 'strategy'),
      )).thenAnswer((_) async => expectedResult);

      expectLater(
        bloc.stream,
        emitsThrough(isA<SimulatorState>().having((s) => s.result, 'result', expectedResult)),
      );

      bloc.add(SimulatePayoffEvent());
    });
  });
}
