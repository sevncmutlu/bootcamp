import 'package:maki_app/features/coach/domain/entities/coach_source_entity.dart';

class CoachMessageEntity {
  final String text;
  final bool isUser;
  final bool isError;
  final List<CoachSourceEntity> sources;
  final String? assistantMode;

  const CoachMessageEntity({
    required this.text,
    required this.isUser,
    this.isError = false,
    this.sources = const <CoachSourceEntity>[],
    this.assistantMode,
  });
}
