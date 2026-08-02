import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/core/config/app_environment.dart';
import 'package:maki_app/core/config/capability_registry.dart';

void main() {
  group('AppEnvironment', () {
    test('production requires an HTTPS API', () {
      expect(
        () => AppEnvironment(
          stage: MakiStage.production,
          backendUri: Uri.parse('http://api.example.test'),
        ),
        throwsStateError,
      );
    });

    test('partial OIDC settings fail closed', () {
      expect(
        () => AppEnvironment(
          stage: MakiStage.staging,
          backendUri: Uri.parse('https://api.example.test'),
          oidcIssuer: Uri.parse('https://login.example.test'),
        ),
        throwsStateError,
      );
    });

    test('local mode remains available without OIDC', () {
      final environment = AppEnvironment(
        stage: MakiStage.development,
        backendUri: Uri.parse('http://localhost:8000'),
      );
      final capabilities = CapabilityRegistry(
        environment: environment,
        target: MakiTarget.android,
      );

      expect(environment.hasOidc, isFalse);
      expect(capabilities.localFinance, isTrue);
      expect(capabilities.storeBillingConfigured, isFalse);
    });

    test('web preview is isolated and online features are disabled', () {
      final environment = AppEnvironment(
        stage: MakiStage.preview,
        backendUri: Uri.parse('http://localhost:8000'),
        webDemoMode: true,
      );
      final capabilities = CapabilityRegistry(
        environment: environment,
        target: MakiTarget.web,
      );

      expect(capabilities.isPreview, isTrue);
      expect(capabilities.usesPersistentFinancialStorage, isFalse);
      expect(capabilities.onlineFeaturesAvailable(hasSession: true), isFalse);
    });

    test('preview stage fails closed without demo flag', () {
      expect(
        () => AppEnvironment(
          stage: MakiStage.preview,
          backendUri: Uri.parse('http://localhost:8000'),
        ),
        throwsStateError,
      );
    });

    test('billing requires OIDC and a product id', () {
      expect(
        () => AppEnvironment(
          stage: MakiStage.production,
          backendUri: Uri.parse('https://api.example.test'),
          storeBillingEnabled: true,
          privacyUri: Uri.parse('https://maki.example.test/gizlilik'),
          termsUri: Uri.parse('https://maki.example.test/kosullar'),
        ),
        throwsStateError,
      );
    });
  });
}
