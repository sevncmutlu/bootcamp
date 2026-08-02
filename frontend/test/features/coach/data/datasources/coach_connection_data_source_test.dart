import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/features/coach/data/datasources/coach_connection_data_source.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockSecureStorage storage;
  late CoachConnectionDataSourceImpl dataSource;

  setUp(() {
    storage = MockSecureStorage();
    dataSource = CoachConnectionDataSourceImpl(storage);
  });

  test('Gemini anahtarını kırpmış biçimde güvenli alana kaydeder', () async {
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});

    await dataSource.saveGeminiApiKey('  ${'g' * 32}  ');

    verify(
      () => storage.write(key: 'maki_gemini_api_key', value: 'g' * 32),
    ).called(1);
  });

  test('kısa anahtarı kaydetmez', () async {
    expect(
      () => dataSource.saveGeminiApiKey('kisa'),
      throwsA(isA<FormatException>()),
    );
    verifyNever(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    );
  });
}
