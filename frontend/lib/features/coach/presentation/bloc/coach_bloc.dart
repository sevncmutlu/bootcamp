import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/core/network/maki_api_client.dart';
import 'package:maki_app/features/coach/domain/entities/coach_message_entity.dart';
import 'package:maki_app/features/coach/domain/repositories/coach_repository.dart';
import 'package:maki_app/features/coach/presentation/bloc/coach_event.dart';
import 'package:maki_app/features/coach/presentation/bloc/coach_state.dart';
import 'package:maki_app/core/utils/pii_scrubber.dart';
import 'dart:developer' as developer;

class CoachBloc extends Bloc<CoachEvent, CoachState> {
  final CoachRepository repository;

  CoachBloc({required this.repository}) : super(CoachState.initial(newSessionId())) {
    on<InitChatEvent>(_onInitChat);
    on<SendMessageEvent>(_onSendMessage);
  }

  void _onInitChat(InitChatEvent event, Emitter<CoachState> emit) {
    if (state.messages.isEmpty) {
      final welcomeMessage = CoachMessageEntity(
        text: event.welcomeMessage,
        isUser: false,
      );
      emit(state.copyWith(messages: [welcomeMessage]));
    }
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<CoachState> emit,
  ) async {
    final text = event.text.trim();
    if (text.isEmpty) return;

    final userMessage = CoachMessageEntity(text: text, isUser: true);
    emit(state.copyWith(
      messages: List.from(state.messages)..add(userMessage),
      isLoading: true,
      error: null, // Clear previous error
    ));

    try {
      final scrubbedText = PiiScrubber.scrub(text);
      final reply = await repository.askCoach(
        question: scrubbedText,
        sessionId: state.sessionId,
      );

      emit(state.copyWith(
        messages: List.from(state.messages)..add(reply),
        isLoading: false,
      ));
    } on MakiApiException catch (e, stackTrace) {
      developer.log(
        'Maki coach error',
        error: e.code,
        stackTrace: stackTrace,
        name: 'CoachBloc',
      );
      
      final errorMessage = CoachMessageEntity(
        text: e.userMessage,
        isUser: false,
        isError: true,
      );
      
      emit(state.copyWith(
        messages: List.from(state.messages)..add(errorMessage),
        isLoading: false,
      ));
    } catch (e, stackTrace) {
      developer.log(
        'Unexpected coach error',
        error: e,
        stackTrace: stackTrace,
        name: 'CoachBloc',
      );
      
      final errorMessage = const CoachMessageEntity(
        text: 'Beklenmeyen bir hata oluştu.',
        isUser: false,
        isError: true,
      );
      
      emit(state.copyWith(
        messages: List.from(state.messages)..add(errorMessage),
        isLoading: false,
      ));
    }
  }
}
