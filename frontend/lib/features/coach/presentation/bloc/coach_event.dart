import 'package:equatable/equatable.dart';

abstract class CoachEvent extends Equatable {
  const CoachEvent();

  @override
  List<Object?> get props => [];
}

class InitChatEvent extends CoachEvent {
  final String welcomeMessage;

  const InitChatEvent(this.welcomeMessage);

  @override
  List<Object?> get props => [welcomeMessage];
}

class SendMessageEvent extends CoachEvent {
  final String text;
  final String? contextHint;

  const SendMessageEvent(this.text, {this.contextHint});

  @override
  List<Object?> get props => [text, contextHint];
}
