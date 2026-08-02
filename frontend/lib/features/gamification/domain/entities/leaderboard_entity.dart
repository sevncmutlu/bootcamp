import 'package:equatable/equatable.dart';

class LeaderboardEntity extends Equatable {
  final bool available;
  final int? percentile;
  final String cohortSize;

  const LeaderboardEntity({
    required this.available,
    this.percentile,
    required this.cohortSize,
  });

  @override
  List<Object?> get props => [available, percentile, cohortSize];
}
