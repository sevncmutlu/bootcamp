import 'package:equatable/equatable.dart';

class PremiumState extends Equatable {
  final bool isPremium;
  final bool isLoading;
  final String? error;
  final bool purchaseSuccess;
  final String? localizedPrice;
  final bool purchaseAvailable;

  const PremiumState({
    required this.isPremium,
    required this.isLoading,
    this.error,
    this.purchaseSuccess = false,
    this.localizedPrice,
    this.purchaseAvailable = false,
  });

  factory PremiumState.initial() {
    return const PremiumState(isPremium: false, isLoading: false);
  }

  PremiumState copyWith({
    bool? isPremium,
    bool? isLoading,
    String? error,
    bool? purchaseSuccess,
    bool clearError = false,
    bool clearPurchaseSuccess = false,
    String? localizedPrice,
    bool? purchaseAvailable,
  }) {
    return PremiumState(
      isPremium: isPremium ?? this.isPremium,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      purchaseSuccess: clearPurchaseSuccess
          ? false
          : (purchaseSuccess ?? this.purchaseSuccess),
      localizedPrice: localizedPrice ?? this.localizedPrice,
      purchaseAvailable: purchaseAvailable ?? this.purchaseAvailable,
    );
  }

  @override
  List<Object?> get props => [
    isPremium,
    isLoading,
    error,
    purchaseSuccess,
    localizedPrice,
    purchaseAvailable,
  ];
}
