part of 'inflation_screen.dart';

class InflationBreakdownSection extends StatelessWidget {
  const InflationBreakdownSection({super.key, required this.breakdowns});

  final List<CategoryBreakdownEntity> breakdowns;

  @override
  Widget build(BuildContext context) {
    if (breakdowns.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final isTurkish = Localizations.localeOf(context).languageCode == 'tr';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isTurkish
              ? 'Sepet dağılımı ve fiyat değişimi'
              : 'Basket mix and price change',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isTurkish
              ? 'Ağırlıklar yalnızca senin doğruladığın ürünlerden hesaplanır.'
              : 'Weights use only the products you confirmed.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 18),
        AspectRatio(
          aspectRatio: 1.8,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 100,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => theme.colorScheme.surfaceContainer,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final item = breakdowns[groupIndex];
                    return BarTooltipItem(
                      '${getLocalizedCategoryName(context, item.category)}\n'
                      '${_formatInflationPercent(context, rod.toY, decimal: 1)}',
                      TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= breakdowns.length) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          getLocalizedCategoryName(
                            context,
                            breakdowns[index].category,
                          ),
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall,
                        ),
                      );
                    },
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
              barGroups: [
                for (var index = 0; index < breakdowns.length; index++)
                  BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: breakdowns[index].personalWeight,
                        width: 18,
                        color: _inflationCategoryColor(
                          breakdowns[index].category,
                          theme,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        for (final item in breakdowns)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _inflationCategoryColor(
                    item.category,
                    theme,
                  ).withValues(alpha: .12),
                  child: Icon(
                    _inflationCategoryIcon(item.category),
                    color: _inflationCategoryColor(item.category, theme),
                  ),
                ),
                title: Text(
                  getLocalizedCategoryName(context, item.category),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${isTurkish ? 'Sepet payı' : 'Basket share'}: '
                  '${_formatInflationPercent(context, item.personalWeight, decimal: 1)}',
                ),
                trailing: Text(
                  _formatInflationPercent(
                    context,
                    item.inflationRate,
                    decimal: 1,
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: _inflationCategoryColor(item.category, theme),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

String _formatInflationPercent(
  BuildContext context,
  double value, {
  int decimal = 2,
}) {
  final valueText = value.toStringAsFixed(decimal);
  return Localizations.localeOf(context).languageCode == 'tr'
      ? '%$valueText'
      : '$valueText%';
}

IconData _inflationCategoryIcon(String category) {
  return switch (category.toLowerCase()) {
    'market' || 'alışveriş' => Icons.shopping_cart_outlined,
    'restaurant' || 'restoran' || 'yemek' => Icons.restaurant_outlined,
    'rent' || 'kira' => Icons.home_outlined,
    'transport' || 'ulaşım' => Icons.directions_bus_outlined,
    'fun' || 'eğlence' => Icons.sports_esports_outlined,
    'bills' || 'faturalar' => Icons.receipt_long_outlined,
    _ => Icons.category_outlined,
  };
}

Color _inflationCategoryColor(String category, ThemeData theme) {
  return switch (category.toLowerCase()) {
    'market' || 'alışveriş' => theme.colorScheme.primary,
    'restaurant' || 'restoran' || 'yemek' => Colors.orange,
    'rent' || 'kira' => Colors.green,
    'transport' || 'ulaşım' => Colors.blue,
    'fun' || 'eğlence' => Colors.purple,
    'bills' || 'faturalar' => Colors.red,
    _ => theme.colorScheme.primary,
  };
}
