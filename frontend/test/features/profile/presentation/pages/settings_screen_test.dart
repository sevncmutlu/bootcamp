import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/features/profile/presentation/bloc/settings_bloc.dart';
import 'package:maki_app/features/profile/presentation/bloc/settings_event.dart';
import 'package:maki_app/features/profile/presentation/bloc/settings_state.dart';
import 'package:maki_app/features/profile/presentation/pages/settings_screen.dart';
import 'package:maki_app/features/profile/domain/entities/settings_entity.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:maki_app/features/auth/domain/entities/user_entity.dart';
import 'dart:async';

class FakeSettingsEvent extends Fake implements SettingsEvent {}
class FakeAuthEvent extends Fake implements AuthEvent {}

class MockAuthBloc extends Mock implements AuthBloc {
  final _controller = StreamController<AuthState>.broadcast();

  @override
  Stream<AuthState> get stream => _controller.stream;

  @override
  AuthState get state => _state;
  AuthState _state = const AuthState();

  void emit(AuthState state) {
    _state = state;
    _controller.add(state);
  }

  @override
  Future<void> close() async {
    await _controller.close();
  }
}

class MockSettingsBloc extends Mock implements SettingsBloc {
  final _controller = StreamController<SettingsState>.broadcast();

  @override
  Stream<SettingsState> get stream => _controller.stream;

  @override
  SettingsState get state => _state;

  SettingsState _state = SettingsState.initial();

  void emit(SettingsState state) {
    _state = state;
    _controller.add(state);
  }

  @override
  Future<void> close() async {
    await _controller.close();
  }
}

void main() {
  late MockSettingsBloc mockSettingsBloc;
  late MockAuthBloc mockAuthBloc;

  setUpAll(() {
    registerFallbackValue(FakeSettingsEvent());
    registerFallbackValue(FakeAuthEvent());
  });

  setUp(() {
    mockSettingsBloc = MockSettingsBloc();
    mockAuthBloc = MockAuthBloc();

    final user = const UserEntity(
      userId: '123',
      email: 'test@test.com',
      displayName: 'Test User',
      avatarUrl: null,
      financialGoal: 'track_spending',
    );
    mockAuthBloc.emit(AuthState(
      status: AuthStatus.authenticated,
      user: user,
    ));

    final settings = SettingsEntity(
      primaryGoal: 'track_spending',
      isPremium: false,
      themeMode: 'system',
      accentColor: 'green',
      language: 'tr',
    );
    mockSettingsBloc.emit(SettingsState(isLoading: false, settings: settings));
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr'),
        Locale('en'),
      ],
      home: MultiBlocProvider(
        providers: [
          BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        ],
        child: const SettingsScreen(),
      ),
    );
  }

  group('SettingsScreen UI Tests', () {
    testWidgets('renders settings screen elements correctly', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Check for theme, language and premium settings by Icon
      // In SettingsScreen it uses Icons.dark_mode_outlined for Theme, Icons.language_outlined for language, Icons.star_outline_rounded for premium
      expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget); // Theme
      expect(find.byIcon(Icons.language_outlined), findsOneWidget); // Language
      expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget); // Premium
    });

    testWidgets('shows theme selection dialog', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byIcon(Icons.dark_mode_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.dark_mode_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('shows language selection dialog', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byIcon(Icons.language_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.language_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}
