import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/rendering.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/core/utils/category_l10n.dart';
import 'package:maki_app/core/widgets/empty_state.dart';
import 'package:maki_app/features/insights/presentation/bloc/inflation_bloc.dart';
import 'package:maki_app/features/insights/presentation/bloc/inflation_event.dart';
import 'package:maki_app/features/insights/presentation/bloc/inflation_state.dart';
import 'package:maki_app/features/insights/domain/entities/category_breakdown_entity.dart';
import 'package:public_file_saver/public_file_saver.dart';
import 'package:share_plus/share_plus.dart';
import 'package:maki_app/features/insights/data/services/price_basket_service.dart';
import 'package:maki_app/features/insights/presentation/widgets/price_observation_sheet.dart';
part 'inflation_breakdown_section.dart';
part '../widgets/inflation_maki_waiting_card.dart';
part '../widgets/inflation_maki_share_card.dart';
part '../widgets/inflation_metric.dart';

class InflationScreen extends StatefulWidget {
  final bool showAppBar;
  final PriceBasketService? priceBasketService;
  const InflationScreen({
    super.key,
    this.showAppBar = true,
    this.priceBasketService,
  });

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
          final hasPriceBasket = state is InflationLoaded
              ? state.data.hasPriceBasket
              : false;
          final personalInflation = state is InflationLoaded
              ? state.data.personalInflation
              : null;
          final officialInflation = state is InflationLoaded
              ? state.data.officialInflation
              : null;
          final breakdowns = state is InflationLoaded
              ? state.data.breakdowns
              : <CategoryBreakdownEntity>[];
          final coveragePercent = state is InflationLoaded
              ? state.data.coveragePercent
              : null;
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
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: widget.priceBasketService == null
                                ? null
                                : () async {
                                    final saved =
                                        await showModalBottomSheet<bool>(
                                          context: context,
                                          isScrollControlled: true,
                                          useSafeArea: true,
                                          builder: (_) => PriceObservationSheet(
                                            service: widget.priceBasketService!,
                                          ),
                                        );
                                    if (saved == true && context.mounted) {
                                      _fetchAndCalculateInflation();
                                    }
                                  },
                            icon: const Icon(Icons.add_shopping_cart_rounded),
                            label: const Text('Sepetime fiyat ekle'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (personalInflation == null) ...[
                          InflationMakiWaitingCard(
                            status: inflationStatus,
                            coveragePercent: coveragePercent,
                          ),
                          const SizedBox(height: 20),
                        ],
                        if (!hasPriceBasket)
                          EmptyState(
                            title: l10n.inflationDataTitle,
                            message: l10n.inflationDataRequired,
                          ),

                        if (personalInflation != null) ...[
                          InflationMakiShareCard(
                            personalInflation: personalInflation,
                            officialInflation: officialInflation,
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
