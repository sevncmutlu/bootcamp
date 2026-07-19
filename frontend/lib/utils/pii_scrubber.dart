class PiiScrubber {
  static final RegExp _emailRegex = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
    caseSensitive: false,
  );

  static final RegExp _creditCardRegex = RegExp(r'\b(?:\d[ -]*?){13,19}\b');

  static final RegExp _turkishIbanRegex = RegExp(
    r'\bTR\d{2}[ ]?(?:\d{4}[ ]?){5}\d{2}\b',
    caseSensitive: false,
  );

  static final RegExp _phoneRegex = RegExp(
    r'\+?\b(?:90|0)?[ ]?\d{3}[ ]?\d{3}[ ]?\d{2}[ ]?\d{2}\b',
  );

  static String scrub(String input) {
    if (input.isEmpty) return input;

    String output = input;

    output = output.replaceAllMapped(_emailRegex, (match) => '[EMAIL]');

    output = output.replaceAllMapped(_turkishIbanRegex, (match) => '[IBAN]');

    output = output.replaceAllMapped(
      _creditCardRegex,
      (match) => '[CARD_NUMBER]',
    );

    output = output.replaceAllMapped(_phoneRegex, (match) => '[PHONE_NUMBER]');

    return output;
  }
}
