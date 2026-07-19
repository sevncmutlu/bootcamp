import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/screens/onboarding_screen.dart';

void main() {
  testWidgets('küçük ekranda taşmadan kaydırılabilir', (tester) async {
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OnboardingScreen(onCompleted: (_) {}),
      ),
    );

    await tester.tap(find.text('Borçlarımı azaltmak/kapatmak'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(Scrollable), findsOneWidget);
    await tester.drag(find.byType(Scrollable), const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Devam Et'), findsOneWidget);
  });
}
