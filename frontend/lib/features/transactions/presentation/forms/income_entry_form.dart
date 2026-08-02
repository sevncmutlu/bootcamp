part of '../pages/expense_entry_screen.dart';

extension _IncomeEntryForm on _ExpenseEntryScreenState {
  void _showAddIncomeDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String selectedSource = 'Salary';
    DateTime selectedDate = DateTime.now();
    var affectsGoal = false;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final l10n = AppLocalizations.of(context)!;
            final theme = Theme.of(context);
            final reduceMotion =
                MediaQuery.maybeOf(context)?.disableAnimations ?? false;

            final incomeSources = const [
              'Salary',
              'Freelance',
              'Investment',
              'Rent',
              'Bonus',
              'Other',
            ];

            return SafeArea(
              top: false,
              child: AnimatedPadding(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.addIncome,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          key: const ValueKey('income-title-field'),
                          controller: titleController,
                          decoration: InputDecoration(
                            labelText: l10n.labelIncomeTitle,
                            prefixIcon: const Icon(Icons.title_outlined),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return l10n.validationTitle;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const ValueKey('income-amount-field'),
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.labelAmount,
                            prefixIcon: const Icon(Icons.currency_lira),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return l10n.validationAmount;
                            }
                            final amount = double.tryParse(
                              value.trim().replaceAll(',', '.'),
                            );
                            if (amount == null || amount <= 0) {
                              return l10n.validationAmount;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: selectedSource,
                          decoration: InputDecoration(
                            labelText: l10n.labelSource,
                          ),
                          items: incomeSources.map((srcKey) {
                            return DropdownMenuItem<String>(
                              value: srcKey,
                              child: Row(
                                children: [
                                  Icon(
                                    _getIncomeSourceIcon(srcKey),
                                    size: 20,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _getLocalizedIncomeSource(context, srcKey),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() {
                                selectedSource = val;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setModalState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(16.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 18.0,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: theme.colorScheme.outline.withValues(
                                  alpha: 0.15,
                                ),
                              ),
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined),
                                const SizedBox(width: 16),
                                Text(
                                  '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_activeGoal != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          SwitchListTile.adaptive(
                            key: const ValueKey('income-affects-goal'),
                            contentPadding: EdgeInsets.zero,
                            value: affectsGoal,
                            onChanged: (value) =>
                                setModalState(() => affectsGoal = value),
                            secondary: const Icon(Icons.savings_outlined),
                            title: Text(
                              'Bu geliri ${_activeGoal!.title} hedefime ayırdım',
                            ),
                            subtitle: Text(
                              affectsGoal
                                  ? 'Gelirin tamamı hedef yolunda katkı olacak.'
                                  : 'Varsayılan: gelir hedef yolunu değiştirmez.',
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              final title = titleController.text.trim();
                              final amount = double.parse(
                                amountController.text.trim().replaceAll(
                                  ',',
                                  '.',
                                ),
                              );

                              context.read<TransactionBloc>().add(
                                AddIncomeEvent(
                                  IncomeEntity(
                                    title: title,
                                    amount: amount,
                                    date: selectedDate,
                                    source: selectedSource,
                                    goalId: affectsGoal
                                        ? _activeGoal?.id
                                        : null,
                                  ),
                                ),
                              );

                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            l10n.addIncome,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
