import 'package:maki_app/features/session/domain/maki_session.dart';

abstract interface class SessionRepository {
  MakiSession get current;
  Stream<MakiSession> watch();

  Future<void> initialize();
  Future<void> connect();
  Future<void> disconnect();
  Future<String?> getAccessToken();
  Future<void> dispose();
}
