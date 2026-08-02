import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/features/gamification/domain/entities/living_forest_snapshot.dart';
import 'package:maki_app/features/gamification/presentation/pages/goal_world_map_screen.dart';

void main() {
  const goal = SavingsGoalView(
    id: 'goal-1',
    title: 'Yeni bilgisayar',
    targetAmount: 10000,
    startingAmount: 1000,
    contributedAmount: 4000,
    isPrimary: true,
    iconKey: 'laptop',
    targetDate: null,
  );

  Widget buildMap({required Future<void> Function() onContribute}) {
    return MaterialApp(
      theme: ThemeData(colorSchemeSeed: const Color(0xFF1F7A5A)),
      home: GoalWorldMapScreen(
        goal: goal,
        seedBalance: 48,
        onContribute: onContribute,
      ),
    );
  }

  for (final size in [const Size(390, 844), const Size(844, 390)]) {
    testWidgets('hedef haritasi $size boyutunda tasmaz', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildMap(onContribute: () async {}));
      await tester.pump();

      expect(
        find.image(
          const AssetImage('assets/images/maki_goal_world_map_v1.png'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('goal-map-node-15')), findsOneWidget);
      expect(find.byKey(const ValueKey('goal-map-node-30')), findsOneWidget);
      expect(find.text('Durak 15 / 30'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('kilitli durak ayrintisini acar', (tester) async {
    await tester.pumpWidget(buildMap(onContribute: () async {}));
    await tester.pump();

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 700));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goal-map-node-30')));
    await tester.pumpAndSettle();

    expect(find.text('Patika durağı 30'), findsOneWidget);
    expect(find.textContaining('kilometre taşı'), findsOneWidget);
    expect(find.text('Hedefe katkı ekle'), findsOneWidget);
  });

  testWidgets('yeni hedef ilk durakta güvenle açılır', (tester) async {
    const freshGoal = SavingsGoalView(
      id: 'goal-fresh',
      title: 'İlk hedef',
      targetAmount: 5000,
      startingAmount: 0,
      contributedAmount: 0,
      isPrimary: true,
      iconKey: 'seedling',
      targetDate: null,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: GoalWorldMapScreen(
          goal: freshGoal,
          seedBalance: 0,
          onContribute: () async {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Durak 1 / 30'), findsOneWidget);
    expect(find.byKey(const ValueKey('goal-map-node-1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
