part of 'expense_entry_screen.dart';

extension _ExpenseEntryGoalAction on _ExpenseEntryScreenState {
  Future<void> _openSavingsGoal() async {
    final goal = _activeGoal;
    if (goal == null) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => GoalWorldMapScreen(
          goal: goal,
          seedBalance: _seedBalance,
          onContribute: () => _showGoalContribution(goal),
        ),
      ),
    );
    await _loadCurrentStreak();
  }

  Future<void> _chooseSavingsGoal() async {
    final selected = await showModalBottomSheet<SavingsGoalView>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Aktif hedefini seç',
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Yeni gelir ve gider kayıtlarında “hedefi etkilesin” seçimi bu hedefe uygulanır.',
                style: Theme.of(sheetContext).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              ..._availableGoals.map(
                (goal) => ListTile(
                  key: ValueKey('select-savings-goal-${goal.id}'),
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Icon(
                      goal.isPrimary
                          ? Icons.check_rounded
                          : Icons.savings_outlined,
                    ),
                  ),
                  title: Text(goal.title),
                  subtitle: Text(
                    '%${(goal.progress * 100).round()} tamamlandı',
                  ),
                  trailing: goal.isPrimary
                      ? const Text(
                          'Aktif',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        )
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pop(sheetContext, goal),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected == null || selected.isPrimary) return;
    await di.sl<LivingForestService>().selectPrimaryGoal(selected.id);
    await _loadCurrentStreak();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selected.title} aktif hedef oldu.')),
      );
    }
  }

  Future<void> _showGoalContribution(SavingsGoalView goal) async {
    final amountController = TextEditingController();
    var source = GoalContributionSource.confirmedTransfer;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${goal.title} rotasına katkı',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: amountController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Katkı tutarı',
                    prefixIcon: Icon(Icons.currency_lira_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<GoalContributionSource>(
                  initialValue: source,
                  decoration: const InputDecoration(labelText: 'Katkı türü'),
                  items: const [
                    DropdownMenuItem(
                      value: GoalContributionSource.confirmedTransfer,
                      child: Text('Gerçekten ayırdım / aktardım'),
                    ),
                    DropdownMenuItem(
                      value: GoalContributionSource.manualUnverified,
                      child: Text('Yalnız rota ilerlemesini düzelt'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setSheetState(() => source = value);
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () async {
                    final amount = double.tryParse(
                      amountController.text.trim().replaceAll(',', '.'),
                    );
                    if (amount == null || amount <= 0) return;
                    await di.sl<LivingForestService>().addContribution(
                      goalId: goal.id,
                      amount: amount,
                      source: source,
                    );
                    if (sheetContext.mounted) {
                      Navigator.pop(sheetContext, true);
                    }
                  },
                  child: const Text('Katkıyı işle'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    amountController.dispose();
    if (saved == true) await _loadCurrentStreak();
  }
}
