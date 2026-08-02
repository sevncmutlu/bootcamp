import 'package:flutter/foundation.dart';
import 'package:maki_app/core/config/app_environment.dart';

enum MakiTarget { android, ios, web, other }

final class CapabilityRegistry {
  const CapabilityRegistry({required this.environment, required this.target});

  factory CapabilityRegistry.current(AppEnvironment environment) {
    final target = kIsWeb
        ? MakiTarget.web
        : switch (defaultTargetPlatform) {
            TargetPlatform.android => MakiTarget.android,
            TargetPlatform.iOS => MakiTarget.ios,
            _ => MakiTarget.other,
          };
    return CapabilityRegistry(environment: environment, target: target);
  }

  final AppEnvironment environment;
  final MakiTarget target;

  bool get localFinance => true;
  bool get usesPersistentFinancialStorage => target != MakiTarget.web;
  bool get isPreview => target == MakiTarget.web && environment.isWebPreview;
  bool get identityConfigured => environment.hasOidc;
  bool get legalLinksConfigured => environment.hasLegalLinks;
  bool get nativeStoreSupported =>
      target == MakiTarget.android || target == MakiTarget.ios;
  bool get storeBillingConfigured =>
      environment.storeBillingEnabled &&
      environment.billingProductId != null &&
      nativeStoreSupported &&
      identityConfigured;

  bool onlineFeaturesAvailable({required bool hasSession}) =>
      !isPreview && (hasSession || !environment.isProduction);

  bool purchaseAvailable({
    required bool hasSession,
    required bool storeAvailable,
  }) => storeBillingConfigured && hasSession && storeAvailable;
}
