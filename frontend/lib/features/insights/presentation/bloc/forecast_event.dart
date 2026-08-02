import 'package:equatable/equatable.dart';

abstract class ForecastEvent extends Equatable {
  const ForecastEvent();

  @override
  List<Object?> get props => [];
}

class LoadForecastEvent extends ForecastEvent {}
