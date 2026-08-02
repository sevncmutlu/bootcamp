import 'package:drift/drift.dart';

/// Persists Turkish lira values as signed 64-bit minor units (kuruş).
///
/// The application domain keeps decimal TL values, while SQLite only receives
/// integer kuruş values. More than two meaningful decimal places are rejected
/// instead of being silently rounded.
class MoneyMinorConverter extends TypeConverter<double, int> {
  const MoneyMinorConverter();

  static const int scale = 100;
  static const double _epsilon = 0.000001;

  @override
  double fromSql(int fromDb) => fromDb / scale;

  @override
  int toSql(double value) {
    if (!value.isFinite) {
      throw const FormatException('Para tutarı sonlu bir sayı olmalıdır.');
    }

    final scaled = value * scale;
    final minor = scaled.round();
    if ((scaled - minor).abs() > _epsilon) {
      throw const FormatException(
        'Para tutarı en fazla iki ondalık basamak içerebilir.',
      );
    }
    return minor;
  }
}
