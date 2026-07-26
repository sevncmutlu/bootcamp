import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/core/network/maki_api_client.dart';
import 'package:maki_app/features/coach/data/repositories/coach_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockMakiApiClient extends Mock implements MakiApiClient {}

void main() {
  late MockMakiApiClient mockApiClient;
  late CoachRepositoryImpl repository;

  setUp(() {
    mockApiClient = MockMakiApiClient();
    repository = CoachRepositoryImpl(apiClient: mockApiClient);
  });

  group('CoachRepositoryImpl', () {
    test('askCoach returns CoachMessageEntity', () async {
      const question = 'Test question';
      const sessionId = 'session123';
      final reply = CoachReply(
        answer: 'Test answer',
        sources: [
          CoachSource(
            institution: 'Inst',
            seriesId: 'ID',
            period: '2023',
            value: '100',
            unit: 'USD',
            sourceUrl: Uri.parse('http://example.com'),
          )
        ],
      );

      when(() => mockApiClient.askCoach(
            question: any(named: 'question'),
            sessionId: any(named: 'sessionId'),
          )).thenAnswer((_) async => reply);

      final result = await repository.askCoach(question: question, sessionId: sessionId);

      expect(result.text, 'Test answer');
      expect(result.isUser, false);
      expect(result.sources, isNotEmpty);
      expect(result.sources.first.institution, 'Inst');
      
      verify(() => mockApiClient.askCoach(question: question, sessionId: sessionId)).called(1);
    });
  });
}
