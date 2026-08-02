import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/features/gamification/presentation/bloc/gamification_bloc.dart';
import 'package:maki_app/features/gamification/presentation/bloc/gamification_state.dart';
import 'package:maki_app/features/gamification/presentation/pages/leaderboard_screen.dart';
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: LeaderboardScreen(userLevel: 1)),
      ),
    );
  }

  group('LeaderboardScreen UI Tests', () {
    testWidgets('renders initial UI correctly', (tester) async {
      when(
        () => mockGamificationBloc.state,
      ).thenReturn(GamificationState.initial());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(LeaderboardScreen), findsOneWidget);
    });
  });
}
