enum MakiSessionStatus { localOnly, signedOut, connecting, connected, failure }

final class MakiSession {
  const MakiSession({
    required this.status,
    this.subject,
    this.displayName,
    this.email,
    this.message,
    this.isDevelopmentSession = false,
  });

  const MakiSession.localOnly()
    : this(
        status: MakiSessionStatus.localOnly,
        message: 'Verilerin bu cihazda kalıyor.',
      );

  const MakiSession.signedOut()
    : this(
        status: MakiSessionStatus.signedOut,
        message: 'Çevrim içi özellikler için hesabını bağlayabilirsin.',
      );

  final MakiSessionStatus status;
  final String? subject;
  final String? displayName;
  final String? email;
  final String? message;
  final bool isDevelopmentSession;

  bool get isAuthenticated => status == MakiSessionStatus.connected;
  bool get isBusy => status == MakiSessionStatus.connecting;
}
