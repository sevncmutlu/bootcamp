import '../money/money.dart';

/// Borç simülasyonunun kapanış durumu.
enum DebtSimulationStatus {
  paidOff,
  insufficientMinimumBudget,
  negativeAmortization,
  horizonExceeded,
}

/// Bir ayda tek borç için muhasebe satırı.
final class DebtMonthLine {
  const DebtMonthLine({
    required this.debtId,
    required this.startingBalance,
    required this.interest,
    required this.payment,
    required this.principalPaid,
    required this.endingBalance,
  });

  final String debtId;
  final Money startingBalance;
  final Money interest;
  final Money payment;
  final Money principalPaid;
  final Money endingBalance;
}

/// Tek bir ayın değişmez ödeme özeti.
final class DebtMonth {
  DebtMonth({
    required this.monthNumber,
    required List<DebtMonthLine> lines,
    required this.totalPayment,
  }) : lines = List.unmodifiable(lines);

  final int monthNumber;
  final List<DebtMonthLine> lines;
  final Money totalPayment;
}

/// Borç ödeme simülasyonu sonucu.
final class DebtSimulation {
  DebtSimulation({
    required this.status,
    required this.monthsElapsed,
    required this.totalInterest,
    required this.totalPaid,
    required this.remainingBalance,
    required List<DebtMonth> schedule,
  }) : schedule = List.unmodifiable(schedule);

  final DebtSimulationStatus status;
  final int? monthsElapsed;
  final Money totalInterest;
  final Money totalPaid;
  final Money remainingBalance;
  final List<DebtMonth> schedule;
}
