import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/core/theme/app_theme.dart';

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
                label: 'Gelir/Gider',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                label: 'Borç',
              ),
              NavigationDestination(
                icon: Icon(Icons.compare_arrows_rounded),
                label: 'Karşılaştır',
              ),
              NavigationDestination(
                icon: Icon(Icons.donut_large_outlined),
                label: 'Analiz',
              ),
              NavigationDestination(
                icon: Icon(Icons.leaderboard_outlined),
                label: 'Lider',
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Gelir/Gider'), findsOneWidget);
    expect(find.text('Lider'), findsOneWidget);
  });
}
