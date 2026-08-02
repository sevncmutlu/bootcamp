import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/core/theme/app_theme.dart';
import 'package:maki_app/core/widgets/maki_adaptive_navigation.dart';
import 'package:maki_app/core/widgets/maki_navigation_dock.dart';

const _destinations = [
  NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Ana'),
  NavigationDestination(icon: Icon(Icons.analytics_outlined), label: 'Analiz'),
];

Widget _app() => MaterialApp(
  theme: AppTheme.lightTheme,
  home: MakiAdaptiveNavigation(
    body: const ColoredBox(color: Colors.white),
    selectedIndex: 0,
    onDestinationSelected: (_) {},
    destinations: _destinations,
  ),
);

void main() {
  testWidgets('portrait düzende alt dock kullanır', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.byType(MakiNavigationDock), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('844x390 telefon yatay düzende alt dock kullanır ve taşmaz', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('maki-navigation-rail')), findsNothing);
    expect(find.byType(MakiNavigationDock), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('1200 piksel web düzende rail kullanır ve taşmaz', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('maki-navigation-rail')), findsOneWidget);
    expect(find.byType(MakiNavigationDock), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
