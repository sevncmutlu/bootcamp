import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/features/premium/domain/repositories/premium_repository.dart';
import 'package:maki_app/features/premium/presentation/bloc/premium_event.dart';
import 'package:maki_app/features/premium/presentation/bloc/premium_state.dart';

class PremiumBloc extends Bloc<PremiumEvent, PremiumState> {
  final PremiumRepository repository;

  PremiumBloc({required this.repository}) : super(PremiumState.initial()) {
    on<CheckPremiumStatusEvent>(_onCheckPremiumStatus);
    on<PurchasePremiumEvent>(_onPurchasePremium);
    on<RestorePremiumEvent>(_onRestorePremium);
  }

  Future<void> _onCheckPremiumStatus(
    CheckPremiumStatusEvent event,
    Emitter<PremiumState> emit,
  ) async {
    final isPremium = await repository.isPremium();
    emit(state.copyWith(
      isPremium: isPremium,
      clearPurchaseSuccess: !isPremium,
    ));
  }

  Future<void> _onPurchasePremium(
    PurchasePremiumEvent event,
    Emitter<PremiumState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      if (!kDebugMode) {
        throw StateError('Mağaza satın alma bağlantısı Sprint 3 kapsamında etkinleştirilecek.');
      }
      await repository.setPremium(true);
      emit(state.copyWith(
        isLoading: false,
        isPremium: true,
        purchaseSuccess: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Abonelik etkinleştirilemedi.',
      ));
    }
  }

  Future<void> _onRestorePremium(
    RestorePremiumEvent event,
    Emitter<PremiumState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      if (!kDebugMode) {
        throw StateError('Mağaza geri yükleme bağlantısı Sprint 3 kapsamında etkinleştirilecek.');
      }
      // Mocking a restore operation
      await Future<void>.delayed(const Duration(seconds: 1));
      
      emit(state.copyWith(
        isLoading: false,
        isPremium: false, // In reality, this would be true if they had a past purchase
        error: 'Önceki abonelik bulunamadı.',
        clearPurchaseSuccess: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Abonelik geri yüklenemedi.',
        clearPurchaseSuccess: true,
      ));
    }
  }
}
