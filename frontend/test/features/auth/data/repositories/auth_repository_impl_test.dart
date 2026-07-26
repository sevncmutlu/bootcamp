import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:maki_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:maki_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:maki_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:maki_app/features/auth/domain/entities/user_entity.dart';

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}
class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthLocalDataSource mockLocalDataSource;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockFlutterSecureStorage mockSecureStorage;

  setUp(() {
    mockLocalDataSource = MockAuthLocalDataSource();
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockSecureStorage = MockFlutterSecureStorage();

    repository = AuthRepositoryImpl(
      localDataSource: mockLocalDataSource,
      remoteDataSource: mockRemoteDataSource,
      storage: mockSecureStorage,
    );
  });

  group('AuthRepositoryImpl', () {
    const tEmail = 'test@example.com';
    const tPassword = 'password123';
    
    final tUser = UserEntity(
      userId: '123',
      email: tEmail,
      displayName: 'Test User',
      avatarUrl: null,
      financialGoal: null,
    );
    
    final tAuthResponse = AuthResponseModel(
      user: tUser,
      accessToken: 'dummy_token',
    );

    test('login authenticates user and caches data', () async {
      when(() => mockRemoteDataSource.login(tEmail, tPassword))
          .thenAnswer((_) async => tAuthResponse);
      when(() => mockLocalDataSource.saveAccessToken(any()))
          .thenAnswer((_) async => {});
      when(() => mockSecureStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async => {});

      final result = await repository.login(email: tEmail, password: tPassword);

      expect(result, equals(tUser));
      expect(repository.currentUser, equals(tUser));
      expect(repository.accessToken, equals('dummy_token'));
      expect(repository.isLoggedIn, isTrue);

      verify(() => mockRemoteDataSource.login(tEmail, tPassword)).called(1);
      verify(() => mockLocalDataSource.saveAccessToken('dummy_token')).called(1);
      verify(() => mockSecureStorage.write(
          key: 'maki_auth_user', value: any(named: 'value'))).called(1);
    });

    test('logout clears user data', () async {
      when(() => mockLocalDataSource.clearSession()).thenAnswer((_) async => {});
      when(() => mockSecureStorage.delete(key: any(named: 'key'))).thenAnswer((_) async => {});

      await repository.logout();

      expect(repository.currentUser, isNull);
      expect(repository.accessToken, isNull);
      expect(repository.isLoggedIn, isFalse);

      verify(() => mockLocalDataSource.clearSession()).called(1);
      verify(() => mockSecureStorage.delete(key: 'maki_auth_user')).called(1);
    });
  });
}
