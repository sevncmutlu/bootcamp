import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/core/widgets/maki_lazy_indexed_stack.dart';

void main() {
  testWidgets('builds destinations lazily and keeps each one alive', (
    tester,
  ) async {
    final selectedIndex = ValueNotifier<int>(0);
    final buildCounts = List<int>.filled(5, 0);
    addTearDown(selectedIndex.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<int>(
            valueListenable: selectedIndex,
            builder: (context, index, _) {
              return MakiLazyIndexedStack(
                index: index,
                itemCount: 5,
                reduceMotion: true,
                itemBuilder: (context, itemIndex) {
                  buildCounts[itemIndex]++;
                  return ColoredBox(
                    key: ValueKey('screen-$itemIndex'),
                    color: Colors.white,
                  );
                },
              );
            },
          ),
        ),
      ),
    );

    expect(buildCounts, <int>[1, 0, 0, 0, 0]);

    for (var index = 1; index < 5; index++) {
      selectedIndex.value = index;
      await tester.pump();
      expect(find.byKey(ValueKey('screen-$index')).hitTestable(), findsOne);
    }

    expect(buildCounts, <int>[1, 1, 1, 1, 1]);

    selectedIndex.value = 0;
    await tester.pump();
    selectedIndex.value = 4;
    await tester.pump();

    expect(buildCounts, <int>[1, 1, 1, 1, 1]);
    expect(find.byKey(const ValueKey('screen-4')).hitTestable(), findsOne);
  });

  testWidgets('rapid destination changes leave only the last screen active', (
    tester,
  ) async {
    final selectedIndex = ValueNotifier<int>(0);
    addTearDown(selectedIndex.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<int>(
            valueListenable: selectedIndex,
            builder: (context, index, _) => MakiLazyIndexedStack(
              index: index,
              itemCount: 5,
              itemBuilder: (context, itemIndex) => ColoredBox(
                key: ValueKey('rapid-screen-$itemIndex'),
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );

    selectedIndex.value = 1;
    await tester.pump(const Duration(milliseconds: 20));
    selectedIndex.value = 3;
    await tester.pump(const Duration(milliseconds: 20));
    selectedIndex.value = 2;
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.byKey(const ValueKey('rapid-screen-2')).hitTestable(),
      findsOne,
    );
    expect(
      find.byKey(const ValueKey('rapid-screen-1')).hitTestable(),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('rapid-screen-3')).hitTestable(),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
