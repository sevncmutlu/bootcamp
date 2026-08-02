part of 'forest_screen.dart';

extension _ForestGoalForms on ForestScreenState {
  Future<void> _loadLivingForest() async {
    if (!di.sl.isRegistered<LivingForestService>()) return;
    try {
      final snapshot = await di.sl<LivingForestService>().load();
      if (mounted) _updateForestView(() => _livingForest = snapshot);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'living forest',
          context: ErrorDescription('Yaşayan orman verileri yüklenirken'),
        ),
      );
    }
  }

  Future<void> _showCreateGoal() async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    var primary = _livingForest.goals.isEmpty;
    var saving = false;
    String? formError;
    final createdGoalId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Yeni hedef rotası',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontFamily: 'MakiDisplay',
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Ne için birikiyorsun? Maki bu hedefi ormanda görünür bir patikaya çevirecek.',
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: titleController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Hedef adı',
                  hintText: 'Örn. Yeni bilgisayar',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Hedef tutarı',
                  prefixIcon: Icon(Icons.currency_lira_rounded),
                ),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: primary,
                onChanged: (value) => setSheetState(() => primary = value),
                title: const Text('Ana hedefim olsun'),
                subtitle: const Text(
                  'Ana finans kartı ve Maki önerileri bu rotayı izler.',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (formError != null) ...[
                Text(
                  formError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        final amount = double.tryParse(
                          amountController.text.trim().replaceAll(',', '.'),
                        );
                        if (titleController.text.trim().isEmpty ||
                            amount == null ||
                            amount <= 0) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(
                              content: Text('Hedef adı ve tutarı gerekli.'),
                            ),
                          );
                          return;
                        }
                        setSheetState(() {
                          saving = true;
                          formError = null;
                        });
                        try {
                          final goalId = await di
                              .sl<LivingForestService>()
                              .createGoal(
                                title: titleController.text,
                                targetAmount: amount,
                                primary: primary,
                              );
                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext, goalId);
                          }
                        } on Object catch (error, stackTrace) {
                          FlutterError.reportError(
                            FlutterErrorDetails(
                              exception: error,
                              stack: stackTrace,
                              library: 'living forest goal creation',
                            ),
                          );
                          if (sheetContext.mounted) {
                            setSheetState(() {
                              saving = false;
                              formError = error is StateError
                                  ? error.message
                                  : 'Hedef şu anda oluşturulamadı. Kayıtların güvende; yeniden deneyebilirsin.';
                            });
                          }
                        }
                      },
                child: saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Rotayı oluştur'),
              ),
            ],
          ),
        ),
      ),
    );
    titleController.dispose();
    amountController.dispose();
    if (createdGoalId == null || !mounted) return;
    await _loadLivingForest();
    if (!mounted) return;
    SavingsGoalView? createdGoal;
    for (final goal in _livingForest.goals) {
      if (goal.id == createdGoalId) {
        createdGoal = goal;
        break;
      }
    }
    if (createdGoal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hedef kaydedildi. Yol haritası Orman’da hazır.'),
        ),
      );
      return;
    }
    await _openGoalMap(createdGoal);
  }

  Future<void> _showContribution(SavingsGoalView goal) async {
    final amountController = TextEditingController();
    var source = GoalContributionSource.confirmedTransfer;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
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
                decoration: const InputDecoration(
                  labelText: 'Katkı türü',
                  prefixIcon: Icon(Icons.verified_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: GoalContributionSource.confirmedTransfer,
                    child: Text('Gerçekten ayırdım / aktardım'),
                  ),
                  DropdownMenuItem(
                    value: GoalContributionSource.manualUnverified,
                    child: Text('Yalnız rota ilerlemesini düzelt'),
                  ),
                  DropdownMenuItem(
                    value: GoalContributionSource.balanceAdjustment,
                    child: Text('Başlangıç bakiyesi düzeltmesi'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setSheetState(() => source = value);
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                source == GoalContributionSource.confirmedTransfer
                    ? 'Doğrulanmış katkının ödülü 24 saat sonra kesinleşir. Maki banka hesabından para taşımaz.'
                    : 'Bu seçim rotayı düzeltir; XP veya tohum vermez ve banka bakiyesini değiştirmez.',
                style: Theme.of(context).textTheme.bodySmall,
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
                  if (sheetContext.mounted) Navigator.pop(sheetContext, true);
                },
                child: const Text('Katkıyı işle'),
              ),
            ],
          ),
        ),
      ),
    );
    amountController.dispose();
    if (saved == true) await _loadLivingForest();
  }
}
