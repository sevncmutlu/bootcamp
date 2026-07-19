import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:maki_finance_core/maki_finance_core.dart' as finance;
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/utils/currency.dart';
import 'package:maki_app/widgets/stat_card.dart';

class DebtSimulatorScreen extends StatefulWidget {
  const DebtSimulatorScreen({super.key, this.initialDebts = const []});

  final List<DebtModel> initialDebts;

  @override
  State<DebtSimulatorScreen> createState() => _DebtSimulatorScreenState();
}

class _DebtSimulatorScreenState extends State<DebtSimulatorScreen> {
  late final List<DebtModel> _debts;
  final _budgetController = TextEditingController(text: '300');
  int _nextDebtId = 0;

  String _selectedStrategy = 'avalanche';
  bool _isLoading = false;

  int? _monthsToFree;
  double? _totalInterestPaid;
  double? _successProbability;
  List<PayoffMonth> _schedule = [];

  @override
  void initState() {
    super.initState();
    _debts = List<DebtModel>.of(widget.initialDebts);
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  void _clearSimulation() {
    _monthsToFree = null;
    _totalInterestPaid = null;
    _successProbability = null;
    _schedule = [];
  }

  void _removeDebt(String id) {
    setState(() {
      _debts.removeWhere((debt) => debt.id == id);
      _clearSimulation();
    });
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
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);

        return Padding(
          padding: EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 24.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
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

                        setState(() {
                          _debts.add(
                            DebtModel(
                              id: 'borc-${DateTime.now().microsecondsSinceEpoch}-${_nextDebtId++}',
                              name: name,
                              balance: balance,
                              interestRate: rate,
                              minPayment: minPay,
                            ),
                          );
                          _clearSimulation();
                        });
                        Navigator.pop(context);
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

  Future<void> _simulatePayoff() async {
    if (_debts.isEmpty) return;

    final budget = double.tryParse(_budgetController.text.trim()) ?? 0.0;
    if (budget <= 0) return;

    setState(() {
      _isLoading = true;
      _monthsToFree = null;
      _totalInterestPaid = null;
      _successProbability = null;
      _schedule = [];
    });

    try {
      const currency = finance.Currency('TRY');
      final accounts = [
        for (final debt in _debts)
          finance.DebtAccount(
            id: debt.id,
            balance: finance.Money(
              minorUnits: (debt.balance * 100).round(),
              currency: currency,
            ),
            annualRate: finance.AnnualRate(
              basisPoints: (debt.interestRate * 100).round(),
            ),
            minimumPayment: finance.Money(
              minorUnits: (debt.minPayment * 100).round(),
              currency: currency,
            ),
          ),
      ];
      final minimumPayments = accounts.fold<int>(
        0,
        (sum, account) => sum + account.minimumPayment.minorUnits,
      );
      final result = const finance.DebtEngine().simulate(
        finance.DebtScenario(
          debts: accounts,
          monthlyBudget: finance.Money(
            minorUnits: minimumPayments + (budget * 100).round(),
            currency: currency,
          ),
          strategy: _selectedStrategy == 'snowball'
              ? finance.DebtStrategy.snowball
              : finance.DebtStrategy.avalanche,
          maxMonths: 1200,
        ),
      );
      if (result.status != finance.DebtSimulationStatus.paidOff) {
        throw const finance.DebtValidationException(
          'Bu ödeme planı borçları güvenli biçimde kapatmıyor.',
        );
      }
      if (mounted) {
        setState(() {
          _monthsToFree = result.monthsElapsed;
          _totalInterestPaid = result.totalInterest.minorUnits / 100;
          _successProbability = null;
          _schedule = result.schedule
              .map(
                (month) => PayoffMonth(
                  month: month.monthNumber,
                  remainingBalance:
                      month.lines.fold<int>(
                        0,
                        (sum, line) => sum + line.endingBalance.minorUnits,
                      ) /
                      100,
                ),
              )
              .toList(growable: false);
        });
      }
    } on Object catch (error, stackTrace) {
      developer.log(
        'Borç ödeme simülasyonu tamamlanamadı.',
        error: error,
        stackTrace: stackTrace,
        name: 'DebtSimulatorScreen',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.simulatorError)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.simulatorTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
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
                      selected: _selectedStrategy == 'avalanche',
                      onTap: () {
                        setState(() {
                          _selectedStrategy = 'avalanche';
                          _clearSimulation();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    _StrategyOption(
                      title: l10n.strategySnowball,
                      description: l10n.strategySnowballDescription,
                      icon: Icons.snowing,
                      selected: _selectedStrategy == 'snowball',
                      onTap: () {
                        setState(() {
                          _selectedStrategy = 'snowball';
                          _clearSimulation();
                        });
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

            if (_debts.isEmpty)
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
              ..._debts.map((debt) {
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
                                onPressed: () => _removeDebt(debt.id),
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
              onPressed: _debts.isNotEmpty && !_isLoading
                  ? _simulatePayoff
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
              child: _isLoading
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

            if (_monthsToFree != null) ...[
              const Divider(height: 40),
              StatCard(
                label: l10n.monthsToFree,
                value: '$_monthsToFree',
                icon: Icons.event_available_outlined,
                footer: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.totalInterest),
                    Text(
                      formatTL(_totalInterestPaid!),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_successProbability != null)
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
                                  _successProbability!,
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

              if (_schedule.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _schedule.length > 12
                      ? 12
                      : _schedule.length, // Önizleme ilk 12 ayla sınırlıdır.
                  itemBuilder: (context, index) {
                    final item = _schedule[index];
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

class DebtModel {
  final String id;
  final String name;
  final double balance;
  final double interestRate;
  final double minPayment;

  const DebtModel({
    required this.id,
    required this.name,
    required this.balance,
    required this.interestRate,
    required this.minPayment,
  });
}

class PayoffMonth {
  final int month;
  final double remainingBalance;

  PayoffMonth({required this.month, required this.remainingBalance});
}
