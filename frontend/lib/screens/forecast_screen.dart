import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maki_app/database/database.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/config/api_config.dart';
import 'dart:developer' as developer;

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
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
    setState(() {
      _isLoading = true;
      _hasInsufficientHistory = false;
    });

    try {
      final expenses = await _database.getAllExpenses();
      
      // Calculate unique transaction days
      final uniqueDays = expenses.map((e) => e.date.toIso8601String().substring(0, 10)).toSet();
      if (uniqueDays.length < 3) {
        setState(() {
          _hasInsufficientHistory = true;
        });
      }

      // Map local Drift expenses to JSON request format
      final transactionsPayload = expenses.map((e) {
        final dateStr = '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}';
        return {
          'date': dateStr,
          'amount': e.amount,
        };
      }).toList();

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/forecast');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'transactions': transactionsPayload,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> list = data['forecast'] ?? [];
        
        setState(() {
          _forecast = list.map((item) => ForecastDay.fromJson(item)).toList();
        });
      } else {
        throw Exception('Status code: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error calculating expense forecast', error: e, name: 'ForecastScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.forecastError)),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.forecastTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _fetchAndCalculateForecast,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    l10n.forecastLoading,
                    style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Forecast Description Card
                  Card(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
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

                  // Insufficient history warning banner
                  if (_hasInsufficientHistory)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(
                            color: theme.colorScheme.error.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: theme.colorScheme.error),
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

                  // Daily predicted values list
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
                                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                    child: Icon(Icons.calendar_month, color: theme.colorScheme.primary),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      item.date,
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '\$${item.predictedAmount.toStringAsFixed(2)}',
                                    style: theme.textTheme.titleMedium?.copyWith(
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
    );
  }
}

class ForecastDay {
  final String date;
  final double predictedAmount;

  ForecastDay({required this.date, required this.predictedAmount});

  factory ForecastDay.fromJson(Map<String, dynamic> json) {
    return ForecastDay(
      date: json['date'] ?? '',
      predictedAmount: (json['predicted_amount'] ?? 0.0).toDouble(),
    );
  }
}
