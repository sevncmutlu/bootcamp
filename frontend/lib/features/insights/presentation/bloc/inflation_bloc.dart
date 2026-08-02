import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/features/insights/domain/repositories/insights_repository.dart';
import 'package:maki_app/features/insights/presentation/bloc/inflation_event.dart';
import 'package:maki_app/features/insights/presentation/bloc/inflation_state.dart';
import 'dart:developer' as developer;

class InflationBloc extends Bloc<InflationEvent, InflationState> {
  final InsightsRepository repository;

  InflationBloc({required this.repository}) : super(InflationInitial()) {
    on<LoadInflationEvent>(_onLoadInflation);
  }

  Future<void> _onLoadInflation(
    LoadInflationEvent event,
    Emitter<InflationState> emit,
  ) async {
    emit(InflationLoading());
    try {
      final inflationData = await repository.getInflation();
      emit(InflationLoaded(inflationData));
    } catch (e, stackTrace) {
      developer.log(
        'Inflation unexpected error',
        error: e,
        stackTrace: stackTrace,
        name: 'InflationBloc',
      );
      emit(const InflationError('Beklenmeyen bir hata oluştu.'));
    }
  }
}
