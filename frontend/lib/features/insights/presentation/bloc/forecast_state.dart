import 'package:equatable/equatable.dart';
import 'package:maki_app/features/insights/domain/entities/forecast_day_entity.dart';

abstract class ForecastState extends Equatable {
  const ForecastState();

  @override
  List<Object?> get props => [];
}

class ForecastInitial extends ForecastState {}

class ForecastLoading extends ForecastState {}

class ForecastLoaded extends ForecastState {
  final List<ForecastDayEntity> forecast;

  const ForecastLoaded(this.forecast);

  @override
  List<Object?> get props => [forecast];
}

class ForecastError extends ForecastState {
  final String message;
  final bool hasInsufficientHistory;

  const ForecastError(this.message, {this.hasInsufficientHistory = false});

  @override
  List<Object?> get props => [message, hasInsufficientHistory];
}
