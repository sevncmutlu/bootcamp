import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:maki_app/config/api_config.dart';
import 'package:maki_app/services/session_service.dart';

typedef TokenProvider = Future<String?> Function();
typedef WaitFunction = Future<void> Function(Duration duration);

final class MakiApiException implements Exception {
  const MakiApiException(this.code, this.userMessage);

  final String code;
  final String userMessage;

  @override
  String toString() => userMessage;
}

final class CoachSource {
  const CoachSource({
    required this.institution,
    required this.seriesId,
    required this.period,
    required this.value,
    required this.unit,
    required this.sourceUrl,
  });

  final String institution;
  final String seriesId;
  final String period;
  final String value;
  final String unit;
  final Uri sourceUrl;
}

final class CoachReply {
  const CoachReply({required this.answer, required this.sources});

  final String answer;
  final List<CoachSource> sources;
}

final class ForecastReply {
  const ForecastReply({required this.predictions, required this.modelName});

  final List<double> predictions;
  final String modelName;
}

final class ReceiptScan {
  const ReceiptScan({
    required this.merchantName,
    required this.totalMinor,
    required this.requiresReview,
  });

  final String? merchantName;
  final int? totalMinor;
  final bool requiresReview;
}

final class LeaderboardStanding {
  const LeaderboardStanding({
    required this.available,
    required this.percentile,
    required this.cohortSize,
  });

  final bool available;
  final int? percentile;
  final String cohortSize;
}

final class MakiApiClient {
  MakiApiClient({
    required this.baseUri,
    required this.tokenProvider,
    http.Client? client,
    WaitFunction? wait,
    this.requestTimeout = const Duration(seconds: 15),
    this.maximumPollCount = 30,
  }) : _client = client ?? http.Client(),
       _wait = wait ?? Future<void>.delayed;

  final Uri baseUri;
  final TokenProvider tokenProvider;
  final Duration requestTimeout;
  final int maximumPollCount;
  final http.Client _client;
  final WaitFunction _wait;

  Future<CoachReply> askCoach({
    required String question,
    required String sessionId,
  }) async {
    final job = await _acceptJsonJob('/api/v1/coach/queries', {
      'question': question,
      'locale': 'tr-TR',
      'session_id': sessionId,
    });
    final result = await _awaitJob(job);
    final answer = _map(result['answer'], 'Koç sonucu geçersiz.');
    final safety = _string(answer['safety'], 'Koç güvenlik sonucu eksik.');
    if (safety != 'answered') {
      throw const MakiApiException(
        'KAYNAK_YETERSIZ',
        'Güvenilir resmi kaynak bulunamadığı için yanıt üretilemedi.',
      );
    }
    final text = _string(answer['answer'], 'Koç yanıtı eksik.');
    final rawSources = _list(answer['sources'], 'Koç kaynakları geçersiz.');
    final sources = rawSources
        .map((source) {
          final item = _map(source, 'Koç kaynağı geçersiz.');
          return CoachSource(
            institution: _string(item['institution'], 'Kurum bilgisi eksik.'),
            seriesId: _string(item['series_id'], 'Seri bilgisi eksik.'),
            period: _string(item['period'], 'Dönem bilgisi eksik.'),
            value: _string(item['value'], 'Kaynak değeri eksik.'),
            unit: _string(item['unit'], 'Kaynak birimi eksik.'),
            sourceUrl: Uri.parse(
              _string(item['source_url'], 'Kaynak adresi eksik.'),
            ),
          );
        })
        .toList(growable: false);
    return CoachReply(answer: text, sources: sources);
  }

  Future<ForecastReply> forecast({
    required List<double> relativeIndexes,
    int horizon = 7,
  }) async {
    if (relativeIndexes.length < 56 ||
        relativeIndexes.any((value) => !value.isFinite || value <= 0)) {
      throw const MakiApiException(
        'TAHMIN_GIRDISI_GECERSIZ',
        'Tahmin için en az 56 günlük geçerli seri gereklidir.',
      );
    }
    final job = await _acceptJsonJob('/api/v1/forecasts/jobs', {
      'series': {
        'points': [
          for (var day = 0; day < relativeIndexes.length; day++)
            {'day': day, 'index': relativeIndexes[day]},
        ],
      },
      'horizon': horizon,
    });
    final result = await _awaitJob(job);
    final forecastResult = _map(result['forecast'], 'Tahmin sonucu geçersiz.');
    final forecast = _map(
      forecastResult['forecast'],
      'Tahmin modeli sonucu geçersiz.',
    );
    final points = _list(forecast['points'], 'Tahmin noktaları geçersiz.');
    return ForecastReply(
      modelName: _string(forecast['model_name'], 'Tahmin modeli eksik.'),
      predictions: points
          .map(
            (point) => _number(
              _map(point, 'Tahmin noktası geçersiz.')['prediction'],
              'Tahmin değeri geçersiz.',
            ),
          )
          .toList(growable: false),
    );
  }

