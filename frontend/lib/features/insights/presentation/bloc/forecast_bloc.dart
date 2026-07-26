import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/core/network/maki_api_client.dart';
import 'package:maki_app/features/insights/domain/repositories/insights_repository.dart';
import 'package:maki_app/features/insights/presentation/bloc/forecast_event.dart';
import 'package:maki_app/features/insights/presentation/bloc/forecast_state.dart';
import 'dart:developer' as developer;

class ForecastBloc extends Bloc<ForecastEvent, ForecastState> {
  final InsightsRepository repository;

  ForecastBloc({required this.repository}) : super(ForecastInitial()) {
    on<LoadForecastEvent>(_onLoadForecast);
  }

  Future<void> _onLoadForecast(
    LoadForecastEvent event,
    Emitter<ForecastState> emit,
  ) async {
    emit(ForecastLoading());
    try {
      final forecast = await repository.getForecast();
      emit(ForecastLoaded(forecast));
    } on MakiApiException catch (e, stackTrace) {
      if (e.code == 'INSUFFICIENT_DATA') {
        emit(ForecastError(e.userMessage, hasInsufficientHistory: true));
      } else {
        developer.log('Forecast exception', error: e.code, stackTrace: stackTrace, name: 'ForecastBloc');
        emit(ForecastError(e.userMessage));
      }
    } catch (e, stackTrace) {
      developer.log('Forecast unexpected error', error: e, stackTrace: stackTrace, name: 'ForecastBloc');
      emit(ForecastError('Beklenmeyen bir hata oluştu.'));
    }
  }
}
