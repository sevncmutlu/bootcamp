import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/widgets/money_field.dart';

void main() {
  group('MoneyField.tryParse', () {
    test('Türkçe ondalık virgülü ayrıştırır', () {
      expect(MoneyField.tryParse('1234,56'), 1234.56);
    });

    test('Türkçe binlik ayırıcı ve ondalık virgülü ayrıştırır', () {
      expect(MoneyField.tryParse('1.234,56'), 1234.56);
    });

    test('ondalık noktayı ayrıştırır', () {
      expect(MoneyField.tryParse('1234.56'), 1234.56);
    });

    test('tam sayıyı ayrıştırır', () {
      expect(MoneyField.tryParse('1234'), 1234);
    });

    test('çevresindeki boşlukları temizler', () {
      expect(MoneyField.tryParse('  42,5 '), 42.5);
    });

    test('boş veya geçersiz girdide null döndürür', () {
      expect(MoneyField.tryParse(''), isNull);
      expect(MoneyField.tryParse('abc'), isNull);
      expect(MoneyField.tryParse(null), isNull);
    });
  });
}
