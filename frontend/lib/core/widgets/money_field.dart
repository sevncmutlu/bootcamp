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

  static double? tryParse(String? raw) {
    if (raw == null) return null;
    var s = raw.trim();
    if (s.isEmpty) return null;
    final hasComma = s.contains(',');
    final hasDot = s.contains('.');
    if (hasComma && hasDot) {
      s = s.replaceAll('.', '').replaceAll(',', '.');
    } else if (hasComma) {
      s = s.replaceAll(',', '.');
    }
    return double.tryParse(s);
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
