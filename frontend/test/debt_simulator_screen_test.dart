import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/screens/debt_simulator_screen.dart';

Widget _uygulama({required List<DebtModel> borclar}) {
  return MaterialApp(
    locale: const Locale('tr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: DebtSimulatorScreen(initialDebts: borclar),
  );
}

void main() {
  testWidgets('silinen borç ekrandan hemen kaldırılır', (tester) async {
    await tester.pumpWidget(
      _uygulama(
        borclar: const [
          DebtModel(
            id: 'kart-1',
            name: 'Kredi Kartı',
            balance: 12500,
            interestRate: 4.25,
            minPayment: 2500,
          ),
        ],
      ),
    );

    expect(find.text('Kredi Kartı'), findsOneWidget);
    await tester.tap(find.byTooltip('Borcu sil'));
    await tester.pump();

    expect(find.text('Kredi Kartı'), findsNothing);
    expect(find.textContaining('Henüz borç eklenmedi'), findsOneWidget);
  });

  testWidgets('dar ekranda ödeme stratejisi taşma üretmez', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _uygulama(
        borclar: const [
          DebtModel(
            id: 'kredi-1',
            name: 'İhtiyaç Kredisi',
            balance: 50000,
            interestRate: 3.49,
            minPayment: 4200,
          ),
        ],
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Çığ (En Yüksek Faiz)'), findsOneWidget);
    expect(find.text('Kar Topu (En Düşük Bakiye)'), findsOneWidget);
  });
}
