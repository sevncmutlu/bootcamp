import 'cholesky.dart';

/// LinTS durum veya olay sözleşmesi geçersiz.
final class LinTsContractException implements Exception {
  const LinTsContractException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Yeni bir arm için başlangıç ayarı.
final class LinTsArmSeed {
  const LinTsArmSeed({
    required this.armId,
    required this.messageKey,
    this.rewardVector = const [],
  });

  final String armId;
  final String messageKey;
  final List<double> rewardVector;
}

/// Tek bir armın posterior yeterli istatistikleri.
final class LinTsArmState {
  LinTsArmState._({
    required this.armId,
    required this.messageKey,
    required List<List<double>> precisionMatrix,
    required List<double> rewardVector,
  }) : precisionMatrix = _immutableMatrix(precisionMatrix),
       rewardVector = List.unmodifiable(rewardVector);

  final String armId;
  final String messageKey;
  final List<List<double>> precisionMatrix;
  final List<double> rewardVector;

  LinTsArmState update(List<double> context, double reward) {
    final matrix = precisionMatrix
        .map((row) => row.toList(growable: false))
        .toList(growable: false);
    final vector = rewardVector.toList(growable: false);
    for (var row = 0; row < context.length; row++) {
      vector[row] += reward * context[row];
      for (var column = 0; column < context.length; column++) {
        matrix[row][column] += context[row] * context[column];
      }
    }
    return LinTsArmState._(
      armId: armId,
      messageKey: messageKey,
      precisionMatrix: matrix,
      rewardVector: vector,
    );
  }

  Map<String, Object> toJson() => {
    'armId': armId,
    'messageKey': messageKey,
    'precisionMatrix': precisionMatrix,
    'rewardVector': rewardVector,
  };
}

/// Karar ile ödül arasındaki kalıcı bağ.
final class LinTsDecisionRecord {
  LinTsDecisionRecord._({
    required this.decisionId,
    required this.armId,
    required List<double> context,
    required this.reward,
  }) : context = List.unmodifiable(context);

  factory LinTsDecisionRecord.pending({
    required String decisionId,
    required String armId,
    required List<double> context,
  }) => LinTsDecisionRecord._(
    decisionId: decisionId,
    armId: armId,
    context: context,
    reward: null,
  );

  final String decisionId;
  final String armId;
  final List<double> context;
  final double? reward;

  bool get rewarded => reward != null;

  LinTsDecisionRecord applyReward(double value) => LinTsDecisionRecord._(
    decisionId: decisionId,
    armId: armId,
    context: context,
    reward: value,
  );

  Map<String, Object?> toJson() => {
    'decisionId': decisionId,
    'armId': armId,
    'context': context,
    'reward': reward,
  };
}

/// Sürümlü ve JSON ile kalıcılaştırılabilir LinTS durumu.
final class LinTsState {
  LinTsState._({
    required this.policyId,
    required this.dimension,
    required this.sequence,
    required List<LinTsArmState> arms,
    required List<LinTsDecisionRecord> decisions,
  }) : arms = List.unmodifiable(arms),
       decisions = List.unmodifiable(decisions);

  factory LinTsState.initial({
    required String policyId,
    required int dimension,
    required List<LinTsArmSeed> arms,
    double priorPrecision = 1,
  }) {
    _validateHeader(policyId: policyId, dimension: dimension, sequence: 0);
    if (arms.isEmpty) {
      throw const LinTsContractException('LinTS en az bir arm taşımalıdır.');
    }
    if (!priorPrecision.isFinite || priorPrecision <= 0) {
      throw const LinTsContractException(
        'Önsel kesinlik sıfırdan büyük olmalıdır.',
      );
    }
    final ids = <String>{};
    final states = arms.map((seed) {
      _validateIdentity(seed.armId, 'Arm kimliği');
      _validateIdentity(seed.messageKey, 'Mesaj anahtarı');
      if (!ids.add(seed.armId)) {
        throw LinTsContractException(
          'Arm kimlikleri benzersiz olmalıdır: ${seed.armId}.',
        );
      }
      final rewardVector = seed.rewardVector.isEmpty
          ? List<double>.filled(dimension, 0)
          : _finiteVector(
              seed.rewardVector,
              dimension: dimension,
              field: 'Ödül vektörü',
            );
      final matrix = List.generate(
        dimension,
        (row) => List.generate(
          dimension,
          (column) => row == column ? priorPrecision : 0.0,
        ),
      );
      return LinTsArmState._(
        armId: seed.armId,
        messageKey: seed.messageKey,
        precisionMatrix: matrix,
        rewardVector: rewardVector,
      );
    }).toList()..sort((left, right) => left.armId.compareTo(right.armId));
    return LinTsState._(
      policyId: policyId,
      dimension: dimension,
      sequence: 0,
      arms: states,
      decisions: const [],
    );
  }

