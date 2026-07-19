import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/widgets/forest_progress_card.dart';
import 'package:maki_app/widgets/mascot.dart';

void main() {
  testWidgets('orman aşaması gerçek ilerlemeyi dar ekranda gösterir', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: ForestProgressCard(
              level: 3,
              xp: 125,
              maxXp: 300,
              savingsScoreBasisPoints: 4200,
              hasWeeklyIncome: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Büyüyen Fidan'), findsOneWidget);
    expect(find.text('Aşama 3 / 5'), findsOneWidget);
    expect(find.text('Orman sağlığı'), findsOneWidget);
    expect(find.text('%42'), findsOneWidget);
    expect(find.byType(Mascot), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
