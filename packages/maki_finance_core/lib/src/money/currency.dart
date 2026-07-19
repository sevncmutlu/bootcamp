/// Üç harfli ISO 4217 para birimi kodu.
final class Currency {
  const Currency(this.code) : assert(code.length == 3);

  /// Dış girdiyi büyük harfli ISO kodu olarak doğrular.
  factory Currency.parse(String code) {
    final valid = RegExp(r'^[A-Z]{3}$').hasMatch(code);
    if (!valid) {
      throw const FormatException(
        'Para birimi üç büyük Latin harfinden oluşmalıdır.',
      );
    }
    return Currency(code);
  }

  final String code;

  @override
  bool operator ==(Object other) => other is Currency && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => code;
}
