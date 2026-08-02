import 'package:equatable/equatable.dart';
import 'package:maki_app/features/simulator/domain/entities/debt_entity.dart';

abstract class SimulatorEvent extends Equatable {
  const SimulatorEvent();

  @override
  List<Object?> get props => [];
}

class InitSimulatorEvent extends SimulatorEvent {
  final List<DebtEntity> initialDebts;

  const InitSimulatorEvent(this.initialDebts);

  @override
  List<Object?> get props => [initialDebts];
}

class AddDebtEvent extends SimulatorEvent {
  final DebtEntity debt;

  const AddDebtEvent(this.debt);

  @override
  List<Object?> get props => [debt];
}

class RemoveDebtEvent extends SimulatorEvent {
  final String debtId;

  const RemoveDebtEvent(this.debtId);

  @override
  List<Object?> get props => [debtId];
}

class UpdateBudgetEvent extends SimulatorEvent {
  final double extraBudget;

  const UpdateBudgetEvent(this.extraBudget);

  @override
  List<Object?> get props => [extraBudget];
}

class UpdateStrategyEvent extends SimulatorEvent {
  final String strategy;

  const UpdateStrategyEvent(this.strategy);

  @override
  List<Object?> get props => [strategy];
}

class SimulatePayoffEvent extends SimulatorEvent {}
