import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:maki_app/utils/dates.dart';
import 'package:maki_app/database/database.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/services/maki_api_client.dart';
import 'package:maki_app/utils/currency.dart';

class ForecastScreen extends StatefulWidget {
  final bool showAppBar;
  const ForecastScreen({super.key, this.showAppBar = true});

  @override
  State<ForecastScreen> createState() => ForecastScreenState();
}

class ForecastScreenState extends State<ForecastScreen> {
  void refresh() {
    _fetchAndCalculateForecast();
  }

  final _database = AppDatabase.instance;
  List<ForecastDay> _forecast = [];
  bool _isLoading = false;
  bool _hasInsufficientHistory = false;

  @override
  void initState() {
    super.initState();
    _fetchAndCalculateForecast();
  }

  Future<void> _fetchAndCalculateForecast() async {
    if (_forecast.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }
    setState(() {
      _hasInsufficientHistory = false;
    });

    try {
      final expenses = await _database.getAllExpenses();
      final today = DateTime.now();
      final start = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(const Duration(days: 55));
      final totals = List<double>.filled(56, 0);
      final observedDays = <int>{};
      for (final expense in expenses) {
        final date = DateTime(
          expense.date.year,
          expense.date.month,
          expense.date.day,
        );
        final day = date.difference(start).inDays;
        if (day >= 0 && day < totals.length) {
          totals[day] += expense.amount;
          observedDays.add(day);
        }
      }
      if (observedDays.length < 3) {
        setState(() {
          _hasInsufficientHistory = true;
          _forecast = [];
        });
        return;
      }

      final mean = totals.reduce((left, right) => left + right) / totals.length;
      final scale = mean + 1;
      final relativeIndexes = totals
          .map((amount) => ((amount + 1) / scale) * 100)
          .toList(growable: false);
      final reply = await MakiApi.instance.forecast(
        relativeIndexes: relativeIndexes,
      );

      if (mounted) {
        setState(() {
          _forecast = [
            for (var index = 0; index < reply.predictions.length; index++)
              ForecastDay(
                date: DateTime(today.year, today.month, today.day)
                    .add(Duration(days: index + 1))
                    .toIso8601String()
                    .substring(0, 10),
                predictedAmount: ((reply.predictions[index] / 100) * scale - 1)
                    .clamp(0, double.infinity),
              ),
          ];
        });
      }
    } on MakiApiException catch (error, stackTrace) {
      developer.log(
        'Harcama tahmini tamamlanamadı.',
        error: error.code,
        stackTrace: stackTrace,
        name: 'ForecastScreen',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.userMessage)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: RefreshIndicator(
        onRefresh: _fetchAndCalculateForecast,
        child: _isLoading
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
                                  Icons.auto_awesome,
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

                    if (_hasInsufficientHistory)
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

                    if (_forecast.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _forecast.length,
                        itemBuilder: (context, index) {
                          final item = _forecast[index];
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
                    else if (!_isLoading)
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
      ),
    );
  }
}

class ForecastDay {
  final String date;
  final double predictedAmount;

  ForecastDay({required this.date, required this.predictedAmount});
}
