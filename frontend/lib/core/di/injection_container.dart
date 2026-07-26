import 'package:get_it/get_it.dart';
import 'package:maki_app/core/database/database.dart';
import 'package:maki_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:maki_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:maki_app/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:maki_app/features/insights/domain/repositories/insights_repository.dart';
import 'package:maki_app/features/insights/data/repositories/insights_repository_impl.dart';
import 'package:maki_app/features/insights/presentation/bloc/forecast_bloc.dart';
import 'package:maki_app/features/insights/presentation/bloc/inflation_bloc.dart';
import 'package:maki_app/features/coach/domain/repositories/coach_repository.dart';
import 'package:maki_app/features/coach/data/repositories/coach_repository_impl.dart';
import 'package:maki_app/features/coach/presentation/bloc/coach_bloc.dart';
import 'package:maki_app/features/simulator/domain/repositories/simulator_repository.dart';
import 'package:maki_app/features/simulator/data/repositories/simulator_repository_impl.dart';
import 'package:maki_app/features/simulator/presentation/bloc/simulator_bloc.dart';
import 'package:maki_app/features/gamification/domain/repositories/gamification_repository.dart';
import 'package:maki_app/features/gamification/data/repositories/gamification_repository_impl.dart';
import 'package:maki_app/features/gamification/presentation/bloc/gamification_bloc.dart';
import 'package:maki_app/features/gamification/data/datasources/gamification_local_data_source.dart';
import 'package:maki_app/features/profile/domain/repositories/settings_repository.dart';
import 'package:maki_app/features/profile/data/repositories/settings_repository_impl.dart';
import 'package:maki_app/features/profile/presentation/bloc/settings_bloc.dart';
import 'package:maki_app/features/profile/data/datasources/onboarding_local_data_source.dart';
import 'package:maki_app/features/premium/data/datasources/premium_local_data_source.dart';
import 'package:maki_app/features/premium/domain/repositories/premium_repository.dart';
import 'package:maki_app/features/premium/data/repositories/premium_repository_impl.dart';
import 'package:maki_app/features/premium/presentation/bloc/premium_bloc.dart';
import 'package:maki_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:maki_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:maki_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:maki_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:maki_app/core/network/maki_api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

Future<void> init() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  // Transactions
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(sl()),
  );

  // Insights
  sl.registerLazySingleton<InsightsRepository>(
    () => InsightsRepositoryImpl(database: sl(), apiClient: MakiApi.instance),
  );

  // Coach
  sl.registerLazySingleton<CoachRepository>(
    () => CoachRepositoryImpl(apiClient: MakiApi.instance),
  );

  // Simulator
  sl.registerLazySingleton<SimulatorRepository>(
    () => SimulatorRepositoryImpl(),
  );

  // Gamification
  sl.registerLazySingleton<GamificationRepository>(
    () => GamificationRepositoryImpl(
      apiClient: MakiApi.instance,
      gamificationDataSource: sl(),
      database: AppDatabase.instance,
    ),
  );

  // Settings
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(
      onboardingDataSource: sl(),
      premiumDataSource: sl(),
      database: sl(),
    ),
  );

  // ---------------------------------------------------------------------------
  // Blocs
  // ---------------------------------------------------------------------------
  // Auth
  sl.registerFactory(() => AuthBloc(repository: sl()));

  // Transactions
  sl.registerFactory(() => TransactionBloc(repository: sl()));

  // Insights
  sl.registerFactory(() => ForecastBloc(repository: sl()));
  sl.registerFactory(() => InflationBloc(repository: sl()));

  // Coach
  sl.registerFactory(() => CoachBloc(repository: sl()));

  // Simulator
  sl.registerFactory(() => SimulatorBloc(repository: sl()));

  // Gamification
  sl.registerFactory(() => GamificationBloc(repository: sl()));

  // Settings
  sl.registerFactory(() => SettingsBloc(repository: sl()));
  
  // Premium
  sl.registerFactory(() => PremiumBloc(repository: sl()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      storage: sl(),
    ),
  );

  sl.registerLazySingleton<PremiumRepository>(
    () => PremiumRepositoryImpl(sl()),
  );

  // Data Sources
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<OnboardingLocalDataSource>(
    () => OnboardingLocalDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<GamificationLocalDataSource>(
    () => GamificationLocalDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<PremiumLocalDataSource>(
    () => PremiumLocalDataSourceImpl(sl()),
  );

  // Core & External
  sl.registerLazySingleton(() => AppDatabase.instance);
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  sl.registerLazySingleton(() => http.Client());

}
