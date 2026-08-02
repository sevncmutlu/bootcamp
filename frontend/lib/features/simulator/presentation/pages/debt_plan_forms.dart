part of 'debt_simulator_screen.dart';

extension _DebtPlanForms on _DebtSimulatorScreenState {
  Future<void> _openPlanBuilder({
    DebtPlanDefinition? existing,
    bool duplicate = false,
  }) async {
    final nameController = TextEditingController(
      text: duplicate ? '${existing?.name ?? ''} kopyası' : existing?.name,
    );
    var primary = existing?.primary ?? 'interestRate';
    var primaryDirection = existing?.primaryDirection ?? 'descending';
    var tieBreaker = existing?.tieBreaker ?? 'balance';
    var tieBreakerDirection = existing?.tieBreakerDirection ?? 'ascending';
    var allocation = existing?.allocation ?? 'focused';

    final result = await showModalBottomSheet<DebtPlanDefinition>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final theme = Theme.of(context);
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  existing == null || duplicate
                      ? 'Kendi ödeme yolunu oluştur'
                      : 'Ödeme yolunu düzenle',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Maki, seçtiğin kuralları her ay aynı sırayla uygular.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Planın adı',
                    hintText: 'Örneğin: Önce kartları kapat',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _PlanDropdown(
                  label: 'Önce neye bakalım?',
                  value: primary,
                  items: _criterionLabels,
                  onChanged: (value) => setSheetState(() => primary = value),
                ),
                const SizedBox(height: AppSpacing.sm),
                _PlanDropdown(
                  label: 'Hangi değer önce gelsin?',
                  value: primaryDirection,
                  items: _directionLabels,
                  onChanged: (value) =>
                      setSheetState(() => primaryDirection = value),
                ),
                const SizedBox(height: AppSpacing.md),
                _PlanDropdown(
                  label: 'Eşitlik olursa neye bakalım?',
                  value: tieBreaker,
                  items: _criterionLabels,
                  onChanged: (value) => setSheetState(() => tieBreaker = value),
                ),
                const SizedBox(height: AppSpacing.sm),
                _PlanDropdown(
                  label: 'Eşitlikte hangi değer önce gelsin?',
                  value: tieBreakerDirection,
                  items: _directionLabels,
                  onChanged: (value) =>
                      setSheetState(() => tieBreakerDirection = value),
                ),
                const SizedBox(height: AppSpacing.md),
                _PlanDropdown(
                  label: 'Artan para nasıl dağıtılsın?',
                  value: allocation,
                  items: _allocationLabels,
                  onChanged: (value) => setSheetState(() => allocation = value),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        const SnackBar(content: Text('Planına bir ad ver.')),
                      );
                      return;
                    }
                    if (primary == tieBreaker) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'İlk kural ile eşitlik kuralı farklı olmalı.',
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(
                      sheetContext,
                      DebtPlanDefinition(
                        id: existing != null && !duplicate
                            ? existing.id
                            : 'plan-${DateTime.now().microsecondsSinceEpoch}',
                        name: name,
                        primary: primary,
                        primaryDirection: primaryDirection,
                        tieBreaker: tieBreaker,
                        tieBreakerDirection: tieBreakerDirection,
                        allocation: allocation,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: Text(
                    existing == null || duplicate
                        ? 'Planı kaydet'
                        : 'Değişiklikleri kaydet',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    nameController.dispose();
    if (result == null || !mounted) return;

    final plans = [..._customPlans];
    final index = plans.indexWhere((plan) => plan.id == result.id);
    if (index < 0) {
      plans.add(result);
    } else {
      plans[index] = result;
    }
    await _savePlans(plans);
    if (!mounted) return;
    context.read<SimulatorBloc>().add(UpdateStrategyEvent(result.strategyCode));
  }

  Future<void> _deletePlan(
    DebtPlanDefinition plan,
    SimulatorState state,
  ) async {
    await _savePlans(_customPlans.where((item) => item.id != plan.id).toList());
    if (!mounted) return;
    if (state.strategy == plan.strategyCode) {
      context.read<SimulatorBloc>().add(const UpdateStrategyEvent('avalanche'));
    }
  }
}

const _criterionLabels = <String, String>{
  'interestRate': 'Faiz oranı',
  'balance': 'Kalan borç',
  'minimumPayment': 'Aylık en az ödeme',
  'payoffMonths': 'Tahmini kapanma süresi',
};
const _directionLabels = <String, String>{
  'ascending': 'Küçük değer önce',
  'descending': 'Büyük değer önce',
};
const _allocationLabels = <String, String>{
  'focused': 'Bir borca odaklan',
  'equal': 'Borçlara eşit dağıt',
};
