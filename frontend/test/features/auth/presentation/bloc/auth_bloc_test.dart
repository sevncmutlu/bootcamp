import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/features/auth/domain/entities/user_entity.dart';
import 'package:maki_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late AuthBloc authBloc;
  late MockAuthRepository repository;

  const profile = UserEntity(
    userId: 'device_123',
    email: '',
    displayName: 'Test User',
    age: 24,
  );

  setUp(() {
    repository = MockAuthRepository();
    authBloc = AuthBloc(repository: repository);
  });

  tearDown(() async {
    await authBloc.close();
  });

  test('starts empty', () {
    expect(authBloc.state, const AuthState());
  });

  test('creates a local device profile', () async {
    when(
      () => repository.createProfile(
        displayName: 'Test User',
        age: 24,
        email: '',
        financialGoal: null,
      ),
    ).thenAnswer((_) async => profile);

    expectLater(
      authBloc.stream,
      emitsInOrder([
        const AuthState(isLoading: true),
        const AuthState(
          status: AuthStatus.authenticated,
          user: profile,
          isSuccess: true,
        ),
      ]),
    );
    authBloc.add(const CreateProfileEvent(displayName: 'Test User', age: 24));
  });

  test('deletes the local profile', () async {
    when(() => repository.deleteProfile()).thenAnswer((_) async {});

    expectLater(
      authBloc.stream,
      emitsInOrder([
        const AuthState(isLoading: true),
        const AuthState(status: AuthStatus.unauthenticated),
      ]),
    );
    authBloc.add(DeleteProfileEvent());
  });
}
