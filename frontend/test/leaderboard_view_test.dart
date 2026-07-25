import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/screens/leaderboard_screen.dart';

void main() {
  testWidgets('LeaderboardView renders filter chips and privacy notice', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: LeaderboardView(
            scoreBasisPoints: 3500,
            userLevel: 2,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(ChoiceChip), findsAtLeastNWidgets(5));
    expect(find.text('Yaş grubu'), findsOneWidget);
    expect(find.text('Hane büyüklüğü'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
