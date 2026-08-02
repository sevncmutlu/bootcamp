import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/features/coach/domain/entities/coach_message_entity.dart';
import 'package:maki_app/features/coach/domain/repositories/coach_repository.dart';
import 'package:maki_app/features/coach/presentation/bloc/coach_bloc.dart';
import 'package:maki_app/features/coach/presentation/bloc/coach_event.dart';
import 'package:maki_app/features/coach/presentation/bloc/coach_state.dart';
import 'package:mocktail/mocktail.dart';

class MockCoachRepository extends Mock implements CoachRepository {}

void main() {
  late MockCoachRepository mockRepository;
  late CoachBloc bloc;

  setUp(() {
    mockRepository = MockCoachRepository();
    bloc = CoachBloc(repository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('CoachBloc', () {
    test('initial state is correct', () {
      expect(bloc.state.isLoading, false);
      expect(bloc.state.messages, isEmpty);
      expect(bloc.state.sessionId, isNotEmpty);
    });

    test('emits expected states when SendMessageEvent is successful', () async {
      const responseMessage = CoachMessageEntity(
        text: 'Reply',
        isUser: false,
        sources: [],
      );

      when(
        () => mockRepository.askCoach(
          question: any(named: 'question'),
          sessionId: any(named: 'sessionId'),
        ),
      ).thenAnswer((_) async => responseMessage);

      final expectedStates = [
        isA<CoachState>().having((s) => s.isLoading, 'isLoading', true),
        isA<CoachState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.messages.length, 'messages length', 2),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(const SendMessageEvent('Hello'));
    });

    test('emits error state when SendMessageEvent fails', () async {
      when(
        () => mockRepository.askCoach(
          question: any(named: 'question'),
          sessionId: any(named: 'sessionId'),
        ),
      ).thenThrow(Exception('Failed'));

      final expectedStates = [
        isA<CoachState>().having((s) => s.isLoading, 'isLoading', true),
        isA<CoachState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.messages.last.isError, 'isError', true)
            .having(
              (s) => s.messages.last.text,
              'text',
              'Beklenmeyen bir hata oluştu.',
            ),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(const SendMessageEvent('Hello'));
    });
  });
}
