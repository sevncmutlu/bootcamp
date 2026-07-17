import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:maki_app/database/database.dart';
import 'package:maki_app/l10n/app_localizations.dart';

import 'package:maki_app/screens/receipt_scanner_screen.dart';
import 'package:maki_app/screens/settings_screen.dart';

class ExpenseEntryScreen extends StatefulWidget {
  const ExpenseEntryScreen({super.key});

  @override
  State<ExpenseEntryScreen> createState() => _ExpenseEntryScreenState();
}

class _ExpenseEntryScreenState extends State<ExpenseEntryScreen> {
  final _database = AppDatabase.instance;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategoriesAndSeed();
  }

  Future<void> _loadCategoriesAndSeed() async {
    // Check and seed default categories
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
    Category? selectedCategory = _categories.isNotEmpty ? _categories.first : null;
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
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
                    // Title
                    Text(
                      l10n.manualExpense,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Title Field
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
                    // Amount Field
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: l10n.labelAmount,
                        prefixIcon: const Icon(Icons.attach_money),
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
                    // Category Dropdown
                    DropdownButtonFormField<Category>(
                      initialValue: selectedCategory,
                      decoration: InputDecoration(
                        labelText: l10n.labelCategory,
                        prefixIcon: const Icon(Icons.category_outlined),
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
                              Text(cat.name),
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
                    // Date Picker Selector
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
                            color: theme.colorScheme.outline.withValues(alpha: 0.15),
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
                    // Save Button
                    ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final title = titleController.text.trim();
                          final amount = double.parse(amountController.text.trim());

                          await _database.insertExpense(
                            ExpensesCompanion.insert(
                              title: title,
                              amount: amount,
                              date: selectedDate,
                              category: selectedCategory!.name,
                              notes: const drift.Value(null),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
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
                MaterialPageRoute(builder: (context) => const ReceiptScannerScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Expense>>(
        stream: _database.watchAllExpenses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = snapshot.data ?? [];
          final total = list.fold<double>(0.0, (sum, item) => sum + item.amount);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Stats Card
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Text(
                          l10n.totalExpense,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${total.toStringAsFixed(2)}',
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
              // List view
              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: Text(
                          l10n.noExpenses,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final item = list[index];

                          // Resolve category details
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
                            key: ValueKey(item.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24.0),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              child: Icon(
                                Icons.delete_outline,
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                            onDismissed: (_) async {
                              await _database.deleteExpense(item.id);
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _parseHexColor(cat.colorHex).withValues(alpha: 0.15),
                                    child: Icon(
                                      _getCategoryIcon(cat.iconName),
                                      color: _parseHexColor(cat.colorHex),
                                    ),
                                  ),
                                  title: Text(
                                    item.title,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    '${item.date.year}-${item.date.month.toString().padLeft(2, '0')}-${item.date.day.toString().padLeft(2, '0')} · ${item.category}',
                                  ),
                                  trailing: Text(
                                    '\$${item.amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseDialog,
        icon: const Icon(Icons.add),
        label: Text(l10n.manualExpense),
        elevation: 0,
      ),
    );
  }
}
