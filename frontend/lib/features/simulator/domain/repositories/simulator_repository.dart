import 'package:maki_app/features/simulator/domain/entities/debt_entity.dart';
import 'package:maki_app/features/simulator/domain/entities/simulation_result_entity.dart';

abstract class SimulatorRepository {
  Future<SimulationResultEntity> simulatePayoff({
    required List<DebtEntity> debts,
    required double extraBudget,
    required String strategy, // 'avalanche' or 'snowball'
  });
}
