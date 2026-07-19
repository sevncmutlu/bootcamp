import 'dart:convert';

/// Model manifesti sözleşme hatası.
final class ModelManifestException implements Exception {
  const ModelManifestException(this.message);

  final String message;

  @override
  String toString() => message;
}

enum ModelCalibrationMethod { none, platt, isotonic }

/// Cihazda uygulanacak olasılık kalibrasyonu.
final class ModelCalibration {
  ModelCalibration._({required this.method, required List<double> parameters})
    : parameters = List.unmodifiable(parameters);

  final ModelCalibrationMethod method;
  final List<double> parameters;

  static ModelCalibration none() => ModelCalibration._(
    method: ModelCalibrationMethod.none,
    parameters: const [],
  );

  static ModelCalibration parse(Object? value) {
    if (value is! Map<String, Object?> ||
        value.keys.toSet().difference(const {
          'method',
          'parameters',
        }).isNotEmpty ||
        !value.containsKey('method') ||
        !value.containsKey('parameters')) {
      throw const ModelManifestException('Model kalibrasyon şeması geçersiz.');
    }
    final methodText = value['method'];
    final method = switch (methodText) {
      'none' => ModelCalibrationMethod.none,
      'platt' => ModelCalibrationMethod.platt,
      'isotonic' => ModelCalibrationMethod.isotonic,
      _ => throw ModelManifestException(
        'Model kalibrasyon yöntemi desteklenmiyor: $methodText.',
      ),
    };
    final parameterValue = value['parameters'];
    if (parameterValue is! List<Object?> || parameterValue.length > 10000) {
      throw const ModelManifestException(
        'Model kalibrasyon parametreleri liste olmalıdır.',
      );
    }
    final parameters = parameterValue
        .map((item) {
          if (item is! num || !item.isFinite) {
            throw const ModelManifestException(
              'Model kalibrasyon parametreleri sonlu sayı olmalıdır.',
            );
          }
          return item.toDouble();
        })
        .toList(growable: false);
    _validateParameters(method, parameters);
    return ModelCalibration._(method: method, parameters: parameters);
  }

  Map<String, Object> toJson() => {
    'method': method.name,
    'parameters': parameters,
  };
}

/// İmzalı modelin değişmez dağıtım manifesti.
final class ModelManifest {
  ModelManifest._({
    required this.schemaVersion,
    required this.modelVersion,
    required List<String> featureNames,
    required this.trainedUntil,
    required String trainedUntilText,
    required this.modelSha256,
    required this.signature,
    required this.datasetSha256,
    required this.objective,
    required this.calibration,
    required this.decisionThreshold,
  }) : featureNames = List.unmodifiable(featureNames),
       _trainedUntilText = trainedUntilText;

  static const _versionOneFields = {
    'schemaVersion',
    'modelVersion',
    'featureNames',
    'trainedUntil',
    'modelSha256',
    'signature',
  };
  static const _versionTwoFields = {
    ..._versionOneFields,
    'datasetSha256',
    'objective',
    'calibration',
    'decisionThreshold',
  };

  final int schemaVersion;
  final String modelVersion;
  final List<String> featureNames;
  final DateTime trainedUntil;
  final String _trainedUntilText;
  final String modelSha256;
  final String signature;
  final String? datasetSha256;
  final String objective;
  final ModelCalibration calibration;
  final double decisionThreshold;

