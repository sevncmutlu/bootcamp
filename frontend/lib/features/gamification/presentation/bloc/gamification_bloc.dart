import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/features/gamification/domain/repositories/gamification_repository.dart';
import 'package:maki_app/features/gamification/presentation/bloc/gamification_event.dart';
import 'package:maki_app/features/gamification/presentation/bloc/gamification_state.dart';
import 'dart:developer' as developer;

class GamificationBloc extends Bloc<GamificationEvent, GamificationState> {
  final GamificationRepository repository;

  GamificationBloc({required this.repository}) : super(GamificationState.initial()) {
    on<LoadGamificationDataEvent>(_onLoadGamificationData);
    on<ClaimXPEvent>(_onClaimXP);
    on<LoadLeaderboardEvent>(_onLoadLeaderboard);
    on<UpdateLeaderboardFiltersEvent>(_onUpdateLeaderboardFilters);
  }

  Future<void> _onLoadGamificationData(
    LoadGamificationDataEvent event,
    Emitter<GamificationState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      final now = DateTime.now();
      
      await repository.evaluateDailyChallenges(now);
      final challenges = await repository.getDailyChallenges(now);
      final status = await repository.getGamificationStatus();
      final score = await repository.getSavingsScoreBasisPoints();
      final hasWeeklyIncome = await repository.hasWeeklyIncome();

      emit(state.copyWith(
        isLoading: false,
        status: status,
        challenges: challenges,
        savingsScoreBasisPoints: score,
        hasWeeklyIncome: hasWeeklyIncome,
      ));
    } catch (e, stackTrace) {
      developer.log(
        'Failed to load gamification data',
        error: e,
        stackTrace: stackTrace,
        name: 'GamificationBloc',
      );
      emit(state.copyWith(isLoading: false, error: 'Oyunlaştırma verileri yüklenirken bir hata oluştu.'));
    }
  }

  Future<void> _onClaimXP(
    ClaimXPEvent event,
    Emitter<GamificationState> emit,
  ) async {
    if (!event.challenge.isCompleted || event.challenge.xpReward == 0) return;

    try {
      final updatedStatus = await repository.claimXP(event.challenge);
      
      // Refresh challenges after claiming
      final now = DateTime.now();
      final challenges = await repository.getDailyChallenges(now);

      emit(state.copyWith(
        status: updatedStatus,
        challenges: challenges,
        newlyClaimedXP: event.challenge.xpReward,
      ));
    } catch (e, stackTrace) {
      developer.log(
        'Failed to claim XP',
        error: e,
        stackTrace: stackTrace,
        name: 'GamificationBloc',
      );
      emit(state.copyWith(error: 'XP alınırken bir hata oluştu.'));
    }
  }

  Future<void> _onLoadLeaderboard(
    LoadLeaderboardEvent event,
    Emitter<GamificationState> emit,
  ) async {
    emit(state.copyWith(isLeaderboardLoading: true));
    try {
      final leaderboard = await repository.getLeaderboard(
        ageBand: state.leaderboardAgeBand,
        householdBand: state.leaderboardHouseholdBand,
        scoreBasisPoints: state.savingsScoreBasisPoints,
      );
      emit(state.copyWith(
        isLeaderboardLoading: false,
        leaderboard: leaderboard,
      ));
    } catch (e, stackTrace) {
      developer.log(
        'Failed to load leaderboard',
        error: e,
        stackTrace: stackTrace,
        name: 'GamificationBloc',
      );
      emit(state.copyWith(
        isLeaderboardLoading: false,
        leaderboardError: 'Sıralama verileri yüklenirken bir hata oluştu.',
      ));
    }
  }

  Future<void> _onUpdateLeaderboardFilters(
    UpdateLeaderboardFiltersEvent event,
    Emitter<GamificationState> emit,
  ) async {
    emit(state.copyWith(
      leaderboardAgeBand: event.ageBand,
      leaderboardHouseholdBand: event.householdBand,
    ));
    add(const LoadLeaderboardEvent());
  }
}
