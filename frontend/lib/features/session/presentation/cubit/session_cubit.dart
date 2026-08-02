import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/features/session/domain/maki_session.dart';
import 'package:maki_app/features/session/domain/session_repository.dart';

final class SessionCubit extends Cubit<MakiSession> {
  SessionCubit(this._repository) : super(_repository.current) {
    _subscription = _repository.watch().listen(emit);
  }

  final SessionRepository _repository;
  late final StreamSubscription<MakiSession> _subscription;

  Future<void> initialize() => _repository.initialize();
  Future<void> connect() => _repository.connect();
  Future<void> disconnect() => _repository.disconnect();

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
