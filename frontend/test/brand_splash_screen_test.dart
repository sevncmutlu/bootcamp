import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/screens/brand_splash_screen.dart';
import 'package:maki_app/widgets/brand_wordmark.dart';
import 'package:maki_app/widgets/mascot.dart';

void main() {
  testWidgets('maskotu ve MakiKoç imzasını gösterip tamamlanır', (
    tester,
  ) async {
    var tamamlanmaSayisi = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: BrandSplashScreen(
          onCompleted: () {
            tamamlanmaSayisi++;
          },
        ),
      ),
    );

    expect(find.byType(Mascot), findsOneWidget);
    expect(find.byType(BrandWordmark), findsOneWidget);
    expect(tamamlanmaSayisi, 0);

    await tester.pump(const Duration(seconds: 2));
    expect(tamamlanmaSayisi, 1);
  });

  testWidgets('hareket azaltıldığında beklemeden tamamlanır', (tester) async {
    var tamamlanmaSayisi = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: BrandSplashScreen(
            onCompleted: () {
              tamamlanmaSayisi++;
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tamamlanmaSayisi, 1);
  });
}
