import 'package:maki_app/core/network/maki_api_client.dart';
import 'package:maki_app/features/coach/domain/entities/coach_message_entity.dart';
import 'package:maki_app/features/coach/domain/entities/coach_source_entity.dart';
import 'package:maki_app/features/coach/domain/repositories/coach_repository.dart';

class CoachRepositoryImpl implements CoachRepository {
  final MakiApiClient apiClient;

  CoachRepositoryImpl({required this.apiClient});

  @override
  Future<CoachMessageEntity> askCoach({
    required String question,
    required String sessionId,
  }) async {
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
  }
}
