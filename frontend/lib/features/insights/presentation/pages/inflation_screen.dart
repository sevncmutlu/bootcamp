import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/rendering.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/core/utils/category_l10n.dart';
import 'package:maki_app/core/utils/currency.dart';
import 'package:maki_app/features/insights/presentation/bloc/inflation_bloc.dart';
import 'package:maki_app/features/insights/presentation/bloc/inflation_event.dart';
import 'package:maki_app/features/insights/presentation/bloc/inflation_state.dart';
import 'package:maki_app/features/insights/domain/entities/category_breakdown_entity.dart';
import 'package:public_file_saver/public_file_saver.dart';
import 'package:share_plus/share_plus.dart';
part 'inflation_breakdown_section.dart';
part '../widgets/inflation_maki_waiting_card.dart';
part '../widgets/inflation_maki_share_card.dart';
part '../widgets/inflation_share_actions.dart';
part '../widgets/inflation_metric.dart';

class InflationScreen extends StatefulWidget {
  final bool showAppBar;
  const InflationScreen({super.key, this.showAppBar = true});

  @override
  State<InflationScreen> createState() => InflationScreenState();
}

class InflationScreenState extends State<InflationScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchAndCalculateInflation();
  }

  void refresh() {
    _fetchAndCalculateInflation();
  }

  void _fetchAndCalculateInflation() {
    context.read<InflationBloc>().add(LoadInflationEvent());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(
                l10n.inflationTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            )
          : null,
      body: BlocConsumer<InflationBloc, InflationState>(
        listener: (context, state) {
          if (state is InflationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading =
              state is InflationLoading || state is InflationInitial;
          final personalInflation = state is InflationLoaded
              ? state.data.personalInflation
              : null;
          final officialInflation = state is InflationLoaded
              ? state.data.officialInflation
              : null;
          final breakdowns = state is InflationLoaded
              ? state.data.breakdowns
              : <CategoryBreakdownEntity>[];
          final inflationStatus = state is InflationLoaded
              ? state.data.status
              : 'insufficient_data';
          final basePeriod = state is InflationLoaded
              ? state.data.basePeriod
              : null;
          final currentPeriod = state is InflationLoaded
              ? state.data.currentPeriod
              : null;

          return RefreshIndicator(
            onRefresh: () async => _fetchAndCalculateInflation(),
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          l10n.loadingInflation,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.inflationSubtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (state is InflationLoaded) ...[
                          InflationMakiShareCard(
                            personalSpendingChange: personalInflation,
                            officialInflation: officialInflation,
                            currentIncome: state.data.currentIncome ?? 0,
                            currentExpenses: state.data.currentExpenses ?? 0,
                            debtPayments: state.data.debtPayments ?? 0,
                            netCashFlow: state.data.netCashFlow ?? 0,
                            financialPressure: state.data.financialPressure,
                            status: inflationStatus,
                            currentTransactionCount:
                                state.data.currentTransactionCount,
                            previousTransactionCount:
                                state.data.previousTransactionCount,
                            basePeriod: basePeriod,
                            currentPeriod: currentPeriod,
                          ),
                          const SizedBox(height: 24),
                          InflationBreakdownSection(breakdowns: breakdowns),
                        ],
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }
}
