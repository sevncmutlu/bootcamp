import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/features/premium/presentation/bloc/premium_bloc.dart';
import 'package:maki_app/features/premium/presentation/bloc/premium_state.dart';
import 'package:maki_app/features/premium/presentation/pages/paywall_screen.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockPremiumBloc extends Mock implements PremiumBloc {}

void main() {
  late MockPremiumBloc mockPremiumBloc;

  setUpAll(() {
    registerFallbackValue(const PremiumState(isLoading: false, isPremium: false));
  });

  setUp(() {
    mockPremiumBloc = MockPremiumBloc();
    when(() => mockPremiumBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockPremiumBloc.close()).thenAnswer((_) async {});
  });

  Widget createWidgetUnderTest() {
    return BlocProvider<PremiumBloc>.value(
      value: mockPremiumBloc,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PaywallScreen(),
      ),
    );
  }

  group('PaywallScreen UI Tests', () {
    testWidgets('renders initial UI correctly', (tester) async {
      when(() => mockPremiumBloc.state).thenReturn(const PremiumState(isLoading: false, isPremium: false));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(PaywallScreen), findsOneWidget);
    });
  });
}
