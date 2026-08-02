import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/features/simulator/presentation/bloc/simulator_bloc.dart';
import 'package:maki_app/features/simulator/presentation/bloc/simulator_state.dart';
import 'package:maki_app/features/simulator/presentation/pages/debt_simulator_screen.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockSimulatorBloc extends Mock implements SimulatorBloc {}

void main() {
  late MockSimulatorBloc mockSimulatorBloc;

  setUpAll(() {
    registerFallbackValue(SimulatorState.initial());
  });

  setUp(() {
    mockSimulatorBloc = MockSimulatorBloc();
    when(
      () => mockSimulatorBloc.stream,
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockSimulatorBloc.close()).thenAnswer((_) async {});
  });

  Widget createWidgetUnderTest() {
    return BlocProvider<SimulatorBloc>.value(
      value: mockSimulatorBloc,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: DebtSimulatorScreen(initialDebts: [])),
      ),
    );
  }

  group('DebtSimulatorScreen UI Tests', () {
    testWidgets('renders initial UI correctly', (tester) async {
      when(() => mockSimulatorBloc.state).thenReturn(SimulatorState.initial());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byType(DebtSimulatorScreen), findsOneWidget);
    });
  });
}
