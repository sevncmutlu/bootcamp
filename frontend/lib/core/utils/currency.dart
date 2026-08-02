import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class Money {
  Money._();

  static const String symbol = '₺';

  static String format(num amount, {int decimals = 2, String? locale}) {
    final activeLocale = locale ?? Intl.defaultLocale ?? 'tr_TR';
    return NumberFormat.currency(
      locale: activeLocale,
      symbol: symbol,
      decimalDigits: decimals,
    ).format(amount);
  }

  static String formatCompact(num amount, {String? locale}) {
    final activeLocale = locale ?? Intl.defaultLocale ?? 'tr_TR';
    return NumberFormat.compactCurrency(
      locale: activeLocale,
      symbol: symbol,
      decimalDigits: 1,
    ).format(amount);
  }

  static String formatRatioAsPercent(
    num ratio, {
    int decimals = 1,
    String? locale,
  }) =>
      formatPercent(ratio * 100, decimals: decimals, locale: locale ?? 'tr_TR');

  static String formatPercent(
    num value, {
    int decimals = 1,
    String locale = 'tr_TR',
  }) {
    final str = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: decimals,
    ).format(value);
    return locale.startsWith('tr') ? '%$str' : '$str%';
  }
}

String formatTL(
  num amount, {
  int decimals = 2,
  String? locale,
  BuildContext? context,
}) {
  final loc =
      locale ??
      (context != null
          ? Localizations.localeOf(context).toString()
          : Intl.defaultLocale ?? 'tr_TR');
  return Money.format(amount, decimals: decimals, locale: loc);
}
