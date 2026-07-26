import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/main.dart';
import 'package:maki_app/core/utils/currency.dart';
import 'package:maki_app/core/widgets/stat_card.dart';
import 'package:maki_app/features/simulator/domain/entities/debt_entity.dart';
import 'package:maki_app/features/simulator/presentation/bloc/simulator_bloc.dart';
import 'package:maki_app/features/simulator/presentation/bloc/simulator_event.dart';
import 'package:maki_app/features/simulator/presentation/bloc/simulator_state.dart';

class DebtSimulatorScreen extends StatefulWidget {
  const DebtSimulatorScreen({super.key, this.initialDebts = const []});

  final List<DebtEntity> initialDebts;

  @override
  State<DebtSimulatorScreen> createState() => _DebtSimulatorScreenState();
}

class _DebtSimulatorScreenState extends State<DebtSimulatorScreen> {
  final _budgetController = TextEditingController(text: '300');
  int _nextDebtId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialDebts.isNotEmpty) {
        context.read<SimulatorBloc>().add(InitSimulatorEvent(widget.initialDebts));
      }
    });

    _budgetController.addListener(() {
      final value = double.tryParse(_budgetController.text.trim()) ?? 0.0;
      context.read<SimulatorBloc>().add(UpdateBudgetEvent(value));
    });
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

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

                        context.read<SimulatorBloc>().add(AddDebtEvent(newDebt));
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => MainNavigationScreen.openDrawer(),
        ),
        title: Text(
          l10n.simulatorTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<SimulatorBloc, SimulatorState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error ?? l10n.simulatorError)),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.simulatorSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _budgetController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.extraBudget,
                            prefixIcon: const Icon(Icons.account_balance_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l10n.labelStrategy,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _StrategyOption(
                          title: l10n.strategyAvalanche,
                          description: l10n.strategyAvalancheDescription,
                          icon: Icons.trending_down_rounded,
                          selected: state.strategy == 'avalanche',
                          onTap: () {
                            context.read<SimulatorBloc>().add(
                              const UpdateStrategyEvent('avalanche'),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        _StrategyOption(
                          title: l10n.strategySnowball,
                          description: l10n.strategySnowballDescription,
                          icon: Icons.snowing,
                          selected: state.strategy == 'snowball',
                          onTap: () {
                            context.read<SimulatorBloc>().add(
                              const UpdateStrategyEvent('snowball'),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      l10n.debtListTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addDebtDialog,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addDebt),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (state.debts.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        l10n.noDebts,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...state.debts.map((debt) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Card(
                        key: ValueKey('borc-${debt.id}'),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 8, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      debt.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    key: ValueKey('borc-sil-${debt.id}'),
                                    tooltip: l10n.deleteDebt,
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      color: theme.colorScheme.error,
                                    ),
                                    onPressed: () {
                                      context.read<SimulatorBloc>().add(
                                        RemoveDebtEvent(debt.id),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              Text(
                                formatTL(debt.balance, decimals: 0),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _DebtDetail(
                                    icon: Icons.payments_outlined,
                                    text:
                                        '${l10n.minPayment}: ${formatTL(debt.minPayment, decimals: 0)}',
                                  ),
                                  _DebtDetail(
                                    icon: Icons.percent_rounded,
                                    text:
                                        '${l10n.interestRateAbbr}: ${debt.interestRate}%',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: state.debts.isNotEmpty && !state.isLoading
                      ? () => context.read<SimulatorBloc>().add(SimulatePayoffEvent())
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    elevation: 0,
                  ),
                  child: state.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          l10n.simulateButton,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),

                if (state.result != null) ...[
                  const Divider(height: 40),
                  StatCard(
                    label: l10n.monthsToFree,
                    value: '${state.result!.monthsToFree}',
                    icon: Icons.event_available_outlined,
                    footer: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.totalInterest),
                        Text(
                          formatTL(state.result!.totalInterestPaid),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (state.result!.successProbability != null)
                    Card(
                      color: theme.colorScheme.secondaryContainer.withValues(
                        alpha: 0.15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: theme.colorScheme.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.psychology_outlined,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.feasibilityLabel,
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    Money.formatRatioAsPercent(
                                      state.result!.successProbability!,
                                    ),
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    l10n.predictedByLgbm,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  if (state.result!.schedule.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.result!.schedule.length > 12
                          ? 12
                          : state.result!.schedule.length, // Önizleme ilk 12 ayla sınırlıdır.
                      itemBuilder: (context, index) {
                        final item = state.result!.schedule[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: ListTile(
                            leading: CircleAvatar(child: Text('${item.month}')),
                            title: Text(l10n.payoffMonthLabel(item.month)),
                            trailing: Text(
                              formatTL(item.remainingBalance),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StrategyOption extends StatelessWidget {
  const _StrategyOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? scheme.primary.withValues(alpha: 0.10)
            : scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected
                ? scheme.primary
                : scheme.outline.withValues(alpha: 0.18),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: selected ? scheme.primary : scheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected ? scheme.primary : scheme.outline,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DebtDetail extends StatelessWidget {
  const _DebtDetail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}
