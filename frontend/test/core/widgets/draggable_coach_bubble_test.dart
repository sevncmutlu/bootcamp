import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/core/widgets/draggable_coach_bubble.dart';

Widget _app({
  Offset initialPosition = const Offset(1, 0.62),
  VoidCallback? onTap,
  ValueChanged<Offset>? onPositionChanged,
}) {
  return MaterialApp(
    home: Scaffold(
      body: DraggableCoachBubble(
        initialPosition: initialPosition,
        onTap: onTap ?? () {},
        onPositionChanged: onPositionChanged ?? (_) {},
        tooltip: 'Maki Koç',
        child: const Icon(Icons.pets_rounded),
      ),
    ),
  );
}

void main() {
  testWidgets('a normal tap opens the coach', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_app(onTap: () => taps++));

    await tester.tap(find.byKey(const ValueKey('maki-coach-bubble')));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('dragging does not tap and snaps to the nearest edge', (
    tester,
  ) async {
    var taps = 0;
    Offset? savedPosition;
    await tester.pumpWidget(
      _app(
        onTap: () => taps++,
        onPositionChanged: (position) => savedPosition = position,
      ),
    );

    await tester.drag(
      find.byKey(const ValueKey('maki-coach-bubble')),
      const Offset(-700, -80),
    );
    await tester.pumpAndSettle();

    expect(taps, 0);
    expect(savedPosition, isNotNull);
    expect(savedPosition!.dx, 0);
    expect(savedPosition!.dy, inInclusiveRange(0, 1));
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('maki-coach-bubble'))).dx,
      12,
    );
  });

  testWidgets('saved position remains inside the safe area after rotation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(initialPosition: const Offset(1, 0.98)));
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(844, 390);
    await tester.pumpWidget(_app(initialPosition: const Offset(1, 0.98)));
    await tester.pumpAndSettle();

    final rect = tester.getRect(
      find.byKey(const ValueKey('maki-coach-bubble')),
    );
    expect(rect.left, greaterThanOrEqualTo(12));
    expect(rect.right, lessThanOrEqualTo(844 - 12));
    expect(rect.top, greaterThanOrEqualTo(kToolbarHeight + 12));
    expect(rect.bottom, lessThanOrEqualTo(390 - 12));
    expect(tester.takeException(), isNull);
  });
}
