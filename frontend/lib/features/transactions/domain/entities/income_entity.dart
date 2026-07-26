import 'package:equatable/equatable.dart';

class IncomeEntity extends Equatable {
  final int? id;
  final String title;
  final double amount;
  final DateTime date;
  final String source;
  final String? notes;

  const IncomeEntity({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.source,
    this.notes,
  });

  @override
  List<Object?> get props => [id, title, amount, date, source, notes];
}
