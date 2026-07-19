import 'dart:convert';

import 'lightgbm_model.dart';

/// Desteklenen LightGBM JSON sözleşmesini ayrıştırır.
abstract final class LightGbmParser {
  static const _maximumTrees = 10000;
  static const _maximumFeatures = 10000;
  static const _maximumDepth = 256;
  static const _maximumNodes = 1000000;

  static const _rootFields = {
    'name',
    'version',
    'num_class',
    'num_tree_per_iteration',
    'label_index',
    'max_feature_idx',
    'objective',
    'average_output',
    'feature_names',
    'monotone_constraints',
    'feature_infos',
    'tree_info',
    'feature_importances',
    'pandas_categorical',
    'parameters',
  };
  static const _treeFields = {
    'tree_index',
    'num_leaves',
    'num_cat',
    'shrinkage',
    'tree_structure',
  };
  static const _branchFields = {
    'split_index',
    'split_feature',
    'split_gain',
    'threshold',
    'decision_type',
    'default_left',
    'missing_type',
    'internal_value',
    'internal_weight',
    'internal_count',
    'left_child',
    'right_child',
  };
  static const _leafFields = {
    'leaf_index',
    'leaf_value',
    'leaf_weight',
    'leaf_count',
  };

  static LightGbmModel parse(List<int> bytes) {
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException catch (error) {
      throw ModelContractException(
        'LightGBM modeli geçerli JSON değil: ${error.message}',
      );
    }
    final root = _map(decoded, 'Model kökü nesne olmalıdır.');
    _rejectUnknown(root, _rootFields, 'model kökü');

    final objective = _string(root, 'objective');
    if (objective != 'binary' && !objective.startsWith('binary ')) {
      throw ModelContractException(
        'Yalnızca binary LightGBM amacı desteklenir: $objective.',
      );
    }
    final sigmoid = _sigmoid(objective);
    final numberOfClasses = root['num_class'];
    if (numberOfClasses != null && numberOfClasses != 1) {
      throw const ModelContractException(
        'LightGBM modeli tek sınıf skoru üretmelidir.',
      );
    }
    final treesPerIteration = root['num_tree_per_iteration'];
    if (treesPerIteration != null && treesPerIteration != 1) {
      throw const ModelContractException(
        'Çok sınıflı LightGBM ağaç düzeni desteklenmez.',
      );
    }
    if (root['average_output'] == true) {
      throw const ModelContractException('Ortalama ağaç çıktısı desteklenmez.');
    }

    final featureNames = _strings(root['feature_names'], 'feature_names');
    if (featureNames.isEmpty || featureNames.length > _maximumFeatures) {
      throw const ModelContractException('Model özellik sayısı geçersiz.');
    }
    if (featureNames.toSet().length != featureNames.length) {
      throw const ModelContractException(
        'Model özellik adları benzersiz olmalıdır.',
      );
    }
    final treeValues = _list(root['tree_info'], 'tree_info');
    if (treeValues.length > _maximumTrees) {
      throw const ModelContractException(
        'Model ağaç sayısı güvenlik sınırını aşıyor.',
      );
    }

    var nodeCount = 0;
    final trees = <LightGbmTree>[];
    for (final treeValue in treeValues) {
      final tree = _map(treeValue, 'Ağaç bilgisi nesne olmalıdır.');
      _rejectUnknown(tree, _treeFields, 'ağaç bilgisi');
      final structure = tree['tree_structure'];
      trees.add(
        LightGbmTree(
          root: _node(
            structure,
            featureCount: featureNames.length,
            depth: 0,
            onNode: () {
              nodeCount++;
              if (nodeCount > _maximumNodes) {
                throw const ModelContractException(
                  'Model düğüm sayısı güvenlik sınırını aşıyor.',
                );
              }
            },
          ),
        ),
      );
    }
    return LightGbmModel(
      featureNames: featureNames,
      trees: trees,
      sigmoid: sigmoid,
    );
  }

