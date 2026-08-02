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
  final rawMsg = event.message?.formatted;
  final sanitizedMsg = rawMsg != null ? SentryMessage(redactSensitiveText(rawMsg)) : event.message;
  final sanitizedExceptions = event.exceptions?.map((exc) {
    final val = exc.value;
    final sanitizedValue = val != null ? redactSensitiveText(val) : val;
    return SentryException(
      type: exc.type,
      value: sanitizedValue,
      module: exc.module,
      threadId: exc.threadId,
      mechanism: exc.mechanism,
    );
  }).toList();

  return event.copyWith(
    user: null,
    request: null,
    breadcrumbs: null,
    message: sanitizedMsg,
    exceptions: sanitizedExceptions,
  );
}
