import 'package:flutter/material.dart';

class MoneyField extends StatelessWidget {
  const MoneyField({
    super.key,
    required this.controller,
    this.labelText,
    this.validator,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String? labelText;
  final String? Function(String?)? validator;
  final bool autofocus;

  static int? tryParseMinor(String? raw) {
    if (raw == null) return null;
    var s = raw.trim();
    if (s.isEmpty) return null;
    s = s.replaceAll('₺', '').replaceAll(RegExp(r'\s+'), '');
    final hasComma = s.contains(',');
    final hasDot = s.contains('.');
    if (hasComma && hasDot) {
      final commaIsDecimal = s.lastIndexOf(',') > s.lastIndexOf('.');
      s = commaIsDecimal
          ? s.replaceAll('.', '').replaceAll(',', '.')
          : s.replaceAll(',', '');
    } else if (hasComma) {
      s = s.replaceAll(',', '.');
    }
    if (!RegExp(r'^[-+]?\d+(?:\.\d{1,2})?$').hasMatch(s)) return null;

    final negative = s.startsWith('-');
    final unsigned = s.replaceFirst(RegExp(r'^[-+]'), '');
    final parts = unsigned.split('.');
    final whole = int.tryParse(parts.first);
    if (whole == null) return null;
    final fraction = parts.length == 1
        ? 0
        : int.parse(parts.last.padRight(2, '0'));
    final minor = whole * 100 + fraction;
    return negative ? -minor : minor;
  }

  static double? tryParse(String? raw) {
    final minor = tryParseMinor(raw);
    return minor == null ? null : minor / 100;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: const Icon(Icons.payments_outlined),
        suffixText: '₺',
      ),
      validator: validator,
    );
  }
}
