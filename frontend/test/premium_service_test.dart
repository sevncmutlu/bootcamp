import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:maki_app/services/premium_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Reset the FlutterSecureStorage mock between tests
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('isPremium defaults to false when no value is stored', () async {
    final service = PremiumService.instance;
    expect(await service.isPremium(), isFalse);
  });

  test('setPremium(true) persists and isPremium returns true', () async {
    final service = PremiumService.instance;
    await service.setPremium(value: true);
    expect(await service.isPremium(), isTrue);
  });

  test('setPremium(false) reverts premium status to false', () async {
    final service = PremiumService.instance;
    await service.setPremium(value: true);
    await service.setPremium(value: false);
    expect(await service.isPremium(), isFalse);
  });
}
