import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/features/simulator/data/datasources/debt_plan_local_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('stores the user debt plans', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final source = DebtPlanLocalDataSource(preferences);
    const plan = DebtPlanDefinition(
      id: 'my-plan',
      name: 'Kartları azalt',
      primary: 'interestRate',
      primaryDirection: 'descending',
      tieBreaker: 'balance',
      tieBreakerDirection: 'ascending',
      allocation: 'focused',
    );

    await source.save(const [plan]);

    final loaded = source.load();
    expect(loaded, hasLength(1));
    expect(loaded.single.name, 'Kartları azalt');
    expect(
      loaded.single.strategyCode,
      'custom|interestRate|descending|balance|ascending|focused',
    );
  });

  test('ignores a corrupted local record', () async {
    SharedPreferences.setMockInitialValues({'maki_debt_plans_v1': '{bad'});
    final preferences = await SharedPreferences.getInstance();

    expect(DebtPlanLocalDataSource(preferences).load(), isEmpty);
  });
}
