part of 'expense_entry_screen.dart';

extension _ExpenseEntryLifecycle on _ExpenseEntryScreenState {
  void _initializeExpenseEntry() {
    _selectedDate = PersonalizedFinanceOverview.dateOnly(
      widget.today ?? DateTime.now(),
    );
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!mounted) return;
      _updateExpenseView(() {});
    });
    if (di.sl.isRegistered<LivingForestService>()) {
      _forestChanges = di.sl<LivingForestService>().changes.listen((_) {
        unawaited(_loadCurrentStreak());
      });
    }
    unawaited(_loadCurrentStreak());
  }

  Future<void> _loadCurrentStreak() async {
    if (!di.sl.isRegistered<LivingForestService>()) return;
    try {
      final snapshot = await di.sl<LivingForestService>().load();
      if (mounted) {
        _updateExpenseView(() {
          _currentStreak = snapshot.currentStreak;
          _activeGoal = snapshot.primaryGoal;
        });
      }
    } catch (_) {
      // The finance flow remains usable if the optional forest layer is not
      // ready yet; pull-to-refresh or the next transaction retries it.
    }
  }
}
