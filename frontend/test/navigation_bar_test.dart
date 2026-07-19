import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/theme/app_theme.dart';

void main() {
  testWidgets('beş Türkçe menü dar ekranda taşmaz', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          bottomNavigationBar: NavigationBar(
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.wallet_outlined),
                label: 'Harcama',
              ),
              NavigationDestination(
                icon: Icon(Icons.pie_chart_outline),
                label: 'Analiz',
              ),
              NavigationDestination(
                icon: Icon(Icons.credit_card_outlined),
                label: 'Borç',
              ),
              NavigationDestination(
                icon: Icon(Icons.forest_outlined),
                label: 'Orman',
              ),
              NavigationDestination(
                icon: Icon(Icons.spa_outlined),
                label: 'Koç',
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Harcama'), findsOneWidget);
    expect(find.text('Koç'), findsOneWidget);
  });
}
