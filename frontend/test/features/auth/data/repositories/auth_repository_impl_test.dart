import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late AuthRepositoryImpl repository;
  late MockFlutterSecureStorage storage;

  setUp(() {
    storage = MockFlutterSecureStorage();
    repository = AuthRepositoryImpl(storage: storage);
  });

  test(
    'creates a privacy-first profile only in secure device storage',
    () async {
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      final profile = await repository.createProfile(
        displayName: 'Test User',
        age: 24,
        email: 'test@example.com',
        financialGoal: 'save',
      );

      expect(profile.userId, startsWith('device_'));
      expect(profile.displayName, 'Test User');
      expect(profile.age, 24);
      expect(repository.currentUser, profile);
      expect(repository.isLoggedIn, isTrue);
      verify(
        () => storage.write(
          key: 'maki_device_profile',
          value: any(named: 'value'),
        ),
      ).called(1);
    },
  );

  test('deletes only the local device profile', () async {
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
    await repository.createProfile(displayName: 'Test User', age: 24);

    await repository.deleteProfile();

    expect(repository.currentUser, isNull);
    expect(repository.isLoggedIn, isFalse);
    verify(() => storage.delete(key: 'maki_device_profile')).called(1);
  });

  test('reads an older profile without an age', () async {
    when(() => storage.read(key: 'maki_device_profile')).thenAnswer(
      (_) async =>
          '{"user_id":"device_old","email":"","display_name":"Eski Profil","financial_goal":null,"avatar_url":null}',
    );

    await repository.initialize();

    expect(repository.currentUser?.displayName, 'Eski Profil');
    expect(repository.currentUser?.age, isNull);
  });

  test('rejects an age outside the privacy profile range', () async {
    expect(
      () => repository.createProfile(displayName: 'Test User', age: 12),
      throwsA(isA<FormatException>()),
    );
  });
}
