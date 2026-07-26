import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:maki_app/features/profile/presentation/pages/profile_screen.dart';
import 'package:maki_app/features/auth/domain/entities/user_entity.dart';
import 'dart:async';

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

void main() {
  late MockAuthBloc mockAuthBloc;

  setUpAll(() {
    registerFallbackValue(FakeAuthEvent());
  });

  setUp(() {
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
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const ProfileScreen(),
      ),
    );
  }

  group('ProfileScreen UI Tests', () {
    testWidgets('renders profile screen elements correctly', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Test User'), findsNWidgets(2));
      expect(find.text('test@test.com'), findsNWidgets(2));
      
      // Check for logout and delete buttons by Icon or something standard since text depends on locale
      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
      expect(find.byIcon(Icons.delete_forever_rounded), findsOneWidget);
    });

    testWidgets('shows logout confirmation dialog', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byIcon(Icons.logout_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.logout_rounded));
      await tester.pumpAndSettle();

      // Check if dialog is shown by looking for a button
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('shows delete account confirmation dialog', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byIcon(Icons.delete_forever_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_forever_rounded));
      await tester.pumpAndSettle();

      // Check if dialog is shown
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}
