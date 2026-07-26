import 'package:equatable/equatable.dart';
import 'package:maki_app/features/insights/domain/entities/inflation_data_entity.dart';

abstract class InflationState extends Equatable {
  const InflationState();

  @override
  List<Object?> get props => [];
}

class InflationInitial extends InflationState {}

class InflationLoading extends InflationState {}

class InflationLoaded extends InflationState {
  final InflationDataEntity data;

  const InflationLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class InflationError extends InflationState {
  final String message;

  const InflationError(this.message);

  @override
  List<Object?> get props => [message];
}
