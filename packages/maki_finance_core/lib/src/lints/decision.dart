/// LinTS politikasının değişmez karar kaydı.
final class LinTsDecision {
  LinTsDecision({
    required this.decisionId,
    required this.armId,
    required this.messageKey,
    required this.scheduledAt,
    required List<double> context,
  }) : context = List.unmodifiable(context);

  final String decisionId;
  final String armId;
  final String messageKey;
  final DateTime scheduledAt;
  final List<double> context;
}
