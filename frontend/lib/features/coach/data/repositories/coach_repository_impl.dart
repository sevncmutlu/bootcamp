import 'package:maki_app/core/network/maki_api_client.dart';
import 'package:maki_app/features/coach/data/datasources/coach_connection_data_source.dart';
import 'package:maki_app/features/coach/data/datasources/local_coach_engine.dart';
import 'package:maki_app/features/coach/domain/entities/coach_message_entity.dart';
import 'package:maki_app/features/coach/domain/entities/coach_source_entity.dart';
import 'package:maki_app/features/coach/domain/repositories/coach_repository.dart';

class CoachRepositoryImpl implements CoachRepository {
  final MakiApiClient apiClient;
  final CoachConnectionDataSource connectionDataSource;
  final LocalCoachEngine localCoach;

  CoachRepositoryImpl({
    required this.apiClient,
    required this.connectionDataSource,
    required this.localCoach,
  });

  @override
  Future<CoachMessageEntity> askCoach({
    required String question,
    required String sessionId,
  }) async {
    final hasGeminiKey = await _hasGeminiKey();
    if (!hasGeminiKey) {
      return _localReply(question: question, sessionId: sessionId);
    }

    try {
      final reply = await apiClient.askCoach(
        question: question,
        sessionId: sessionId,
      );

      return CoachMessageEntity(
        text: reply.answer,
        isUser: false,
        assistantMode: reply.mode,
        sources: reply.sources
            .map(
              (s) => CoachSourceEntity(
                institution: s.institution,
                seriesId: s.seriesId,
                period: s.period,
                value: s.value,
                unit: s.unit,
                sourceUrl: s.sourceUrl,
              ),
            )
            .toList(),
      );
    } on MakiApiException {
      return _localReply(question: question, sessionId: sessionId);
    }
  }

  CoachMessageEntity _localReply({
    required String question,
    required String sessionId,
  }) => CoachMessageEntity(
    text: localCoach.respond(question: question, sessionId: sessionId),
    isUser: false,
    assistantMode: 'local_guidance',
  );

  Future<bool> _hasGeminiKey() async {
    try {
      return await connectionDataSource.hasGeminiApiKey();
    } on Exception {
      return false;
    }
  }
}
