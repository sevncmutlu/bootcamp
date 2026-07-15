import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/utils/pii_scrubber.dart';

void main() {
  group('PiiScrubber Tests', () {
    test('should scrub emails', () {
      const input = 'My email is user@example.com, send updates there.';
      final output = PiiScrubber.scrub(input);
      expect(output, equals('My email is [EMAIL], send updates there.'));
    });

    test('should scrub Turkish IBANs', () {
      const input = 'Please transfer money to TR56 0006 2000 0001 2098 7654 32';
      final output = PiiScrubber.scrub(input);
      expect(output, equals('Please transfer money to [IBAN]'));
    });

    test('should scrub credit card numbers', () {
      const input = 'My card number is 4111 2222 3333 4444.';
      final output = PiiScrubber.scrub(input);
      expect(output, equals('My card number is [CARD_NUMBER].'));
    });

    test('should scrub Turkish phone numbers', () {
      const input = 'Reach me at 0532 123 45 67 or +905321234567';
      final output = PiiScrubber.scrub(input);
      expect(output, equals('Reach me at [PHONE_NUMBER] or [PHONE_NUMBER]'));
    });
  });
}
