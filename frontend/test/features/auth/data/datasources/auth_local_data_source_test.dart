import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage storage;

  setUp(() {
    storage = MockFlutterSecureStorage();
  });

  test('a compiled development token overrides a stale stored token', () async {
    final dataSource = AuthLocalDataSourceImpl(
      storage,
      developmentToken: ' fresh-development-token ',
    );

    final token = await dataSource.getAccessToken();

    expect(token, 'fresh-development-token');
    verifyNever(() => storage.read(key: any(named: 'key')));
  });

  test(
    'stored token remains available when no development token exists',
    () async {
      when(
        () => storage.read(key: 'maki_access_token'),
      ).thenAnswer((_) async => 'stored-oidc-token');
      final dataSource = AuthLocalDataSourceImpl(storage);

      final token = await dataSource.getAccessToken();

      expect(token, 'stored-oidc-token');
      verify(() => storage.read(key: 'maki_access_token')).called(1);
    },
  );
}
