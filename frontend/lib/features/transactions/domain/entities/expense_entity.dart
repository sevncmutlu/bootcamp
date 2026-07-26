import 'package:equatable/equatable.dart';

class ExpenseEntity extends Equatable {
  final int? id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final String? notes;

  const ExpenseEntity({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.notes,
  });

  @override
  List<Object?> get props => [id, title, amount, date, category, notes];
}
