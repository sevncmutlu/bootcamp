import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/core/network/maki_api_client.dart';
import 'package:maki_app/features/coach/data/datasources/coach_connection_data_source.dart';
import 'package:maki_app/features/coach/data/datasources/local_coach_engine.dart';
import 'package:maki_app/features/coach/data/repositories/coach_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockMakiApiClient extends Mock implements MakiApiClient {}

class MockCoachConnectionDataSource extends Mock
    implements CoachConnectionDataSource {}

void main() {
  late MockMakiApiClient mockApiClient;
  late MockCoachConnectionDataSource mockConnectionDataSource;
  late CoachRepositoryImpl repository;

  setUp(() {
    mockApiClient = MockMakiApiClient();
    mockConnectionDataSource = MockCoachConnectionDataSource();
    repository = CoachRepositoryImpl(
      apiClient: mockApiClient,
      connectionDataSource: mockConnectionDataSource,
      localCoach: LocalCoachEngine(),
    );
  });

  group('CoachRepositoryImpl', () {
    test('askCoach returns CoachMessageEntity', () async {
      const question = 'Test question';
      const sessionId = 'session123';
      final reply = CoachReply(
        answer: 'Test answer',
        mode: 'answered',
        sources: [
          CoachSource(
            institution: 'Inst',
            seriesId: 'ID',
            period: '2023',
            value: '100',
            unit: 'USD',
            sourceUrl: Uri.parse('http://example.com'),
          ),
        ],
      );

      when(
        () => mockConnectionDataSource.hasGeminiApiKey(),
      ).thenAnswer((_) async => true);

      when(
        () => mockApiClient.askCoach(
          question: any(named: 'question'),
          sessionId: any(named: 'sessionId'),
        ),
      ).thenAnswer((_) async => reply);

      final result = await repository.askCoach(
        question: question,
        sessionId: sessionId,
      );

      expect(result.text, 'Test answer');
      expect(result.isUser, false);
      expect(result.sources, isNotEmpty);
      expect(result.sources.first.institution, 'Inst');

      verify(
        () => mockApiClient.askCoach(question: question, sessionId: sessionId),
      ).called(1);
    });

    test('Gemini anahtarı yokken cihaz içi rehber yanıt verir', () async {
      when(
        () => mockConnectionDataSource.hasGeminiApiKey(),
      ).thenAnswer((_) async => false);

      final result = await repository.askCoach(
        question: 'Borçlarım için bir ödeme planı oluşturalım.',
        sessionId: 'local-session',
      );

      expect(result.text, contains('Borçlarının kalan tutarını'));
      expect(result.assistantMode, 'local_guidance');
      expect(result.isError, isFalse);
      verifyNever(
        () => mockApiClient.askCoach(
          question: any(named: 'question'),
          sessionId: any(named: 'sessionId'),
        ),
      );
    });

    test('çevrimiçi koç hatasında cihaz içi rehbere düşer', () async {
      when(
        () => mockConnectionDataSource.hasGeminiApiKey(),
      ).thenAnswer((_) async => true);
      when(
        () => mockApiClient.askCoach(
          question: any(named: 'question'),
          sessionId: any(named: 'sessionId'),
        ),
      ).thenThrow(
        const MakiApiException('OTURUM_GEREKLI', 'Oturum doğrulanamadı.'),
      );

      final result = await repository.askCoach(
        question: 'Bütçemi toparlamak istiyorum.',
        sessionId: 'fallback-session',
      );

      expect(result.text, contains('Son dört haftayı'));
      expect(result.assistantMode, 'local_guidance');
      expect(result.isError, isFalse);
    });

    test('anahtar deposu okunamazsa cihaz içi rehber çalışır', () async {
      when(
        () => mockConnectionDataSource.hasGeminiApiKey(),
      ).thenThrow(Exception('secure storage unavailable'));

      final result = await repository.askCoach(
        question: 'Selam Maki',
        sessionId: 'storage-fallback-session',
      );

      expect(result.text, contains('Merhaba'));
      expect(result.assistantMode, 'local_guidance');
      verifyNever(
        () => mockApiClient.askCoach(
          question: any(named: 'question'),
          sessionId: any(named: 'sessionId'),
        ),
      );
    });
  });
}