  Future<ReceiptScan> scanReceipt({
    required Uint8List bytes,
    required String fileName,
    required String mediaType,
  }) async {
    if (bytes.isEmpty || bytes.length > 8 * 1024 * 1024) {
      throw const MakiApiException(
        'FIS_BOYUTU_GECERSIZ',
        'Fiş görseli boş olamaz ve 8 MiB sınırını aşamaz.',
      );
    }
    if (mediaType != 'image/jpeg' && mediaType != 'image/png') {
      throw const MakiApiException(
        'FIS_TURU_GECERSIZ',
        'Yalnızca JPEG veya PNG fiş görseli seçilebilir.',
      );
    }
    final token = await _requiredToken();
    final request =
        http.MultipartRequest('POST', _resolve('/api/v1/receipts/jobs'))
          ..headers.addAll(_headers(token))
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              bytes,
              filename: fileName,
              contentType: MediaType.parse(mediaType),
            ),
          );
    final response = await _send(request);
    final job = _acceptedJob(response);
    final result = await _awaitJob(job);
    final receipt = _map(result['receipt'], 'Fiş sonucu geçersiz.');
    return ReceiptScan(
      merchantName: _optionalString(receipt['merchant_name']),
      totalMinor: _optionalInt(receipt['total_minor']),
      requiresReview: _boolean(
        receipt['requires_review'],
        'Fiş inceleme durumu eksik.',
      ),
    );
  }

  Future<LeaderboardStanding> leaderboard({
    required String ageBand,
    required String householdBand,
    required int scoreBasisPoints,
  }) async {
    final response = await _postJson('/api/v1/leaderboard/percentiles', {
      'cohort': {'age_band': ageBand, 'household_band': householdBand},
      'score_basis_points': scoreBasisPoints.clamp(0, 10000),
    });
    final status = _string(response['status'], 'Liderlik durumu eksik.');
    return LeaderboardStanding(
      available: status == 'available',
      percentile: _optionalInt(response['percentile_bucket']),
      cohortSize: _string(
        response['cohort_size_bucket'],
        'Kohort büyüklüğü eksik.',
      ),
    );
  }

  Future<bool> hasActiveEntitlement() async {
    final response = await _getJson('/api/v1/billing/entitlements');
    final items = _list(response['items'], 'Abonelik sonucu geçersiz.');
    return items.any((item) {
      final entitlement = _map(item, 'Abonelik kaydı geçersiz.');
      return entitlement['status'] == 'active';
    });
  }

  Future<_AcceptedJob> _acceptJsonJob(
    String path,
    Map<String, Object?> body,
  ) async {
    final token = await _requiredToken();
    final request = http.Request('POST', _resolve(path))
      ..headers.addAll(_headers(token))
      ..headers['Content-Type'] = 'application/json; charset=utf-8'
      ..body = jsonEncode(body);
    return _acceptedJob(await _send(request));
  }

  Future<Map<String, Object?>> _postJson(
    String path,
    Map<String, Object?> body,
  ) async {
    final token = await _requiredToken();
    final request = http.Request('POST', _resolve(path))
      ..headers.addAll(_headers(token))
      ..headers['Content-Type'] = 'application/json; charset=utf-8'
      ..body = jsonEncode(body);
    return _jsonObject(await _send(request));
  }

  Future<Map<String, Object?>> _getJson(String path) async {
    final token = await _requiredToken();
    final request = http.Request('GET', _resolve(path))
      ..headers.addAll(_headers(token));
    return _jsonObject(await _send(request));
  }

  Future<Map<String, Object?>> _awaitJob(_AcceptedJob accepted) async {
    for (var poll = 0; poll < maximumPollCount; poll++) {
      if (poll > 0) {
        await _wait(accepted.retryAfter);
      }
      final view = await _getJson(accepted.statusPath);
      final status = _string(view['status'], 'İş durumu eksik.');
      if (status == 'failed') {
        final failureCode =
            _optionalString(view['failure_code']) ?? 'IS_BASARISIZ';
        throw MakiApiException(
          failureCode,
          'İşlem tamamlanamadı. Lütfen yeniden deneyin.',
        );
      }
      if (status != 'succeeded') {
        continue;
      }
      if (view['result_state'] != 'ready') {
        throw const MakiApiException(
          'SONUC_SURESI_DOLDU',
          'İşlem sonucu artık erişilebilir değil. Lütfen yeniden deneyin.',
        );
      }
      final envelope = _map(view['result'], 'İşlem sonucu geçersiz.');
      return envelope;
    }
    throw const MakiApiException(
      'ISLEM_ZAMAN_ASIMI',
      'İşlem beklenenden uzun sürdü. Lütfen daha sonra yeniden deneyin.',
    );
  }

  _AcceptedJob _acceptedJob(http.Response response) {
    if (response.statusCode != 202) {
      throw _responseError(response);
    }
    final body = _jsonObject(response);
    final jobId = _string(body['job_id'], 'İş kimliği eksik.');
    final path = _string(body['status_url'], 'İş durum adresi eksik.');
    final retrySeconds = _optionalInt(body['retry_after_seconds']) ?? 2;
    return _AcceptedJob(
      jobId: jobId,
      statusPath: path,
      retryAfter: Duration(seconds: retrySeconds.clamp(1, 60)),
    );
  }

  Future<http.Response> _send(http.BaseRequest request) async {
    try {
      final streamed = await _client.send(request).timeout(requestTimeout);
      final response = await http.Response.fromStream(
        streamed,
      ).timeout(requestTimeout);
      if (response.bodyBytes.length > 1024 * 1024) {
        throw const MakiApiException(
          'YANIT_COK_BUYUK',
          'Sunucu yanıtı güvenli boyut sınırını aştı.',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _responseError(response);
      }
      return response;
    } on MakiApiException {
      rethrow;
    } on TimeoutException {
      throw const MakiApiException(
        'AG_ZAMAN_ASIMI',
        'Sunucu yanıt vermedi. Bağlantınızı kontrol edip yeniden deneyin.',
      );
    } on http.ClientException {
      throw const MakiApiException(
        'AG_BAGLANTI_HATASI',
        'Sunucuya bağlanılamadı. Bağlantınızı kontrol edin.',
      );
    }
  }

  MakiApiException _responseError(http.Response response) {
    try {
      final body = _jsonObject(response, allowErrorStatus: true);
      return MakiApiException(
        _optionalString(body['kod']) ??
            _optionalString(body['code']) ??
            'SUNUCU_HATASI',
        _optionalString(body['mesaj']) ??
            _optionalString(body['detail']) ??
            _optionalString(body['message']) ??
            'Sunucu isteği tamamlayamadı.',
      );
    } on FormatException {
      return const MakiApiException(
        'SUNUCU_YANITI_GECERSIZ',
        'Sunucudan geçersiz yanıt alındı.',
      );
    }
  }

  Map<String, Object?> _jsonObject(
    http.Response response, {
    bool allowErrorStatus = false,
  }) {
    if (!allowErrorStatus &&
        (response.statusCode < 200 || response.statusCode >= 300)) {
      throw _responseError(response);
    }
    if (response.bodyBytes.isEmpty) {
      throw const FormatException('Boş JSON yanıtı.');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    return _map(decoded, 'Sunucu yanıtı nesne değil.');
  }

  Future<String> _requiredToken() async {
    final token = (await tokenProvider())?.trim();
    if (token == null || token.isEmpty) {
      throw const MakiApiException(
        'OTURUM_GEREKLI',
        'Bu işlem için güvenli oturum açılması gerekiyor.',
      );
    }
    return token;
  }

  Map<String, String> _headers(String token) => {
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
    'Idempotency-Key': _secureIdentifier(32),
  };

  Uri _resolve(String path) => baseUri.resolve(path);
}

final class MakiApi {
  MakiApi._();

  static final MakiApiClient instance = MakiApiClient(
    baseUri: Uri.parse(ApiConfig.baseUrl),
    tokenProvider: SessionService.instance.accessToken,
  );
}

final class _AcceptedJob {
  const _AcceptedJob({
    required this.jobId,
    required this.statusPath,
    required this.retryAfter,
  });

  final String jobId;
  final String statusPath;
  final Duration retryAfter;
}

String newSessionId() => _secureIdentifier(26);

String _secureIdentifier(int length) {
  const alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  final random = Random.secure();
  return List.generate(
    length,
    (_) => alphabet[random.nextInt(alphabet.length)],
    growable: false,
  ).join();
}

Map<String, Object?> _map(Object? value, String message) {
  if (value is! Map<String, dynamic>) {
    throw FormatException(message);
  }
  return value.cast<String, Object?>();
}

List<Object?> _list(Object? value, String message) {
  if (value is! List<dynamic>) {
    throw FormatException(message);
  }
  return value.cast<Object?>();
}

String _string(Object? value, String message) {
  if (value is! String || value.isEmpty) {
    throw FormatException(message);
  }
  return value;
}

String? _optionalString(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

int? _optionalInt(Object? value) => switch (value) {
  int number => number,
  num number => number.toInt(),
  _ => null,
};

double _number(Object? value, String message) {
  if (value is! num || !value.isFinite) {
    throw FormatException(message);
  }
  return value.toDouble();
}

bool _boolean(Object? value, String message) {
  if (value is! bool) {
    throw FormatException(message);
  }
  return value;
}
