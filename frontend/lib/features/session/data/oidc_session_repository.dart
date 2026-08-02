import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:maki_app/core/config/app_environment.dart';
import 'package:maki_app/core/errors/app_error_reporter.dart';
import 'package:maki_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:maki_app/features/session/domain/maki_session.dart';
import 'package:maki_app/features/session/domain/session_repository.dart';
import 'package:oidc/oidc.dart';
import 'package:oidc_default_store/oidc_default_store.dart';

final class OidcSessionRepository implements SessionRepository {
  OidcSessionRepository({
    required this.environment,
    required this.localAuth,
    required this.errorReporter,
    required this.secureStorage,
  });

  final AppEnvironment environment;
  final AuthLocalDataSource localAuth;
  final AppErrorReporter errorReporter;
  final FlutterSecureStorage secureStorage;
  final StreamController<MakiSession> _changes =
      StreamController<MakiSession>.broadcast(sync: true);

  MakiSession _current = const MakiSession.localOnly();
  OidcUserManager? _manager;
  StreamSubscription<OidcUser?>? _userSubscription;
  Future<void>? _initializeFuture;

  @override
  MakiSession get current => _current;

  @override
  Stream<MakiSession> watch() => _changes.stream;

  @override
  Future<void> initialize() => _initializeFuture ??= _initialize();

  Future<void> _initialize() async {
    if (!environment.hasOidc) {
      final developmentToken = await localAuth.getAccessToken();
      if (!environment.isProduction && developmentToken?.isNotEmpty == true) {
        _emit(
          const MakiSession(
            status: MakiSessionStatus.connected,
            displayName: 'Geliştirme oturumu',
            message: 'Yerel API erişimi açık.',
            isDevelopmentSession: true,
          ),
        );
      } else {
        _emit(const MakiSession.localOnly());
      }
      return;
    }

    try {
      final manager = _createManager();
      _manager = manager;
      await manager.init();
      _userSubscription = manager.userChanges().listen(
        _syncUser,
        onError: (Object error, StackTrace stackTrace) {
          unawaited(
            errorReporter.report(error, stackTrace, area: 'güvenli_oturum'),
          );
          _emit(
            const MakiSession(
              status: MakiSessionStatus.failure,
              message:
                  'Oturum yenilenemedi. Yerel kayıtlarını kullanabilirsin.',
            ),
          );
        },
      );
      _syncUser(manager.currentUser);
    } on Object catch (error, stackTrace) {
      await errorReporter.report(error, stackTrace, area: 'güvenli_oturum');
      _emit(
        const MakiSession(
          status: MakiSessionStatus.failure,
          message: 'Hesap bağlantısı kurulamadı. Yerel kayıtların güvende.',
        ),
      );
    }
  }

  OidcUserManager _createManager() {
    final issuer = environment.oidcIssuer!;
    final clientId = environment.oidcClientId!;
    final audience = environment.oidcAudience!;
    final redirectUri = environment.oidcRedirectUri!;
    final frontChannelLogoutUri = kIsWeb
        ? redirectUri.replace(
            queryParameters: {
              ...redirectUri.queryParameters,
              'requestType': 'front-channel-logout',
              'managerId': 'maki',
            },
          )
        : null;

    return OidcUserManager.lazy(
      id: 'maki',
      discoveryDocumentUri: OidcUtils.getOpenIdConfigWellKnownUri(issuer),
      clientCredentials: OidcClientAuthentication.none(clientId: clientId),
      store: OidcDefaultStore(secureStorageInstance: secureStorage),
      settings: OidcUserManagerSettings(
        redirectUri: redirectUri,
        postLogoutRedirectUri: redirectUri,
        frontChannelLogoutUri: frontChannelLogoutUri,
        scope: ['openid', 'profile', 'email', if (!kIsWeb) 'offline_access'],
        supportOfflineAuth: !kIsWeb,
        strictIssuerValidation: true,
        expectedIssuer: issuer,
        allowedIdTokenAlgorithms: const ['RS256', 'ES256', 'EdDSA'],
        allowedAudiences: [audience],
        extraAuthenticationParameters: {'audience': audience},
        uiLocales: const ['tr'],
      ),
    );
  }

  @override
  Future<void> connect() async {
    await initialize();
    final manager = _manager;
    if (manager == null) {
      _emit(
        const MakiSession(
          status: MakiSessionStatus.localOnly,
          message: 'Bu sürüm yerel kullanım için hazırlandı.',
        ),
      );
      return;
    }

    _emit(
      const MakiSession(
        status: MakiSessionStatus.connecting,
        message: 'Güvenli hesap bağlantısı açılıyor…',
      ),
    );
    try {
      final user = await manager.loginAuthorizationCodeFlow();
      _syncUser(user ?? manager.currentUser);
    } on Object catch (error, stackTrace) {
      await errorReporter.report(error, stackTrace, area: 'oturum_acma');
      _emit(
        const MakiSession(
          status: MakiSessionStatus.failure,
          message: 'Hesap bağlantısı tamamlanamadı. Yeniden deneyebilirsin.',
        ),
      );
    }
  }

  @override
  Future<void> disconnect() async {
    final manager = _manager;
    try {
      if (manager != null && manager.currentUser != null) {
        await manager.logout();
      }
    } on Object catch (error, stackTrace) {
      await errorReporter.report(error, stackTrace, area: 'oturum_kapatma');
      await manager?.forgetUser();
    } finally {
      await localAuth.clearSession();
      _emit(
        environment.hasOidc
            ? const MakiSession.signedOut()
            : const MakiSession.localOnly(),
      );
    }
  }

  @override
  Future<String?> getAccessToken() async {
    await initialize();
    final manager = _manager;
    if (manager != null) {
      try {
        return await manager.getAccessToken();
      } on Object catch (error, stackTrace) {
        await errorReporter.report(error, stackTrace, area: 'oturum_yenileme');
        return null;
      }
    }
    if (!environment.isProduction) return localAuth.getAccessToken();
    return null;
  }

  @override
  Future<void> dispose() async {
    await _userSubscription?.cancel();
    await _changes.close();
  }

  void _syncUser(OidcUser? user) {
    if (user == null) {
      _emit(const MakiSession.signedOut());
      return;
    }
    final claims = user.aggregatedClaims;
    _emit(
      MakiSession(
        status: MakiSessionStatus.connected,
        subject: _claim(claims, 'sub') ?? user.uid,
        displayName:
            _claim(claims, 'name') ?? _claim(claims, 'preferred_username'),
        email: _claim(claims, 'email'),
        message: 'Çevrim içi Maki özellikleri hazır.',
      ),
    );
  }

  void _emit(MakiSession session) {
    _current = session;
    if (!_changes.isClosed) _changes.add(session);
  }

  static String? _claim(Map<String, dynamic> claims, String key) {
    final value = claims[key];
    return value is String && value.trim().isNotEmpty ? value.trim() : null;
  }
}
