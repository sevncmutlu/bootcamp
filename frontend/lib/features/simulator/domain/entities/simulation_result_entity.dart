import 'package:equatable/equatable.dart';
import 'package:maki_app/features/simulator/domain/entities/payoff_month_entity.dart';

class SimulationResultEntity extends Equatable {
  final int monthsToFree;
  final double totalInterestPaid;
  final double? successProbability;
  final List<PayoffMonthEntity> schedule;

  const SimulationResultEntity({
    required this.monthsToFree,
    required this.totalInterestPaid,
    this.successProbability,
    required this.schedule,
  });

  @override
  List<Object?> get props => [
    monthsToFree,
    totalInterestPaid,
    successProbability,
    schedule,
  ];
}