  static ModelManifest parse(List<int> bytes) {
    Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException catch (error) {
      throw ModelManifestException(
        'Model manifesti geçerli JSON değil: ${error.message}',
      );
    }
    if (decoded is! Map<String, Object?>) {
      throw const ModelManifestException(
        'Model manifestinin kökü nesne olmalıdır.',
      );
    }
    final schemaVersion = decoded['schemaVersion'];
    if (schemaVersion is! int || (schemaVersion != 1 && schemaVersion != 2)) {
      throw ModelManifestException(
        'Model manifesti şema sürümü desteklenmiyor: $schemaVersion.',
      );
    }
    final allowedFields = schemaVersion == 1
        ? _versionOneFields
        : _versionTwoFields;
    final unknownFields = decoded.keys.toSet().difference(allowedFields);
    if (unknownFields.isNotEmpty) {
      final fields = unknownFields.toList()..sort();
      throw ModelManifestException(
        'Model manifestinde bilinmeyen alan var: ${fields.join(', ')}.',
      );
    }
    if (!allowedFields.every(decoded.containsKey)) {
      throw const ModelManifestException(
        'Model manifestinde zorunlu alan eksik.',
      );
    }

    final modelVersion = _requiredString(decoded, 'modelVersion');
    if (modelVersion.length > 128) {
      throw const ModelManifestException('Model sürümü 128 karakteri aşamaz.');
    }
    final featureNames = _featureNames(decoded['featureNames']);
    final trainedUntilText = _requiredString(decoded, 'trainedUntil');
    final trainedUntil = DateTime.tryParse(trainedUntilText);
    if (trainedUntil == null ||
        !trainedUntil.isUtc ||
        !trainedUntilText.endsWith('Z')) {
      throw const ModelManifestException(
        'Eğitim bitiş zamanı UTC ISO-8601 olmalıdır.',
      );
    }
    final modelSha256 = _requiredString(decoded, 'modelSha256');
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(modelSha256)) {
      throw const ModelManifestException('Model SHA-256 özeti geçersiz.');
    }
    final signature = _requiredString(decoded, 'signature');
    if (signature.isEmpty) {
      throw const ModelManifestException('Model imzası boş olamaz.');
    }
    final String? datasetSha256;
    final String objective;
    final ModelCalibration calibration;
    final double decisionThreshold;
    if (schemaVersion == 2) {
      datasetSha256 = _requiredString(decoded, 'datasetSha256');
      if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(datasetSha256)) {
        throw const ModelManifestException('Veri SHA-256 özeti geçersiz.');
      }
      objective = _requiredString(decoded, 'objective');
      if (objective != 'binary') {
        throw const ModelManifestException(
          'Yalnızca ikili model amacı desteklenir.',
        );
      }
      calibration = ModelCalibration.parse(decoded['calibration']);
      final threshold = decoded['decisionThreshold'];
      if (threshold is! num ||
          !threshold.isFinite ||
          threshold < 0 ||
          threshold > 1) {
        throw const ModelManifestException('Model karar eşiği geçersiz.');
      }
      decisionThreshold = threshold.toDouble();
    } else {
      datasetSha256 = null;
      objective = 'binary';
      calibration = ModelCalibration.none();
      decisionThreshold = 0.5;
    }

    return ModelManifest._(
      schemaVersion: schemaVersion,
      modelVersion: modelVersion,
      featureNames: featureNames,
      trainedUntil: trainedUntil,
      trainedUntilText: trainedUntilText,
      modelSha256: modelSha256,
      signature: signature,
      datasetSha256: datasetSha256,
      objective: objective,
      calibration: calibration,
      decisionThreshold: decisionThreshold,
    );
  }

  List<int> canonicalBodyBytes() {
    final body = <String, Object>{
      'schemaVersion': schemaVersion,
      'modelVersion': modelVersion,
      'featureNames': featureNames,
      'trainedUntil': _trainedUntilText,
      'modelSha256': modelSha256,
      if (schemaVersion == 2) ...{
        'datasetSha256': datasetSha256!,
        'objective': objective,
        'calibration': calibration.toJson(),
        'decisionThreshold': decisionThreshold,
      },
    };
    return utf8.encode(_canonicalJson(body));
  }

  static List<String> _featureNames(Object? value) {
    if (value is! List<Object?> || value.isEmpty || value.length > 10000) {
      throw const ModelManifestException(
        'Model özellikleri boş olmayan bir liste olmalıdır.',
      );
    }
    final names = <String>[];
    final seen = <String>{};
    for (final item in value) {
      if (item is! String || item.trim().isEmpty || item.length > 128) {
        throw const ModelManifestException(
          'Model özellik adları dolu metin olmalıdır.',
        );
      }
      if (!seen.add(item)) {
        throw ModelManifestException(
          'Model özellik adları benzersiz olmalıdır: $item.',
        );
      }
      names.add(item);
    }
    return names;
  }

  static String _requiredString(Map<String, Object?> map, String field) {
    final value = map[field];
    if (value is! String || value.trim().isEmpty) {
      throw ModelManifestException(
        'Model manifesti alanı dolu metin olmalıdır: $field.',
      );
    }
    return value;
  }
}

void _validateParameters(
  ModelCalibrationMethod method,
  List<double> parameters,
) {
  if (method == ModelCalibrationMethod.none && parameters.isNotEmpty) {
    throw const ModelManifestException(
      'Kalibrasyonsuz model parametre taşıyamaz.',
    );
  }
  if (method == ModelCalibrationMethod.platt && parameters.length != 2) {
    throw const ModelManifestException(
      'Platt kalibrasyonu iki parametre taşımalıdır.',
    );
  }
  if (method == ModelCalibrationMethod.isotonic) {
    if (parameters.length < 2 || parameters.length.isOdd) {
      throw const ModelManifestException(
        'Isotonic kalibrasyon çiftleri geçersiz.',
      );
    }
    for (var index = 0; index < parameters.length; index += 2) {
      final probability = parameters[index + 1];
      if (probability < 0 || probability > 1) {
        throw const ModelManifestException('Isotonic olasılığı geçersiz.');
      }
      if (index > 0 && parameters[index - 2] >= parameters[index]) {
        throw const ModelManifestException(
          'Isotonic sınırları artan olmalıdır.',
        );
      }
    }
  }
}

String _canonicalJson(Object? value) {
  if (value is Map<String, Object?>) {
    final keys = value.keys.toList()..sort();
    final fields = keys.map(
      (key) => '${jsonEncode(key)}:${_canonicalJson(value[key])}',
    );
    return '{${fields.join(',')}}';
  }
  if (value is List<Object?>) {
    return '[${value.map(_canonicalJson).join(',')}]';
  }
  return jsonEncode(value);
}
