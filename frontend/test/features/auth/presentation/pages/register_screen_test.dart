import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:maki_app/features/auth/presentation/pages/register_screen.dart';
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
        child: const RegisterScreen(),
      ),
    );
  }

  group('RegisterScreen UI Tests', () {
    testWidgets('renders register screen elements correctly', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(find.text('Kayıt Ol'), findsWidgets);
      expect(find.text('Ad Soyad'), findsOneWidget);
      expect(find.text('E-posta Adresi'), findsOneWidget);
      expect(find.text('Şifre'), findsOneWidget);
    });

    testWidgets('shows validation errors when fields are empty', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final registerButton = find.widgetWithText(ElevatedButton, 'Kayıt Ol');
      await tester.ensureVisible(registerButton);
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      expect(find.text('Ad Soyad'), findsWidgets);
      expect(find.text('E-posta Adresi'), findsWidgets);
      expect(find.text('Şifre'), findsWidgets);
      verifyNever(() => mockAuthBloc.add(any(that: isA<RegisterEvent>())));
    });

    testWidgets('adds RegisterEvent when fields are valid', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final nameField = find.byKey(const Key('register_name_field'));
      final emailField = find.byKey(const Key('register_email_field'));
      final passwordField = find.byKey(const Key('register_password_field'));

      await tester.enterText(nameField, 'Test User');
      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');
      await tester.pumpAndSettle();

      final registerButton = find.widgetWithText(ElevatedButton, 'Kayıt Ol');
      await tester.ensureVisible(registerButton);
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      verify(() => mockAuthBloc.add(
            const RegisterEvent(email: 'test@example.com', password: 'password123', displayName: 'Test User'),
          )).called(1);
    });
  });
}
