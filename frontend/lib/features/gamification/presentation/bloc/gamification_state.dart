import 'package:equatable/equatable.dart';
import 'package:maki_app/features/gamification/domain/entities/daily_challenge_entity.dart';
import 'package:maki_app/features/gamification/domain/entities/gamification_status_entity.dart';
import 'package:maki_app/features/gamification/domain/entities/leaderboard_entity.dart';

class GamificationState extends Equatable {
  final bool isLoading;
  final GamificationStatusEntity? status;
  final List<DailyChallengeEntity> challenges;
  final int savingsScoreBasisPoints;
  final bool hasWeeklyIncome;
  final String? error;
  final int? newlyClaimedXP;
  final LeaderboardEntity? leaderboard;
  final bool isLeaderboardLoading;
  final String leaderboardAgeBand;
  final String leaderboardHouseholdBand;
  final String? leaderboardError;

  const GamificationState({
    required this.isLoading,
    this.status,
    required this.challenges,
    required this.savingsScoreBasisPoints,
    required this.hasWeeklyIncome,
    this.error,
    this.newlyClaimedXP,
    this.leaderboard,
    required this.isLeaderboardLoading,
    required this.leaderboardAgeBand,
    required this.leaderboardHouseholdBand,
    this.leaderboardError,
  });

  factory GamificationState.initial() {
    return const GamificationState(
      isLoading: true,
      challenges: [],
      savingsScoreBasisPoints: 0,
      hasWeeklyIncome: false,
      isLeaderboardLoading: false,
      leaderboardAgeBand: '25-34',
      leaderboardHouseholdBand: '1',
    );
  }

  GamificationState copyWith({
    bool? isLoading,
    GamificationStatusEntity? status,
    List<DailyChallengeEntity>? challenges,
    int? savingsScoreBasisPoints,
    bool? hasWeeklyIncome,
    String? error,
    int? newlyClaimedXP,
    LeaderboardEntity? leaderboard,
    bool? isLeaderboardLoading,
    String? leaderboardAgeBand,
    String? leaderboardHouseholdBand,
    String? leaderboardError,
  }) {
    return GamificationState(
      isLoading: isLoading ?? this.isLoading,
      status: status ?? this.status,
      challenges: challenges ?? this.challenges,
      savingsScoreBasisPoints:
          savingsScoreBasisPoints ?? this.savingsScoreBasisPoints,
      hasWeeklyIncome: hasWeeklyIncome ?? this.hasWeeklyIncome,
      error: error,
      newlyClaimedXP: newlyClaimedXP,
      leaderboard: leaderboard ?? this.leaderboard,
      isLeaderboardLoading: isLeaderboardLoading ?? this.isLeaderboardLoading,
      leaderboardAgeBand: leaderboardAgeBand ?? this.leaderboardAgeBand,
      leaderboardHouseholdBand:
          leaderboardHouseholdBand ?? this.leaderboardHouseholdBand,
      leaderboardError: leaderboardError ?? this.leaderboardError,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    status,
    challenges,
    savingsScoreBasisPoints,
    hasWeeklyIncome,
    error,
    newlyClaimedXP,
    leaderboard,
    isLeaderboardLoading,
    leaderboardAgeBand,
    leaderboardHouseholdBand,
    leaderboardError,
  ];
}
