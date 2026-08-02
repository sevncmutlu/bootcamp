import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/main.dart';
import 'package:maki_app/core/utils/currency.dart';
import 'package:maki_app/core/di/injection_container.dart' as di;
import 'package:maki_app/core/widgets/stat_card.dart';
import 'package:maki_app/core/widgets/maki_app_bar_title.dart';
import 'package:maki_app/core/widgets/maki_background.dart';
import 'package:maki_app/core/theme/app_tokens.dart';
import 'package:maki_app/core/personalization/goal_route_banner.dart';
import 'package:maki_app/features/simulator/domain/entities/debt_entity.dart';
import 'package:maki_app/features/simulator/data/datasources/debt_plan_local_data_source.dart';
import 'package:maki_app/features/simulator/presentation/bloc/simulator_bloc.dart';
import 'package:maki_app/features/simulator/presentation/bloc/simulator_event.dart';
import 'package:maki_app/features/simulator/presentation/bloc/simulator_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
part 'debt_plan_forms.dart';
part 'debt_entry_form.dart';
part '../controllers/debt_simulator_view_controller.dart';
part '../widgets/debt_simulator_components.dart';
part 'debt_simulator_lifecycle.dart';

class DebtSimulatorScreen extends StatefulWidget {
  const DebtSimulatorScreen({
    super.key,
    this.initialDebts = const [],
    this.primaryGoal = 'track_spending',
  });

  final List<DebtEntity> initialDebts;
  final String primaryGoal;

  @override
  State<DebtSimulatorScreen> createState() => _DebtSimulatorScreenState();
}

class _DebtSimulatorScreenState extends State<DebtSimulatorScreen> {
  final _budgetController = TextEditingController(text: '300');
  int _nextDebtId = 0;
  List<DebtPlanDefinition> _customPlans = const [];

  void _updateDebtView(VoidCallback callback) => setState(callback);

  @override
  void initState() {
    super.initState();
    _initializeDebtSimulator();
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildSimulatorView(context);
}
