import 'dart:convert';
import 'dart:io';

import 'package:maki_finance_core/maki_finance_core.dart';
import 'package:test/test.dart';

import 'test_model_fixture.dart';

void main() {
  test('Python ve Dart skorları 100 vektörde eşittir', () async {
    final fixtureJson =
        jsonDecode(
              await File(
                '../../contracts/models/lightgbm/parity-fixture.json',
              ).readAsString(),
            )
            as Map<String, Object?>;
    final modelJson = jsonEncode(fixtureJson['model']);
    final featureNames = (fixtureJson['featureNames'] as List<Object?>)
        .cast<String>();
    final signed = await signModel(
      modelJson: modelJson,
      featureNames: featureNames,
    );
    final model = await VerifiedLightGbmModel.load(
      modelBytes: signed.modelBytes,
      manifestBytes: signed.manifestBytes,
      publicKey: signed.publicKey,
    );
    final vectors = fixtureJson['vectors'] as List<Object?>;

    expect(vectors, hasLength(100));
    for (final vectorValue in vectors) {
      final vector = vectorValue as Map<String, Object?>;
      final features = (vector['features'] as List<Object?>)
          .map((value) => (value as num?)?.toDouble())
          .toList(growable: false);
      expect(
        model.predictRaw(features),
        closeTo((vector['rawScore'] as num).toDouble(), 1e-12),
      );
      expect(
        model.predictProbability(features),
        closeTo((vector['probability'] as num).toDouble(), 1e-12),
      );
    }
  });
}
