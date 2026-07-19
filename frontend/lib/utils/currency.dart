import 'package:intl/intl.dart';

class Money {
  Money._();

  static const String symbol = '₺';
  static const String _locale = 'tr_TR';

  static final NumberFormat _tl2 = NumberFormat.currency(
    locale: _locale,
    symbol: symbol,
    decimalDigits: 2,
  );

  static final NumberFormat _tl0 = NumberFormat.currency(
    locale: _locale,
    symbol: symbol,
    decimalDigits: 0,
  );

  static final NumberFormat _compact = NumberFormat.compactCurrency(
    locale: _locale,
    symbol: symbol,
    decimalDigits: 1,
  );

  static String format(num amount, {int decimals = 2}) {
    switch (decimals) {
      case 0:
        return _tl0.format(amount);
      case 2:
        return _tl2.format(amount);
      default:
        return NumberFormat.currency(
          locale: _locale,
          symbol: symbol,
          decimalDigits: decimals,
        ).format(amount);
    }
  }

  static String formatCompact(num amount) => _compact.format(amount);

  static String formatRatioAsPercent(num ratio, {int decimals = 1}) =>
      formatPercent(ratio * 100, decimals: decimals);

  static String formatPercent(num value, {int decimals = 1}) {
    final str = NumberFormat.decimalPatternDigits(
      locale: _locale,
      decimalDigits: decimals,
    ).format(value);
    return '%$str';
  }
}

String formatTL(num amount, {int decimals = 2}) =>
    Money.format(amount, decimals: decimals);
