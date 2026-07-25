import 'package:flutter/material.dart';
import 'package:maki_app/database/database.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/utils/dates.dart';
import 'package:maki_app/utils/category_l10n.dart';

import 'package:maki_app/screens/receipt_scanner_screen.dart';
import 'package:maki_app/screens/settings_screen.dart';
import 'package:maki_app/theme/app_tokens.dart';
import 'package:maki_app/widgets/net_balance_card.dart';
import 'package:maki_app/main.dart';
import 'package:maki_app/widgets/empty_state.dart';
import 'package:maki_app/widgets/money_text.dart';
import 'package:maki_app/widgets/mascot.dart';

class ExpenseEntryScreen extends StatefulWidget {
  const ExpenseEntryScreen({super.key});

  @override
  State<ExpenseEntryScreen> createState() => _ExpenseEntryScreenState();
}

class _ExpenseEntryScreenState extends State<ExpenseEntryScreen>
    with SingleTickerProviderStateMixin {
  final _database = AppDatabase.instance;
  late TabController _tabController;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
    _loadCategoriesAndSeed();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCategoriesAndSeed() async {
    await _database.seedDefaultCategories();
    final categories = await _database.getAllCategories();
    setState(() {
      _categories = categories;
    });
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'shopping_cart':
        return Icons.shopping_cart_outlined;
      case 'restaurant':
        return Icons.restaurant_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'receipt':
        return Icons.receipt_long_outlined;
      case 'directions_bus':
        return Icons.directions_bus_outlined;
      case 'sports_esports':
        return Icons.sports_esports_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  IconData _getIncomeSourceIcon(String source) {
    switch (source.toLowerCase()) {
      case 'salary':
      case 'maaş':
        return Icons.work_outline;
      case 'freelance':
      case 'ek gelir':
        return Icons.laptop_chromebook_outlined;
      case 'investment':
      case 'yatırım':
        return Icons.trending_up_rounded;
      case 'rent':
      case 'kira':
        return Icons.real_estate_agent_outlined;
      case 'bonus':
      case 'prim':
        return Icons.card_giftcard_outlined;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  String _getLocalizedIncomeSource(BuildContext context, String source) {
    final l10n = AppLocalizations.of(context)!;
    switch (source.toLowerCase()) {
      case 'salary':
      case 'maaş':
        return l10n.sourceSalary;
      case 'freelance':
      case 'ek gelir':
        return l10n.sourceFreelance;
      case 'investment':
      case 'yatırım':
        return l10n.sourceInvestment;
      case 'rent':
      case 'kira':
        return l10n.sourceRent;
      case 'bonus':
      case 'prim':
        return l10n.sourceBonus;
      case 'other':
      case 'diğer':
        return l10n.sourceOther;
      default:
        return source;
    }
  }

  Color _parseHexColor(String hexStr) {
    try {
      final cleanHex = hexStr.replaceAll('#', '');
      return Color(int.parse('FF$cleanHex', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  void _showAddExpenseDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    Category? selectedCategory = _categories.isNotEmpty
        ? _categories.first
        : null;
    DateTime selectedDate = DateTime.now();

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

            final formKey = GlobalKey<FormState>();

            return Padding(
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 24.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.manualExpense,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: l10n.labelTitle,
                        prefixIcon: const Icon(Icons.title),
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
                        final amount = double.tryParse(value.trim());
                        if (amount == null || amount <= 0) {
                          return l10n.validationAmount;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Category>(
                      initialValue: selectedCategory,
                      decoration: InputDecoration(
                        labelText: l10n.labelCategory,
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem<Category>(
                          value: cat,
                          child: Row(
                            children: [
                              Icon(
                                _getCategoryIcon(cat.iconName),
                                color: _parseHexColor(cat.colorHex),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(getLocalizedCategoryName(context, cat.name)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setModalState(() {
                          selectedCategory = val;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return l10n.validationCategory;
                        }
                        return null;
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
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final title = titleController.text.trim();
                          final amount = double.parse(
                            amountController.text.trim(),
                          );

                          await _database.insertExpense(
                            ExpensesCompanion.insert(
                              title: title,
                              amount: amount,
                              date: selectedDate,
                              category: selectedCategory!.name,
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
                        l10n.saveExpense,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddIncomeDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String selectedSource = 'Salary';
    DateTime selectedDate = DateTime.now();

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
            final formKey = GlobalKey<FormState>();

            final incomeSources = const [
              'Salary',
              'Freelance',
              'Investment',
              'Rent',
              'Bonus',
              'Other',
            ];

            return Padding(
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 24.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
              ),
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
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: l10n.labelIncomeTitle,
                        prefixIcon: const Icon(Icons.title),
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
                        final amount = double.tryParse(value.trim());
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
                              Text(_getLocalizedIncomeSource(context, srcKey)),
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
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final title = titleController.text.trim();
                          final amount = double.parse(
                            amountController.text.trim(),
                          );

                          await _database.insertIncome(
                            IncomesCompanion.insert(
                              title: title,
                              amount: amount,
                              date: selectedDate,
                              source: selectedSource,
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => MainNavigationScreen.openDrawer(),
        ),
        title: Text(
          l10n.appTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_outlined),
            tooltip: l10n.scanReceipt,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => const ReceiptScannerScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Expense>>(
        stream: _database.watchAllExpenses(),
        builder: (context, expSnapshot) {
          final expensesList = expSnapshot.data ?? [];
          final totalExpenses = expensesList.fold<double>(
            0.0,
            (sum, item) => sum + item.amount,
          );

          return StreamBuilder<List<Income>>(
            stream: _database.watchAllIncomes(),
            builder: (context, incSnapshot) {
              final incomesList = incSnapshot.data ?? [];
              final totalIncome = incomesList.fold<double>(
                0.0,
                (sum, item) => sum + item.amount,
              );
              final netBalance = totalIncome - totalExpenses;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: NetBalanceCard(
                      netBalance: netBalance,
                      totalIncome: totalIncome,
                      totalExpenses: totalExpenses,
                    ),
                  ),

                  Container(
                    height: 40,
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        color: theme.colorScheme.primary,
                      ),
                      labelColor: theme.colorScheme.onPrimary,
                      unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      tabs: [
                        Tab(
                          height: 36,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.arrow_downward_outlined, size: 16),
                              const SizedBox(width: 6),
                              Text(l10n.tabExpenses),
                            ],
                          ),
                        ),
                        Tab(
                          height: 36,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.arrow_upward_outlined, size: 16),
                              const SizedBox(width: 6),
                              Text(l10n.tabIncome),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Expenses Tab
                        expensesList.isEmpty
                            ? EmptyState(
                                title: l10n.noExpenses,
                                message: l10n.emptyExpensesHint,
                                pose: MascotPose.happy,
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                itemCount: expensesList.length,
                                itemBuilder: (context, index) {
                                  final item = expensesList[index];
                                  final cat = _categories.firstWhere(
                                    (c) => c.name == item.category,
                                    orElse: () => const Category(
                                      id: 0,
                                      name: 'Default',
                                      colorHex: '#FF7F7F7F',
                                      iconName: 'category',
                                    ),
                                  );

                                  return Dismissible(
                                    key: ValueKey('exp-${item.id}'),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(
                                        right: 24.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.errorContainer,
                                        borderRadius: BorderRadius.circular(
                                          16.0,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.delete_outline,
                                        color:
                                            theme.colorScheme.onErrorContainer,
                                      ),
                                    ),
                                    onDismissed: (_) async {
                                      await _database.deleteExpense(item.id);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 8.0,
                                      ),
                                      child: Card(
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: _parseHexColor(
                                              cat.colorHex,
                                            ).withValues(alpha: 0.15),
                                            child: Icon(
                                              _getCategoryIcon(cat.iconName),
                                              color: _parseHexColor(
                                                cat.colorHex,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            item.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${Dates.medium(item.date, Localizations.localeOf(context).toString())} · ${getLocalizedCategoryName(context, item.category)}',
                                          ),
                                          trailing: MoneyText(
                                            item.amount,
                                            kind: MoneyKind.expense,
                                            style: theme.textTheme.titleMedium,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                        // Income Tab
                        incomesList.isEmpty
                            ? EmptyState(
                                title: l10n.noIncomes,
                                message: l10n.emptyIncomesHint,
                                pose: MascotPose.celebrate,
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                itemCount: incomesList.length,
                                itemBuilder: (context, index) {
                                  final item = incomesList[index];

                                  return Dismissible(
                                    key: ValueKey('inc-${item.id}'),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(
                                        right: 24.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.errorContainer,
                                        borderRadius: BorderRadius.circular(
                                          16.0,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.delete_outline,
                                        color:
                                            theme.colorScheme.onErrorContainer,
                                      ),
                                    ),
                                    onDismissed: (_) async {
                                      await _database.deleteIncome(item.id);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 8.0,
                                      ),
                                      child: Card(
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: Colors.teal
                                                .withValues(alpha: 0.15),
                                            child: Icon(
                                              _getIncomeSourceIcon(item.source),
                                              color: Colors.teal,
                                            ),
                                          ),
                                          title: Text(
                                            item.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${Dates.medium(item.date, Localizations.localeOf(context).toString())} · ${_getLocalizedIncomeSource(context, item.source)}',
                                          ),
                                          trailing: MoneyText(
                                            item.amount,
                                            kind: MoneyKind.income,
                                            style: theme.textTheme.titleMedium,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              key: const ValueKey('fab-expense'),
              onPressed: _showAddExpenseDialog,
              icon: const Icon(Icons.add),
              label: Text(l10n.manualExpense),
              elevation: 0,
            )
          : FloatingActionButton.extended(
              key: const ValueKey('fab-income'),
              onPressed: _showAddIncomeDialog,
              icon: const Icon(Icons.add),
              label: Text(l10n.addIncome),
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
    );
  }
}
