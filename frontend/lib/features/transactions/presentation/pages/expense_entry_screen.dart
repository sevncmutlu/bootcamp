import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/features/transactions/domain/entities/category_entity.dart';
import 'package:maki_app/features/transactions/domain/entities/expense_entity.dart';
import 'package:maki_app/features/transactions/domain/entities/income_entity.dart';
import 'package:maki_app/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:maki_app/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:maki_app/features/transactions/presentation/bloc/transaction_state.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/core/utils/dates.dart';
import 'package:maki_app/core/utils/category_l10n.dart';

import 'package:maki_app/features/transactions/presentation/pages/receipt_scanner_screen.dart';
import 'package:maki_app/features/transactions/presentation/pages/finance_calendar_screen.dart';
import 'package:maki_app/features/profile/presentation/pages/settings_screen.dart';
import 'package:maki_app/features/profile/presentation/bloc/settings_bloc.dart';
import 'package:maki_app/core/theme/app_tokens.dart';
import 'package:maki_app/core/di/injection_container.dart' as di;
import 'package:maki_app/main.dart';
import 'package:maki_app/core/widgets/empty_state.dart';
import 'package:maki_app/core/widgets/money_text.dart';
import 'package:maki_app/core/widgets/mascot.dart';
import 'package:maki_app/core/widgets/maki_app_bar_title.dart';
import 'package:maki_app/core/widgets/maki_background.dart';
import 'package:maki_app/features/transactions/presentation/widgets/personalized_finance_overview.dart';
import 'package:maki_app/features/gamification/data/services/living_forest_service.dart';
import 'package:maki_app/features/gamification/domain/entities/living_forest_snapshot.dart';
import 'package:maki_app/features/gamification/presentation/bloc/gamification_bloc.dart';
import 'package:maki_app/features/gamification/presentation/pages/forest_screen.dart';
part 'expense_entry_helpers.dart';
part '../forms/expense_entry_form.dart';
part '../forms/income_entry_form.dart';
part '../controllers/expense_entry_view_controller.dart';
part 'expense_entry_goal_action.dart';
part 'expense_entry_lifecycle.dart';

class ExpenseEntryScreen extends StatefulWidget {
  const ExpenseEntryScreen({
    super.key,
    this.primaryGoal = 'track_spending',
    this.today,
  });

  final String primaryGoal;
  final DateTime? today;

  @override
  State<ExpenseEntryScreen> createState() => _ExpenseEntryScreenState();
}

class _ExpenseEntryScreenState extends State<ExpenseEntryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateTime _selectedDate;
  int _currentStreak = 0;
  SavingsGoalView? _activeGoal;
  StreamSubscription<void>? _forestChanges;

  void _updateExpenseView(VoidCallback callback) => setState(callback);

  @override
  void initState() {
    super.initState();
    _initializeExpenseEntry();
  }

  @override
  void dispose() {
    _forestChanges?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildExpenseEntryView(context);
}
