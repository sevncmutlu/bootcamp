import 'package:flutter/foundation.dart';

enum MakiStage { development, staging, preview, production }

final class AppEnvironment {
  AppEnvironment({
    required this.stage,
    required this.backendUri,
    this.oidcIssuer,
    this.oidcClientId,
    this.oidcAudience,
    this.oidcRedirectUri,
    this.billingProductId,
    this.storeBillingEnabled = false,
    this.privacyUri,
    this.termsUri,
    this.sentryDsn,
    this.webDemoMode = false,
  }) {
    _validate();
  }

  factory AppEnvironment.fromEnvironment() {
    const rawStage = String.fromEnvironment('MAKI_ENV');
    const rawBackendUrl = String.fromEnvironment('BACKEND_URL');
    const rawIssuer = String.fromEnvironment('OIDC_ISSUER');
    const rawClientId = String.fromEnvironment('OIDC_CLIENT_ID');
    const rawAudience = String.fromEnvironment('OIDC_AUDIENCE');
    const rawRedirectUri = String.fromEnvironment('OIDC_REDIRECT_URI');
    const rawBillingProductId = String.fromEnvironment('BILLING_PRODUCT_ID');
    const rawStoreBilling = String.fromEnvironment('ENABLE_STORE_BILLING');
    const rawPrivacyUrl = String.fromEnvironment('PRIVACY_URL');
    const rawTermsUrl = String.fromEnvironment('TERMS_URL');
    const rawSentryDsn = String.fromEnvironment('SENTRY_DSN');
    const rawWebDemoMode = String.fromEnvironment('WEB_DEMO_MODE');

    final stage = _parseStage(rawStage);
    final backendUri = rawBackendUrl.trim().isNotEmpty
        ? _requiredUri(rawBackendUrl, 'API adresi')
        : _developmentBackend(stage);

    return AppEnvironment(
      stage: stage,
      backendUri: backendUri,
      oidcIssuer: _optionalUri(rawIssuer, 'Oturum sağlayıcısı'),
      oidcClientId: _optionalText(rawClientId),
      oidcAudience: _optionalText(rawAudience),
      oidcRedirectUri: _optionalUri(rawRedirectUri, 'Oturum dönüş adresi'),
      billingProductId: _optionalText(rawBillingProductId),
      storeBillingEnabled: rawStoreBilling.toLowerCase() == 'true',
      privacyUri: _optionalUri(rawPrivacyUrl, 'Gizlilik adresi'),
      termsUri: _optionalUri(rawTermsUrl, 'Kullanım koşulları adresi'),
      sentryDsn: _optionalText(rawSentryDsn),
      webDemoMode: rawWebDemoMode.toLowerCase() == 'true',
    );
  }

  static final AppEnvironment current = AppEnvironment.fromEnvironment();

  final MakiStage stage;
  final Uri backendUri;
  final Uri? oidcIssuer;
  final String? oidcClientId;
  final String? oidcAudience;
  final Uri? oidcRedirectUri;
  final String? billingProductId;
  final bool storeBillingEnabled;
  final Uri? privacyUri;
  final Uri? termsUri;
  final String? sentryDsn;
  final bool webDemoMode;

  bool get isProduction => stage == MakiStage.production;
  bool get isWebPreview => stage == MakiStage.preview && webDemoMode;

  bool get hasOidc =>
      oidcIssuer != null &&
      oidcClientId != null &&
      oidcAudience != null &&
      oidcRedirectUri != null;

  bool get hasLegalLinks => privacyUri != null && termsUri != null;

  String get stageName => stage.name;

  void _validate() {
    if (isProduction && backendUri.scheme != 'https') {
      throw StateError('Üretim API adresi HTTPS kullanmalıdır.');
    }

    if (isProduction && !hasLegalLinks) {
      throw StateError(
        'Üretimde gizlilik ve kullanım koşulları adresleri tanımlanmalıdır.',
      );
    }

    if (isProduction && !hasOidc) {
      throw StateError('Üretimde OIDC oturum ayarları eksiksiz olmalıdır.');
    }

    if (isProduction && (!storeBillingEnabled || billingProductId == null)) {
      throw StateError(
        'Üretimde mağaza faturalandırması ve ürün kimliği tanımlanmalıdır.',
      );
    }

    if (stage == MakiStage.preview && !webDemoMode) {
      throw StateError('Preview derlemesi WEB_DEMO_MODE=true gerektirir.');
    }

    if (webDemoMode && stage != MakiStage.preview && stage != MakiStage.development) {
      throw StateError(
        'WEB_DEMO_MODE yalnızca preview veya development aşamasında kullanılabilir.',
      );
    }

    if (kIsWeb && isProduction) {
      throw StateError(
        'Web istemcisi production finans verisi için yayınlanamaz; preview kullanın.',
      );
    }

    final oidcValues = <Object?>[
      oidcIssuer,
      oidcClientId,
      oidcAudience,
      oidcRedirectUri,
    ];
    final configuredOidcValues = oidcValues
        .where((value) => value != null)
        .length;
    if (configuredOidcValues != 0 &&
        configuredOidcValues != oidcValues.length) {
      throw StateError(
        'Güvenli oturum ayarları eksik. Sağlayıcı, istemci, hedef ve dönüş adresi birlikte tanımlanmalıdır.',
      );
    }

    if (oidcIssuer != null && oidcIssuer!.scheme != 'https') {
      throw StateError('Oturum sağlayıcısı HTTPS kullanmalıdır.');
    }

    if (isProduction &&
        oidcRedirectUri != null &&
        oidcRedirectUri!.scheme == 'http' &&
        !_isLoopback(oidcRedirectUri!)) {
      throw StateError('Üretim oturum dönüş adresi güvenli olmalıdır.');
    }

    if (storeBillingEnabled && (billingProductId == null || !hasOidc)) {
      throw StateError(
        'Mağaza bağlantısı için ürün kimliği ve güvenli oturum birlikte tanımlanmalıdır.',
      );
    }
  }

  static MakiStage _parseStage(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      // A release binary is not necessarily a production deployment: local web
      // previews and test APKs are release builds too. Production's strict URL,
      // legal and session checks are enabled explicitly with
      // --dart-define=MAKI_ENV=production.
      return MakiStage.development;
    }
    return switch (normalized) {
      'development' => MakiStage.development,
      'staging' => MakiStage.staging,
      'preview' => MakiStage.preview,
      'production' => MakiStage.production,
      _ => throw StateError(
        'MAKI_ENV development, staging veya production olmalıdır.',
      ),
    };
  }

  static Uri _developmentBackend(MakiStage stage) {
    if (stage == MakiStage.production) {
      throw StateError('Üretim API adresi tanımlanmadı.');
    }
    if (kIsWeb) return Uri.parse('http://localhost:8000');
    if (defaultTargetPlatform == TargetPlatform.android) {
      return Uri.parse('http://10.0.2.2:8000');
    }
    return Uri.parse('http://localhost:8000');
  }

  static String? _optionalText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static Uri _requiredUri(String value, String label) {
    final uri = Uri.tryParse(value.trim());
    final invalidNetworkUri =
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        !uri.hasAuthority;
    if (uri == null || uri.scheme.isEmpty || invalidNetworkUri) {
      throw StateError('$label geçersiz.');
    }
    return uri;
  }

  static Uri? _optionalUri(String value, String label) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : _requiredUri(trimmed, label);
  }

  static bool _isLoopback(Uri uri) =>
      uri.host == 'localhost' || uri.host == '127.0.0.1' || uri.host == '::1';
}
