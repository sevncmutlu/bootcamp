import 'package:maki_app/features/coach/domain/entities/coach_message_entity.dart';

abstract class CoachRepository {
  Future<CoachMessageEntity> askCoach({
    required String question,
    required String sessionId,
  });
}