  static LightGbmNode _node(
    Object? value, {
    required int featureCount,
    required int depth,
    required void Function() onNode,
  }) {
    if (depth > _maximumDepth) {
      throw const ModelContractException(
        'Model ağaç derinliği güvenlik sınırını aşıyor.',
      );
    }
    onNode();
    final node = _map(value, 'Ağaç düğümü nesne olmalıdır.');
    if (node.containsKey('leaf_value')) {
      _rejectUnknown(node, _leafFields, 'yaprak');
      return LightGbmLeaf(_finiteNumber(node, 'leaf_value'));
    }

    _rejectUnknown(node, _branchFields, 'dal');
    final featureIndex = _integer(node, 'split_feature');
    if (featureIndex < 0 || featureIndex >= featureCount) {
      throw ModelContractException(
        'Dal özellik sırası geçersiz: $featureIndex.',
      );
    }
    final defaultLeft = node['default_left'];
    if (defaultLeft is! bool) {
      throw const ModelContractException(
        'Dalın default_left alanı doğru/yanlış olmalıdır.',
      );
    }
    final missingType = switch (node['missing_type']) {
      'None' => LightGbmMissingType.none,
      'Zero' => LightGbmMissingType.zero,
      'NaN' => LightGbmMissingType.nan,
      final Object? value => throw ModelContractException(
        'Eksik değer türü desteklenmiyor: $value.',
      ),
    };
    final left = _node(
      node['left_child'],
      featureCount: featureCount,
      depth: depth + 1,
      onNode: onNode,
    );
    final right = _node(
      node['right_child'],
      featureCount: featureCount,
      depth: depth + 1,
      onNode: onNode,
    );
    final decisionType = _string(node, 'decision_type');
    if (decisionType == '<=') {
      return LightGbmBranch.numeric(
        featureIndex: featureIndex,
        threshold: _finiteNumber(node, 'threshold'),
        defaultLeft: defaultLeft,
        missingType: missingType,
        left: left,
        right: right,
      );
    }
    if (decisionType == '==') {
      final threshold = _string(node, 'threshold');
      final categories = <int>{};
      for (final part in threshold.split('||')) {
        final category = int.tryParse(part);
        if (category == null || category < 0) {
          throw const ModelContractException('Kategorik dal eşiği geçersiz.');
        }
        categories.add(category);
      }
      if (categories.isEmpty) {
        throw const ModelContractException(
          'Kategorik dal en az bir değer taşımalıdır.',
        );
      }
      return LightGbmBranch.categorical(
        featureIndex: featureIndex,
        categories: categories,
        defaultLeft: defaultLeft,
        missingType: missingType,
        left: left,
        right: right,
      );
    }
    throw ModelContractException(
      'LightGBM karar türü desteklenmiyor: $decisionType.',
    );
  }

  static Map<String, Object?> _map(Object? value, String message) {
    if (value is! Map<String, Object?>) {
      throw ModelContractException(message);
    }
    return value;
  }

  static List<Object?> _list(Object? value, String field) {
    if (value is! List<Object?>) {
      throw ModelContractException('$field alanı liste olmalıdır.');
    }
    return value;
  }

  static List<String> _strings(Object? value, String field) {
    final list = _list(value, field);
    final strings = <String>[];
    for (final item in list) {
      if (item is! String || item.trim().isEmpty) {
        throw ModelContractException(
          '$field alanı dolu metinlerden oluşmalıdır.',
        );
      }
      strings.add(item);
    }
    return strings;
  }

  static String _string(Map<String, Object?> map, String field) {
    final value = map[field];
    if (value is! String || value.isEmpty) {
      throw ModelContractException('$field alanı dolu metin olmalıdır.');
    }
    return value;
  }

  static int _integer(Map<String, Object?> map, String field) {
    final value = map[field];
    if (value is! int) {
      throw ModelContractException('$field alanı tamsayı olmalıdır.');
    }
    return value;
  }

  static double _finiteNumber(Map<String, Object?> map, String field) {
    final value = map[field];
    if (value is! num || !value.isFinite) {
      throw ModelContractException('$field alanı sonlu sayı olmalıdır.');
    }
    return value.toDouble();
  }

  static double _sigmoid(String objective) {
    if (objective == 'binary') {
      return 1;
    }
    var sigmoid = 1.0;
    for (final token in objective.split(' ').skip(1)) {
      final parts = token.split(':');
      if (parts.length != 2 || parts.first != 'sigmoid') {
        throw ModelContractException(
          'Binary model amacı parametresi desteklenmiyor: $token.',
        );
      }
      final parsed = double.tryParse(parts.last);
      if (parsed == null || !parsed.isFinite || parsed <= 0) {
        throw const ModelContractException(
          'Binary sigmoid değeri sıfırdan büyük olmalıdır.',
        );
      }
      sigmoid = parsed;
    }
    return sigmoid;
  }

  static void _rejectUnknown(
    Map<String, Object?> map,
    Set<String> allowed,
    String location,
  ) {
    final unknown = map.keys.toSet().difference(allowed);
    if (unknown.isEmpty) {
      return;
    }
    final fields = unknown.toList()..sort();
    throw ModelContractException(
      '$location içinde bilinmeyen alan var: ${fields.join(', ')}.',
    );
  }
}
