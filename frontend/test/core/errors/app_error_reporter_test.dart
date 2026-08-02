import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/core/errors/app_error_reporter.dart';

void main() {
  test('hassas değerleri hata metninden temizler', () {
    const input =
        'email emir@example.com IBAN TR120006200000000000000001 token: eyJabc.def.ghi';

    final sanitized = redactSensitiveText(input);

    expect(sanitized, isNot(contains('emir@example.com')));
    expect(sanitized, isNot(contains('TR120006200000000000000001')));
    expect(sanitized, isNot(contains('eyJabc.def.ghi')));
  });
}
