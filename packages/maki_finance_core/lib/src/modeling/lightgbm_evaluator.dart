import 'dart:math' as math;

import 'package:cryptography/cryptography.dart';

import 'lightgbm_model.dart';
import 'lightgbm_parser.dart';
import 'model_manifest.dart';
import 'model_verifier.dart';

/// Yalnızca imza ve bütünlük denetiminden geçmiş LightGBM modeli.
final class VerifiedLightGbmModel {
  const VerifiedLightGbmModel._({
    required LightGbmModel model,
    required this.manifest,
  }) : _model = model;

  final LightGbmModel _model;
  final ModelManifest manifest;

  static Future<VerifiedLightGbmModel> load({
    required List<int> modelBytes,
    required List<int> manifestBytes,
    required SimplePublicKey publicKey,
  }) async {
    final manifest = await ModelVerifier(
      publicKey: publicKey,
    ).verify(modelBytes: modelBytes, manifestBytes: manifestBytes);
    final model = LightGbmParser.parse(modelBytes);
    if (!_sameStrings(model.featureNames, manifest.featureNames)) {
      throw const ModelContractException(
        'Model özellik sırası manifestle uyuşmuyor.',
      );
    }
    return VerifiedLightGbmModel._(model: model, manifest: manifest);
  }

  /// Özellik vektörünün ham ağaç skorunu döndürür.
  double predictRaw(List<num?> features) {
    _validateFeatures(features);
    var total = 0.0;
    for (final tree in _model.trees) {
      total += _evaluateNode(tree.root, features);
    }
    if (!total.isFinite) {
      throw const ModelContractException(
        'Model sonlu olmayan bir skor üretti.',
      );
    }
    return total;
  }

  /// İkili model skorunu taşma güvenli olasılığa dönüştürür.
  double predictProbability(List<num?> features) {
    final rawScore = predictRaw(features);
    final calibration = manifest.calibration;
    if (calibration.method == ModelCalibrationMethod.platt) {
      return _sigmoid(
        calibration.parameters[0] * rawScore + calibration.parameters[1],
      );
    }
    if (calibration.method == ModelCalibrationMethod.isotonic) {
      return _isotonicProbability(rawScore, calibration.parameters);
    }
    return _sigmoid(rawScore * _model.sigmoid);
  }

  double _sigmoid(double value) {
    if (value >= 0) {
      final expNegative = math.exp(-value);
      return 1 / (1 + expNegative);
    }
    final expPositive = math.exp(value);
    return expPositive / (1 + expPositive);
  }

  void _validateFeatures(List<num?> features) {
    if (features.length != _model.featureNames.length) {
      throw ModelInputException(
        'Özellik sayısı ${_model.featureNames.length} olmalıdır.',
      );
    }
    for (var index = 0; index < features.length; index++) {
      final value = features[index];
      if (value != null && value.isInfinite) {
        throw ModelInputException(
          'Özellik değeri sonsuz olamaz: ${_model.featureNames[index]}.',
        );
      }
    }
  }
}

double _isotonicProbability(double score, List<double> parameters) {
  for (var index = 0; index < parameters.length; index += 2) {
    if (score <= parameters[index]) {
      return parameters[index + 1];
    }
  }
  return parameters.last;
}

double _evaluateNode(LightGbmNode node, List<num?> features) {
  var current = node;
  while (current is LightGbmBranch) {
    final value = features[current.featureIndex];
    final goLeft = _goLeft(current, value);
    current = goLeft ? current.left : current.right;
  }
  return (current as LightGbmLeaf).value;
}

bool _goLeft(LightGbmBranch branch, num? value) {
  if (value == null ||
      (value.isNaN && branch.missingType != LightGbmMissingType.none) ||
      (value == 0 && branch.missingType == LightGbmMissingType.zero)) {
    return branch.defaultLeft;
  }
  final numericThreshold = branch.numericThreshold;
  if (numericThreshold != null) {
    return value <= numericThreshold;
  }

  if (value.isNegative || value != value.truncateToDouble()) {
    return branch.defaultLeft;
  }
  return branch.categories!.contains(value.toInt());
}

bool _sameStrings(List<String> left, List<String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