  factory LinTsState.fromJson(Map<String, Object?> json) {
    const fields = {
      'schemaVersion',
      'policyId',
      'dimension',
      'sequence',
      'arms',
      'decisions',
    };
    _requireFields(json, fields, 'LinTS durumu');
    if (json['schemaVersion'] != schemaVersion) {
      throw LinTsContractException(
        'LinTS şema sürümü desteklenmiyor: ${json['schemaVersion']}.',
      );
    }
    final policyId = _string(json, 'policyId');
    final dimension = _integer(json, 'dimension');
    final sequence = _integer(json, 'sequence');
    _validateHeader(
      policyId: policyId,
      dimension: dimension,
      sequence: sequence,
    );

    final armValues = _list(json, 'arms');
    if (armValues.isEmpty) {
      throw const LinTsContractException('LinTS en az bir arm taşımalıdır.');
    }
    final arms = <LinTsArmState>[];
    final armIds = <String>{};
    for (final value in armValues) {
      final map = _object(value, 'Arm nesne olmalıdır.');
      _requireFields(map, const {
        'armId',
        'messageKey',
        'precisionMatrix',
        'rewardVector',
      }, 'Arm');
      final armId = _string(map, 'armId');
      final messageKey = _string(map, 'messageKey');
      _validateIdentity(armId, 'Arm kimliği');
      _validateIdentity(messageKey, 'Mesaj anahtarı');
      if (!armIds.add(armId)) {
        throw LinTsContractException(
          'Arm kimlikleri benzersiz olmalıdır: $armId.',
        );
      }
      final matrix = _matrix(map['precisionMatrix'], dimension: dimension);
      final vector = _numberList(map['rewardVector']);
      final rewardVector = _finiteVector(
        vector,
        dimension: dimension,
        field: 'Ödül vektörü',
      );
      try {
        Cholesky.decompose(matrix);
      } on NumericalStabilityException catch (error) {
        throw LinTsContractException(
          'Arm kesinlik matrisi geçersiz: ${error.message}',
        );
      }
      arms.add(
        LinTsArmState._(
          armId: armId,
          messageKey: messageKey,
          precisionMatrix: matrix,
          rewardVector: rewardVector,
        ),
      );
    }
    arms.sort((left, right) => left.armId.compareTo(right.armId));

    final decisions = <LinTsDecisionRecord>[];
    final decisionIds = <String>{};
    for (final value in _list(json, 'decisions')) {
      final map = _object(value, 'Karar kaydı nesne olmalıdır.');
      _requireFields(map, const {
        'decisionId',
        'armId',
        'context',
        'reward',
      }, 'Karar kaydı');
      final decisionId = _string(map, 'decisionId');
      final armId = _string(map, 'armId');
      if (!decisionIds.add(decisionId)) {
        throw LinTsContractException(
          'Karar kimlikleri benzersiz olmalıdır: $decisionId.',
        );
      }
      if (!armIds.contains(armId)) {
        throw LinTsContractException('Karar bilinmeyen arma bağlı: $armId.');
      }
      final context = _finiteVector(
        _numberList(map['context']),
        dimension: dimension,
        field: 'Karar bağlamı',
      );
      final rewardValue = map['reward'];
      final double? reward;
      if (rewardValue == null) {
        reward = null;
      } else if (rewardValue is num &&
          rewardValue.isFinite &&
          rewardValue >= 0 &&
          rewardValue <= 1) {
        reward = rewardValue.toDouble();
      } else {
        throw const LinTsContractException(
          'Karar ödülü 0 ile 1 arasında olmalıdır.',
        );
      }
      decisions.add(
        LinTsDecisionRecord._(
          decisionId: decisionId,
          armId: armId,
          context: context,
          reward: reward,
        ),
      );
    }
    return LinTsState._(
      policyId: policyId,
      dimension: dimension,
      sequence: sequence,
      arms: arms,
      decisions: decisions,
    );
  }

  static const schemaVersion = 1;

  final String policyId;
  final int dimension;
  final int sequence;
  final List<LinTsArmState> arms;
  final List<LinTsDecisionRecord> decisions;

  LinTsState addDecision(LinTsDecisionRecord record) => LinTsState._(
    policyId: policyId,
    dimension: dimension,
    sequence: sequence + 1,
    arms: arms,
    decisions: [...decisions, record],
  );

