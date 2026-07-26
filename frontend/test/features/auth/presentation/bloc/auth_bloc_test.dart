import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:maki_app/features/auth/domain/entities/user_entity.dart';
import 'package:maki_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late AuthBloc authBloc;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    authBloc = AuthBloc(repository: mockRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    const tEmail = 'test@example.com';
    const tPassword = 'password123';
    
    final tUser = UserEntity(
      userId: '123',
      email: tEmail,
      displayName: 'Test User',
      avatarUrl: null,
      financialGoal: null,
    );

    test('initial state should be empty AuthState', () {
      expect(authBloc.state, const AuthState());
    });

    test('emits authenticated when login is successful', () async {
      when(() => mockRepository.login(email: tEmail, password: tPassword))
          .thenAnswer((_) async => tUser);

      final expectedStates = [
        const AuthState(isLoading: true),
        AuthState(
          status: AuthStatus.authenticated,
          user: tUser,
          isLoading: false,
        ),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));
      authBloc.add(const LoginEvent(email: tEmail, password: tPassword));
    });

    test('emits unauthenticated with error when login fails', () async {
      when(() => mockRepository.login(email: tEmail, password: tPassword))
          .thenThrow(Exception('Invalid credentials'));

      final expectedStates = [
        const AuthState(isLoading: true),
        const AuthState(
          status: AuthStatus.unauthenticated,
          isLoading: false,
          error: 'Invalid credentials',
        ),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));
      authBloc.add(const LoginEvent(email: tEmail, password: tPassword));
    });

    test('emits authenticated when register is successful', () async {
      when(() => mockRepository.register(email: tEmail, password: tPassword, displayName: 'Test User'))
          .thenAnswer((_) async => tUser);

      final expectedStates = [
        const AuthState(isLoading: true),
        AuthState(
          status: AuthStatus.authenticated,
          user: tUser,
          isLoading: false,
        ),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));
      authBloc.add(const RegisterEvent(email: tEmail, password: tPassword, displayName: 'Test User'));
    });

    test('emits unauthenticated when logout is called', () async {
      when(() => mockRepository.logout()).thenAnswer((_) async => {});

      final expectedStates = [
        const AuthState(isLoading: true),
        const AuthState(status: AuthStatus.unauthenticated),
      ];

      expectLater(authBloc.stream, emitsInOrder(expectedStates));
      authBloc.add(LogoutEvent());
    });
  });
}
