part of 'debt_simulator_screen.dart';

extension _DebtEntryForm on _DebtSimulatorScreenState {
  void _addDebtDialog() {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    final rateController = TextEditingController();
    final minPayController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (bottomSheetContext) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);

        return Padding(
          padding: EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 24.0,
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 24.0,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.addDebt,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: l10n.debtName,
                      errorMaxLines: 3,
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.validationDebtName;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: balanceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.debtBalance,
                      errorMaxLines: 3,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.validationDebtBalance;
                      }
                      final parsed = double.tryParse(value.trim());
                      if (parsed == null || parsed <= 0) {
                        return l10n.validationDebtBalance;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: rateController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.interestRate,
                      errorMaxLines: 3,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.validationDebtRate;
                      }
                      final parsed = double.tryParse(value.trim());
                      if (parsed == null || parsed < 0) {
                        return l10n.validationDebtRate;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: minPayController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.minPayment,
                      errorMaxLines: 3,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.validationDebtMinPayment;
                      }
                      final parsed = double.tryParse(value.trim());
                      if (parsed == null || parsed <= 0) {
                        return l10n.validationDebtMinPayment;
                      }
                      final balanceVal =
                          double.tryParse(balanceController.text.trim()) ?? 0.0;
                      if (parsed > balanceVal) {
                        return l10n.validationDebtMinPayment;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        final name = nameController.text.trim();
                        final balance =
                            double.tryParse(balanceController.text.trim()) ??
                            0.0;
                        final rate =
                            double.tryParse(rateController.text.trim()) ?? 0.0;
                        final minPay =
                            double.tryParse(minPayController.text.trim()) ??
                            0.0;

                        final newDebt = DebtEntity(
                          id: 'borc-${DateTime.now().microsecondsSinceEpoch}-${_nextDebtId++}',
                          name: name,
                          balance: balance,
                          interestRate: rate,
                          minPayment: minPay,
                        );

                        context.read<SimulatorBloc>().add(
                          AddDebtEvent(newDebt),
                        );
                        Navigator.pop(bottomSheetContext);
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
                      l10n.addDebt,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
