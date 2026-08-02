part of 'debt_simulator_screen.dart';

extension _DebtSimulatorLifecycle on _DebtSimulatorScreenState {
  DebtPlanLocalDataSource? get _planStore =>
      di.sl.isRegistered<SharedPreferences>()
      ? DebtPlanLocalDataSource(di.sl<SharedPreferences>())
      : null;

  void _initializeDebtSimulator() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final plans = _planStore?.load() ?? const <DebtPlanDefinition>[];
      if (mounted) _updateDebtView(() => _customPlans = plans);
      if (widget.initialDebts.isNotEmpty) {
        context.read<SimulatorBloc>().add(
          InitSimulatorEvent(widget.initialDebts),
        );
      }
    });

    _budgetController.addListener(() {
      final value = double.tryParse(_budgetController.text.trim()) ?? 0.0;
      context.read<SimulatorBloc>().add(UpdateBudgetEvent(value));
    });
  }

  Future<void> _savePlans(List<DebtPlanDefinition> plans) async {
    _updateDebtView(() => _customPlans = List.unmodifiable(plans));
    await _planStore?.save(plans);
  }
}
