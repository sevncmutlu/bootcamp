import 'package:equatable/equatable.dart';

class DebtEntity extends Equatable {
  final String id;
  final String name;
  final double balance;
  final double interestRate;
  final double minPayment;

  const DebtEntity({
    required this.id,
    required this.name,
    required this.balance,
    required this.interestRate,
    required this.minPayment,
  });

  @override
  List<Object?> get props => [id, name, balance, interestRate, minPayment];
}
