import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:maki_app/database/database.dart';
import 'package:maki_app/config/api_config.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'dart:developer' as developer;

class InflationScreen extends StatefulWidget {
  final bool showAppBar;
  const InflationScreen({super.key, this.showAppBar = true});

  @override
  State<InflationScreen> createState() => InflationScreenState();
}

class InflationScreenState extends State<InflationScreen> {
  void refresh() {
    _fetchAndCalculateInflation();
  }

  String _formatPercent(double value, {int decimal = 2}) {
    if (!mounted) return value.toStringAsFixed(decimal);
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final valStr = value.toStringAsFixed(decimal);
    return isTr ? '%$valStr' : '$valStr%';
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'market':
      case 'alışveriş':
        return Icons.shopping_cart_outlined;
      case 'restaurant':
      case 'yemek':
        return Icons.restaurant_outlined;
      case 'rent':
      case 'kira':
        return Icons.home_outlined;
      case 'transport':
      case 'ulaşım':
        return Icons.directions_bus_outlined;
      case 'fun':
      case 'eğlence':
        return Icons.sports_esports_outlined;
      case 'bills':
      case 'faturalar':
        return Icons.receipt_long_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  Color _getCategoryColor(String category, ThemeData theme) {
    switch (category.toLowerCase()) {
      case 'market':
      case 'alışveriş':
        return Colors.teal;
      case 'restaurant':
      case 'yemek':
        return Colors.orange;
      case 'rent':
      case 'kira':
        return Colors.green;
      case 'transport':
      case 'ulaşım':
        return Colors.blue;
      case 'fun':
      case 'eğlence':
        return Colors.purple;
      case 'bills':
      case 'faturalar':
        return Colors.red;
      default:
        return theme.colorScheme.primary;
    }
  }

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
    if (_breakdowns.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }

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
      appBar: widget.showAppBar ? AppBar(
        title: Text(
          l10n.inflationTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ) : null,
      body: RefreshIndicator(
        onRefresh: _fetchAndCalculateInflation,
        child: _isLoading
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
                physics: const AlwaysScrollableScrollPhysics(),
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
                                    _formatPercent(_personalInflation!),
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
                                    _formatPercent(_officialInflation!),
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
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (group) => theme.colorScheme.surfaceContainer,
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  final cat = _breakdowns[groupIndex].category;
                                  final type = rodIndex == 0 ? l10n.personalWeight : l10n.officialWeight;
                                  final val = _formatPercent(rod.toY, decimal: 1);
                                  return BarTooltipItem(
                                    '$cat\n$type: $val',
                                    TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index >= 0 && index < _breakdowns.length) {
                                      return SideTitleWidget(
                                        meta: meta,
                                        space: 8,
                                        child: Transform.rotate(
                                          angle: -0.3,
                                          child: Text(
                                            _breakdowns[index].category,
                                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                  reservedSize: 38,
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
                                    width: 10,
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  BarChartRodData(
                                    toY: item.officialWeight,
                                    color: Colors.grey.shade400,
                                    width: 10,
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                ],
                                barsSpace: 4,
                              );
                            }),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Table Breakdown List
                    ..._breakdowns.map((item) {
                      final catColor = _getCategoryColor(item.category, theme);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16.0),
                            border: Border.all(
                              color: theme.colorScheme.outline.withValues(alpha: 0.1),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16.0),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    width: 6,
                                    color: catColor,
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      _getCategoryIcon(item.category),
                                                      color: catColor,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      item.category,
                                                      style: theme.textTheme.titleMedium?.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                Row(
                                                  children: [
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          l10n.personalWeight,
                                                          style: theme.textTheme.bodySmall?.copyWith(
                                                            color: theme.colorScheme.onSurfaceVariant,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          _formatPercent(item.personalWeight, decimal: 1),
                                                          style: theme.textTheme.bodyMedium?.copyWith(
                                                            fontWeight: FontWeight.bold,
                                                            color: theme.colorScheme.primary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(width: 24),
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          l10n.officialWeight,
                                                          style: theme.textTheme.bodySmall?.copyWith(
                                                            color: theme.colorScheme.onSurfaceVariant,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          _formatPercent(item.officialWeight, decimal: 1),
                                                          style: theme.textTheme.bodyMedium?.copyWith(
                                                            fontWeight: FontWeight.bold,
                                                            color: theme.colorScheme.onSurfaceVariant,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Container(
                                            width: 1,
                                            color: theme.colorScheme.outline.withValues(alpha: 0.15),
                                          ),
                                          const SizedBox(width: 20),
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                _formatPercent(item.inflationRate, decimal: 1),
                                                style: theme.textTheme.titleLarge?.copyWith(
                                                  color: catColor,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 22,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                l10n.categoryInflationLabel.toUpperCase(),
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: theme.colorScheme.onSurfaceVariant,
                                                  fontSize: 9,
                                                  letterSpacing: 0.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ]
                ],
              ),
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