  LinTsState applyReward({
    required String decisionId,
    required List<double> context,
    required double reward,
  }) {
    final decisionIndex = decisions.indexWhere(
      (decision) => decision.decisionId == decisionId,
    );
    if (decisionIndex < 0) {
      throw LinTsContractException(
        'Ödül bilinmeyen karara bağlı: $decisionId.',
      );
    }
    final decision = decisions[decisionIndex];
    if (!_sameVector(decision.context, context)) {
      throw const LinTsContractException(
        'Ödül bağlamı karar bağlamıyla uyuşmuyor.',
      );
    }
    if (decision.rewarded) {
      if (decision.reward != reward) {
        throw const LinTsContractException(
          'Aynı karar farklı ödülle tekrar uygulanamaz.',
        );
      }
      return this;
    }

    final armIndex = arms.indexWhere((arm) => arm.armId == decision.armId);
    final updatedArms = [...arms];
    updatedArms[armIndex] = updatedArms[armIndex].update(context, reward);
    final updatedDecisions = [...decisions];
    updatedDecisions[decisionIndex] = decision.applyReward(reward);
    return LinTsState._(
      policyId: policyId,
      dimension: dimension,
      sequence: sequence,
      arms: updatedArms,
      decisions: updatedDecisions,
    );
  }

  Map<String, Object> toJson() => {
    'schemaVersion': schemaVersion,
    'policyId': policyId,
    'dimension': dimension,
    'sequence': sequence,
    'arms': arms.map((arm) => arm.toJson()).toList(growable: false),
    'decisions': decisions
        .map((decision) => decision.toJson())
        .toList(growable: false),
  };

  static void _validateHeader({
    required String policyId,
    required int dimension,
    required int sequence,
  }) {
    _validateIdentity(policyId, 'Politika kimliği');
    if (dimension <= 0 || dimension > 128) {
      throw const LinTsContractException(
        'LinTS boyutu 1 ile 128 arasında olmalıdır.',
      );
    }
    if (sequence < 0) {
      throw const LinTsContractException('Karar sırası negatif olamaz.');
    }
  }
}

List<List<double>> _immutableMatrix(List<List<double>> matrix) =>
    List.unmodifiable(matrix.map(List<double>.unmodifiable));

List<double> _finiteVector(
  List<num> values, {
  required int dimension,
  required String field,
}) {
  if (values.length != dimension) {
    throw LinTsContractException('$field boyutu $dimension olmalıdır.');
  }
  final result = <double>[];
  for (final value in values) {
    final converted = value.toDouble();
    if (!converted.isFinite) {
      throw LinTsContractException('$field sonlu değerler taşımalıdır.');
    }
    result.add(converted);
  }
  return result;
}

List<List<double>> _matrix(Object? value, {required int dimension}) {
  if (value is! List<Object?> || value.length != dimension) {
    throw LinTsContractException(
      'Kesinlik matrisi $dimension satır taşımalıdır.',
    );
  }
  return value
      .map(
        (row) => _finiteVector(
          _numberList(row),
          dimension: dimension,
          field: 'Kesinlik matrisi satırı',
        ),
      )
      .toList(growable: false);
}

List<num> _numberList(Object? value) {
  if (value is! List<Object?>) {
    throw const LinTsContractException('Sayısal liste bekleniyor.');
  }
  final result = <num>[];
  for (final item in value) {
    if (item is! num) {
      throw const LinTsContractException('Liste yalnızca sayı taşımalıdır.');
    }
    result.add(item);
  }
  return result;
}

Map<String, Object?> _object(Object? value, String message) {
  if (value is! Map<String, Object?>) {
    throw LinTsContractException(message);
  }
  return value;
}

List<Object?> _list(Map<String, Object?> map, String field) {
  final value = map[field];
  if (value is! List<Object?>) {
    throw LinTsContractException('$field alanı liste olmalıdır.');
  }
  return value;
}

String _string(Map<String, Object?> map, String field) {
  final value = map[field];
  if (value is! String || value.trim().isEmpty) {
    throw LinTsContractException('$field alanı dolu metin olmalıdır.');
  }
  return value;
}

int _integer(Map<String, Object?> map, String field) {
  final value = map[field];
  if (value is! int) {
    throw LinTsContractException('$field alanı tamsayı olmalıdır.');
  }
  return value;
}

void _requireFields(
  Map<String, Object?> map,
  Set<String> fields,
  String location,
) {
  final actual = map.keys.toSet();
  final missing = fields.difference(actual);
  final unknown = actual.difference(fields);
  if (missing.isNotEmpty || unknown.isNotEmpty) {
    throw LinTsContractException('$location alanları sözleşmeyle uyuşmuyor.');
  }
}

void _validateIdentity(String value, String field) {
  if (value.trim().isEmpty || value.length > 128) {
    throw LinTsContractException('$field boş olamaz ve 128 karakteri aşamaz.');
  }
}

bool _sameVector(List<double> left, List<double> right) {
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
