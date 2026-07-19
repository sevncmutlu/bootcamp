import 'package:flutter/material.dart';
import 'package:maki_app/theme/app_tokens.dart';
import 'package:maki_app/utils/currency.dart';

enum MoneyKind { neutral, income, expense }

class MoneyText extends StatelessWidget {
  const MoneyText(
    this.amount, {
    super.key,
    this.kind = MoneyKind.neutral,
    this.decimals = 2,
    this.style,
    this.signed = false,
  });

  final num amount;
  final MoneyKind kind;
  final int decimals;
  final TextStyle? style;

  final bool signed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color? color;
    String prefix = '';
    switch (kind) {
      case MoneyKind.income:
        color = ForestColors.income;
        if (signed) prefix = '+';
        break;
      case MoneyKind.expense:
        color = ForestColors.expense;
        if (signed) prefix = '-';
        break;
      case MoneyKind.neutral:
        color = null;
        break;
    }

    final baseStyle = (style ?? Theme.of(context).textTheme.titleMedium)
        ?.copyWith(
          fontWeight: FontWeight.w700,
          color: color ?? scheme.onSurface,
        );

    return Text(
      '$prefix${formatTL(amount, decimals: decimals)}',
      style: baseStyle,
    );
  }
}
