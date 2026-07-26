import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/features/coach/presentation/bloc/coach_bloc.dart';
import 'package:maki_app/features/coach/presentation/bloc/coach_state.dart';
import 'package:maki_app/features/coach/presentation/pages/chat_screen.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockCoachBloc extends Mock implements CoachBloc {}

void main() {
  late MockCoachBloc mockCoachBloc;

  setUpAll(() {
    registerFallbackValue(CoachState.initial('mock_session_id'));
  });

  setUp(() {
    mockCoachBloc = MockCoachBloc();
    when(() => mockCoachBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockCoachBloc.close()).thenAnswer((_) async {});
  });

  Widget createWidgetUnderTest() {
    return BlocProvider<CoachBloc>.value(
      value: mockCoachBloc,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ChatScreen()),
      ),
    );
  }

  group('ChatScreen UI Tests', () {
    testWidgets('renders initial UI correctly', (tester) async {
      when(() => mockCoachBloc.state).thenReturn(CoachState.initial('mock_session_id'));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(ChatScreen), findsOneWidget);
    });
  });
}
