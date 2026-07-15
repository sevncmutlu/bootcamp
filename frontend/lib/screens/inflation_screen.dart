import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:maki_app/database/database.dart';
import 'package:maki_app/config/api_config.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'dart:developer' as developer;

class InflationScreen extends StatefulWidget {
  const InflationScreen({super.key});

  @override
  State<InflationScreen> createState() => _InflationScreenState();
}

class _InflationScreenState extends State<InflationScreen> {
  final _database = AppDatabase.instance;
  bool _isLoading = false;
  
  double? _personalInflation;
  double? _officialInflation;
  List<CategoryBreakdown> _breakdowns = [];

  @override
  void initState() {
    super.initState();
    _fetchAndCalculateInflation();
  }

  Future<void> _fetchAndCalculateInflation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final expenses = await _database.getAllExpenses();
      
      // Group expenses by category
      final Map<String, double> categorySpending = {};
      for (final exp in expenses) {
        categorySpending[exp.category] = (categorySpending[exp.category] ?? 0.0) + exp.amount;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/inflation-comparison');
      
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'category_spending': categorySpending,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> list = data['breakdown'] ?? [];
        
        setState(() {
          _personalInflation = (data['personal_inflation'] ?? 0.0).toDouble();
          _officialInflation = (data['official_inflation'] ?? 0.0).toDouble();
          _breakdowns = list.map((item) => CategoryBreakdown.fromJson(item)).toList();
        });
      } else {
        throw Exception('Status code: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error calculating personal inflation comparison', error: e, name: 'InflationScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.inflationError)),
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
          l10n.inflationTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _fetchAndCalculateInflation,
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
                    l10n.loadingInflation,
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
                  // Subtitle
                  Text(
                    l10n.inflationSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Macro Comparison Summary Dashboard
                  if (_personalInflation != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
                            child: Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Column(
                                children: [
                                  Text(
                                    l10n.personalInflation,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '%${_personalInflation!.toStringAsFixed(2)}',
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Column(
                                children: [
                                  Text(
                                    l10n.officialInflation,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '%${_officialInflation!.toStringAsFixed(2)}',
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Chart Panel Title
                    Text(
                      l10n.weightComparison,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    // fl_chart Bar Chart rendering comparison
                    if (_breakdowns.isNotEmpty)
                      AspectRatio(
                        aspectRatio: 1.5,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: 100,
                            barTouchData: BarTouchData(enabled: true),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index >= 0 && index < _breakdowns.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          _breakdowns[index].category.substring(0, 3),
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                  reservedSize: 28,
                                ),
                              ),
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(_breakdowns.length, (index) {
                              final item = _breakdowns[index];
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: item.personalWeight,
                                    color: theme.colorScheme.primary,
                                    width: 12,
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  BarChartRodData(
                                    toY: item.officialWeight,
                                    color: Colors.grey.shade400,
                                    width: 12,
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Table Breakdown List
                    ..._breakdowns.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.category,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${l10n.personalWeight}: %${item.personalWeight.toStringAsFixed(1)} · ${l10n.officialWeight}: %${item.officialWeight.toStringAsFixed(1)}',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '%${item.inflationRate.toStringAsFixed(1)}',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      l10n.categoryInflation.substring(7), // yields "Inflation" or "Enflasyon"
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ]
                ],
              ),
            ),
    );
  }
}

class CategoryBreakdown {
  final String category;
  final double personalWeight;
  final double officialWeight;
  final double inflationRate;

  CategoryBreakdown({
    required this.category,
    required this.personalWeight,
    required this.officialWeight,
    required this.inflationRate,
  });

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdown(
      category: json['category'] ?? '',
      personalWeight: (json['personal_weight'] ?? 0.0).toDouble(),
      officialWeight: (json['official_weight'] ?? 0.0).toDouble(),
      inflationRate: (json['inflation_rate'] ?? 0.0).toDouble(),
    );
  }
}
