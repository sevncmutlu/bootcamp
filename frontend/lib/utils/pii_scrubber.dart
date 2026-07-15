class PiiScrubber {
  // Regex patterns for sensitive personal details
  static final RegExp _emailRegex = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
    caseSensitive: false,
  );

  static final RegExp _creditCardRegex = RegExp(
    r'\b(?:\d[ -]*?){13,19}\b',
  );

  static final RegExp _turkishIbanRegex = RegExp(
    r'\bTR\d{2}[ ]?(?:\d{4}[ ]?){5}\d{2}\b',
    caseSensitive: false,
  );

  static final RegExp _phoneRegex = RegExp(
    r'\+?\b(?:90|0)?[ ]?\d{3}[ ]?\d{3}[ ]?\d{2}[ ]?\d{2}\b',
  );

  /// Scrubs sensitive inputs by replacing them with sanitized placeholders.
  static String scrub(String input) {
    if (input.isEmpty) return input;
    
    String output = input;

    // 1. Clean Emails
    output = output.replaceAllMapped(_emailRegex, (match) => '[EMAIL]');

    // 2. Clean Turkish IBANs
    output = output.replaceAllMapped(_turkishIbanRegex, (match) => '[IBAN]');

    // 3. Clean Credit/Debit Card Numbers
    output = output.replaceAllMapped(_creditCardRegex, (match) => '[CARD_NUMBER]');

    // 4. Clean Phone Numbers
    output = output.replaceAllMapped(_phoneRegex, (match) => '[PHONE_NUMBER]');

    return output;
  }
}
