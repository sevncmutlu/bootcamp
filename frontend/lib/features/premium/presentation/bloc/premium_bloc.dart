import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/features/premium/domain/repositories/premium_repository.dart';
import 'package:maki_app/features/premium/presentation/bloc/premium_event.dart';
import 'package:maki_app/features/premium/presentation/bloc/premium_state.dart';

class PremiumBloc extends Bloc<PremiumEvent, PremiumState> {
  PremiumBloc({required this.repository}) : super(PremiumState.initial()) {
    on<CheckPremiumStatusEvent>(_onCheckPremiumStatus);
    on<PurchasePremiumEvent>(_onPurchasePremium);
    on<RestorePremiumEvent>(_onRestorePremium);
  }

  final PremiumRepository repository;

  Future<void> _onCheckPremiumStatus(
    CheckPremiumStatusEvent event,
    Emitter<PremiumState> emit,
  ) async {
    final isPremium = await repository.isPremium();
    emit(
      state.copyWith(
        isPremium: isPremium,
        clearPurchaseSuccess: !isPremium,
        localizedPrice: repository.localizedPrice,
        purchaseAvailable: repository.purchaseAvailable,
      ),
    );
  }

  Future<void> _onPurchasePremium(
    PurchasePremiumEvent event,
    Emitter<PremiumState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final purchased = await repository.purchase();
      emit(
        state.copyWith(
          isLoading: false,
          isPremium: purchased || state.isPremium,
          purchaseSuccess: purchased,
          error: purchased ? null : 'Satın alma tamamlanmadı.',
          localizedPrice: repository.localizedPrice,
          purchaseAvailable: repository.purchaseAvailable,
        ),
      );
    } on Object {
      emit(
        state.copyWith(isLoading: false, error: 'Abonelik etkinleştirilemedi.'),
      );
    }
  }

  Future<void> _onRestorePremium(
    RestorePremiumEvent event,
    Emitter<PremiumState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final restored = await repository.restore();
      emit(
        state.copyWith(
          isLoading: false,
          isPremium: restored || state.isPremium,
          error: restored ? null : 'Önceki abonelik bulunamadı.',
          clearPurchaseSuccess: true,
        ),
      );
    } on Object {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Abonelik geri yüklenemedi.',
          clearPurchaseSuccess: true,
        ),
      );
    }
  }
}
