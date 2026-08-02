import 'package:maki_app/features/insights/domain/entities/category_breakdown_entity.dart';

class InflationDataEntity {
  final double? personalInflation;
  final double? officialInflation;
  final List<CategoryBreakdownEntity> breakdowns;
  final bool hasPriceBasket;
  final bool hasComparisonData;
  final double? coveragePercent;
  final double? currentIncome;
  final double? currentExpenses;
  final double? debtPayments;
  final double? netCashFlow;
  final double? financialPressure;
  final int currentTransactionCount;
  final int previousTransactionCount;
  final String status;
  final String? basePeriod;
  final String? currentPeriod;

  const InflationDataEntity({
    this.personalInflation,
    this.officialInflation,
    this.breakdowns = const [],
    this.hasPriceBasket = false,
    this.hasComparisonData = false,
    this.coveragePercent,
    this.currentIncome,
    this.currentExpenses,
    this.debtPayments,
    this.netCashFlow,
    this.financialPressure,
    this.currentTransactionCount = 0,
    this.previousTransactionCount = 0,
    this.status = 'insufficient_data',
    this.basePeriod,
    this.currentPeriod,
  });
}
