import 'package:equatable/equatable.dart';

class DailyChallengeEntity extends Equatable {
  final String id;
  final String titleKey;
  final String descKey;
  final int xpReward;
  final bool isCompleted;
  final DateTime date;

  const DailyChallengeEntity({
    required this.id,
    required this.titleKey,
    required this.descKey,
    required this.xpReward,
    required this.isCompleted,
    required this.date,
  });

  @override
  List<Object?> get props => [
        id,
        titleKey,
        descKey,
        xpReward,
        isCompleted,
        date,
      ];
}
