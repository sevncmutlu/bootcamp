import 'package:equatable/equatable.dart';

abstract class InflationEvent extends Equatable {
  const InflationEvent();

  @override
  List<Object?> get props => [];
}

class LoadInflationEvent extends InflationEvent {}
