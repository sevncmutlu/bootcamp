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
  @override
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
    mockAuthBloc.emit(AuthState(status: AuthStatus.authenticated, user: user));
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr'), Locale('en')],
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
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.phonelink_lock_outlined), findsOneWidget);
      expect(find.byIcon(Icons.lock_outlined), findsNothing);
      expect(find.byIcon(Icons.person_remove_outlined), findsOneWidget);
    });

    testWidgets('shows delete device profile confirmation dialog', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -800));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byIcon(Icons.person_remove_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.person_remove_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}
