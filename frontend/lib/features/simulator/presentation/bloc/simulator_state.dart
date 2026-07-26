import 'package:equatable/equatable.dart';
import 'package:maki_app/features/simulator/domain/entities/debt_entity.dart';
import 'package:maki_app/features/simulator/domain/entities/simulation_result_entity.dart';

class SimulatorState extends Equatable {
  final List<DebtEntity> debts;
  final double extraBudget;
  final String strategy; // 'avalanche' or 'snowball'
  final bool isLoading;
  final String? error;
  final SimulationResultEntity? result;

  const SimulatorState({
    required this.debts,
    required this.extraBudget,
    required this.strategy,
    required this.isLoading,
    this.error,
    this.result,
  });

  factory SimulatorState.initial() {
    return const SimulatorState(
      debts: [],
      extraBudget: 300.0,
      strategy: 'avalanche',
      isLoading: false,
    );
  }

  SimulatorState copyWith({
    List<DebtEntity>? debts,
    double? extraBudget,
    String? strategy,
    bool? isLoading,
    String? error,
    SimulationResultEntity? result,
    bool clearResult = false,
  }) {
    return SimulatorState(
      debts: debts ?? this.debts,
      extraBudget: extraBudget ?? this.extraBudget,
      strategy: strategy ?? this.strategy,
      isLoading: isLoading ?? this.isLoading,
      error: error, // If error is not passed, it gets cleared by default unless we want to keep it. We usually clear it.
      result: clearResult ? null : (result ?? this.result),
    );
  }

  @override
  List<Object?> get props => [
        debts,
        extraBudget,
        strategy,
        isLoading,
        error,
        result,
      ];
}
