import 'package:maki_app/core/database/database.dart';
import 'package:maki_app/features/gamification/domain/entities/daily_challenge_catalog.dart';

abstract class GamificationLocalDataSource {
  Future<List<DailyChallenge>> getOrSeedDailyChallenges(DateTime date);
  Future<UserGamificationState> getGamificationStatus();
  Future<void> updateGamificationStatus(UserGamificationState status);
  Future<void> updateChallenge(DailyChallenge challenge);
}

class GamificationLocalDataSourceImpl implements GamificationLocalDataSource {
  GamificationLocalDataSourceImpl(
    this._db, {
    Future<String?> Function()? primaryGoalProvider,
  }) : _primaryGoalProvider = primaryGoalProvider;

  final AppDatabase _db;
  final Future<String?> Function()? _primaryGoalProvider;

  static const _dailyChallengeCount = 4;
  static const _rotationVersion = 'v4';

  @override
  Future<List<DailyChallenge>> getOrSeedDailyChallenges(DateTime date) async {
    final storedGoal = await _primaryGoalProvider?.call();
    final routeKey = DailyChallengeCatalog.routeFamilies.containsKey(storedGoal)
        ? storedGoal!
        : 'track_spending';
    final rotationPrefix = '${_rotationVersion}_${routeKey}_';
    final existing = await _db.getChallengesForDate(date);
    final currentRotation =
        existing
            .where((challenge) => challenge.id.startsWith(rotationPrefix))
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    if (currentRotation.length >= _dailyChallengeCount) {
      return currentRotation.take(_dailyChallengeCount).toList(growable: false);
    }

    final dateStr =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final selected =
        DailyChallengeCatalog.selectionForDay(date, routeKey: routeKey)
            .map(
              (template) => DailyChallenge(
                id: '$rotationPrefix${template.id}_$dateStr',
                titleKey: 'catalog:${template.id}:title',
                descKey: 'catalog:${template.id}:description',
                xpReward: template.xp,
                isCompleted: false,
                date: date,
              ),
            )
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));

    for (final challenge in selected) {
      await _db.insertChallenge(challenge);
    }
    return List.unmodifiable(selected);
  }

  @override
  Future<UserGamificationState> getGamificationStatus() async {
    var status = await _db.getGamificationState();
    if (status == null) {
      status = const UserGamificationState(id: 1, xp: 0, level: 1, badges: '');
      await _db.updateGamificationState(status);
    }
    return status;
  }

  @override
  Future<void> updateGamificationStatus(UserGamificationState status) async {
    await _db.updateGamificationState(status);
  }

  @override
  Future<void> updateChallenge(DailyChallenge challenge) async {
    await _db.updateChallenge(challenge);
  }
}
