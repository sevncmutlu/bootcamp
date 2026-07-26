import 'package:equatable/equatable.dart';

class PayoffMonthEntity extends Equatable {
  final int month;
  final double remainingBalance;

  const PayoffMonthEntity({
    required this.month,
    required this.remainingBalance,
  });

  @override
  List<Object?> get props => [month, remainingBalance];
}
