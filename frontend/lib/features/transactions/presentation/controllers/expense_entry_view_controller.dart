part of '../pages/expense_entry_screen.dart';

extension _ExpenseEntryViewController on _ExpenseEntryScreenState {
  Widget _buildExpenseEntryView(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final compactFab = MediaQuery.sizeOf(context).width < 430;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => MainNavigationScreen.openDrawer(),
        ),
        title: MakiAppBarTitle(title: l10n.navIncomeExpense),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BlocProvider(
                    create: (_) => di.sl<SettingsBloc>(),
                    child: const SettingsScreen(),
                  ),
                ),
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
      body: MakiBackground(
        maxContentWidth: 1120,
        child: BlocConsumer<TransactionBloc, TransactionState>(
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.error!)));
            }
            if (state.isSuccess) unawaited(_loadCurrentStreak());
          },
          builder: (context, state) {
            final expensesList = state.expenses;
            final incomesList = state.incomes;
            final selectedExpensesList = expensesList
                .where(
                  (item) => PersonalizedFinanceOverview.sameDay(
                    item.date,
                    _selectedDate,
                  ),
                )
                .toList();
            final selectedIncomesList = incomesList
                .where(
                  (item) => PersonalizedFinanceOverview.sameDay(
                    item.date,
                    _selectedDate,
                  ),
                )
                .toList();
            return NestedScrollView(
              key: const ValueKey('finance-page-scroll'),
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: PersonalizedFinanceOverview(
                      primaryGoal: widget.primaryGoal,
                      expenses: expensesList,
                      incomes: incomesList,
                      selectedDate: _selectedDate,
                      today: widget.today,
                      streakDays: _currentStreak,
                      savingsGoal: _activeGoal,
                      savingsGoals: _availableGoals,
                      onChooseSavingsGoal: _availableGoals.length > 1
                          ? _chooseSavingsGoal
                          : null,
                      onOpenSavingsGoal: _activeGoal == null
                          ? null
                          : _openSavingsGoal,
                      onDateSelected: (date) {
                        _updateExpenseView(() {
                          _selectedDate = date;
                        });
                      },
                      onOpenCalendar: () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => FinanceCalendarScreen(
                              initialDate: _selectedDate,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    12,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(AppRadius.md),
                        ),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.65,
                          ),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(AppRadius.md - 4),
                          ),
                          color: theme.colorScheme.surfaceContainerLowest,
                          boxShadow: AppShadows.soft(
                            theme.brightness,
                            theme.colorScheme.primary,
                          ),
                        ),
                        labelColor: theme.colorScheme.primary,
                        unselectedLabelColor:
                            theme.colorScheme.onSurfaceVariant,
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
                                const Icon(
                                  Icons.arrow_downward_outlined,
                                  size: 16,
                                ),
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
                                const Icon(
                                  Icons.arrow_upward_outlined,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(l10n.tabIncome),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  // Expenses Tab
                  selectedExpensesList.isEmpty
                      ? EmptyState(
                          title: l10n.noExpenses,
                          message: l10n.emptyExpensesHint,
                          pose: MascotPose.happy,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: selectedExpensesList.length,
                          itemBuilder: (context, index) {
                            final item = selectedExpensesList[index];
                            final cat = state.categories.firstWhere(
                              (c) => c.name == item.category,
                              orElse: () => const CategoryEntity(
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
                              onDismissed: (_) {
                                if (item.id != null) {
                                  context.read<TransactionBloc>().add(
                                    DeleteExpenseEvent(item.id!),
                                  );
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Card(
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: _parseHexColor(
                                        cat.colorHex,
                                      ).withValues(alpha: 0.15),
                                      child: Icon(
                                        _getCategoryIcon(cat.iconName),
                                        color: _parseHexColor(cat.colorHex),
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
                  selectedIncomesList.isEmpty
                      ? EmptyState(
                          title: l10n.noIncomes,
                          message: l10n.emptyIncomesHint,
                          pose: MascotPose.celebrate,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: selectedIncomesList.length,
                          itemBuilder: (context, index) {
                            final item = selectedIncomesList[index];

                            return Dismissible(
                              key: ValueKey('inc-${item.id}'),
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
                              onDismissed: (_) {
                                if (item.id != null) {
                                  context.read<TransactionBloc>().add(
                                    DeleteIncomeEvent(item.id!),
                                  );
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Card(
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          theme.colorScheme.secondaryContainer,
                                      child: Icon(
                                        _getIncomeSourceIcon(item.source),
                                        color: theme.colorScheme.secondary,
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
            );
          },
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? compactFab
                ? FloatingActionButton(
                    heroTag: 'expense-action',
                    key: const ValueKey('fab-expense'),
                    onPressed: _showAddExpenseDialog,
                    tooltip: l10n.manualExpense,
                    elevation: 0,
                    child: const Icon(Icons.add_rounded),
                  )
                : FloatingActionButton.extended(
                    heroTag: 'expense-action',
                    key: const ValueKey('fab-expense'),
                    onPressed: _showAddExpenseDialog,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.manualExpense),
                    elevation: 0,
                  )
          : compactFab
          ? FloatingActionButton(
              heroTag: 'income-action',
              key: const ValueKey('fab-income'),
              onPressed: _showAddIncomeDialog,
              tooltip: l10n.addIncome,
              backgroundColor: theme.colorScheme.secondary,
              foregroundColor: theme.colorScheme.onSecondary,
              elevation: 0,
              child: const Icon(Icons.add_rounded),
            )
          : FloatingActionButton.extended(
              heroTag: 'income-action',
              key: const ValueKey('fab-income'),
              onPressed: _showAddIncomeDialog,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.addIncome),
              backgroundColor: theme.colorScheme.secondary,
              foregroundColor: theme.colorScheme.onSecondary,
              elevation: 0,
            ),
    );
  }
}
