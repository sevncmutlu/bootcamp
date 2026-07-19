import 'dart:convert';

import 'package:maki_finance_core/maki_finance_core.dart';
import 'package:test/test.dart';

import 'test_model_fixture.dart';

void main() {
  test('sayısal, eksik ve kategorik dallar doğru yürünür', () async {
    final fixture = await signModel(
      modelJson: jsonEncode(_model),
      featureNames: const ['monthly_income', 'debt_ratio', 'segment'],
    );
    final model = await VerifiedLightGbmModel.load(
      modelBytes: fixture.modelBytes,
      manifestBytes: fixture.manifestBytes,
      publicKey: fixture.publicKey,
    );

    expect(model.predictRaw(const [4000, 0.2, 1]), closeTo(-0.35, 1e-12));
    expect(model.predictRaw(const [6000, null, 2]), closeTo(0.8, 1e-12));
    expect(model.predictRaw(const [null, 0.8, null]), closeTo(0.15, 1e-12));
    expect(
      model.predictProbability(const [6000, null, 2]),
      closeTo(0.6899744811276125, 1e-12),
    );
  });

  test('özellik sırası manifestle uyuşmazsa model yüklenmez', () async {
    final fixture = await signModel(
      modelJson: jsonEncode(_model),
      featureNames: const ['debt_ratio', 'monthly_income', 'segment'],
    );

    await expectLater(
      VerifiedLightGbmModel.load(
        modelBytes: fixture.modelBytes,
        manifestBytes: fixture.manifestBytes,
        publicKey: fixture.publicKey,
      ),
      throwsA(isA<ModelContractException>()),
    );
  });

  test('özellik sayısı farklıysa çıkarım reddedilir', () async {
    final fixture = await signModel(
      modelJson: jsonEncode(_model),
      featureNames: const ['monthly_income', 'debt_ratio', 'segment'],
    );
    final model = await VerifiedLightGbmModel.load(
      modelBytes: fixture.modelBytes,
      manifestBytes: fixture.manifestBytes,
      publicKey: fixture.publicKey,
    );

    expect(
      () => model.predictRaw(const [4000, 0.2]),
      throwsA(isA<ModelInputException>()),
    );
  });

  test('Zero eksik türü sıfırı varsayılan dala yollar', () async {
    final modelJson = jsonEncode({
      ..._model,
      'feature_names': ['a'],
      'tree_info': [
        {
          'tree_index': 0,
          'num_leaves': 2,
          'num_cat': 0,
          'shrinkage': 1.0,
          'tree_structure': {
            'split_index': 0,
            'split_feature': 0,
            'threshold': -1.0,
            'decision_type': '<=',
            'default_left': true,
            'missing_type': 'Zero',
            'left_child': {'leaf_index': 0, 'leaf_value': -0.5},
            'right_child': {'leaf_index': 1, 'leaf_value': 0.5},
          },
        },
      ],
    });
    final fixture = await signModel(
      modelJson: modelJson,
      featureNames: const ['a'],
    );
    final model = await VerifiedLightGbmModel.load(
      modelBytes: fixture.modelBytes,
      manifestBytes: fixture.manifestBytes,
      publicKey: fixture.publicKey,
    );

    expect(model.predictRaw(const [0]), -0.5);
    expect(model.predictRaw(const [1]), 0.5);
  });

  test('sürüm 2 Platt kalibrasyonu ham skora uygulanır', () async {
    const modelJson =
        '{"feature_names":["a"],"objective":"binary","tree_info":[]}';
    final signed = await signModel(
      modelJson: modelJson,
      featureNames: const ['a'],
      schemaVersion: 2,
      calibration: const {
        'method': 'platt',
        'parameters': [2.0, -1.0],
      },
      decisionThreshold: 0.2,
    );
    final model = await VerifiedLightGbmModel.load(
      modelBytes: signed.modelBytes,
      manifestBytes: signed.manifestBytes,
      publicKey: signed.publicKey,
    );

    expect(
      model.predictProbability(const [0]),
      closeTo(0.2689414213699951, 1e-12),
    );
    expect(model.manifest.decisionThreshold, 0.2);
    expect(model.manifest.datasetSha256, 'a' * 64);
  });
}

const _model = <String, Object>{
  'name': 'tree',
  'version': 'v4',
  'num_class': 1,
  'num_tree_per_iteration': 1,
  'objective': 'binary sigmoid:1',
  'average_output': false,
  'feature_names': ['monthly_income', 'debt_ratio', 'segment'],
  'tree_info': [
    {
      'tree_index': 0,
      'num_leaves': 2,
      'num_cat': 0,
      'shrinkage': 1.0,
      'tree_structure': {
        'split_index': 0,
        'split_feature': 0,
        'threshold': 5000.0,
        'decision_type': '<=',
        'default_left': true,
        'missing_type': 'NaN',
        'left_child': {'leaf_index': 0, 'leaf_value': -0.4},
        'right_child': {'leaf_index': 1, 'leaf_value': 0.6},
      },
    },
    {
      'tree_index': 1,
      'num_leaves': 2,
      'num_cat': 0,
      'shrinkage': 1.0,
      'tree_structure': {
        'split_index': 0,
        'split_feature': 1,
        'threshold': 0.5,
        'decision_type': '<=',
        'default_left': false,
        'missing_type': 'NaN',
        'left_child': {'leaf_index': 0, 'leaf_value': -0.2},
        'right_child': {'leaf_index': 1, 'leaf_value': 0.3},
      },
    },
    {
      'tree_index': 2,
      'num_leaves': 2,
      'num_cat': 1,
      'shrinkage': 1.0,
      'tree_structure': {
        'split_index': 0,
        'split_feature': 2,
        'threshold': '1||3',
        'decision_type': '==',
        'default_left': true,
        'missing_type': 'NaN',
        'left_child': {'leaf_index': 0, 'leaf_value': 0.25},
        'right_child': {'leaf_index': 1, 'leaf_value': -0.1},
      },
    },
  ],
};
