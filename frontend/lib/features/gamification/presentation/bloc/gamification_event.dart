import 'package:equatable/equatable.dart';
import 'package:maki_app/features/gamification/domain/entities/daily_challenge_entity.dart';

abstract class GamificationEvent extends Equatable {
  const GamificationEvent();

  @override
  List<Object?> get props => [];
}

class LoadGamificationDataEvent extends GamificationEvent {}

class ClaimXPEvent extends GamificationEvent {
  final DailyChallengeEntity challenge;

  const ClaimXPEvent(this.challenge);

  @override
  List<Object?> get props => [challenge];
}

class LoadLeaderboardEvent extends GamificationEvent {
  const LoadLeaderboardEvent();
}

class UpdateLeaderboardFiltersEvent extends GamificationEvent {
  final String? ageBand;
  final String? householdBand;

  const UpdateLeaderboardFiltersEvent({this.ageBand, this.householdBand});

  @override
  List<Object?> get props => [ageBand, householdBand];
}
