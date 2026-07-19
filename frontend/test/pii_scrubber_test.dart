import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/utils/pii_scrubber.dart';

void main() {
  group('Kişisel veri temizleme', () {
    test('e-posta adreslerini temizler', () {
      const input = 'E-postam user@example.com, güncellemeleri buraya gönder.';
      final output = PiiScrubber.scrub(input);
      expect(output, equals('E-postam [EMAIL], güncellemeleri buraya gönder.'));
    });

    test('Türk IBAN numaralarını temizler', () {
      const input = 'TR56 0006 2000 0001 2098 7654 32 hesabına aktar.';
      final output = PiiScrubber.scrub(input);
      expect(output, equals('[IBAN] hesabına aktar.'));
    });

    test('kredi kartı numaralarını temizler', () {
      const input = 'Kart numaram 4111 2222 3333 4444.';
      final output = PiiScrubber.scrub(input);
      expect(output, equals('Kart numaram [CARD_NUMBER].'));
    });

    test('Türk telefon numaralarını temizler', () {
      const input = '0532 123 45 67 veya +905321234567 numarasından ara.';
      final output = PiiScrubber.scrub(input);
      expect(
        output,
        equals('[PHONE_NUMBER] veya [PHONE_NUMBER] numarasından ara.'),
      );
    });
  });
}
