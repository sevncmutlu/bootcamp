import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:maki_app/core/database/database.dart';
import 'package:maki_app/core/notifications/notification_scheduler.dart';
import 'package:maki_finance_core/maki_finance_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SmartNotificationService {
  SmartNotificationService({
    required AppDatabase database,
    required SharedPreferences preferences,
    required MakiNotificationScheduler scheduler,
    GaussianSource? gaussianSource,
    Clock? clock,
  }) : _database = database,
       _preferences = preferences,
       _scheduler = scheduler,
       _gaussianSource = gaussianSource ?? _RandomGaussianSource(),
       _clock = clock ?? const _SystemClock();

  static const enabledPreference = 'smart_notifications_enabled';
  static const _dimension = 6;
  static const _policyId = 'maki-smart-reminders-v1';
  static const _policyRowId = 1;

  final AppDatabase _database;
  final SharedPreferences _preferences;
  final MakiNotificationScheduler _scheduler;
  final GaussianSource _gaussianSource;
  final Clock _clock;

  bool get isEnabled => _preferences.getBool(enabledPreference) ?? false;

  Future<void> initialize() async {
    await _scheduler.initialize(markOpened);
    await _settleExpiredDecisions();
    if (isEnabled) await scheduleNext();
  }

  Future<bool> requestAndEnable() async {
    final granted = await _scheduler.requestPermission();
    await _preferences.setBool(enabledPreference, granted);
    if (granted) await scheduleNext();
    return granted;
  }

  Future<void> disable() async {
    await _preferences.setBool(enabledPreference, false);
    await _scheduler.cancelAll();
  }

  Future<int> currentOptimalHour() async {
    final now = _clock.now();
    final pending =
        await (_database.select(_database.notificationEngagements)
              ..where((row) => row.scheduledAt.isBiggerThanValue(now))
              ..orderBy([(row) => OrderingTerm.asc(row.scheduledAt)])
              ..limit(1))
            .getSingleOrNull();
    return _hourForArm(pending?.arm ?? 'morning');
  }

  Future<void> scheduleNext() async {
    if (!isEnabled) return;
    await _settleExpiredDecisions();

    final now = _clock.now();
    final pending =
        await (_database.select(_database.notificationEngagements)
              ..where((row) => row.scheduledAt.isBiggerThanValue(now))
              ..limit(1))
            .getSingleOrNull();
    if (pending != null) return;

    final rollingStart = now.subtract(const Duration(days: 7));
    final recent =
        await (_database.select(_database.notificationEngagements)..where(
              (row) => row.scheduledAt.isBiggerOrEqualValue(rollingStart),
            ))
            .get();
    if (recent.length >= 7) return;

    final context = await _context(now, recent.length);
    final previousState = await _loadState();
    final policy = LinTsPolicy(
      state: previousState,
      gaussianSource: _gaussianSource,
      clock: _clock,
      exploration: 0.5,
    );
    final decision = policy.decide(context);
    final hour = _hourForArm(decision.armId);
    var scheduledAt = DateTime(now.year, now.month, now.day, hour);
    if (!scheduledAt.isAfter(now.add(const Duration(minutes: 5)))) {
      final tomorrow = now.add(const Duration(days: 1));
      scheduledAt = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, hour);
    }

    final sameDay = recent.any(
      (entry) =>
          entry.scheduledAt.year == scheduledAt.year &&
          entry.scheduledAt.month == scheduledAt.month &&
          entry.scheduledAt.day == scheduledAt.day,
    );
    if (sameDay) return;

    await _database.transaction(() async {
      await _saveState(policy.state);
      await _database
          .into(_database.notificationEngagements)
          .insert(
            NotificationEngagementsCompanion.insert(
              id: decision.decisionId,
              notificationType: 'smart_finance',
              arm: decision.armId,
              scheduledAt: scheduledAt,
            ),
          );
    });

    try {
      await _scheduler.schedule(
        id: _stableNotificationId(decision.decisionId),
        at: scheduledAt,
        title: 'Maki seni bekliyor 🌿',
        body: _messageForArm(decision.armId),
        payload: decision.decisionId,
      );
    } on Object {
      await _database.transaction(() async {
        await (_database.delete(
          _database.notificationEngagements,
        )..where((row) => row.id.equals(decision.decisionId))).go();
        await _saveState(previousState);
      });
      rethrow;
    }
  }

  Future<void> markOpened(String decisionId) async {
    final engagement = await (_database.select(
      _database.notificationEngagements,
    )..where((row) => row.id.equals(decisionId))).getSingleOrNull();
    if (engagement == null || engagement.openedAt != null) return;
    await (_database.update(_database.notificationEngagements)
          ..where((row) => row.id.equals(decisionId)))
        .write(NotificationEngagementsCompanion(openedAt: Value(_clock.now())));
  }

  Future<void> recordMeaningfulAction() async {
    final now = _clock.now();
    final threshold = now.subtract(const Duration(hours: 24));
    final engagement =
        await (_database.select(_database.notificationEngagements)
              ..where(
                (row) =>
                    row.openedAt.isNotNull() &
                    row.openedAt.isBiggerOrEqualValue(threshold) &
                    row.meaningfulActionAt.isNull() &
                    row.rewardSettledAt.isNull(),
              )
              ..orderBy([(row) => OrderingTerm.desc(row.openedAt)])
              ..limit(1))
            .getSingleOrNull();
    if (engagement == null) return;

    await (_database.update(
      _database.notificationEngagements,
    )..where((row) => row.id.equals(engagement.id))).write(
      NotificationEngagementsCompanion(meaningfulActionAt: Value(now)),
    );
    await _applyReward(engagement.id, 1, now);
  }

  Future<void> _settleExpiredDecisions() async {
    final now = _clock.now();
    final deadline = now.subtract(const Duration(hours: 24));
    final expired =
        await (_database.select(_database.notificationEngagements)..where(
              (row) =>
                  row.scheduledAt.isSmallerOrEqualValue(deadline) &
                  row.rewardSettledAt.isNull(),
            ))
            .get();
    for (final engagement in expired) {
      final reward = engagement.meaningfulActionAt != null
          ? 1.0
          : engagement.openedAt != null
          ? 0.25
          : 0.0;
      await _applyReward(engagement.id, reward, now);
    }
  }

  Future<void> _applyReward(
    String decisionId,
    double reward,
    DateTime settledAt,
  ) async {
    final state = await _loadState();
    final decision = state.decisions
        .where((item) => item.decisionId == decisionId)
        .firstOrNull;
    if (decision == null || decision.rewarded) return;

    final policy = LinTsPolicy(
      state: state,
      gaussianSource: _gaussianSource,
      clock: _clock,
    );
    policy.reward(
      decisionId: decisionId,
      context: decision.context,
      reward: reward,
    );
    await _database.transaction(() async {
      await _saveState(policy.state);
      await (_database.update(
        _database.notificationEngagements,
      )..where((row) => row.id.equals(decisionId))).write(
        NotificationEngagementsCompanion(
          rewardSettledAt: Value(settledAt),
          rewardValue: Value(reward),
        ),
      );
    });
  }

  Future<List<double>> _context(DateTime now, int rollingCount) async {
    final activityFloor = now.subtract(const Duration(days: 3));
    final expenses = await _database.getAllExpenses();
    final incomes = await _database.getAllIncomes();
    final hasRecentActivity =
        expenses.any((item) => item.date.isAfter(activityFloor)) ||
        incomes.any((item) => item.date.isAfter(activityFloor));
    final streak = await _database
        .select(_database.forestStreakStates)
        .getSingleOrNull();
    final lastDay = streak?.lastCompletedDay;
    final streakAtRisk =
        (streak?.currentStreak ?? 0) > 0 &&
        (lastDay == null ||
            DateTime(
              lastDay.year,
              lastDay.month,
              lastDay.day,
            ).isBefore(DateTime(now.year, now.month, now.day)));
    final activeGoal =
        await (_database.select(_database.savingsGoals)
              ..where((row) => row.status.equals('active'))
              ..limit(1))
            .getSingleOrNull();
    final weekend =
        now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    return [
      1,
      weekend ? 1 : 0,
      hasRecentActivity ? 1 : 0,
      streakAtRisk ? 1 : 0,
      activeGoal == null ? 0 : 1,
      (rollingCount / 7).clamp(0, 1).toDouble(),
    ];
  }

  Future<LinTsState> _loadState() async {
    final snapshot = await (_database.select(
      _database.notificationPolicySnapshots,
    )..where((row) => row.id.equals(_policyRowId))).getSingleOrNull();
    if (snapshot == null) {
      return LinTsState.initial(
        policyId: _policyId,
        dimension: _dimension,
        arms: const [
          LinTsArmSeed(armId: 'morning', messageKey: 'morning_check'),
          LinTsArmSeed(armId: 'afternoon', messageKey: 'afternoon_check'),
          LinTsArmSeed(armId: 'evening', messageKey: 'evening_check'),
        ],
      );
    }
    final decoded = jsonDecode(snapshot.stateJson);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Bildirim politikası kaydı geçersiz.');
    }
    return LinTsState.fromJson(decoded);
  }

  Future<void> _saveState(LinTsState state) async {
    await _database
        .into(_database.notificationPolicySnapshots)
        .insertOnConflictUpdate(
          NotificationPolicySnapshotsCompanion.insert(
            id: const Value(_policyRowId),
            stateJson: jsonEncode(state.toJson()),
            updatedAt: _clock.now(),
          ),
        );
  }

  static int _hourForArm(String arm) => switch (arm) {
    'afternoon' => 14,
    'evening' => 20,
    _ => 9,
  };

  static String _messageForArm(String arm) => switch (arm) {
    'afternoon' =>
      'Bugünün gelir-gider akışına kısa bir bakış ormanını güçlendirir.',
    'evening' => 'Günü kapatmadan küçük bir finans adımı serini koruyabilir.',
    _ => 'Bugünün finans adımı hazır; küçük bir kayıt büyük bir yol açar.',
  };

  static int _stableNotificationId(String value) {
    var hash = 0x811C9DC5;
    for (final unit in value.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7FFFFFFF;
    }
    return hash;
  }
}

class _RandomGaussianSource implements GaussianSource {
  final Random _random = Random.secure();

  @override
  double next() {
    var first = 0.0;
    while (first == 0) {
      first = _random.nextDouble();
    }
    final second = _random.nextDouble();
    return sqrt(-2 * log(first)) * cos(2 * pi * second);
  }
}

class _SystemClock implements Clock {
  const _SystemClock();

  @override
  DateTime now() => DateTime.now();
}
