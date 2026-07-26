import 'package:equatable/equatable.dart';
import 'package:maki_app/features/coach/domain/entities/coach_message_entity.dart';

class CoachState extends Equatable {
  final List<CoachMessageEntity> messages;
  final bool isLoading;
  final String sessionId;
  final String? error;

  const CoachState({
    required this.messages,
    required this.isLoading,
    required this.sessionId,
    this.error,
  });

  factory CoachState.initial(String sessionId) {
    return CoachState(
      messages: const [],
      isLoading: false,
      sessionId: sessionId,
    );
  }

  CoachState copyWith({
    List<CoachMessageEntity>? messages,
    bool? isLoading,
    String? sessionId,
    String? error,
  }) {
    return CoachState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      sessionId: sessionId ?? this.sessionId,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [messages, isLoading, sessionId, error];
}
