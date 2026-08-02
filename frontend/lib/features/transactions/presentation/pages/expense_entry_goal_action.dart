part of 'expense_entry_screen.dart';

extension _ExpenseEntryGoalAction on _ExpenseEntryScreenState {
  Future<void> _openSavingsGoal() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider(
          create: (_) => di.sl<GamificationBloc>(),
          child: ForestScreen(primaryGoal: widget.primaryGoal),
        ),
      ),
    );
    await _loadCurrentStreak();
  }
}
