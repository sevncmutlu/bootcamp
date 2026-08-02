import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:maki_app/core/config/app_environment.dart';
import 'package:maki_app/core/config/capability_registry.dart';
import 'package:maki_app/core/errors/app_error_reporter.dart';
import 'package:maki_app/core/network/maki_api_client.dart';
import 'package:maki_app/features/premium/data/datasources/premium_local_data_source.dart';
import 'package:maki_app/features/premium/domain/repositories/premium_repository.dart';

final class PremiumRepositoryImpl implements PremiumRepository {
  PremiumRepositoryImpl({
    required this.localDataSource,
    required this.environment,
    required this.capabilities,
    required this.apiClient,
    required this.errorReporter,
  });

  static const _androidPackageName = 'com.team120.maki.maki_app';

  final PremiumLocalDataSource localDataSource;
  final AppEnvironment environment;
  final CapabilityRegistry capabilities;
  final MakiApiClient apiClient;
  final AppErrorReporter errorReporter;

  InAppPurchase? _store;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  ProductDetails? _product;
  StoreAccountBinding? _binding;
  Completer<bool>? _activeOperation;
  Future<void>? _storeInitialization;
  bool _storeAvailable = false;

  @override
  String? get localizedPrice => _product?.price;

  @override
  bool get purchaseAvailable => _storeAvailable && _product != null;

  @override
  Future<bool> isPremium() async {
    if (!environment.storeBillingEnabled || !environment.hasOidc) {
      return localDataSource.isPremium();
    }
    if (capabilities.nativeStoreSupported) await _ensureStoreInitialized();
    try {
      final active = await apiClient.hasActiveEntitlement();
      await localDataSource.setPremium(active);
      return active;
    } on Object catch (error, stackTrace) {
      await errorReporter.report(error, stackTrace, area: 'abonelik_durumu');
      return false;
    }
  }

  @override
  Future<bool> purchase() async {
    if (!environment.storeBillingEnabled) {
      if (kDebugMode) {
        await localDataSource.setPremium(true);
        return true;
      }
      throw StateError('Mağaza bağlantısı bu sürümde yapılandırılmadı.');
    }
    if (!capabilities.nativeStoreSupported) {
      throw StateError(
        'Satın alma işlemini Android veya iOS uygulamasından yapabilirsin.',
      );
    }
    await _ensureStoreInitialized();
    final store = _store;
    final product = _product;
    if (!_storeAvailable || store == null || product == null) {
      throw StateError('Mağaza şu anda kullanılamıyor.');
    }
    final binding = await _getBinding();
    final applicationUserName = switch (capabilities.target) {
      MakiTarget.android => binding.googleAccountId,
      MakiTarget.ios => binding.appleAccountToken,
      _ => null,
    };
    if (applicationUserName == null || applicationUserName.isEmpty) {
      throw StateError('Mağaza hesap bağı hazırlanamadı.');
    }

    final operation = _beginOperation();
    final launched = await store.buyNonConsumable(
      purchaseParam: PurchaseParam(
        productDetails: product,
        applicationUserName: applicationUserName,
      ),
    );
    if (!launched) _completeOperation(false);
    return operation.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () {
        _activeOperation = null;
        throw TimeoutException('Mağaza işlemi zaman aşımına uğradı.');
      },
    );
  }

  @override
  Future<bool> restore() async {
    if (!environment.storeBillingEnabled ||
        !capabilities.nativeStoreSupported) {
      if (kDebugMode) return localDataSource.isPremium();
      throw StateError('Abonelik geri yükleme mobil mağazada kullanılabilir.');
    }
    await _ensureStoreInitialized();
    final store = _store;
    if (!_storeAvailable || store == null) {
      throw StateError('Mağaza şu anda kullanılamıyor.');
    }
    final binding = await _getBinding();
    final applicationUserName = switch (capabilities.target) {
      MakiTarget.android => binding.googleAccountId,
      MakiTarget.ios => binding.appleAccountToken,
      _ => null,
    };
    if (applicationUserName == null || applicationUserName.isEmpty) {
      throw StateError('Mağaza hesap bağı hazırlanamadı.');
    }
    final operation = _beginOperation();
    await store.restorePurchases(applicationUserName: applicationUserName);
    try {
      return await operation.future.timeout(const Duration(seconds: 20));
    } on TimeoutException {
      _activeOperation = null;
      return isPremium();
    }
  }

  Future<void> _ensureStoreInitialized() =>
      _storeInitialization ??= _initializeStore();

  Future<void> _initializeStore() async {
    if (!capabilities.storeBillingConfigured) return;
    final store = InAppPurchase.instance;
    _store = store;
    _purchaseSubscription = store.purchaseStream.listen(
      (purchases) => unawaited(_handlePurchases(purchases)),
      onError: (Object error, StackTrace stackTrace) {
        unawaited(
          errorReporter.report(error, stackTrace, area: 'magaza_akisi'),
        );
        _completeOperation(false);
      },
    );
    try {
      _storeAvailable = await store.isAvailable();
      if (!_storeAvailable) return;
      final productId = environment.billingProductId!;
      final response = await store.queryProductDetails({productId});
      if (response.error != null || response.notFoundIDs.contains(productId)) {
        throw StateError('Mağaza ürünü bulunamadı.');
      }
      for (final product in response.productDetails) {
        if (product.id == productId) {
          _product = product;
          break;
        }
      }
      if (_product == null) throw StateError('Mağaza ürünü bulunamadı.');
    } on Object catch (error, stackTrace) {
      _storeAvailable = false;
      await errorReporter.report(error, stackTrace, area: 'magaza_hazirlama');
    }
  }

  Future<StoreAccountBinding> _getBinding() async =>
      _binding ??= await apiClient.storeAccountBinding();

  Completer<bool> _beginOperation() {
    final existing = _activeOperation;
    if (existing != null && !existing.isCompleted) {
      throw StateError('Devam eden bir mağaza işlemi var.');
    }
    return _activeOperation = Completer<bool>();
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    if (purchases.isEmpty) {
      _completeOperation(false);
      return;
    }
    for (final purchase in purchases) {
      if (purchase.productID != environment.billingProductId) continue;
      switch (purchase.status) {
        case PurchaseStatus.pending:
          continue;
        case PurchaseStatus.canceled:
        case PurchaseStatus.error:
          _completeOperation(false);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndComplete(purchase);
      }
    }
  }

  Future<void> _verifyAndComplete(PurchaseDetails purchase) async {
    try {
      final proof = purchase.verificationData.serverVerificationData.trim();
      if (proof.isEmpty) throw StateError('Mağaza doğrulama kanıtı eksik.');
      final granted = switch (capabilities.target) {
        MakiTarget.android => await apiClient.verifyGooglePlayPurchase(
          packageName: _androidPackageName,
          purchaseToken: proof,
        ),
        MakiTarget.ios => await apiClient.verifyAppStorePurchase(
          signedTransaction: proof,
        ),
        _ => false,
      };
      if (!granted) throw StateError('Abonelik erişim vermiyor.');
      if (purchase.pendingCompletePurchase) {
        await _store!.completePurchase(purchase);
      }
      await localDataSource.setPremium(true);
      _completeOperation(true);
    } on Object catch (error, stackTrace) {
      await errorReporter.report(error, stackTrace, area: 'magaza_dogrulama');
      _completeOperation(false);
    }
  }

  void _completeOperation(bool result) {
    final operation = _activeOperation;
    if (operation == null || operation.isCompleted) return;
    operation.complete(result);
    _activeOperation = null;
  }

  @override
  Future<void> dispose() async {
    await _purchaseSubscription?.cancel();
  }
}
