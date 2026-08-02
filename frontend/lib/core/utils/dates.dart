import 'package:intl/intl.dart';

class Dates {
  Dates._();

  static String long(DateTime date, String locale) =>
      DateFormat.yMMMMd(locale).format(date);

  static String medium(DateTime date, String locale) =>
      DateFormat.yMMMd(locale).format(date);

  static String short(DateTime date, String locale) =>
      DateFormat.yMd(locale).format(date);

  static DateTime? tryParseIso(String raw) => DateTime.tryParse(raw);

  static String fromIso(String raw, String locale) {
    final parsed = tryParseIso(raw);
    return parsed == null ? raw : medium(parsed, locale);
  }
}
