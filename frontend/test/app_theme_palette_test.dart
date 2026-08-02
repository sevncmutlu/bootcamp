import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/core/theme/app_theme.dart';
import 'package:maki_app/core/theme/app_tokens.dart';
import 'package:maki_app/features/transactions/presentation/widgets/personalized_finance_overview.dart';
import 'package:maki_app/l10n/app_localizations.dart';

void main() {
  test('vurgu rengi koyu modun butun yuzey paletini degistirir', () {
    final forest = AppTheme.dark(BrandAccents.forest.color);
    final purple = AppTheme.dark(BrandAccents.purple.color);

    expect(purple.colorScheme.primary, isNot(forest.colorScheme.primary));
    expect(purple.colorScheme.surface, isNot(forest.colorScheme.surface));
    expect(
      purple.colorScheme.surfaceContainerLowest,
      isNot(forest.colorScheme.surfaceContainerLowest),
    );
    expect(
      purple.colorScheme.primaryContainer,
      isNot(forest.colorScheme.primaryContainer),
    );
    expect(purple.makiPalette.heroStart, isNot(forest.makiPalette.heroStart));
  });

  test('finansal anlam renkleri ayni parlaklikta temadan etkilenmez', () {
    final forest = AppTheme.light(BrandAccents.forest.color).makiPalette;
    final pink = AppTheme.light(BrandAccents.pink.color).makiPalette;

    expect(pink.income, forest.income);
    expect(pink.expense, forest.expense);
    expect(pink.warning, forest.warning);
    expect(pink.info, forest.info);
  });

  testWidgets('hedef karti hedef rengini degil secilen temayi kullanir', (
    tester,
  ) async {
    final theme = AppTheme.dark(BrandAccents.purple.color);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: theme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: PersonalizedFinanceOverview(
              primaryGoal: 'save_goal',
              expenses: const [],
              incomes: const [],
              selectedDate: DateTime(2026, 8, 1),
              today: DateTime(2026, 8, 1),
              onDateSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final card = tester.widget<Container>(
      find.byKey(const ValueKey('goal-dashboard-card')),
    );
    final decoration = card.decoration! as BoxDecoration;
    final gradient = decoration.gradient! as LinearGradient;

    expect(gradient.colors, theme.makiPalette.heroGradient.colors);
    expect(tester.takeException(), isNull);
  });
}
