import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maki_app/services/maki_api_client.dart';

void main() {
  test(
    'koç isteğini kimlik ve tekrar güvenliği başlıklarıyla tamamlar',
    () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.url.path == '/api/v1/coach/queries') {
          return http.Response(
            jsonEncode({
              'job_id': '01J00000000000000000000000',
              'status_url': '/api/v1/jobs/01J00000000000000000000000',
              'retry_after_seconds': 1,
            }),
            202,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({
            'job_id': '01J00000000000000000000000',
            'kind': 'coach',
            'status': 'succeeded',
            'result_state': 'ready',
            'result': {
              'kind': 'coach',
              'schema_version': 1,
              'answer': {
                'answer': 'Bütçeni haftalık izle.',
                'safety': 'answered',
                'sources': [
                  {
                    'institution': 'TCMB',
                    'series_id': 'TP.FG.J0',
                    'period': '2026-06-01',
                    'value': '42.35',
                    'unit': 'yüzde',
                    'source_url': 'https://evds2.tcmb.gov.tr',
                  },
                ],
              },
            },
            'failure_code': null,
            'updated_at': '2026-07-19T20:00:00Z',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final api = MakiApiClient(
        baseUri: Uri.parse('https://api.maki.test'),
        tokenProvider: () async => 'gecerli-token',
        client: client,
        wait: (_) async {},
      );

      final reply = await api.askCoach(
        question: 'Bütçemi nasıl toparlarım?',
        sessionId: '01J00000000000000000000000',
      );

      expect(reply.answer, 'Bütçeni haftalık izle.');
      expect(reply.sources.single.institution, 'TCMB');
      expect(requests, hasLength(2));
      expect(requests.first.headers['Authorization'], 'Bearer gecerli-token');
      expect(requests.first.headers['Idempotency-Key'], isNotEmpty);
      expect(jsonDecode(requests.first.body), {
        'question': 'Bütçemi nasıl toparlarım?',
        'locale': 'tr-TR',
        'session_id': '01J00000000000000000000000',
      });
    },
  );

  test('sunucu hata sözleşmesini Türkçe istemci hatasına çevirir', () async {
    final api = MakiApiClient(
      baseUri: Uri.parse('https://api.maki.test'),
      tokenProvider: () async => 'gecerli-token',
      client: MockClient(
        (_) async => http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'kod': 'SERVIS_HAZIR_DEGIL',
              'mesaj': 'Koç servisi şu anda hazır değil.',
              'istek_kimligi': '01J00000000000000000000000',
              'tekrar_denenebilir': true,
              'ayrintilar': <Object?>[],
            }),
          ),
          503,
          headers: {'content-type': 'application/problem+json'},
        ),
      ),
      wait: (_) async {},
    );

    await expectLater(
      api.askCoach(
        question: 'Merhaba',
        sessionId: '01J00000000000000000000000',
      ),
      throwsA(
        isA<MakiApiException>()
            .having((error) => error.code, 'kod', 'SERVIS_HAZIR_DEGIL')
            .having(
              (error) => error.userMessage,
              'mesaj',
              'Koç servisi şu anda hazır değil.',
            ),
      ),
    );
  });

  test('erişim belirteci yoksa ağ isteği göndermeden kapalı kalır', () async {
    var called = false;
    final api = MakiApiClient(
      baseUri: Uri.parse('https://api.maki.test'),
      tokenProvider: () async => null,
      client: MockClient((_) async {
        called = true;
        return http.Response('', 500);
      }),
      wait: (_) async {},
    );

    await expectLater(
      api.askCoach(
        question: 'Merhaba',
        sessionId: '01J00000000000000000000000',
      ),
      throwsA(
        isA<MakiApiException>().having(
          (error) => error.code,
          'kod',
          'OTURUM_GEREKLI',
        ),
      ),
    );
    expect(called, isFalse);
  });
}
