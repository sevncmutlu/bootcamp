import 'package:flutter/foundation.dart';
import 'package:maki_app/core/config/app_environment.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

abstract interface class AppErrorReporter {
  Future<void> report(
    Object error,
    StackTrace stackTrace, {
    String area = 'uygulama',
  });
}

final class SafeAppErrorReporter implements AppErrorReporter {
  const SafeAppErrorReporter(this.environment);

  final AppEnvironment environment;

  @override
  Future<void> report(
    Object error,
    StackTrace stackTrace, {
    String area = 'uygulama',
  }) async {
    if (kDebugMode) {
      debugPrint(
        'Maki hata alanı: $area · ${redactSensitiveText(error.toString())}',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
    if (environment.sentryDsn == null) return;

    await Sentry.captureException(
      _SafeReportedError(
        type: error.runtimeType.toString(),
        message: redactSensitiveText(error.toString()),
      ),
      stackTrace: stackTrace,
      withScope: (scope) => scope.setTag('maki.area', area),
    );
  }
}

final class _SafeReportedError implements Exception {
  const _SafeReportedError({required this.type, required this.message});

  final String type;
  final String message;

  @override
  String toString() => '$type: $message';
}

String redactSensitiveText(String input) {
  var output = input;
  final replacements = <RegExp, String>{
    RegExp(r'\b[A-Z]{2}\d{2}[A-Z0-9]{10,30}\b', caseSensitive: false):
        '[IBAN gizlendi]',
    RegExp(r'\b(?:\d[ -]*?){13,19}\b'): '[kart numarası gizlendi]',
    RegExp(r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b', caseSensitive: false):
        '[e-posta gizlendi]',
    RegExp(r'\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b'):
        '[erişim belirteci gizlendi]',
    RegExp(
      r'(api[_ -]?key|token|authorization|bearer)\s*[:=]\s*\S+',
      caseSensitive: false,
    ): '[gizli değer gizlendi]',
  };
  for (final entry in replacements.entries) {
    output = output.replaceAll(entry.key, entry.value);
  }
  return output;
}

SentryEvent sanitizeSentryEvent(SentryEvent event) {
  event.user = null;
  event.request = null;
  event.breadcrumbs = null;
  final message = event.message;
  if (message != null) {
    message.formatted = redactSensitiveText(message.formatted);
  }
  for (final exception in event.exceptions ?? const <SentryException>[]) {
    final value = exception.value;
    if (value != null) exception.value = redactSensitiveText(value);
    exception.throwable = null;
  }
  return event;
}
