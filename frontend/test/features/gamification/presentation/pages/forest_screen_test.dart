import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/features/gamification/presentation/bloc/gamification_bloc.dart';
import 'package:maki_app/features/gamification/presentation/bloc/gamification_state.dart';
import 'package:maki_app/features/gamification/presentation/pages/forest_screen.dart';
import 'package:maki_app/features/gamification/domain/entities/gamification_status_entity.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockGamificationBloc extends Mock implements GamificationBloc {}

void main() {
  late MockGamificationBloc mockGamificationBloc;

  setUpAll(() {
    registerFallbackValue(GamificationState.initial());
  });

  setUp(() {
    mockGamificationBloc = MockGamificationBloc();
    when(
      () => mockGamificationBloc.stream,
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockGamificationBloc.close()).thenAnswer((_) async {});
  });

  Widget createWidgetUnderTest() {
    return BlocProvider<GamificationBloc>.value(
      value: mockGamificationBloc,
      child: const MaterialApp(
        locale: Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ForestScreen()),
      ),
    );
  }

  group('ForestScreen UI Tests', () {
    testWidgets('renders initial UI correctly', (tester) async {
      when(
        () => mockGamificationBloc.state,
      ).thenReturn(GamificationState.initial());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byType(ForestScreen), findsOneWidget);
      expect(find.byType(TabBar), findsNothing);
      expect(find.text('Tasarruf Liderlik Tablosu'), findsNothing);
    });

    testWidgets('geri dugmesi ana finans ekranina doner', (tester) async {
      when(
        () => mockGamificationBloc.state,
      ).thenReturn(GamificationState.initial());

      await tester.pumpWidget(
        BlocProvider<GamificationBloc>.value(
          value: mockGamificationBloc,
          child: MaterialApp(
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: FilledButton(
                  key: const ValueKey('open-forest'),
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const ForestScreen(),
                    ),
                  ),
                  child: const Text('Ormani ac'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('open-forest')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(ForestScreen), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('forest-back-button')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(ForestScreen), findsNothing);
      expect(find.byKey(const ValueKey('open-forest')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ustteki puanli magaza kisayolu magazayi acar', (tester) async {
      when(() => mockGamificationBloc.state).thenReturn(
        GamificationState.initial().copyWith(
          isLoading: false,
          status: const GamificationStatusEntity(xp: 0, level: 1),
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(
        find.byKey(const ValueKey('forest-store-shortcut')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('forest-points-balance')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('forest-store-shortcut')));
      await tester.pumpAndSettle();

      expect(find.text('Orman mağazası'), findsOneWidget);
      expect(find.textContaining('tohumlarla'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('flora kartindan secili orman bolgesine girilir', (
      tester,
    ) async {
      when(() => mockGamificationBloc.state).thenReturn(
        GamificationState.initial().copyWith(
          isLoading: false,
          status: const GamificationStatusEntity(xp: 20, level: 1),
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      final district = find.byKey(
        const ValueKey('forest-district-track_spending'),
      );
      await tester.ensureVisible(district);
      await tester.tap(district);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('forest-district-screen-track_spending')),
        findsOneWidget,
      );
      expect(find.textContaining('Maki’yi nasıl değiştirir'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final size in [const Size(390, 844), const Size(844, 390)]) {
      testWidgets('yaşayan orman $size boyutunda taşmaz', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        when(() => mockGamificationBloc.state).thenReturn(
          GamificationState.initial().copyWith(
            isLoading: false,
            status: const GamificationStatusEntity(xp: 140, level: 3),
            savingsScoreBasisPoints: 4200,
            hasWeeklyIncome: true,
          ),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        expect(find.byType(ForestScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
