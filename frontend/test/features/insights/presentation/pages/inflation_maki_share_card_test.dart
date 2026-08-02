import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/features/insights/presentation/pages/inflation_screen.dart';
import 'package:maki_app/l10n/app_localizations.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    required double personal,
    required double official,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: InflationMakiShareCard(
              personalInflation: personal,
              officialInflation: official,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows a proud Maki and export actions below comparison', (
    tester,
  ) async {
    await pumpCard(tester, personal: 28.5, official: 31.0);

    expect(find.byKey(const ValueKey('inflation-maki-proud')), findsOneWidget);
    expect(find.text('Tebrikler, ritmin dengeli'), findsOneWidget);
    expect(find.text('PNG indir'), findsOneWidget);
    expect(find.text('Paylaş'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('download-inflation-card')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('share-inflation-card')), findsOneWidget);
  });

  testWidgets('shows a concerned Maki when the personal basket rises faster', (
    tester,
  ) async {
    await pumpCard(tester, personal: 38.2, official: 31.0);

    expect(
      find.byKey(const ValueKey('inflation-maki-concerned')),
      findsOneWidget,
    );
    expect(find.text('Birlikte biraz dikkat edelim'), findsOneWidget);
    expect(find.textContaining('puan üzerinde'), findsOneWidget);
  });

  testWidgets('shows an honest 3D Maki preview while data is missing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(child: InflationMakiWaitingCard()),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('inflation-maki-waiting')),
      findsOneWidget,
    );
    expect(find.text('ÖRNEK · VERİ BEKLENİYOR'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
