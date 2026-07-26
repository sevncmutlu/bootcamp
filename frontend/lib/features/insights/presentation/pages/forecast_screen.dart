import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/core/utils/dates.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/core/utils/currency.dart';
import 'package:maki_app/features/insights/presentation/bloc/forecast_bloc.dart';
import 'package:maki_app/features/insights/presentation/bloc/forecast_event.dart';
import 'package:maki_app/features/insights/presentation/bloc/forecast_state.dart';
import 'package:maki_app/features/insights/domain/entities/forecast_day_entity.dart';

class ForecastScreen extends StatefulWidget {
  final bool showAppBar;
  const ForecastScreen({super.key, this.showAppBar = true});

  @override
  State<ForecastScreen> createState() => ForecastScreenState();
}

class ForecastScreenState extends State<ForecastScreen>
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchAndCalculateForecast();
  }

  void refresh() {
    _fetchAndCalculateForecast();
  }

  void _fetchAndCalculateForecast() {
    context.read<ForecastBloc>().add(LoadForecastEvent());
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
                l10n.forecastTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            )
          : null,
      body: BlocConsumer<ForecastBloc, ForecastState>(
        listener: (context, state) {
          if (state is ForecastError && !state.hasInsufficientHistory) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is ForecastLoading || state is ForecastInitial;
          final hasInsufficientHistory = state is ForecastError && state.hasInsufficientHistory;
          final forecast = state is ForecastLoaded ? state.forecast : <ForecastDayEntity>[];

          return RefreshIndicator(
            onRefresh: () async => _fetchAndCalculateForecast(),
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          l10n.forecastLoading,
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
                        Card(
                          color: theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.15,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.auto_awesome_outlined,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      l10n.projectedSpend,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  l10n.forecastSubtitle,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (hasInsufficientHistory)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20.0),
                            child: Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(16.0),
                                border: Border.all(
                                  color: theme.colorScheme.error.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: theme.colorScheme.error,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      l10n.forecastEmpty,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onErrorContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        if (forecast.isNotEmpty)
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: forecast.length,
                            itemBuilder: (context, index) {
                              final item = forecast[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(18.0),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: theme.colorScheme.primary
                                              .withValues(alpha: 0.1),
                                          child: Icon(
                                            Icons.calendar_month,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            Dates.fromIso(
                                              item.date,
                                              Localizations.localeOf(
                                                context,
                                              ).toString(),
                                            ),
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                        Text(
                                          formatTL(item.predictedAmount),
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.onSurface,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        else if (!isLoading && !hasInsufficientHistory)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40.0),
                              child: Text(
                                l10n.noExpenses,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }
}
