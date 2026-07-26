import 'package:maki_app/features/premium/data/datasources/premium_local_data_source.dart';
import 'package:maki_app/features/premium/domain/repositories/premium_repository.dart';

class PremiumRepositoryImpl implements PremiumRepository {
  final PremiumLocalDataSource _localDataSource;

  PremiumRepositoryImpl(this._localDataSource);

  @override
  Future<bool> isPremium() async {
    return await _localDataSource.isPremium();
  }

  @override
  Future<void> setPremium(bool value) async {
    await _localDataSource.setPremium(value);
  }
}
