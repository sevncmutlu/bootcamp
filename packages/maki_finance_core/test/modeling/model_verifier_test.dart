import 'dart:convert';

import 'package:maki_finance_core/maki_finance_core.dart';
import 'package:test/test.dart';

import 'test_model_fixture.dart';

void main() {
  const modelJson =
      '{"feature_names":["a"],"objective":"binary",'
      '"tree_info":[]}';

  test('imzasız model yüklenmez', () async {
    final fixture = await signModel(
      modelJson: modelJson,
      featureNames: const ['a'],
    );
    final manifest =
        jsonDecode(utf8.decode(fixture.manifestBytes)) as Map<String, Object?>;
    manifest.remove('signature');

    await expectLater(
      ModelVerifier(publicKey: fixture.publicKey).verify(
        modelBytes: fixture.modelBytes,
        manifestBytes: utf8.encode(jsonEncode(manifest)),
      ),
      throwsA(isA<ModelVerificationException>()),
    );
  });

  test('geçerli imza ve model özeti kabul edilir', () async {
    final fixture = await signModel(
      modelJson: modelJson,
      featureNames: const ['a'],
    );

    final manifest = await ModelVerifier(publicKey: fixture.publicKey).verify(
      modelBytes: fixture.modelBytes,
      manifestBytes: fixture.manifestBytes,
    );

    expect(manifest.modelVersion, 'test-1');
    expect(manifest.featureNames, const ['a']);
  });

  test('imzalı fakat yanlış model özeti reddedilir', () async {
    final fixture = await signModel(
      modelJson: modelJson,
      featureNames: const ['a'],
      modelDigest: '0' * 64,
    );

    await expectLater(
      ModelVerifier(publicKey: fixture.publicKey).verify(
        modelBytes: fixture.modelBytes,
        manifestBytes: fixture.manifestBytes,
      ),
      throwsA(
        isA<ModelVerificationException>().having(
          (error) => error.code,
          'kod',
          'MODEL_DIGEST_MISMATCH',
        ),
      ),
    );
  });

  test('manifestte bilinmeyen alan reddedilir', () async {
    final fixture = await signModel(
      modelJson: modelJson,
      featureNames: const ['a'],
    );
    final manifest =
        jsonDecode(utf8.decode(fixture.manifestBytes)) as Map<String, Object?>;
    manifest['debug'] = true;

    await expectLater(
      ModelVerifier(publicKey: fixture.publicKey).verify(
        modelBytes: fixture.modelBytes,
        manifestBytes: utf8.encode(jsonEncode(manifest)),
      ),
      throwsA(isA<ModelVerificationException>()),
    );
  });
}
