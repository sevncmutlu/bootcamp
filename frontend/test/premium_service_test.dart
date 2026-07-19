import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:maki_app/services/premium_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('kayıt yoksa premium durumu kapalıdır', () async {
    final service = PremiumService.instance;
    expect(await service.isPremium(), isFalse);
  });

  test('premium açıldığında kalıcılaştırılır', () async {
    final service = PremiumService.instance;
    await service.setPremium(value: true);
    expect(await service.isPremium(), isTrue);
  });

  test('premium kapatıldığında durum geri alınır', () async {
    final service = PremiumService.instance;
    await service.setPremium(value: true);
    await service.setPremium(value: false);
    expect(await service.isPremium(), isFalse);
  });
}
