import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/features/simulator/domain/repositories/simulator_repository.dart';
import 'package:maki_app/features/simulator/presentation/bloc/simulator_event.dart';
import 'package:maki_app/features/simulator/presentation/bloc/simulator_state.dart';
import 'dart:developer' as developer;

class SimulatorBloc extends Bloc<SimulatorEvent, SimulatorState> {
  final SimulatorRepository repository;

  SimulatorBloc({required this.repository}) : super(SimulatorState.initial()) {
    on<InitSimulatorEvent>(_onInitSimulator);
    on<AddDebtEvent>(_onAddDebt);
    on<RemoveDebtEvent>(_onRemoveDebt);
    on<UpdateBudgetEvent>(_onUpdateBudget);
    on<UpdateStrategyEvent>(_onUpdateStrategy);
    on<SimulatePayoffEvent>(_onSimulatePayoff);
  }

  void _onInitSimulator(
    InitSimulatorEvent event,
    Emitter<SimulatorState> emit,
  ) {
    if (state.debts.isEmpty && event.initialDebts.isNotEmpty) {
      emit(state.copyWith(debts: event.initialDebts, clearResult: true));
    }
  }

  void _onAddDebt(AddDebtEvent event, Emitter<SimulatorState> emit) {
    emit(
      state.copyWith(
        debts: List.from(state.debts)..add(event.debt),
        clearResult: true,
      ),
    );
  }

  void _onRemoveDebt(RemoveDebtEvent event, Emitter<SimulatorState> emit) {
    emit(
      state.copyWith(
        debts: List.from(state.debts)..removeWhere((d) => d.id == event.debtId),
        clearResult: true,
      ),
    );
  }

  void _onUpdateBudget(UpdateBudgetEvent event, Emitter<SimulatorState> emit) {
    emit(state.copyWith(extraBudget: event.extraBudget, clearResult: true));
  }

  void _onUpdateStrategy(
    UpdateStrategyEvent event,
    Emitter<SimulatorState> emit,
  ) {
    emit(state.copyWith(strategy: event.strategy, clearResult: true));
  }

  Future<void> _onSimulatePayoff(
    SimulatePayoffEvent event,
    Emitter<SimulatorState> emit,
  ) async {
    if (state.debts.isEmpty) return;
    if (state.extraBudget <= 0) return;

    emit(state.copyWith(isLoading: true, clearResult: true));

    try {
      final result = await repository.simulatePayoff(
        debts: state.debts,
        extraBudget: state.extraBudget,
        strategy: state.strategy,
      );

      emit(state.copyWith(isLoading: false, result: result));
    } catch (e, stackTrace) {
      developer.log(
        'Borç ödeme simülasyonu tamamlanamadı.',
        error: e,
        stackTrace: stackTrace,
        name: 'SimulatorBloc',
      );
      emit(state.copyWith(isLoading: false, error: 'Simülasyon hatası'));
    }
  }
}
