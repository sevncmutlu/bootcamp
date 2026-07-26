import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:maki_app/features/auth/presentation/pages/login_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'dart:async';

class FakeAuthEvent extends Fake implements AuthEvent {}

class MockAuthBloc extends Mock implements AuthBloc {
  final StreamController<AuthState> _controller = StreamController<AuthState>.broadcast();

  @override
  Stream<AuthState> get stream => _controller.stream;

  @override
  AuthState get state => const AuthState();

  @override
  Future<void> close() async {
    await _controller.close();
  }
}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUpAll(() {
    registerFallbackValue(FakeAuthEvent());
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
  });

  tearDown(() {
    mockAuthBloc.close();
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
        Locale('en'),
        Locale('tr'),
      ],
      locale: const Locale('tr'),
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const LoginScreen(),
      ),
    );
  }

  group('LoginScreen UI Tests', () {
    testWidgets('renders login screen elements correctly', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Giriş Yap'), findsWidgets);
      expect(find.text('E-posta Adresi'), findsOneWidget);
      expect(find.text('Şifre'), findsOneWidget);
    });

    testWidgets('shows validation errors when fields are empty', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final loginButton = find.widgetWithText(ElevatedButton, 'Giriş Yap');
      await tester.ensureVisible(loginButton);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      expect(find.text('E-posta Adresi'), findsWidgets);
      expect(find.text('Şifre'), findsWidgets);
      verifyNever(() => mockAuthBloc.add(any(that: isA<LoginEvent>())));
    });

    testWidgets('adds LoginEvent when fields are valid', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final emailField = find.byKey(const Key('login_email_field'));
      final passwordField = find.byKey(const Key('login_password_field'));

      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');
      await tester.pumpAndSettle();

      final loginButton = find.widgetWithText(ElevatedButton, 'Giriş Yap');
      await tester.ensureVisible(loginButton);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      verify(() => mockAuthBloc.add(
            const LoginEvent(email: 'test@example.com', password: 'password123'),
          )).called(1);
    });
  });
}
