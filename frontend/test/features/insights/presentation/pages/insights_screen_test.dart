import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/features/insights/presentation/bloc/forecast_bloc.dart';
import 'package:maki_app/features/insights/presentation/bloc/forecast_state.dart';
import 'package:maki_app/features/insights/presentation/bloc/inflation_bloc.dart';
import 'package:maki_app/features/insights/presentation/bloc/inflation_state.dart';
import 'package:maki_app/features/insights/domain/entities/inflation_data_entity.dart';
import 'package:maki_app/features/insights/presentation/pages/insights_screen.dart';
import 'package:maki_app/features/insights/presentation/pages/forecast_screen.dart';
import 'package:maki_app/features/insights/presentation/pages/inflation_screen.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:maki_app/features/premium/presentation/bloc/premium_bloc.dart';
import 'package:maki_app/features/premium/presentation/bloc/premium_state.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:maki_app/features/auth/domain/entities/user_entity.dart';
import 'package:maki_app/core/di/injection_container.dart';

class MockForecastBloc extends Mock implements ForecastBloc {}
class MockInflationBloc extends Mock implements InflationBloc {}
class MockPremiumBloc extends Mock implements PremiumBloc {}
class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockForecastBloc mockForecastBloc;
  late MockInflationBloc mockInflationBloc;
  late MockPremiumBloc mockPremiumBloc;
  late MockAuthBloc mockAuthBloc;

  setUpAll(() {
    registerFallbackValue(ForecastInitial());
    registerFallbackValue(InflationInitial());
    registerFallbackValue(const PremiumState(isPremium: false, isLoading: false));
    registerFallbackValue(const AuthState());
  });

  setUp(() async {
    await sl.reset();
    
    mockForecastBloc = MockForecastBloc();
    when(() => mockForecastBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockForecastBloc.close()).thenAnswer((_) async {});
    
    mockInflationBloc = MockInflationBloc();
    when(() => mockInflationBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockInflationBloc.close()).thenAnswer((_) async {});
    
    mockPremiumBloc = MockPremiumBloc();
    when(() => mockPremiumBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockPremiumBloc.close()).thenAnswer((_) async {});
    
    mockAuthBloc = MockAuthBloc();
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockAuthBloc.close()).thenAnswer((_) async {});
    
    sl.registerFactory<ForecastBloc>(() => mockForecastBloc);
    sl.registerFactory<InflationBloc>(() => mockInflationBloc);
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ForecastBloc>.value(value: mockForecastBloc),
        BlocProvider<InflationBloc>.value(value: mockInflationBloc),
        BlocProvider<PremiumBloc>.value(value: mockPremiumBloc),
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: InsightsScreen(),
        ),
      ),
    );
  }

  group('InsightsScreen UI Tests', () {
    testWidgets('renders tabs correctly', (tester) async {
      when(() => mockForecastBloc.state).thenReturn(const ForecastLoaded([]));
      when(() => mockInflationBloc.state).thenReturn(const InflationLoaded(
        InflationDataEntity(
          hasPriceBasket: false,
          personalInflation: null,
          officialInflation: null,
          breakdowns: [],
        ),
      ));
      when(() => mockPremiumBloc.state).thenReturn(const PremiumState(isPremium: true, isLoading: false));
      when(() => mockAuthBloc.state).thenReturn(const AuthState(
        status: AuthStatus.authenticated,
        user: UserEntity(userId: '1', email: 'test@test.com', displayName: 'Test'),
      ));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(InsightsScreen), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(ForecastScreen), findsOneWidget);
      expect(find.byType(InflationScreen), findsNothing); // Offscreen/other tab
    });
  });
}
