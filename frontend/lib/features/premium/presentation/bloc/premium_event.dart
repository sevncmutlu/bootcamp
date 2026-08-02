import 'package:equatable/equatable.dart';

abstract class PremiumEvent extends Equatable {
  const PremiumEvent();

  @override
  List<Object?> get props => [];
}

class CheckPremiumStatusEvent extends PremiumEvent {}

class PurchasePremiumEvent extends PremiumEvent {}

class RestorePremiumEvent extends PremiumEvent {}
