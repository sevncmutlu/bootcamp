import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:maki_app/features/auth/data/datasources/auth_remote_data_source.dart';

class MockHttpClient extends Mock implements http.Client {}

class FakeUri extends Fake implements Uri {}

void main() {
  late AuthRemoteDataSourceImpl dataSource;
  late MockHttpClient mockHttpClient;

  setUpAll(() {
    registerFallbackValue(FakeUri());
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
    dataSource = AuthRemoteDataSourceImpl(mockHttpClient);
  });

  group('AuthRemoteDataSourceImpl', () {
    const tEmail = 'test@example.com';
    const tPassword = 'password123';
    
    final tUserJson = {
      'user_id': '123',
      'email': tEmail,
      'display_name': 'Test User',
    };

    test('login returns AuthResponseModel on success 200', () async {
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'user_id': '123',
              'email': tEmail,
              'display_name': 'Test User',
              'access_token': 'dummy_token'
            }), 200));

      final result = await dataSource.login(tEmail, tPassword);
      
      expect(result.accessToken, 'dummy_token');
      expect(result.user.userId, '123');
      expect(result.user.email, tEmail);
    });

    test('login throws Exception on failure', () async {
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('Error', 400));

      expect(() => dataSource.login(tEmail, tPassword), throwsException);
    });

    test('register returns AuthResponseModel on success 201', () async {
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'user_id': '123',
              'email': tEmail,
              'display_name': 'Test User',
              'access_token': 'dummy_token'
            }), 201));

      final result = await dataSource.register(tEmail, tPassword, 'Test User');
      
      expect(result.accessToken, 'dummy_token');
      expect(result.user.userId, '123');
    });

    test('getUserProfile returns UserEntity on 200', () async {
      when(() => mockHttpClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(jsonEncode(tUserJson), 200));

      final result = await dataSource.getUserProfile('token');
      
      expect(result.userId, '123');
    });
  });
}
