import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/config/api_config.dart';
import 'package:maki_app/utils/pii_scrubber.dart';
import 'dart:developer' as developer;

class DebtSimulatorScreen extends StatefulWidget {
  const DebtSimulatorScreen({super.key});

  @override
  State<DebtSimulatorScreen> createState() => _DebtSimulatorScreenState();
}

class _DebtSimulatorScreenState extends State<DebtSimulatorScreen> {
  final List<DebtModel> _debts = [];
  final _budgetController = TextEditingController(text: '300');
  
  String _selectedStrategy = 'avalanche';
  bool _isLoading = false;
  
  // Results fields
  int? _monthsToFree;
  double? _totalInterestPaid;
  List<PayoffMonth> _schedule = [];

  void _addDebtDialog() {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    final rateController = TextEditingController();
    final minPayController = TextEditingController();

    showModalBottomSheet(
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.addDebt,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: l10n.debtName),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: balanceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.debtBalance),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: rateController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l10n.interestRate),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: minPayController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.minPayment),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final balance = double.tryParse(balanceController.text.trim()) ?? 0.0;
                  final rate = double.tryParse(rateController.text.trim()) ?? 0.0;
                  final minPay = double.tryParse(minPayController.text.trim()) ?? 0.0;

                  if (name.isNotEmpty && balance > 0 && rate >= 0 && minPay > 0) {
                    setState(() {
                      _debts.add(DebtModel(
                        name: name,
                        balance: balance,
                        interestRate: rate,
                        minPayment: minPay,
                      ));
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
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
      _schedule = [];
    });

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/debt-simulator');

      final payload = {
        'debts': _debts.map((d) => {
          'name': PiiScrubber.scrub(d.name),
          'balance': d.balance,
          'interest_rate': d.interestRate,
          'min_payment': d.minPayment,
        }).toList(),
        'monthly_budget': budget,
        'strategy': _selectedStrategy,
      };

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> scheduleRaw = data['payoff_schedule'] ?? [];

        setState(() {
          _monthsToFree = data['months_to_debt_free'] ?? 0;
          _totalInterestPaid = (data['total_interest_paid'] ?? 0.0).toDouble();
          _schedule = scheduleRaw.map((item) => PayoffMonth.fromJson(item)).toList();
        });
      } else {
        final errData = json.decode(response.body);
        final errMsg = errData['detail'] ?? 'Simulation failed.';
        throw Exception(errMsg);
      }
    } catch (e) {
      developer.log('Error simulating debt payoff strategies', error: e, name: 'DebtSimulatorScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.simulatorError)),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
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
            // Subtitle description
            Text(
              l10n.simulatorSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Extra Budget & Strategy Selection
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
                    DropdownButtonFormField<String>(
                      initialValue: _selectedStrategy,
                      decoration: InputDecoration(
                        labelText: l10n.labelCategory, // maps category dropdown labels
                        prefixIcon: const Icon(Icons.insights_outlined),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'avalanche',
                          child: Text(l10n.strategyAvalanche),
                        ),
                        DropdownMenuItem(
                          value: 'snowball',
                          child: Text(l10n.strategySnowball),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedStrategy = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Debts List Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.debtListTitle,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _addDebtDialog,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addDebt),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Debts items list
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
              ...List.generate(_debts.length, (index) {
                final debt = _debts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Card(
                    child: ListTile(
                      title: Text(
                        debt.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${l10n.minPayment}: \$${debt.minPayment.toStringAsFixed(0)} · ${l10n.interestRateAbbr}: ${debt.interestRate}%',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '\$${debt.balance.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _debts.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            
            const SizedBox(height: 20),

            // Run simulation button
            ElevatedButton(
              onPressed: _debts.isNotEmpty && !_isLoading ? _simulatePayoff : null,
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
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      l10n.simulateButton,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
            ),
            
            // Result summaries
            if (_monthsToFree != null) ...[
              const Divider(height: 40),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              l10n.monthsToFree,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$_monthsToFree',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              l10n.totalInterest,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '\$${_totalInterestPaid!.toStringAsFixed(2)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Payoff monthly schedule timeline
              if (_schedule.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _schedule.length > 12 ? 12 : _schedule.length, // Limit preview list to first 12 months
                  itemBuilder: (context, index) {
                    final item = _schedule[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('${item.month}'),
                        ),
                        title: Text(l10n.payoffMonthLabel(item.month)),
                        trailing: Text(
                          '\$${item.remainingBalance.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
            ]
          ],
        ),
      ),
    );
  }
}

class DebtModel {
  final String name;
  final double balance;
  final double interestRate;
  final double minPayment;

  DebtModel({
    required this.name,
    required this.balance,
    required this.interestRate,
    required this.minPayment,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'balance': balance,
      'interest_rate': interestRate,
      'min_payment': minPayment,
    };
  }
}

class PayoffMonth {
  final int month;
  final double remainingBalance;

  PayoffMonth({required this.month, required this.remainingBalance});

  factory PayoffMonth.fromJson(Map<String, dynamic> json) {
    return PayoffMonth(
      month: json['month'] ?? 0,
      remainingBalance: (json['remaining_balance'] ?? 0.0).toDouble(),
    );
  }
}
